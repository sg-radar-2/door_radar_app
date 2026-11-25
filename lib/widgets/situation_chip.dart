import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';

/// 빨간 "이상" 칩 (기록 목록, 이벤트 상세)
class AbnormalChip extends StatelessWidget {
  const AbnormalChip({super.key, this.height = 20, this.fontSize = 11});

  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height / 2.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.alert, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text('이상', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: AppColors.surface)),
    );
  }
}
