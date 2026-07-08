import 'package:flutter/material.dart';

/// Centralized color palette for the Admin Panel.
/// Use these constants instead of hardcoded colors everywhere.
abstract final class AppColors {
  // ── Brand / Primary ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5); // Indigo-600
  static const Color primaryDark = Color(0xFF4338CA); // Indigo-700
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo-50

  static const Color secondary = Color(0xFF0EA5E9); // Sky-500
  static const Color secondaryDark = Color(0xFF0284C7); // Sky-600

  static const Color accent = Color(0xFF8B5CF6); // Violet-500

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E); // Green-500
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF06B6D4); // Cyan-500
  static const Color infoLight = Color(0xFFECFEFF);

  // ── Light theme neutrals ───────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate-50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9); // Slate-100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate-900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate-500
  static const Color textDisabledLight = Color(0xFFCBD5E1); // Slate-300

  // ── Dark theme neutrals ────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A); // Slate-900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate-800
  static const Color surfaceVariantDark = Color(0xFF334155); // Slate-700
  static const Color borderDark = Color(0xFF334155); // Slate-700
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate-50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate-400
  static const Color textDisabledDark = Color(0xFF475569); // Slate-600

  // ── Sidebar ────────────────────────────────────────────────────────────────
  static const Color sidebarLight = Color(0xFF1E293B);
  static const Color sidebarDark = Color(0xFF0F172A);
  static const Color sidebarIconLight = Color(0xFF94A3B8);
  static const Color sidebarIconActive = Color(0xFFFFFFFF);
}
