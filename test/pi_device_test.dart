import 'package:door_radar_app/data/models/pi_device.dart';
import 'package:door_radar_app/data/storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PiDevice.tryParse', () {
    test('IP 만 쓰면 8080', () {
      final d = PiDevice.tryParse(' 192.168.0.10 ')!;
      expect(d.host, '192.168.0.10');
      expect(d.port, 8080);
      expect(d.address, '192.168.0.10');
      expect(d.baseUri.toString(), 'http://192.168.0.10:8080');
    });

    test('포트·스킴·끝 슬래시', () {
      expect(PiDevice.tryParse('10.0.2.2:8080'), const PiDevice(host: '10.0.2.2'));
      expect(PiDevice.tryParse('http://doorradar.local:9000/')!.address, 'doorradar.local:9000');
    });

    test('잘못된 입력은 null', () {
      for (final s in ['', '   ', 'ws://10.0.0.1', '10.0.0.1/api', 'a b', '10.0.0.1:99999', 'http://']) {
        expect(PiDevice.tryParse(s), isNull, reason: s);
      }
    });
  });

  group('AppStorage', () {
    test('저장하고 다시 읽기, 토큰만 지우기', () async {
      final kv = MemoryKv();
      final storage = AppStorage(kv);
      expect((await storage.load()).isPaired, isFalse);

      await storage.save(const PiDevice(host: '10.0.2.2', name: 'doorradar'), 'tok');
      var s = await storage.load();
      expect(s.isPaired, isTrue);
      expect(s.device, const PiDevice(host: '10.0.2.2'));
      expect(s.device!.name, 'doorradar');
      expect(s.token, 'tok');

      await storage.clearToken();
      s = await storage.load();
      expect(s.isPaired, isFalse);
      expect(s.device!.address, '10.0.2.2'); // 마지막 주소는 남는다
    });
  });
}
