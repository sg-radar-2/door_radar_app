import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app/constants.dart';
import 'models/pi_device.dart';

/// 키-값 저장소. 앱에서는 [SecureKv](flutter_secure_storage), 테스트에서는 [MemoryKv].
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureKv implements KeyValueStore {
  SecureKv([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) => _s.read(key: key);

  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

class MemoryKv implements KeyValueStore {
  MemoryKv([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// 저장된 연결 정보. [device] 는 늘 클라우드 주소(빌드 설정)이고, 토큰이 있으면 바로 홈으로 간다.
class SavedSession {
  const SavedSession({this.device, this.token});

  final PiDevice? device;
  final String? token;

  /// 바로 /home 으로 갈 수 있는지
  bool get isPaired => device != null && token != null && token!.isNotEmpty;
}

/// 토큰과 페어링한 파이 이름. 앱이 다시 켜져도 자동으로 붙도록(SPEC P0).
/// 서버 주소는 빌드 때 정해지므로(SPEC 9장) 저장하지 않고, 토큰을 받은 서버만 적어 둔다.
/// 빌드의 서버가 바뀌면(개발 ↔ 실제) 예전 토큰은 버린다.
class AppStorage {
  AppStorage(this._kv, {PiDevice? server}) : server = server ?? PiDevice.cloud;

  final KeyValueStore _kv;

  /// 지금 빌드가 붙는 서버
  final PiDevice server;

  static const _kToken = 'pi_token';
  static const _kAddress = 'pi_address'; // 토큰을 받은 서버 주소
  static const _kName = 'pi_name';

  Future<SavedSession> load() async {
    final address = await _kv.read(_kAddress);
    final name = await _kv.read(_kName);
    final token = await _kv.read(_kToken);
    final sameServer = address == server.address;
    return SavedSession(
      device: server.copyWith(name: sameServer ? name : null),
      token: sameServer ? token : null,
    );
  }

  Future<void> save(PiDevice device, String token) async {
    await _kv.write(_kAddress, device.address);
    if (device.name != null) {
      await _kv.write(_kName, device.name!);
    } else {
      await _kv.delete(_kName);
    }
    await _kv.write(_kToken, token);
  }

  /// 토큰만 지운다(토큰 거절).
  Future<void> clearToken() => _kv.delete(_kToken);

  /// 연결 해제: 토큰과 파이 이름을 지운다. (폰에 보관한 사진·보관 기간은 남긴다)
  Future<void> clearDevice() async {
    await _kv.delete(_kToken);
    await _kv.delete(_kAddress);
    await _kv.delete(_kName);
  }

  static const _kKeepDays = 'phone_keep_days';

  /// 휴대폰 사진 보관 기간(일). 앱에만 저장한다(SPEC 6장). 없거나 이상하면 기본 300일, 범위 밖이면 끝값.
  Future<int> loadKeepDays() async {
    final v = int.tryParse(await _kv.read(_kKeepDays) ?? '');
    return v == null ? PhotoKeep.defaultDays : PhotoKeep.clamp(v);
  }

  Future<void> saveKeepDays(int days) => _kv.write(_kKeepDays, '${PhotoKeep.clamp(days)}');
}
