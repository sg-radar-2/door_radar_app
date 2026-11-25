import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../state/live.dart';

/// 와이어프레임 SVG 크기 (306×236). 영역 4m×3m = 280×210px (70px/m)
const mapDesignSize = Size(306, 236);

/// 문 앞 지도의 m → px 변환. 순수 계산이라 테스트한다.
///
/// - 측정 영역(region)을 [size] 안에 비율을 지켜 가장 크게, 가로 가운데에 놓는다.
/// - 레이더(문)는 x=0, y=0. y 는 아래에서 위로(문에서 멀어질수록 위).
class DoorMapGeometry {
  factory DoorMapGeometry(Region region, Size size, {EdgeInsets padding = defaultPadding}) {
    final xSpan = region.xmax - region.xmin;
    final ySpan = region.ymax - region.ymin;
    final availW = size.width - padding.horizontal;
    final availH = size.height - padding.vertical;
    final scale = math.min(availW / xSpan, availH / ySpan);
    final w = xSpan * scale;
    final h = ySpan * scale;
    final left = padding.left + (availW - w) / 2;
    final top = padding.top + (availH - h) / 2;
    final area = Rect.fromLTWH(left, top, w, h);
    final door = Offset(left - region.xmin * scale, area.bottom + region.ymin * scale);
    return DoorMapGeometry._(region, size, scale, area, door);
  }

  const DoorMapGeometry._(this.region, this.size, this.scale, this.area, this.door);

  /// 와이어프레임: 영역 (13,12)~(293,222), 아래 여백 14
  static const defaultPadding = EdgeInsets.fromLTRB(13, 12, 13, 14);

  final Region region;
  final Size size;

  /// px / m
  final double scale;

  /// 측정 영역 (px)
  final Rect area;

  /// 레이더(문) 위치 (px)
  final Offset door;

  Offset toPx(double x, double y) => Offset(door.dx + x * scale, door.dy - y * scale);

  /// 화각 선의 끝점: 문에서 정면(위)으로부터 ±fov/2 기울어진 선이 영역 테두리와 만나는 곳.
  /// [side] 는 -1(왼쪽) 또는 1(오른쪽).
  Offset fovEnd(int side) {
    final half = region.fovDeg / 2 * math.pi / 180;
    final dx = math.sin(half) * side;
    final dy = -math.cos(half); // 화면 좌표는 위가 -
    var t = double.infinity;
    if (dx > 1e-9) t = math.min(t, (area.right - door.dx) / dx);
    if (dx < -1e-9) t = math.min(t, (area.left - door.dx) / dx);
    if (dy < -1e-9) t = math.min(t, (area.top - door.dy) / dy);
    return door + Offset(dx, dy) * t;
  }
}

/// DESIGN.md "문 앞 지도". 와이어프레임 Home/HomeAlert 의 SVG 를 그대로 옮겼다.
class DoorMapPainter extends CustomPainter {
  DoorMapPainter({required this.region, required this.people, this.textScaler = TextScaler.noScaling, this.showLabels = true});

  final Region region;
  final List<TrackedPerson> people;
  final TextScaler textScaler;

  /// 사람 옆 흰 라벨 (이벤트 상세의 궤적 지도에서는 끈다)
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final g = DoorMapGeometry(region, size);
    final s = g.scale / 70; // 와이어프레임 대비 배율 (점 크기·글자도 같이)

    // 측정 영역: 점선 둥근 사각형
    final areaPath = Path()..addRRect(RRect.fromRectAndRadius(g.area, Radius.circular(10 * s)));
    canvas.drawPath(
      _dashed(areaPath, 3 * s, 5 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.mapLine
        ..strokeWidth = 1,
    );

    // 1m, 2m 원호
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.mapArc
      ..strokeWidth = 1;
    for (final r in [1.0, 2.0]) {
      canvas.drawArc(Rect.fromCircle(center: g.door, radius: r * g.scale), math.pi, math.pi, false, arc);
    }

    // 화각
    final fov = Paint()
      ..color = AppColors.mapLine
      ..strokeWidth = 1;
    canvas.drawLine(g.door, g.fovEnd(1), fov);
    canvas.drawLine(g.door, g.fovEnd(-1), fov);

    // 거리 라벨 (와이어프레임 위치: 1m 는 원호 오른쪽 끝 바로 위, 2m 는 오른쪽 화각 선 위)
    final scaleLabel = TextStyle(fontSize: 10 * s, color: const Color(0xFF8A8A8A));
    _text(canvas, '1m', g.door + Offset(73 * s, -16 * s), scaleLabel);
    _text(canvas, '2m', g.door + Offset(126 * s, -82 * s), scaleLabel);

    // 문: 흰 막대 + "문"
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: g.door + Offset(0, 0.5 * s), width: 30 * s, height: 7 * s),
          Radius.circular(3.5 * s)),
      Paint()..color = AppColors.surface,
    );
    _text(canvas, '문', g.door + Offset(0, -18 * s), TextStyle(fontSize: 10 * s, color: AppColors.onDarkMuted),
        center: true);

    // 사람: 궤적 → 후광 → 점 → 라벨 (라벨이 다른 사람 점을 가리지 않게 마지막에)
    for (final p in people) {
      final color = p.abnormal ? AppColors.alert : AppColors.point;
      if (p.trail.length >= 2) {
        final path = Path();
        Offset? last;
        for (final t in p.trail) {
          final o = g.toPx(t.x, t.y);
          if (last == null) {
            path.moveTo(o.dx, o.dy);
          } else if ((o - last).distance >= 0.5) {
            // 제자리에 머문 점이 겹치면 이음새가 네모로 찍혀서 건너뛴다
            path.lineTo(o.dx, o.dy);
          } else {
            continue;
          }
          last = o;
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * s
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = color.withValues(alpha: p.abnormal ? 0.6 : 0.45),
        );
      }
    }
    for (final p in people) {
      final color = p.abnormal ? AppColors.alert : AppColors.point;
      final c = g.toPx(p.person.x, p.person.y);
      canvas.drawCircle(
          c, (p.abnormal ? 22 : 13) * s, Paint()..color = color.withValues(alpha: p.abnormal ? 0.16 : 0.18));
      final dot = (p.abnormal ? 7 : 6) * s;
      if (p.person.hidden) {
        // 가려진 사람: 속 빈 점, 마지막 위치
        canvas.drawCircle(
            c,
            dot - 0.75 * s,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 * s
              ..color = color);
      } else {
        canvas.drawCircle(c, dot, Paint()..color = color);
      }
    }
    if (showLabels) {
      for (final p in people) {
        _personLabel(canvas, g, s, p);
      }
    }
  }

  void _personLabel(Canvas canvas, DoorMapGeometry g, double s, TrackedPerson p) {
    final c = g.toPx(p.person.x, p.person.y);
    final tp = _layout(personLabel(p.person),
        TextStyle(fontSize: 11 * s, fontWeight: FontWeight.w600, color: AppColors.ink));
    final w = tp.width + 24 * s;
    final h = 24 * s;
    final gap = (p.abnormal ? 20 : 15) * s;
    // 오른쪽에 두고, 넘치면 왼쪽 (와이어프레임: 정상은 오른쪽, 오른쪽 끝 근처는 왼쪽)
    var left = c.dx + gap;
    if (left + w > g.size.width - 4 * s) left = c.dx - gap - w;
    left = left.clamp(0.0, math.max(0.0, g.size.width - w)).toDouble();
    final top = (c.dy - h / 2).clamp(0.0, math.max(0.0, g.size.height - h)).toDouble();
    final rect = Rect.fromLTWH(left, top, w, h);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(h / 2)), Paint()..color = AppColors.surface);
    tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  TextPainter _layout(String text, TextStyle style) => TextPainter(
        // CustomPainter 는 테마 글꼴을 물려받지 않아 직접 지정
        text: TextSpan(text: text, style: style.copyWith(fontFamily: AppFonts.family, fontFamilyFallback: AppFonts.fallback)),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();

  /// [at] 은 글자 왼쪽 위 (center 면 가운데 위)
  void _text(Canvas canvas, String text, Offset at, TextStyle style, {bool center = false}) {
    final tp = _layout(text, style);
    tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
  }

  static Path _dashed(Path source, double dash, double gap) {
    final out = Path();
    for (final ui.PathMetric m in source.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        out.addPath(m.extractPath(d, math.min(d + dash, m.length)), Offset.zero);
        d += dash + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(DoorMapPainter old) =>
      !identical(old.people, people) || old.region != region || old.textScaler != textScaler;
}
