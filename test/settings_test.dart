import 'dart:io';

import 'package:door_radar_app/data/discovery.dart';
import 'package:door_radar_app/data/storage.dart';
import 'package:door_radar_app/features/settings/device_screen.dart';
import 'package:door_radar_app/features/settings/settings_screen.dart';
import 'package:door_radar_app/state/live.dart';
import 'package:door_radar_app/state/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsd/nsd.dart' as nsd;

void main() {
  test('알림 상황 켜고 끄기: 순서는 장시간 체류 · 배회 · 반복 접근', () {
    expect(toggleNotify(['반복 접근'], '장시간 체류', true), ['장시간 체류', '반복 접근']);
    expect(toggleNotify(['장시간 체류', '배회', '반복 접근'], '배회', false), ['장시간 체류', '반복 접근']);
    expect(toggleNotify([], '배회', false), isEmpty);
  });

  test('휴대폰 보관 기간 입력 검사와 끝값 맞추기', () {
    expect(parseKeepDays('300'), 300);
    expect(parseKeepDays('7'), 7);
    expect(parseKeepDays('6'), isNull);
    expect(parseKeepDays('731'), isNull);
    expect(parseKeepDays(''), isNull);
    expect(fixKeepDays('999', 300), 730);
    expect(fixKeepDays('0', 300), 7);
    expect(fixKeepDays('', 120), 120); // 비우면 원래 값
  });

  test('보관 기간 저장: 범위 밖은 끝값, 없으면 300', () async {
    final kv = MemoryKv();
    final s = AppStorage(kv);
    expect(await s.loadKeepDays(), 300);
    await s.saveKeepDays(1000);
    expect(await s.loadKeepDays(), 730);
    kv.values['phone_keep_days'] = 'abc';
    expect(await s.loadKeepDays(), 300);
  });

  test('연결 해제는 토큰·주소·이름을 지우고 보관 기간은 남긴다', () async {
    final kv = MemoryKv({'pi_token': 't', 'pi_address': '1.2.3.4', 'pi_name': 'doorradar', 'phone_keep_days': '30'});
    await AppStorage(kv).clearDevice();
    expect(kv.values, {'phone_keep_days': '30'});
  });

  test('문구', () {
    expect(cameraCriteria(0.6, 1.0), '60% 이상 · 1초 유지');
    expect(cameraCriteria(0.75, 1.5), '75% 이상 · 1.5초 유지');
    expect(uptimeText(3 * 86400 + 4 * 3600 + 59), '3일 4시간째 켜짐');
    expect(uptimeText(2 * 3600 + 5 * 60), '2시간 5분째 켜짐');
    expect(uptimeText(720), '12분째 켜짐');
    expect(radarWord('stale'), '응답 없음');
    expect(cameraLabel('ok'), '카메라 정상');
    expect(cameraLabel('error'), '카메라 오류');
    expect(cameraLabel('none'), '카메라 없음');
    expect(cameraBackendWord('helper'), 'picamera2');
    expect(cameraBackendWord('none'), isNull);
    expect(gb(1.2), '1.2');
    expect(gb(29), '29');
  });

  test('mDNS 서비스 → 카드: IPv4 만, 같은 IP·포트는 하나로', () {
    final list = toFoundDevices([
      nsd.Service(
          name: 'doorradar', host: 'rad2pi.local.', port: 8080, addresses: [InternetAddress('192.168.0.10')]),
      nsd.Service(
          name: 'doorradar', host: 'rad2pi.local.', port: 8080, addresses: [InternetAddress('192.168.0.10')]),
      nsd.Service(name: 'v6only', port: 8080, addresses: [InternetAddress('fe80::1')]),
      const nsd.Service(name: 'unresolved', port: 8080),
    ]);
    expect(list, hasLength(1));
    expect(list.single.title, 'rad2pi.local');
    expect(list.single.device.address, '192.168.0.10');
  });
}
