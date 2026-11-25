import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../app/constants.dart';
import '../models/models.dart';

/// `/ws/live` 로 오는 메시지
sealed class LiveMessage {
  const LiveMessage();

  /// 모르는 type 이거나 형식이 틀리면 null (연결은 유지)
  static LiveMessage? tryParse(Object? raw) {
    try {
      final json = raw is String ? jsonDecode(raw) : raw;
      if (json is! Map<String, dynamic>) return null;
      return switch (json['type']) {
        'frame' => LiveFrameMessage(LiveFrame.fromJson(json)),
        'event' => LiveEventMessage(Event.fromJson(json['event'] as Map<String, dynamic>)),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}

class LiveFrameMessage extends LiveMessage {
  const LiveFrameMessage(this.frame);
  final LiveFrame frame;
}

class LiveEventMessage extends LiveMessage {
  const LiveEventMessage(this.event);
  final Event event;
}

enum LiveSocketStatus { connecting, connected, retrying, closed }

/// 소켓 상태. [retryIn] 은 retrying 일 때 다음 시도까지 기다리는 시간.
class LiveSocketState {
  const LiveSocketState(this.status, {this.retryIn, this.attempt = 0});

  final LiveSocketStatus status;
  final Duration? retryIn;
  final int attempt; // 연속 실패 횟수 (붙으면 0)
}

typedef ChannelConnector = WebSocketChannel Function(Uri uri);

/// `/ws/live?token=` 연결. 끊기면 1·2·4·8초(이후 8초 반복) 간격으로 다시 붙는다.
/// 한 번 붙었다가 끊긴 뒤 다시 붙으면 [onReconnected] 를 부른다 → `/api/events?since=` 로 빈 기간 채우기.
/// 파이는 사람이 없어도 frame 을 초당 5번 보내므로, [frameTimeout](2초) 넘게 아무것도 안 오면
/// 끊긴 것으로 보고 다시 붙는다 (Wi-Fi 가 조용히 끊겨 소켓이 닫히지 않는 경우).
class LiveSocket {
  LiveSocket({
    required PiDevice device,
    required String token,
    this.onReconnected,
    ChannelConnector? connector,
    List<int> delaysSec = PiServer.reconnectDelays,
    Duration readyTimeout = const Duration(seconds: 5),
    this.frameTimeout = const Duration(seconds: 2),
  })  : uri = device.baseUri.replace(scheme: device.wsScheme, path: '/ws/live', queryParameters: {'token': token}),
        _connector = connector ?? WebSocketChannel.connect,
        _delays = delaysSec.map((s) => Duration(seconds: s)).toList(),
        _readyTimeout = readyTimeout;

  final Uri uri;
  final void Function()? onReconnected;
  final ChannelConnector _connector;
  final List<Duration> _delays;
  final Duration _readyTimeout;

  /// 이 시간 넘게 메시지가 없으면 끊긴 것으로 본다. null 이면 감시 안 함.
  final Duration? frameTimeout;

  final _messages = StreamController<LiveMessage>.broadcast();
  final _states = StreamController<LiveSocketState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _retryTimer;
  Timer? _silenceTimer;
  bool _started = false;
  bool _closed = false;
  bool _everConnected = false;
  int _failures = 0;
  LiveSocketState _state = const LiveSocketState(LiveSocketStatus.connecting);

  Stream<LiveMessage> get messages => _messages.stream;
  Stream<LiveFrame> get frames => messages.whereType<LiveFrameMessage>().map((m) => m.frame);
  Stream<Event> get events => messages.whereType<LiveEventMessage>().map((m) => m.event);
  Stream<LiveSocketState> get states => _states.stream;
  LiveSocketState get state => _state;

  /// 다음에 기다릴 시간: 1, 2, 4, 8, 8, 8 …
  static Duration delayFor(int failures, List<Duration> delays) =>
      delays[(failures - 1).clamp(0, delays.length - 1)];

  void start() {
    if (_started || _closed) return;
    _started = true;
    _connect();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _retryTimer?.cancel();
    _silenceTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _setState(const LiveSocketState(LiveSocketStatus.closed));
    await _messages.close();
    await _states.close();
  }

  Future<void> _connect() async {
    if (_closed) return;
    _setState(LiveSocketState(LiveSocketStatus.connecting, attempt: _failures));
    final WebSocketChannel channel;
    try {
      channel = _connector(uri);
      _channel = channel;
      await channel.ready.timeout(_readyTimeout);
    } catch (_) {
      // 핸드셰이크 거절(토큰 틀림)도 여기로 온다. 구분은 연결 상태 쪽에서 REST 로 확인.
      _channel?.sink.close().ignore();
      _channel = null;
      _scheduleRetry();
      return;
    }
    if (_closed) {
      channel.sink.close().ignore();
      return;
    }

    final reconnect = _everConnected;
    _everConnected = true;
    _failures = 0;
    _setState(const LiveSocketState(LiveSocketStatus.connected));
    _sub = channel.stream.listen(
      (raw) {
        _watchSilence();
        final msg = LiveMessage.tryParse(raw);
        if (msg != null && !_messages.isClosed) _messages.add(msg);
      },
      onError: (_) {}, // onDone 이 뒤따라 온다
      onDone: _onDropped,
      cancelOnError: false,
    );
    _watchSilence();
    if (reconnect) onReconnected?.call();
  }

  void _watchSilence() {
    final limit = frameTimeout;
    if (limit == null) return;
    _silenceTimer?.cancel();
    _silenceTimer = Timer(limit, () {
      _channel?.sink.close().ignore();
      _onDropped();
    });
  }

  void _onDropped() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    if (_channel == null && _sub == null) return; // 이미 처리함 (감시 타이머 뒤에 onDone 이 와도 한 번만)
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (!_closed) _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_closed) return;
    _failures++;
    final wait = delayFor(_failures, _delays);
    _setState(LiveSocketState(LiveSocketStatus.retrying, retryIn: wait, attempt: _failures));
    _retryTimer?.cancel();
    _retryTimer = Timer(wait, _connect);
  }

  void _setState(LiveSocketState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }
}

extension on Stream<LiveMessage> {
  Stream<T> whereType<T>() => where((m) => m is T).cast<T>();
}
