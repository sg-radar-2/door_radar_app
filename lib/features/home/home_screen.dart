import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../data/notifications.dart';
import '../../state/connection.dart';
import '../../state/events.dart';
import '../../state/live.dart';
import '../../state/settings.dart';
import 'door_map_painter.dart';

/// 와이어프레임 Home.dc.html / HomeAlert.dc.html
/// 문 앞 지도(실시간), 진행 중 판정, 최근 기록 2개, 이상 상황이면 빨간 배너.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const alertBannerKey = Key('home.alert');
  static const alertPhotoKey = Key('home.alert.photo');
  static const alertOkKey = Key('home.alert.ok');
  static const mapKey = Key('home.map');

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// region 을 아직 못 받았을 때 (SPEC 기본값)
const _defaultRegion = Region(xmin: -2, xmax: 2, ymin: 0, ymax: 3, fovDeg: 135);

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Android 13+ 알림 권한. 홈에 처음 들어왔을 때 한 번.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(alertNotificationsProvider).requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alert = ref.watch(homeAlertProvider);
    final live = ref.watch(liveProvider);
    final people = cardOrder(live.people);
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpace.navHeight + AppSpace.navBottom + AppSpace.gap;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpace.screenH, 24, AppSpace.screenH, bottom),
          children: [
            _Header(alerting: alert != null),
            if (alert != null) ...[
              const SizedBox(height: AppSpace.gap),
              _AlertBanner(event: alert, person: live.find(alert.person)),
            ],
            const SizedBox(height: AppSpace.gap),
            const _MapCard(),
            const SizedBox(height: AppSpace.gap),
            if (people.isEmpty)
              _EmptyProgressCard(linked: ref.watch(connectionProvider.select((c) => c.status)) == LinkStatus.connected)
            else
              for (final (i, p) in people.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                _ProgressCard(person: p),
              ],
            const SizedBox(height: AppSpace.gap),
            const _RecentEvents(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 상단

class _Header extends ConsumerWidget {
  const _Header({required this.alerting});

  final bool alerting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: alerting ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('현관', style: Theme.of(context).textTheme.headlineLarge),
              // 이상 배너가 뜨면 와이어프레임(HomeAlert)처럼 칩을 숨긴다
              if (!alerting) ...[const SizedBox(height: 10), const _StatusChips()],
            ],
          ),
        ),
        Semantics(
          button: true,
          label: '알림 기록',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.go('/events'),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 22, color: AppColors.surface),
                  if (alerting)
                    Positioned(
                      top: 10,
                      right: 11,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.alert,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 레이더 연결 / 카메라 정상. 실시간 연결이 끊기면 연결 상태 칩 하나로 바뀐다.
class _StatusChips extends ConsumerWidget {
  const _StatusChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(connectionProvider.select((c) => c.status));
    final radar = ref.watch(liveProvider.select((l) => l.radar));
    final status = ref.watch(deviceStatusProvider);

    final chips = <Widget>[
      if (link != LinkStatus.connected)
        StatusChip(label: link.label, ok: false)
      else ...[
        StatusChip(label: radarLabel(radar ?? status?.radar), ok: (radar ?? status?.radar) == 'ok'),
        if (status != null) StatusChip(label: cameraLabel(status.camera), ok: status.cameraOk),
      ],
    ];
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 정상: 검은 점, 아니면 속 빈 점
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? AppColors.ink : null,
              border: ok ? null : Border.all(color: AppColors.muted, width: 1.2),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 이상 배너

class _AlertBanner extends ConsumerWidget {
  const _AlertBanner({required this.event, required this.person});

  final Event event;
  final TrackedPerson? person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat('HH:mm:ss').format(event.time.toLocal());
    final p = person;
    final detail = p == null
        ? null
        : event.situation == '장시간 체류'
            ? '문 앞 ${p.distance.toStringAsFixed(1)}m에서 ${formatSeconds(p.person.stillS)}째 머무는 중'
            : '문 앞 ${p.distance.toStringAsFixed(1)}m · ${formatSeconds(p.person.elapsedS)}째';

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: HomeScreen.alertBannerKey,
        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
        decoration: BoxDecoration(color: AppColors.alert, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.photo ? '이상 상황 · $time 촬영됨' : '이상 상황 · $time',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.surface.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.situation} 감지',
                        style: const TextStyle(
                            fontSize: 22,
                            height: 28 / 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                            color: AppColors.surface),
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: 4),
                        Text(detail, style: const TextStyle(fontSize: 13, height: 19 / 13, color: AppColors.surface)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Pill(
                  height: 28,
                  color: AppColors.surface,
                  child: Text('${(event.prob * 100).round()}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      key: HomeScreen.alertPhotoKey,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.ink,
                        minimumSize: const Size.fromHeight(44),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => context.go('/events/${event.id}'),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(event.photo ? '사진 보기' : '자세히 보기'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    key: HomeScreen.alertOkKey,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.surface.withValues(alpha: 0.7)),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => ref.read(homeAlertProvider.notifier).dismiss(),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 지도

class _MapCard extends ConsumerWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveProvider);
    final conn = ref.watch(connectionProvider);
    final region = conn.info?.region ?? ref.watch(piSettingsProvider.select((s) => s?.region)) ?? _defaultRegion;
    final linked = conn.status == LinkStatus.connected;
    final count = live.people.length;

    final String? overlay;
    final String? overlaySub;
    if (!linked) {
      overlay = conn.status == LinkStatus.retrying ? '다시 연결하는 중' : conn.status.label;
      overlaySub = conn.retryIn == null ? null : '${conn.retryIn!.inSeconds}초 뒤 다시 시도';
    } else if (live.hasFrame && !live.radarOk) {
      overlay = radarLabel(live.radar);
      overlaySub = '파이가 레이더에 다시 연결하고 있어요';
    } else {
      overlay = null;
      overlaySub = null;
    }

    final nearest = cardOrder(live.people).firstOrNull;
    final semantics = count == 0
        ? '문 앞 실시간 지도: 아무도 없음'
        : '문 앞 실시간 지도: 문에서 ${nearest!.distance.toStringAsFixed(1)}m 거리에 $count명';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: linked ? AppColors.point : AppColors.onDarkMuted,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('LIVE · 위에서 본 문 앞',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.surface)),
              ),
              Text(linked ? '$count명' : '-',
                  style: const TextStyle(fontSize: 13, color: AppColors.onDarkMuted)),
            ],
          ),
          const SizedBox(height: 6),
          AspectRatio(
            aspectRatio: mapDesignSize.width / mapDesignSize.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  key: HomeScreen.mapKey,
                  image: true,
                  label: linked ? semantics : '문 앞 실시간 지도: 연결 안 됨',
                  child: CustomPaint(
                    painter: DoorMapPainter(
                      region: region,
                      people: live.people,
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
                if (overlay != null)
                  ColoredBox(
                    color: AppColors.ink.withValues(alpha: 0.72),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!linked)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                            ),
                          const SizedBox(height: 10),
                          Text(overlay,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.surface)),
                          if (overlaySub != null) ...[
                            const SizedBox(height: 4),
                            Text(overlaySub, style: const TextStyle(fontSize: 12, color: AppColors.onDarkMuted)),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 진행 중 판정

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.person});

  final TrackedPerson person;

  @override
  Widget build(BuildContext context) {
    final p = person.person;
    final deciding = p.situation == Situations.deciding;
    final pct = (p.prob * 100).round();
    const big = TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.8, color: AppColors.ink);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.softCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${p.id} · ${formatSeconds(p.elapsedS)} 전부터',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
              const Text('진행 중 판정', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(p.situation, style: big.copyWith(color: p.abnormal ? AppColors.alert : AppColors.ink)),
              ),
              if (!deciding)
                Text.rich(TextSpan(text: '$pct', style: big, children: const [
                  TextSpan(text: '%', style: TextStyle(fontSize: 15)),
                ])),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: deciding ? null : p.prob.clamp(0.0, 1.0).toDouble(),
              minHeight: 4,
              backgroundColor: AppColors.background,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Fact(label: '거리', value: '${person.distance.toStringAsFixed(1)}m'),
              const SizedBox(width: 8),
              _Fact(label: '머문 시간', value: formatSeconds(p.stillS)),
              const SizedBox(width: 8),
              _Fact(label: '나타난 곳', value: person.appearedAt),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _EmptyProgressCard extends StatelessWidget {
  const _EmptyProgressCard({required this.linked});

  final bool linked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.softCard)),
      child: Row(
        children: [
          Expanded(
            child: Text(linked ? '문 앞에 아무도 없어요' : '연결되면 실시간으로 보여요',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
          const Text('진행 중 판정', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 최근 기록

class _RecentEvents extends ConsumerWidget {
  const _RecentEvents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(recentEventsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text('최근 기록',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ),
              InkWell(
                onTap: () => context.go('/events'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('전체 보기', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (events == null)
          const SizedBox(height: 56)
        else if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text('아직 기록이 없어요', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          )
        else
          for (final (i, e) in events.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            _RecentRow(event: e),
          ],
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final abnormal = event.abnormal;
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/events/${event.id}'),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: abnormal ? AppColors.alert : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    abnormal ? Icons.photo_camera_outlined : Icons.door_front_door_outlined,
                    size: 18,
                    color: abnormal ? AppColors.surface : AppColors.ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(event.situation,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                ),
                Text(DateFormat('HH:mm').format(event.time.toLocal()),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.height, required this.color, required this.child});

  final double height;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: child,
    );
  }
}
