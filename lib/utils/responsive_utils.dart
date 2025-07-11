import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 800 && width <= 1200;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= 800;
  }

  static double getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 48;
    if (isTablet(context)) return 24;
    return 16;
  }

  static double getVerticalSpacing(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }

  static double getFontSize(
    BuildContext context, {
    required double desktop,
    required double tablet,
    required double mobile,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static EdgeInsets getContentPadding(BuildContext context) {
    final horizontal = getHorizontalPadding(context);
    final vertical = getVerticalSpacing(context);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static int getGridCrossAxisCount(
    BuildContext context, {
    required double itemWidth,
    int maxColumns = 8,
    int minColumns = 2,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = getHorizontalPadding(context) * 2;
    final spacing = 16.0;

    final availableWidth = screenWidth - padding;
    int columns = (availableWidth / (itemWidth + spacing)).floor();

    return columns.clamp(minColumns, maxColumns);
  }
}

class AppTheme {
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF2196F3);

  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF666666);

  static TextStyle headlineStyle(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getFontSize(
        context,
        desktop: 32,
        tablet: 28,
        mobile: 24,
      ),
      fontWeight: FontWeight.bold,
      color: textPrimary,
      letterSpacing: 0.5,
    );
  }

  static TextStyle titleStyle(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getFontSize(
        context,
        desktop: 22,
        tablet: 20,
        mobile: 18,
      ),
      fontWeight: FontWeight.bold,
      color: textPrimary,
      letterSpacing: 0.3,
    );
  }

  static TextStyle bodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getFontSize(
        context,
        desktop: 16,
        tablet: 15,
        mobile: 14,
      ),
      color: textSecondary,
      height: 1.4,
    );
  }

  static TextStyle captionStyle(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getFontSize(
        context,
        desktop: 14,
        tablet: 13,
        mobile: 12,
      ),
      color: textTertiary,
    );
  }

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardDark,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration hoverDecoration = BoxDecoration(
    color: cardDark,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class AnimationConstants {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
}
