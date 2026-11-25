import 'package:door_radar_app/data/models/models.dart';
import 'package:door_radar_app/features/home/door_map_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const region = Region(xmin: -2, xmax: 2, ymin: 0, ymax: 3, fovDeg: 135);

  group('DoorMapGeometry (와이어프레임 SVG 306×236 기준)', () {
    final g = DoorMapGeometry(region, mapDesignSize);

    test('영역 4m×3m = 280×210px, 70px/m', () {
      expect(g.scale, 70);
      expect(g.area, const Rect.fromLTWH(13, 12, 280, 210));
    });

    test('문은 아래 가운데 (153, 222)', () {
      expect(g.door, const Offset(153, 222));
      expect(g.toPx(0, 0), const Offset(153, 222));
    });

    test('m → px: x 는 오른쪽, y 는 위로', () {
      expect(g.toPx(-2, 3), const Offset(13, 12)); // 왼쪽 위 모서리
      expect(g.toPx(2, 0), const Offset(293, 222)); // 오른쪽 아래
      expect(g.toPx(1, 1), const Offset(223, 152));
      // 와이어프레임 사람 점 (181, 128) ≈ (0.4m, 1.34m)
      final p = g.toPx(0.4, 1.342857);
      expect(p.dx, closeTo(181, 0.01));
      expect(p.dy, closeTo(128, 0.01));
    });

    test('화각 135° 선은 영역 옆 테두리 (293,164) / (13,164) 에서 끝난다', () {
      final r = g.fovEnd(1);
      final l = g.fovEnd(-1);
      expect(r.dx, closeTo(293, 0.01));
      expect(r.dy, closeTo(164, 0.1));
      expect(l.dx, closeTo(13, 0.01));
      expect(l.dy, closeTo(164, 0.1));
    });

    test('화각이 좁으면 위 테두리에서 끝난다', () {
      final narrow = DoorMapGeometry(region.copyWith(fovDeg: 60), mapDesignSize);
      final r = narrow.fovEnd(1);
      expect(r.dy, closeTo(12, 0.01));
      expect(r.dx, closeTo(153 + 210 * 0.57735, 0.01)); // tan 30°
    });
  });

  test('크기가 커지면 비율을 지켜 늘어나고 가로 가운데', () {
    final g = DoorMapGeometry(region, const Size(612, 472));
    expect(g.scale, closeTo((612 - 26) / 4, 1e-9));
    expect(g.door.dx, closeTo(306, 1e-9));
  });

  test('영역 비율이 다르면 세로에 맞추고 가로 가운데', () {
    const tall = Region(xmin: -1, xmax: 1, ymin: 0, ymax: 3, fovDeg: 135);
    final g = DoorMapGeometry(tall, mapDesignSize);
    expect(g.scale, 70); // 210 / 3
    expect(g.area.width, 140);
    expect(g.area.center.dx, closeTo(153, 1e-9));
    expect(g.door, const Offset(153, 222));
  });

  test('ymin 이 0 보다 크면 문은 영역 아래에 있다', () {
    const r = Region(xmin: -2, xmax: 2, ymin: 0.5, ymax: 3.5, fovDeg: 135);
    final g = DoorMapGeometry(r, mapDesignSize);
    expect(g.toPx(0, 0.5).dy, closeTo(g.area.bottom, 1e-9));
    expect(g.door.dy, closeTo(g.area.bottom + 35, 1e-9));
  });
}
