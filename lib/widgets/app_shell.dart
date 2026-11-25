import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';

/// 하단에 떠 있는 알약 모양 탭(홈 · 기록 · 설정). 활성 탭만 검은 알약.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (icon: Icons.home_outlined, label: '홈'),
    (icon: Icons.schedule, label: '기록'),
    (icon: Icons.tune, label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpace.screenH, 0, AppSpace.screenH, AppSpace.navBottom),
        child: Container(
          height: AppSpace.navHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                _NavItem(
                  icon: _tabs[i].icon,
                  label: _tabs[i].label,
                  active: shell.currentIndex == i,
                  onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.surface : AppColors.muted;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: active ? 20 : 18),
          decoration: BoxDecoration(
            color: active ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: fg, fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
