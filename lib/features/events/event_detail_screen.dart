import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../data/api/pi_api.dart';
import '../../data/local_store.dart';
import '../../data/models/models.dart';
import '../../state/connection.dart';
import '../../state/events.dart';
import '../../state/live.dart';
import '../../state/settings.dart';
import '../../widgets/situation_chip.dart';
import '../home/door_map_painter.dart';
import 'events_screen.dart' show eventDuration;

/// 와이어프레임 EventDetail.dc.html
/// 사진(폰 저장본 우선), 나온 행동(이상 먼저), 근거, 궤적, 판정 확인(정답 표시), 갤러리에 저장.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  static const saveKey = Key('detail.save');
  static const yesKey = Key('detail.yes');
  static const otherKey = Key('detail.other');
  static const undoKey = Key('detail.undo');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventDetailProvider(eventId));
    final stored = async.value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 24, AppSpace.screenH, 24),
          children: [
            _TopBar(stored: stored),
            const SizedBox(height: AppSpace.gap),
            if (stored != null) ...[
              _Photo(stored: stored),
              const SizedBox(height: AppSpace.gap),
              _Heading(event: stored.event),
              if (stored.event.behaviors?.isNotEmpty == true || stored.event.reason != null) ...[
                const SizedBox(height: AppSpace.gap),
                _Behaviors(event: stored.event),
              ],
              if ((stored.event.track?.length ?? 0) >= 2) ...[
                const SizedBox(height: AppSpace.gap),
                _TrackMap(event: stored.event),
              ],
              const SizedBox(height: AppSpace.gap),
              _LabelCard(eventId: eventId, event: stored.event),
            ] else if (async.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  async.error is PiApiException && (async.error! as PiApiException).statusCode == 404
                      ? '이 기록은 기기에서 지워졌어요'
                      : '기록을 불러오지 못했어요. 기기 연결을 확인해 주세요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 위

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.stored});

  final StoredEvent? stored;

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final s = stored!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await Gal.hasPermission()) {
        if (!await Gal.requestPermission()) {
          messenger.showSnackBar(const SnackBar(content: Text('갤러리 접근을 허용해야 저장할 수 있어요')));
          return;
        }
      }
      final Uint8List bytes;
      if (s.photoPath != null && File(s.photoPath!).existsSync()) {
        bytes = await File(s.photoPath!).readAsBytes();
      } else {
        final api = ref.read(piApiProvider);
        if (api == null) throw StateError('not paired');
        bytes = await api.photo(s.event.id);
      }
      await Gal.putImageBytes(bytes, name: 'doorradar_${s.event.id}');
      messenger.showSnackBar(const SnackBar(content: Text('갤러리에 저장했어요')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('갤러리에 저장하지 못했어요')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = stored?.event;
    final canSave = e != null && e.photo;
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back,
          label: '뒤로',
          onTap: () => context.canPop() ? context.pop() : context.go('/events'),
        ),
        Expanded(
          child: Text(
            e == null ? '' : '${DateFormat('M월 d일').format(e.time.toLocal())} · ${e.person}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
        _CircleButton(
          key: EventDetailScreen.saveKey,
          icon: Icons.download,
          label: '갤러리에 저장',
          onTap: canSave ? () => _save(context, ref) : null,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: Tooltip(
        message: label,
        child: Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: 22, color: onTap == null ? AppColors.subtle : AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 사진

class _Photo extends ConsumerWidget {
  const _Photo({required this.stored});

  final StoredEvent stored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = stored.event;
    final api = ref.watch(piApiProvider);
    final local = stored.photoPath != null && File(stored.photoPath!).existsSync() ? stored.photoPath : null;

    Widget placeholder(String text) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_outlined, size: 34, color: Color(0xFF8A8A8A)),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A))),
          ],
        );

    final Widget image;
    if (local != null) {
      // 원본(1920×1080)을 그대로 풀면 늦어서 화면 폭에 맞춰 줄여 디코딩
      final w = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round();
      image = Image.file(File(local), fit: BoxFit.cover, width: double.infinity, height: double.infinity, cacheWidth: w);
    } else if (e.photo && api != null) {
      image = CachedNetworkImage(
        imageUrl: api.photoUrl(e.id),
        httpHeaders: api.authHeaders,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => const Center(
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8A8A8A))),
        ),
        errorWidget: (_, _, _) => Center(child: placeholder('사진을 불러오지 못했어요')),
      );
    } else {
      image = Center(child: placeholder(e.photo ? '기기에 연결되면 사진을 받아 와요' : '촬영 사진 없음'));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.photo),
      child: Container(
        height: 210,
        color: AppColors.darkCard,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Positioned(
              left: 14,
              top: 14,
              child: _Badge(
                color: AppColors.surface.withValues(alpha: 0.92),
                child: Text(DateFormat('HH:mm:ss').format(e.time.toLocal()),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ),
            ),
            if (local != null)
              Positioned(
                right: 14,
                bottom: 14,
                child: _Badge(
                  color: AppColors.ink.withValues(alpha: 0.85),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.point, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('이 폰에 저장됨', style: TextStyle(fontSize: 12, color: AppColors.surface)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: child,
    );
  }
}

// ---------------------------------------------------------------- 판정

class _Heading extends StatelessWidget {
  const _Heading({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final hms = DateFormat('HH:mm:ss');
    final d = eventDuration(e);
    final range = e.endedTime == null
        ? '${hms.format(e.startedTime.toLocal())}부터 · 진행 중 촬영'
        : '${hms.format(e.startedTime.toLocal())} – ${hms.format(e.endedTime!.toLocal())}'
            '${d == null ? '' : ' · ${formatSeconds(d.inMilliseconds / 1000)}'}';
    const big = TextStyle(fontSize: 30, height: 36 / 30, fontWeight: FontWeight.w600, letterSpacing: -1, color: AppColors.ink);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (e.abnormal) ...[const AbnormalChip(height: 24, fontSize: 12), const SizedBox(width: 8)],
            Expanded(child: Text(range, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(e.situation, style: big)),
            Text.rich(TextSpan(text: '${(e.prob * 100).round()}', style: big, children: const [
              TextSpan(text: '%', style: TextStyle(fontSize: 16)),
            ])),
          ],
        ),
        if (e.path != null) ...[
          const SizedBox(height: 6),
          Text(_spacedPath(e.path!), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ],
      ],
    );
  }

  /// "외곽에서 들어옴(2.4m)" → "외곽에서 들어옴 (2.4m)" (와이어프레임 표기)
  static String _spacedPath(String p) => p.replaceAllMapped(RegExp(r'(\S)\('), (m) => '${m[1]} (');
}

/// 나온 행동: 이상 먼저. 이상은 검은 칩 + 빨간 점, 정상은 회색 칩. 끝날 때 판정은 "· 끝날 때".
class _Behaviors extends StatelessWidget {
  const _Behaviors({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final list = sortBehaviors(event.behaviors ?? const []);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('나온 행동', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
          if (list.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final b in list) _BehaviorChip(behavior: b)],
            ),
          ],
          if (event.reason != null) ...[
            const SizedBox(height: 12),
            Text(event.reason!, style: const TextStyle(fontSize: 13, height: 20 / 13, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

/// 이상 행동 먼저, 그 안에서는 확률 높은 순
List<Behavior> sortBehaviors(List<Behavior> list) {
  final out = [...list];
  out.sort((a, b) {
    final aa = Situations.isAbnormal(a.situation);
    final bb = Situations.isAbnormal(b.situation);
    if (aa != bb) return aa ? -1 : 1;
    return b.prob.compareTo(a.prob);
  });
  return out;
}

String behaviorLabel(Behavior b) =>
    '${b.situation} ${(b.prob * 100).round()}%${b.source == 'end' ? ' · 끝날 때' : ''}';

class _BehaviorChip extends StatelessWidget {
  const _BehaviorChip({required this.behavior});

  final Behavior behavior;

  @override
  Widget build(BuildContext context) {
    final abnormal = Situations.isAbnormal(behavior.situation);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: abnormal ? AppColors.ink : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (abnormal) ...[
            Container(
                width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.alert, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(behaviorLabel(behavior),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: abnormal ? AppColors.surface : AppColors.ink)),
        ],
      ),
    );
  }
}

/// 지나간 길: 처음엔 전체 궤적. 재생 버튼이나 지도를 누르면 실제 속도로 다시 보여 준다(1·2·4배속).
class _TrackMap extends ConsumerStatefulWidget {
  const _TrackMap({required this.event});

  final Event event;

  @override
  ConsumerState<_TrackMap> createState() => _TrackMapState();
}

const trackSpeeds = [1, 2, 4];

abstract final class TrackMapKeys {
  static const play = Key('track.play');
  static const map = Key('track.map');
  static Key speed(int s) => Key('track.speed.$s');
}

class _TrackMapState extends ConsumerState<_TrackMap> with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(vsync: this)..addListener(_tick);
  int _speed = 1;

  /// 재생을 한 번이라도 시작했는지 (아니면 전체 궤적)
  bool _started = false;

  List<TrailPoint> get _trail {
    final start = widget.event.startedTime;
    return [
      for (final p in widget.event.track!)
        if (p.length >= 3) TrailPoint(start.add(Duration(milliseconds: (p[0] * 1000).round())), p[1], p[2]),
    ];
  }

  static Duration _total(List<TrailPoint> trail) =>
      trail.length < 2 ? Duration.zero : trail.last.t.difference(trail.first.t);

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  void _toggle(Duration total) {
    if (total == Duration.zero) return;
    if (_play.isAnimating) {
      _play.stop();
    } else {
      _started = true;
      _play.duration = total * (1 / _speed);
      _play.forward(from: _play.value >= 1 ? 0 : _play.value);
    }
    setState(() {});
  }

  void _setSpeed(int speed, Duration total) {
    if (speed == _speed) return;
    setState(() => _speed = speed);
    if (total == Duration.zero) return;
    _play.duration = total * (1 / speed);
    if (_play.isAnimating) _play.forward(from: _play.value); // 남은 구간을 새 배속으로
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final region = ref.watch(connectionProvider.select((c) => c.info?.region)) ??
        ref.watch(piSettingsProvider.select((s) => s?.region)) ??
        const Region(xmin: -2, xmax: 2, ymin: 0, ymax: 3, fovDeg: 135);
    final full = _trail;
    final total = _total(full);
    final elapsed = _started ? total * _play.value : total;
    final shown = _started ? trailUntil(full, elapsed) : full;
    final head = shown.isEmpty ? full.first : shown.last;
    final playing = _play.isAnimating;

    final person = TrackedPerson(
      person: LivePerson(
        id: event.person,
        x: head.x,
        y: head.y,
        situation: event.situation,
        prob: event.prob,
        abnormal: event.abnormal,
      ),
      trail: shown,
      firstX: full.first.x,
      firstY: full.first.y,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 14),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('지나간 길',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.surface)),
              ),
              Text(
                '${formatSeconds(elapsed.inMilliseconds / 1000)} / ${formatSeconds(total.inMilliseconds / 1000)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onDarkMuted, fontFeatures: [FontFeature.tabularFigures()]),
              ),
              IconButton(
                key: TrackMapKeys.play,
                onPressed: total == Duration.zero ? null : () => _toggle(total),
                tooltip: playing ? '멈추기' : '재생',
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                color: AppColors.surface,
                disabledColor: AppColors.mapLine,
                iconSize: 22,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Center(
            child: SizedBox(
              width: 240,
              child: AspectRatio(
                aspectRatio: mapDesignSize.width / mapDesignSize.height,
                child: Semantics(
                  image: true,
                  label: '이 사람이 지나간 길',
                  child: GestureDetector(
                    key: TrackMapKeys.map,
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggle(total),
                    child: CustomPaint(
                      painter: DoorMapPainter(
                        region: region,
                        people: [person],
                        showLabels: false,
                        textScaler: MediaQuery.textScalerOf(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final sp in trackSpeeds) ...[
                if (sp != trackSpeeds.first) const SizedBox(width: 6),
                _SpeedChip(speed: sp, selected: sp == _speed, onTap: () => _setSpeed(sp, total)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 배속 고르기 (검은 카드 위: 고른 것은 흰 바탕)
class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.speed, required this.selected, required this.onTap});

  final int speed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$speed배속',
      excludeSemantics: true,
      child: GestureDetector(
        key: TrackMapKeys.speed(speed),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 28,
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.mapArc,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$speed×',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.onDarkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 판정 확인 (정답 표시)

class _LabelCard extends ConsumerStatefulWidget {
  const _LabelCard({required this.eventId, required this.event});

  final int eventId;
  final Event event;

  @override
  ConsumerState<_LabelCard> createState() => _LabelCardState();
}

class _LabelCardState extends ConsumerState<_LabelCard> {
  bool _busy = false;

  Future<void> _send(String? situation) async {
    setState(() => _busy = true);
    try {
      await ref.read(eventDetailProvider(widget.eventId).notifier).setLabel(situation);
    } catch (e) {
      if (!mounted) return;
      final String msg;
      if (situation == null && e is PiApiException && e.statusCode == 400) {
        msg = '기기가 아직 되돌리기를 지원하지 않아요. "다른 상황이에요"로 고칠 수 있어요';
      } else if (e is PiApiException && !e.isNetwork) {
        msg = '저장하지 못했어요: ${e.message}';
      } else {
        msg = '기기에 연결할 수 없어 저장하지 못했어요';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickOther() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => _SituationSheet(current: widget.event.label ?? widget.event.situation),
    );
    if (picked != null) await _send(picked);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.event.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.softCard)),
      child: label == null ? _asking() : _done(label),
    );
  }

  Widget _asking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('판정이 맞나요?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 12),
        const Text('알려주시면 다음 학습 데이터로 저장돼요.',
            style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.muted)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: EventDetailScreen.yesKey,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _busy ? null : () => _send(widget.event.situation),
                child: const Text('맞아요', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: EventDetailScreen.otherKey,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _busy ? null : _pickOther,
                child: const Text('다른 상황이에요', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _done(String label) {
    final differs = label != widget.event.situation;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 20, color: AppColors.point),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('정답으로 저장했어요',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(
                differs ? '정답: $label · labels.csv로 내보낼 수 있어요' : 'labels.csv로 내보낼 수 있어요',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: TextButton(
            key: EventDetailScreen.undoKey,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.ink,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            onPressed: _busy ? null : () => _send(null),
            child: const Text('되돌리기'),
          ),
        ),
      ],
    );
  }
}

/// 상황 8개 중 고르기
class _SituationSheet extends StatelessWidget {
  const _SituationSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text('어떤 상황이었나요?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in Situations.all)
                  ChoiceChip(
                    label: Text(s),
                    selected: s == current,
                    showCheckmark: false,
                    shape: const StadiumBorder(),
                    side: BorderSide(color: s == current ? AppColors.ink : AppColors.field),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.ink,
                    labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: s == current ? AppColors.surface : AppColors.ink),
                    onSelected: (_) => Navigator.of(context).pop(s),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
