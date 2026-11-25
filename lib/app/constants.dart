/// 서버(situation_core)와 맞춰야 하는 값들. 바꾸면 docs/SPEC.md 도 같이 고친다.
abstract final class Situations {
  static const normal = ['통과', '귀가', '외출', '방문', '배달'];
  static const abnormal = ['장시간 체류', '배회', '반복 접근'];
  static const all = [...normal, ...abnormal];
  static const deciding = '판단 중';

  static bool isAbnormal(String s) => abnormal.contains(s);
}

abstract final class PiServer {
  static const port = 8080;
  static const mdnsType = '_doorradar._tcp';
  static const defaultHost = 'rad2pi.local'; // 파이 호스트 이름 rad2pi (mDNS 서비스 이름은 doorradar)
  static const maxEventsLimit = 500; // /api/events?limit= 최댓값
  static const reconnectDelays = [1, 2, 4, 8]; // 초, 마지막 값을 계속 반복
}

/// 사진 보관: 폰이 오래 보관하고 파이는 30일 임시 보관만 한다.
abstract final class PhotoKeep {
  static const defaultDays = 300;
  static const minDays = 7;
  static const maxDays = 730;
  static const deviceDays = 30; // 파이 쪽 (읽기 전용, /api/settings.device_keep_days)

  static int clamp(int days) => days.clamp(minDays, maxDays);
}
