import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/live_socket.dart';
import '../data/api/pi_api.dart';
import '../data/models/models.dart';
import '../data/storage.dart';

/// 연결 상태. 홈 상단 칩과 기기 상태 화면에 그대로 보인다.
enum LinkStatus {
  disconnected('연결 안 됨'),
  connecting('연결 중'),
  connected('연결됨'),
  retrying('다시 연결하는 중');

  const LinkStatus(this.label);
  final String label;
}

class PiConnection {
  const PiConnection({
    this.status = LinkStatus.disconnected,
    this.device,
    this.token,
    this.info,
    this.retryIn,
    this.message,
  });

  final LinkStatus status;

  /// 페어링된 현재 기기. 연결 안 됨이면 마지막으로 쓴 기기(입력칸 채우기용, 토큰 없음).
  final PiDevice? device;
  final String? token;
  final DeviceInfo? info;
  final Duration? retryIn; // retrying 일 때 다음 시도까지
  final String? message; // 연결 화면에 보여 줄 안내 (토큰 만료 등)

  bool get isPaired => device != null && token != null;
}

// ---------------------------------------------------------------- 의존성 (테스트에서 override)

/// main() 에서 override 한다.
final appStorageProvider = Provider<AppStorage>((ref) => AppStorage(SecureKv()));

/// 앱 시작 때 읽어 둔 저장값 (router 의 첫 화면을 동기로 정하려고 main 에서 미리 읽는다)
final savedSessionProvider = Provider<SavedSession>((ref) => const SavedSession());

typedef PiApiFactory = PiApi Function(PiDevice device, String? token);
typedef LiveSocketFactory = LiveSocket Function(PiDevice device, String token, void Function() onReconnected);

final piApiFactoryProvider = Provider<PiApiFactory>((ref) => (device, token) => PiApi(device: device, token: token));

final liveSocketFactoryProvider = Provider<LiveSocketFactory>(
  (ref) => (device, token, onReconnected) => LiveSocket(device: device, token: token, onReconnected: onReconnected),
);

// ---------------------------------------------------------------- 상태

final connectionProvider = NotifierProvider<ConnectionNotifier, PiConnection>(ConnectionNotifier.new);

/// 현재 기기의 REST 클라이언트. 페어링 전에는 null.
final piApiProvider = Provider<PiApi?>((ref) {
  final (device, token) = ref.watch(connectionProvider.select((c) => (c.device, c.token)));
  if (device == null || token == null) return null;
  final api = ref.read(piApiFactoryProvider)(device, token);
  ref.onDispose(api.close);
  return api;
});

/// 페어링 실패 단계
enum PairStep { info, pair, save }

class PairException implements Exception {
  const PairException(this.step, this.cause);
  final PairStep step;
  final Object cause;

  @override
  String toString() => 'PairException($step, $cause)';
}

class ConnectionNotifier extends Notifier<PiConnection> {
  LiveSocket? _socket;
  StreamSubscription<LiveSocketState>? _stateSub;
  StreamSubscription<LiveMessage>? _msgSub;
  bool _tokenChecked = false;

  final _messages = StreamController<LiveMessage>.broadcast();
  final _reconnected = StreamController<void>.broadcast();

  /// 실시간 frame/event. 소켓이 바뀌어도(다시 페어링) 같은 스트림을 계속 쓴다.
  Stream<LiveMessage> get messages => _messages.stream;

  /// 끊겼다가 다시 붙을 때마다. events 쪽에서 `/api/events?since=` 로 빈 기간을 채운다.
  Stream<void> get reconnected => _reconnected.stream;

  @override
  PiConnection build() {
    ref.onDispose(() {
      _stopLive();
      _messages.close();
      _reconnected.close();
    });
    final saved = ref.read(savedSessionProvider);
    if (!saved.isPaired) {
      return PiConnection(device: saved.device);
    }
    scheduleMicrotask(_startLive);
    return PiConnection(status: LinkStatus.connecting, device: saved.device, token: saved.token);
  }

  /// IP + 6자리 코드 → `/api/info` 로 확인 → `/api/pair` → 토큰 저장 → 실시간 연결 시작.
  /// 실패하면 [PairException] (어느 단계에서 실패했는지 + PiApiException).
  Future<void> pair(PiDevice device, String code) async {
    final api = ref.read(piApiFactoryProvider)(device, null);
    try {
      final DeviceInfo info;
      try {
        info = await api.info();
      } catch (e) {
        throw PairException(PairStep.info, e);
      }
      final String token;
      try {
        token = await api.pair(code);
      } catch (e) {
        throw PairException(PairStep.pair, e);
      }
      final named = device.copyWith(name: info.name);
      try {
        await ref.read(appStorageProvider).save(named, token);
      } catch (e) {
        throw PairException(PairStep.save, e);
      }
      if (!ref.mounted) return;
      _stopLive();
      _tokenChecked = true; // 방금 받은 토큰
      state = PiConnection(status: LinkStatus.connecting, device: named, token: token, info: info);
      _startLive();
    } finally {
      api.close();
    }
  }

  /// 토큰을 지우고 연결 화면으로 (마지막 주소는 남긴다). 폰에 보관한 사진은 지우지 않는다.
  Future<void> forget({String? message}) async {
    _stopLive();
    await ref.read(appStorageProvider).clearToken();
    if (!ref.mounted) return;
    state = PiConnection(device: state.device, message: message);
  }

  /// 설정의 "연결 해제": 토큰과 마지막 기기까지 지우고 연결 화면으로. 폰에 보관한 사진은 그대로.
  Future<void> disconnect() async {
    _stopLive();
    await ref.read(appStorageProvider).clearDevice();
    if (!ref.mounted) return;
    _tokenChecked = false;
    state = const PiConnection();
  }

  bool _paused = false;
  bool _announceOnConnect = false;

  /// 앱이 화면에서 사라지면 실시간 연결을 끊는다 (초당 5번 프레임 → 배터리).
  /// 페어링 정보는 그대로 두고, [resumeLive] 때 다시 붙는다.
  void pauseLive() {
    if (_paused) return;
    _paused = true;
    if (_socket == null) return;
    _stopLive();
    if (ref.mounted && state.isPaired) {
      state = PiConnection(status: LinkStatus.disconnected, device: state.device, token: state.token, info: state.info);
    }
  }

  /// 앱이 다시 보이면 연결. 붙으면 [reconnected] 로 알려서 그동안 빈 기간을 채운다.
  void resumeLive() {
    if (!_paused) return;
    _paused = false;
    if (!ref.mounted || !state.isPaired || _socket != null) return;
    _announceOnConnect = true;
    state = PiConnection(status: LinkStatus.connecting, device: state.device, token: state.token, info: state.info);
    _startLive();
  }

  void _startLive() {
    final device = state.device;
    final token = state.token;
    if (!ref.mounted || _paused || device == null || token == null || _socket != null) return;
    final socket = ref.read(liveSocketFactoryProvider)(device, token, () {
      if (!_reconnected.isClosed) _reconnected.add(null);
    });
    _socket = socket;
    _stateSub = socket.states.listen(_onSocketState);
    _msgSub = socket.messages.listen((m) {
      if (!_messages.isClosed) _messages.add(m);
    });
    socket.start();
  }

  void _stopLive() {
    _stateSub?.cancel();
    _msgSub?.cancel();
    _socket?.close();
    _socket = null;
    _stateSub = null;
    _msgSub = null;
  }

  void _onSocketState(LiveSocketState s) {
    if (!ref.mounted || !state.isPaired) return;
    final status = switch (s.status) {
      LiveSocketStatus.connecting => state.status == LinkStatus.retrying ? LinkStatus.retrying : LinkStatus.connecting,
      LiveSocketStatus.connected => LinkStatus.connected,
      LiveSocketStatus.retrying => LinkStatus.retrying,
      LiveSocketStatus.closed => LinkStatus.disconnected,
    };
    // 붙으면 다음에 끊겼을 때 토큰을 한 번 다시 확인한다 (파이 DB 가 초기화돼 토큰이 사라진 경우)
    if (s.status == LiveSocketStatus.connected) _tokenChecked = false;
    state = PiConnection(
      status: status,
      device: state.device,
      token: state.token,
      info: state.info,
      retryIn: s.status == LiveSocketStatus.retrying ? s.retryIn : null,
    );
    if (s.status == LiveSocketStatus.retrying && !_tokenChecked) _checkToken();
    if (s.status == LiveSocketStatus.connected && state.info == null) _loadInfo(state.device!);
    if (s.status == LiveSocketStatus.connected && _announceOnConnect) {
      _announceOnConnect = false; // 백그라운드에서 돌아와 새 소켓이 붙음 = 다시 연결
      if (!_reconnected.isClosed) _reconnected.add(null);
    }
  }

  /// 저장된 토큰으로 붙지 못했을 때, 토큰이 틀린 건지(401) 네트워크 문제인지 REST 로 한 번 확인.
  /// (WebSocket 핸드셰이크 거절은 이유를 알 수 없다)
  Future<void> _checkToken() async {
    final device = state.device;
    final token = state.token;
    if (device == null || token == null) return;
    _tokenChecked = true;
    final api = ref.read(piApiFactoryProvider)(device, token);
    try {
      await api.status();
    } on PiApiException catch (e) {
      if (e.isUnauthorized && ref.mounted && state.token == token) {
        await forget(message: '기기가 이 폰을 기억하지 못해요. 페어링 코드를 다시 입력해 주세요.');
        return;
      }
      _tokenChecked = false; // 네트워크 문제면 다음 실패 때 다시 확인
    } finally {
      api.close();
    }
  }

  Future<void> _loadInfo(PiDevice device) async {
    final api = ref.read(piApiFactoryProvider)(device, null);
    try {
      final info = await api.info();
      if (!ref.mounted || state.device != device) return;
      state = PiConnection(
        status: state.status,
        device: state.device!.copyWith(name: info.name),
        token: state.token,
        info: info,
        retryIn: state.retryIn,
      );
    } catch (_) {
      // 기기가 꺼져 있으면 다음 연결 때 다시
    } finally {
      api.close();
    }
  }
}
