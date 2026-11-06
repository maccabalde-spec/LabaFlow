import 'package:flutter/material.dart';

/// Shared layout tokens used by Flutter screens and mirrored in the web theme.
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double card = 14;
  static const double large = 18;
  static const double pill = 999;
}

class AppElevation {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

// ═══════════════════════════════════════════════════════════
//  LABAFLOW COLOR SYSTEM
//  Mirrors the CSS variables from LabaFlow.html exactly
// ═══════════════════════════════════════════════════════════

class AppColors {
  // ── Landing page palette (light) ──
  static const lpBg = Color(0xFFF3FAFB);
  static const lpWhite = Color(0xFFFFFFFF);
  static const lpText = Color(0xFF111827);
  static const lpMuted = Color(0xFF6B7280);
  static const lpSubtle = Color(0xFFF3F4F6);
  static const lpBorder = Color(0xFFD8EAEC);
  static const lpAccent = Color(0xFF078695);
  static const lpAccent2 = Color(0xFF066C79);
  static const lpNavy = Color(0xFF123943);

  // ── App/portal light palette (Option 1: Aqua Glass & Ocean Mesh Aurora) ──
  static const lightBg = Color(0xFFE2F7FA);
  static const lightSidebar = Color(0xF0FFFFFF);
  static const lightSurface = Color(0xF2FFFFFF);
  static const lightCard = Color(0xE8FFFFFF);
  static const lightBorder = Color(0xFFC8EBF0);
  static const lightAccent = Color(0xFF06B6D4);
  static const lightAccent2 = Color(0xFF0284C7);
  static const lightBtn = Color(0xFF0891B2);
  static const lightText = Color(0xFF111827);
  static const lightMuted = Color(0xFF4B6870);
  static const lightDim = Color(0xFF718B91);
  static const successLight = Color(0xFF16866E);
  static const warnLight = Color(0xFFA96A18);
  static const dangerLight = Color(0xFFC54D54);
  static const infoBg = Color(0xFFE0F2FE);
  static const successBg = Color(0xFFDCFCE7);
  static const warnBg = Color(0xFFFEF3C7);
  static const dangerBg = Color(0xFFFEE2E2);
  static const success = successLight;
  static const warn = warnLight;
  static const danger = dangerLight;
  static const bubbleMe = Color(0xFF078695);

  // ── Status badge colors ──
  static const statusPending = Color(0xFF1D4ED8);
  static const statusReceived = Color(0xFF0369A1);
  static const statusProcessing = Color(0xFF92400E);
  static const statusReady = Color(0xFF047857);
  static const statusReleased = Color(0xFF6D28D9);

  // ── Loyalty tier colors ──
  static const tierBronze = Color(0xFFCD7F32);
  static const tierSilver = Color(0xFF9CA3AF);
  static const tierGold = Color(0xFFF59E0B);
  static const tierPlatinum = Color(0xFFA78BFA);
}

// ═══════════════════════════════════════════════════════════
//  THEME DATA
// ═══════════════════════════════════════════════════════════

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightBtn,
        secondary: AppColors.lightAccent2,
        surface: AppColors.lightSurface,
        error: AppColors.dangerLight,
        onPrimary: Colors.white,
        onSurface: AppColors.lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.lightSidebar,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
          side: BorderSide(color: AppColors.lightBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightText, fontSize: 14),
        bodyMedium: TextStyle(color: AppColors.lightMuted, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.lightDim, fontSize: 12),
        titleLarge: TextStyle(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.lightText,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: AppColors.lightText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          color: AppColors.lightMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      dividerColor: AppColors.lightBorder,
      iconTheme: const IconThemeData(color: AppColors.lightMuted),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        constraints: const BoxConstraints(minHeight: 44),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: const BorderSide(
            color: AppColors.lightAccent,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(color: AppColors.lightMuted, fontSize: 12),
        hintStyle: const TextStyle(color: AppColors.lightDim, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightBtn,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightMuted,
          side: const BorderSide(color: AppColors.lightBorder),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.lightMuted,
        textColor: AppColors.lightMuted,
        selectedColor: AppColors.lightAccent,
        selectedTileColor: Color(0x140284C7),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.infoBg,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.lightAccent2
                : AppColors.lightMuted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightAccent2,
        unselectedItemColor: AppColors.lightMuted,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.lightAccent2,
        unselectedLabelColor: AppColors.lightMuted,
        indicatorColor: AppColors.lightAccent,
        dividerColor: AppColors.lightBorder,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightText,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
    );
  }
}
