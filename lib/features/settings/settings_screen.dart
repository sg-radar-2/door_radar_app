import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../data/api/pi_api.dart';
import '../../state/connection.dart';
import '../../state/events.dart';
import '../../state/live.dart';
import '../../state/settings.dart';
import '../../widgets/pill_switch.dart';

/// 와이어프레임 Settings.dc.html
/// 알림 상황 3개(notify), 이상 상황 촬영(camera_on), 촬영 기준(표시만), 휴대폰 보관 기간(앱에만), 기기 상태, 연결 해제.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const keepDaysKey = Key('settings.keepDays');
  static const cameraKey = Key('settings.camera');
  static const disconnectKey = Key('settings.disconnect');
  static Key notifyKey(String situation) => Key('settings.notify.$situation');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpace.navHeight + AppSpace.navBottom + AppSpace.gap;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpace.screenH, 24, AppSpace.screenH, bottom),
          children: [
            Text('설정', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 14),
            const _NotifySection(),
            const SizedBox(height: 14),
            const _CameraSection(),
            const SizedBox(height: 14),
            const _DeviceSection(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 공통

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children, this.footer});

  final String label;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration:
              BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.softCard)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, c) in children.indexed) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.background),
                c,
              ],
            ],
          ),
        ),
        if (footer != null) ...[const SizedBox(height: 8), footer!],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.child, this.trailing, this.onTap});

  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Expanded(child: child),
          ?trailing,
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

const _rowText = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink);
const _hint = TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.muted);

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

String _failMessage(Object e) =>
    e is PiApiException && !e.isNetwork ? '바꾸지 못했어요: ${e.message}' : '기기에 연결할 수 없어 바꾸지 못했어요';

// ---------------------------------------------------------------- 알림

class _NotifySection extends ConsumerWidget {
  const _NotifySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(piSettingsProvider);
    final notify = ref.watch(notifySituationsProvider);
    final enabled = settings != null;

    Future<void> toggle(String situation, bool on) async {
      try {
        await ref.read(piSettingsProvider.notifier).change(notify: toggleNotify(settings!.notify, situation, on));
      } catch (e) {
        if (context.mounted) _snack(context, _failMessage(e));
      }
    }

    return _Section(
      label: '알림',
      footer: enabled
          ? null
          : const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('기기에 연결되면 바꿀 수 있어요', style: _hint),
            ),
      children: [
        for (final s in Situations.abnormal)
          _Row(
            trailing: PillSwitch(
              key: SettingsScreen.notifyKey(s),
              label: '$s 알림',
              value: notify.contains(s),
              onChanged: enabled ? (v) => toggle(s, v) : null,
            ),
            child: Row(
              children: [
                Container(
                    width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.alert, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(s, style: _rowText),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 촬영 · 보관

class _CameraSection extends ConsumerWidget {
  const _CameraSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(piSettingsProvider);

    Future<void> toggle(bool on) async {
      try {
        await ref.read(piSettingsProvider.notifier).change(cameraOn: on);
      } catch (e) {
        if (context.mounted) _snack(context, _failMessage(e));
      }
    }

    return _Section(
      label: '촬영 · 보관',
      children: [
        _Row(
          trailing: PillSwitch(
            key: SettingsScreen.cameraKey,
            label: '이상 상황 촬영',
            value: settings?.cameraOn ?? true,
            onChanged: settings == null ? null : toggle,
          ),
          child: const Text('이상 상황 촬영', style: _rowText),
        ),
        _Row(
          trailing: Text(
            settings == null ? '-' : cameraCriteria(settings.cameraProb, settings.cameraHoldS),
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          child: const Text('촬영 기준', style: _rowText),
        ),
        _KeepDaysRow(deviceDays: settings?.deviceKeepDays ?? PhotoKeep.deviceDays),
      ],
    );
  }
}

/// "60% 이상 · 1초 유지"
String cameraCriteria(double prob, double holdS) => '${(prob * 100).round()}% 이상 · ${formatSeconds(holdS)} 유지';

/// 휴대폰 보관 기간 문자열 검사: 7~730 정수면 그 값, 아니면 null
int? parseKeepDays(String raw) {
  final v = int.tryParse(raw.trim());
  if (v == null || v < PhotoKeep.minDays || v > PhotoKeep.maxDays) return null;
  return v;
}

/// 포커스가 빠질 때: 범위 밖이면 가까운 끝값, 비었거나 숫자가 아니면 원래 값
int fixKeepDays(String raw, int previous) {
  final v = int.tryParse(raw.trim());
  return v == null ? previous : PhotoKeep.clamp(v);
}

/// 휴대폰 보관 기간 (7~730일). 범위 밖이면 테두리·안내 문구가 빨강, 포커스가 빠지면 끝값으로.
class _KeepDaysRow extends ConsumerStatefulWidget {
  const _KeepDaysRow({required this.deviceDays});

  final int deviceDays;

  @override
  ConsumerState<_KeepDaysRow> createState() => _KeepDaysRowState();
}

class _KeepDaysRowState extends ConsumerState<_KeepDaysRow> {
  late final TextEditingController _text;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: '${ref.read(phoneKeepDaysProvider)}');
    _text.addListener(() => setState(() {}));
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    final days = fixKeepDays(_text.text, ref.read(phoneKeepDaysProvider));
    _text.text = '$days';
    if (days != ref.read(phoneKeepDaysProvider)) {
      await ref.read(phoneKeepDaysProvider.notifier).set(days);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = parseKeepDays(_text.text) != null;
    final color = valid ? AppColors.muted : AppColors.alert;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('휴대폰 보관 기간', style: _rowText)),
              Container(
                height: 36,
                padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: valid ? Colors.transparent : AppColors.alert, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 28,
                      child: TextField(
                        key: SettingsScreen.keepDaysKey,
                        controller: _text,
                        focusNode: _focus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        expands: true,
                        maxLines: null,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                        onSubmitted: (_) => _focus.unfocus(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valid ? '이 폰에 7~730일 · 기기에는 ${widget.deviceDays}일만 임시 보관' : '7부터 730 사이의 정수로 입력해 주세요',
            style: _hint.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 기기

class _DeviceSection extends ConsumerWidget {
  const _DeviceSection();

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('연결을 해제할까요?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: const Text(
          '이 폰에 저장한 연결 정보와 기기 주소를 지워요.\n폰에 보관한 사진과 기록은 지우지 않아요.',
          style: TextStyle(fontSize: 14, height: 21 / 14, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            child: const Text('연결 해제', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(connectionProvider.notifier).disconnect(); // router 가 /connect 로 보낸다
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final status = ref.watch(deviceStatusProvider);
    final name = conn.info?.host ?? conn.device?.address ?? '-';
    final word = conn.status != LinkStatus.connected
        ? conn.status.label
        : status == null || (status.radarOk && status.cameraOk)
            ? '정상'
            : '확인 필요';

    return _Section(
      label: '기기',
      children: [
        _Row(
          onTap: () => context.go('/settings/device'),
          trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.subtle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('기기 상태', style: _rowText),
              const SizedBox(height: 1),
              Text('$name · $word', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
        _Row(
          onTap: () => _disconnect(context, ref),
          child: const Text(
            '연결 해제',
            key: SettingsScreen.disconnectKey,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.alert),
          ),
        ),
      ],
    );
  }
}
