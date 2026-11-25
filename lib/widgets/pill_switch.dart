import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';

/// 와이어프레임 스위치: 48×28, 켜짐 검정 / 꺼짐 #D6D6D4, 흰 원 22.
class PillSwitch extends StatelessWidget {
  const PillSwitch({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;

  /// null 이면 비활성 (기기에 연결 안 됨)
  final ValueChanged<bool>? onChanged;

  /// 화면 읽기용 이름 ("장시간 체류 알림")
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Padding(
          // 누르는 영역은 48×48
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? AppColors.ink : AppColors.switchOff,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
