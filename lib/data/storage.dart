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

/// 저장된 연결 정보. 토큰이 없어도 마지막 기기 주소는 남겨서 연결 화면 입력칸을 채운다.
class SavedSession {
  const SavedSession({this.device, this.token});

  final PiDevice? device;
  final String? token;

  /// 바로 /home 으로 갈 수 있는지
  bool get isPaired => device != null && token != null && token!.isNotEmpty;
}

/// 토큰·마지막 기기 주소. 앱이 다시 켜져도 자동으로 붙도록(SPEC P0).
class AppStorage {
  AppStorage(this._kv);

  final KeyValueStore _kv;

  static const _kToken = 'pi_token';
  static const _kAddress = 'pi_address'; // "host" 또는 "host:port"
  static const _kName = 'pi_name';

  Future<SavedSession> load() async {
    final address = await _kv.read(_kAddress);
    final name = await _kv.read(_kName);
    final token = await _kv.read(_kToken);
    final parsed = address == null ? null : PiDevice.tryParse(address);
    return SavedSession(device: parsed?.copyWith(name: name), token: token);
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

  /// 토큰만 지운다(연결 해제, 토큰 거절). 마지막 주소는 남긴다.
  Future<void> clearToken() => _kv.delete(_kToken);

  /// 연결 해제: 토큰과 마지막 기기까지 지운다. (폰에 보관한 사진·보관 기간은 남긴다)
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
