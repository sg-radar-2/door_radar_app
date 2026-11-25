import 'package:material_ui/material_ui.dart';

/// 디자인 토큰. 와이어프레임(docs/wireframe)과 같은 값.
/// 기본은 진한 회색과 흰색 모노톤, 색은 이상 상황(alert)과 실시간 표시(point)에만 쓴다.
abstract final class AppColors {
  static const ink = Color(0xFF141414); // 글자, 검은 카드, 활성 탭
  static const surface = Color(0xFFFFFFFF); // 흰 카드
  static const background = Color(0xFFEFEFEE); // 화면 배경
  static const muted = Color(0xFF6B6B6B); // 보조 글자
  static const subtle = Color(0xFF8A8A88); // 화살표, placeholder
  static const line = Color(0xFFE2E2E0); // 하단 탭 테두리
  static const field = Color(0xFFDCDCDA); // 입력칸 테두리
  static const segment = Color(0xFFE3E3E1); // 세그먼트(전체/이상만) 바탕
  static const switchOff = Color(0xFFD6D6D4);
  static const darkCard = Color(0xFF1E1E1E); // 사진 자리
  static const darkIcon = Color(0xFF2A2A2A); // 기록의 이상 이벤트 사각 아이콘
  static const mapLine = Color(0xFF3A3A3A); // 지도 영역·화각 선
  static const mapArc = Color(0xFF2C2C2C); // 지도 거리 원호
  static const onDarkMuted = Color(0xFFA3A3A3);

  static const alert = Color(0xFFD4381C); // 이상 상황에만
  static const point = Color(0xFFC6F24E); // 실시간 사람 점, LIVE 표시에만
}

/// 글꼴: Inter Tight(숫자·영문) + Noto Sans KR(한글). assets/fonts 에 번들.
abstract final class AppFonts {
  static const family = 'InterTight';
  static const fallback = ['NotoSansKR'];
}

abstract final class AppRadius {
  // 와이어프레임을 고치는 중이라 값이 섞여 있다. docs/wireframe 최신 값을 따른다.
  static const card = 14.0; // 지도·이상 배너·요약·나온 행동 카드 (사용자가 28/24 → 14 로 수정)
  static const softCard = 24.0; // 아직 24 로 남은 흰 카드 (진행 중 판정, 판정 확인 등)
  static const photo = 28.0; // 사진 자리
  static const field = 13.0; // IP 입력칸
  static const pill = 999.0;
}

abstract final class AppSpace {
  static const screenH = 20.0; // 좌우 여백
  static const gap = 16.0; // 카드 사이
  static const navHeight = 64.0;
  static const navBottom = 20.0;
}

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.ink,
    onPrimary: AppColors.surface,
    secondary: AppColors.ink,
    onSecondary: AppColors.surface,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.alert,
    onError: AppColors.surface,
    outline: AppColors.field,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.family,
    fontFamilyFallback: AppFonts.fallback,
  );
  final text = base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w600, letterSpacing: -1.2),
      headlineMedium: text.headlineMedium?.copyWith(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w600, letterSpacing: -0.9),
      titleLarge: text.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.6),
      titleMedium: text.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: text.bodySmall?.copyWith(fontSize: 12, color: AppColors.muted),
      labelMedium: text.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.surface,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink),
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.field),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.field),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    ),
    dividerColor: AppColors.background,
  );
}
