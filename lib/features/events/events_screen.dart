import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../data/local_store.dart';
import '../../data/models/models.dart';
import '../../state/connection.dart';
import '../../state/events.dart';
import '../../state/live.dart';
import '../../widgets/situation_chip.dart';

/// 와이어프레임 Events.dc.html
/// 날짜별 이벤트(폰 저장소 기준이라 파이에 연결이 안 돼도 보인다), 전체/이상만, 요약 카드, 당겨서 새로고침.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  static const dayPillKey = Key('events.day');
  static const abnormalTabKey = Key('events.abnormal');

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

class _EventsScreenState extends ConsumerState<EventsScreen> {
  DateTime _day = _dateOnly(DateTime.now());
  bool _abnormalOnly = false;

  bool get _isToday => _day == _dateOnly(DateTime.now());

  Future<void> _refresh() async {
    try {
      await ref.read(eventSyncProvider.notifier).refreshDay(_day);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기기에 연결할 수 없어 폰에 저장된 기록만 보여요')),
      );
    }
  }

  Future<void> _pickDay() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => _DaySheet(selected: _day),
    );
    if (picked != null && mounted) setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dayEventsProvider(_day));
    final rows = historyRows(async.value ?? const []);
    final shown = _abnormalOnly ? rows.where((s) => s.event.abnormal).toList() : rows;
    final summary = summarize(rows);
    final linked = ref.watch(connectionProvider.select((c) => c.status)) == LinkStatus.connected;
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpace.navHeight + AppSpace.navBottom + AppSpace.gap;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.ink,
          backgroundColor: AppColors.surface,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(AppSpace.screenH, 24, AppSpace.screenH, bottom),
            children: [
              Row(
                children: [
                  Expanded(child: Text('기록', style: Theme.of(context).textTheme.headlineLarge)),
                  _DayPill(label: DateFormat('M월 d일').format(_day), onTap: _pickDay),
                ],
              ),
              const SizedBox(height: AppSpace.gap),
              _Segment(
                abnormalOnly: _abnormalOnly,
                onChanged: (v) => setState(() => _abnormalOnly = v),
              ),
              const SizedBox(height: AppSpace.gap),
              _SummaryCard(summary: summary, today: _isToday),
              const SizedBox(height: AppSpace.gap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _isToday ? '오늘' : DateFormat('M월 d일').format(_day),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 8),
              if (async.hasError && async.value == null)
                const _Empty(text: '폰에 저장된 기록을 읽지 못했어요')
              else if (async.value == null)
                const SizedBox(height: 64)
              else if (shown.isEmpty)
                _Empty(
                  text: _abnormalOnly
                      ? '이상 상황이 없었어요'
                      : linked
                          ? '이 날은 기록이 없어요'
                          : '폰에 저장된 기록이 없어요. 기기에 연결되면 받아 와요',
                )
              else
                for (final (i, s) in shown.indexed) ...[
                  if (i > 0) const SizedBox(height: 8),
                  EventRow(stored: s),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(),
      child: InkWell(
        key: EventsScreen.dayPillKey,
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// 이벤트가 있는 날짜 고르기 (오늘은 항상 맨 위)
class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.selected});

  final DateTime selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = _dateOnly(DateTime.now());
    final days = ref.watch(eventDaysProvider).value ?? const <DayCount>[];
    final counts = {for (final d in days) _dateOnly(d.day): d.count};
    final list = {today, ...counts.keys}.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text('날짜 고르기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final d in list)
                    ListTile(
                      shape: const StadiumBorder(),
                      selected: d == selected,
                      selectedTileColor: AppColors.background,
                      selectedColor: AppColors.ink,
                      title: Text(
                        d == today
                            ? '오늘 · ${DateFormat('M월 d일').format(d)}'
                            : '${DateFormat('M월 d일').format(d)} (${'월화수목금토일'[d.weekday - 1]})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      trailing: Text('${counts[d] ?? 0}건', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                      onTap: () => Navigator.of(context).pop(d),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.abnormalOnly, required this.onChanged});

  final bool abnormalOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool value, {Key? key}) {
      final on = abnormalOnly == value;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: GestureDetector(
            key: key,
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: on ? AppColors.ink : AppColors.muted)),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.segment, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        children: [
          tab('전체', false),
          const SizedBox(width: 4),
          tab('이상만', true, key: EventsScreen.abnormalTabKey),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.today});

  final DaySummary summary;
  final bool today;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, int value, {bool dot = false}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onDarkMuted)),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (dot) ...[
                    Container(
                        width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.alert, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                  ],
                  Text('$value',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.surface)),
                ],
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        children: [
          cell(today ? '오늘 전체' : '이날 전체', summary.total),
          const SizedBox(width: 8),
          cell('이상', summary.abnormal, dot: summary.abnormal > 0),
          const SizedBox(width: 8),
          cell('촬영', summary.photos),
        ],
      ),
    );
  }
}

/// 기록 한 줄: 시각 · 메타("1분 23초 · 촬영", "외곽으로 사라짐"), 확률
class EventRow extends StatelessWidget {
  const EventRow({super.key, required this.stored});

  final StoredEvent stored;

  @override
  Widget build(BuildContext context) {
    final e = stored.event;
    final time = DateFormat('HH:mm').format(e.time.toLocal());
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/events/${e.id}'),
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: e.abnormal ? AppColors.darkIcon : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    e.abnormal ? Icons.photo_camera_outlined : Icons.door_front_door_outlined,
                    size: 20,
                    color: e.abnormal ? AppColors.surface : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(e.situation,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          ),
                          if (e.abnormal) ...[const SizedBox(width: 6), const AbnormalChip()],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('$time · ${eventMeta(e)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(e.prob * 100).round()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.subtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 목록 메타 문구. 이상: "1분 23초 · 촬영", 정상: 경로 끝("외곽으로 사라짐"), 진행 중 촬영: "진행 중 · 촬영"
String eventMeta(Event e) {
  final parts = <String>[];
  if (e.kind == EventKind.camera) {
    parts.add('진행 중');
  } else if (e.abnormal || e.path == null) {
    final d = eventDuration(e);
    if (d != null) parts.add(formatSeconds(d.inMilliseconds / 1000));
  } else {
    parts.add(pathEnd(e.path!));
  }
  if (e.photo) parts.add('촬영');
  return parts.join(' · ');
}

Duration? eventDuration(Event e) => e.endedTime?.difference(e.startedTime);

/// "외곽에서 들어옴(2.4m) → 문으로 사라짐(0.5m)" → "문으로 사라짐"
String pathEnd(String path) =>
    path.split('→').last.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
    );
  }
}
