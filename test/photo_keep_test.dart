import 'package:door_radar_app/app/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('휴대폰 보관 기간은 7~730일, 범위 밖이면 가까운 끝값', () {
    expect(PhotoKeep.defaultDays, 300);
    expect(PhotoKeep.clamp(PhotoKeep.defaultDays), 300);
    expect(PhotoKeep.clamp(7), 7);
    expect(PhotoKeep.clamp(730), 730);
    expect(PhotoKeep.clamp(6), 7);
    expect(PhotoKeep.clamp(0), 7);
    expect(PhotoKeep.clamp(-30), 7);
    expect(PhotoKeep.clamp(731), 730);
    expect(PhotoKeep.clamp(100000), 730);
  });

  test('파이 쪽 보관 기간은 30일 (읽기 전용)', () {
    expect(PhotoKeep.deviceDays, 30);
  });
}
