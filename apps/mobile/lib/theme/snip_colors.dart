import 'package:flutter/material.dart';

abstract final class SnipColors {
  /// Primary Teal from SNIP brand kit (#14B8A6)
  static const Color primary = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF2DD4BF);
  static const Color primaryMuted = Color(0xFFCCFBF1);

  /// Dark Charcoal for headings and sidebar (#1F2937)
  static const Color dark = Color(0xFF1F2937);
  static const Color darkCharcoal = Color(0xFF111827);

  /// Backgrounds & Neutrals
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  /// Borders & Dividers (#E5E7EB)
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  /// Typography colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF97316);
  static const Color warningLight = Color(0xFFFFEDD5);
  static const Color amber = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
}
