import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 驰陌配色系统
/// A版暗色（系统暗黑时使用）和 C版亮色（系统亮色时使用）
class AppColors {
  AppColors._();

  // ========== 共享品牌主色 ==========
  static const Color orange = Color(0xFFFF6B35); // 活力橙（两个风格共用）
  static const Color orangeLight = Color(0xFFFF8C61); // 浅橙
  static const Color orangeGlow = Color(0x40FF6B35); // 橙色光晕

  // ========== 向后兼容别名 ==========
  static const Color mint = darkAccent;    // A版专属薄荷青（原mint）
  static const Color navy = lightAccent;    // C版专属海军蓝（原navy）
  static const Color primary = orange;      // 主色别名
  static const Color primaryLight = orangeLight; // 主色浅别名
  static const Color primaryDark = orange; // 主色深别名（梯度用）

  // ========== A版暗色（跟随系统暗黑模式）==========
  // 背景
  static const Color darkBg = Color(0xFF0D0D0F); // 深炭黑
  static const Color darkSurface = Color(0xFF1A1A1D); // 卡片表面
  static const Color darkSurfaceElevated = Color(0xFF252528); // 提升表面
  static const Color darkDivider = Color(0xFF2A2A2E); // 分隔线
  // 文字
  static const Color darkTextPrimary = Color(0xFFF5F5F7); // 主文字
  static const Color darkTextSecondary = Color(0xFFB0B0B8); // 次要文字
  static const Color darkTextTertiary = Color(0xFF6B6B74); // 辅助文字
  // A版专属点缀色：薄荷青
  static const Color darkAccent = Color(0xFF00E5CC); // 薄荷青（A版专属）

  // ========== C版亮色（跟随系统亮色模式）==========
  // 背景
  static const Color lightBg = Color(0xFFF8F7F5); // 米白
  static const Color lightSurface = Color(0xFFFFFFFF); // 卡片表面
  static const Color lightSurfaceElevated = Color(0xFFF5F5F3); // 提升表面
  static const Color lightDivider = Color(0xFFEEEEEE); // 分隔线
  // 文字
  static const Color lightTextPrimary = Color(0xFF1A1A2E); // 主文字
  static const Color lightTextSecondary = Color(0xFF6B7280); // 次要文字
  static const Color lightTextTertiary = Color(0xFF9CA3AF); // 辅助文字
  // C版专属点缀色：海军蓝
  static const Color lightAccent = Color(0xFF1E3A5F); // 海军蓝（C版专属）

  // ========== 功能色（两个风格共用）==========
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // 跑步数据色（共用）
  static const Color pace = Color(0xFF3B82F6);      // 配速-蓝
  static const Color heartRate = Color(0xFFEF4444);  // 心率-红
  static const Color cadence = Color(0xFF8B5CF6);    // 步频-紫
  static const Color stride = Color(0xFFF59E0B);     // 步幅-橙
  static const Color elevation = Color(0xFF10B981);  // 海拔-绿
}

/// BuildContext 主题色扩展 —— 基于系统明暗，自动切换 A版/C版 配色
///
/// 【重要】背景/文字/强调色全部用各版本专属色，不走系统默认调色：
/// - 系统暗色 → A版暗色（深炭+薄荷青点缀）
/// - 系统亮色 → C版亮色（米白+海军蓝点缀）
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // 背景与表面
  Color get bgColor => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get surfaceElevatedColor =>
      isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
  Color get dividerColor => isDark ? AppColors.darkDivider : AppColors.lightDivider;

  // 文字
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textTertiary =>
      isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

  /// 【特色点缀色】—— 两个版本的核心差异色，A版薄荷青 / C版海军蓝
  Color get accentVariant =>
      isDark ? AppColors.darkAccent : AppColors.lightAccent;
}

class AppTheme {
  AppTheme._();

  /// 统一文字风格：Bebas Neue（粗体标题）+ Noto Sans SC（中文正文）
  static TextTheme _textTheme({required bool isDark}) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'BebasNeue', fontSize: 32.sp, fontWeight: FontWeight.w400, color: textColor),
      displayMedium: TextStyle(fontFamily: 'BebasNeue', fontSize: 28.sp, fontWeight: FontWeight.w400, color: textColor),
      displaySmall: TextStyle(fontFamily: 'BebasNeue', fontSize: 24.sp, fontWeight: FontWeight.w400, color: textColor),
      headlineLarge: TextStyle(fontFamily: 'BebasNeue', fontSize: 22.sp, fontWeight: FontWeight.w400, color: textColor),
      headlineMedium: TextStyle(fontFamily: 'BebasNeue', fontSize: 18.sp, fontWeight: FontWeight.w400, color: textColor),
      headlineSmall: TextStyle(fontFamily: 'BebasNeue', fontSize: 16.sp, fontWeight: FontWeight.w400, color: textColor),
      bodyLarge: TextStyle(fontFamily: 'NotoSansSC', fontSize: 16.sp, color: textColor),
      bodyMedium: TextStyle(fontFamily: 'NotoSansSC', fontSize: 14.sp, color: textSecondary),
      bodySmall: TextStyle(fontFamily: 'NotoSansSC', fontSize: 12.sp, color: textTertiary),
      labelLarge: TextStyle(fontFamily: 'NotoSansSC', fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.orange),
    );
  }

  /// C版亮色主题 - 米白底 + 活力橙 + 海军蓝
  /// 【不走系统默认蓝灰调色，全部用C版专属配色】
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.orange, // 活力橙
        secondary: AppColors.lightAccent, // 海军蓝（C版专属）
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        color: AppColors.lightSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.lightTextTertiary,
        selectedLabelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: _textTheme(isDark: false),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// A版暗色主题 - 深炭底 + 活力橙 + 薄荷青
  /// 【不走系统默认调色，全部用A版专属配色】
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orange, // 活力橙
        secondary: AppColors.darkAccent, // 薄荷青（A版专属）
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        color: AppColors.darkSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkAccent, // A版：薄荷青
        unselectedItemColor: AppColors.darkTextTertiary,
        selectedLabelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: _textTheme(isDark: true),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
        labelStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14.sp),
        hintStyle: TextStyle(color: AppColors.darkTextTertiary, fontSize: 14.sp),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.darkSurface,
        textColor: AppColors.darkTextPrimary,
        iconColor: AppColors.darkTextSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }
}
