import 'package:flutter/material.dart';

/// Centralized color palette for the Admin Panel.
/// Clean, elegant, modern high-fashion color palette inspired by Zara, COS & Uniqlo.
abstract final class AppColors {
  // ── Brand / Fashion Primary & Accent ───────────────────────────────────────
  static const Color primary = Color(0xFF1A1A1A); // Clean matte black / charcoal
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryLight = Color(0xFFF3F4F6);

  static const Color secondary = Color(0xFFFFFFFF);
  static const Color secondaryDark = Color(0xFFF3F4F6);

  static const Color accent = Color(0xFFC8B6A6); // Elegant warm taupe
  static const Color accentLight = Color(0xFFF5F0EB); // Light taupe tint for selected states

  // ── Semantic Colors ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald green
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444); // Crimson red
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6); // Clean blue
  static const Color infoLight = Color(0xFFEFF6FF);

  // ── Light Theme Neutrals ───────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F8F8); // Minimal light grey bg
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF3F4F6);
  static const Color borderLight = Color(0xFFE5E7EB); // Light grey border
  static const Color textPrimaryLight = Color(0xFF1A1A1A); // Charcoal primary text
  static const Color textSecondaryLight = Color(0xFF6B7280); // Muted grey secondary text
  static const Color textDisabledLight = Color(0xFF9CA3AF);

  // ── Dark Theme Neutrals ────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF121212); // Matte dark bg
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceVariantDark = Color(0xFF262626);
  static const Color borderDark = Color(0xFF2E2E2E);
  static const Color textPrimaryDark = Color(0xFFF8F8F8);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textDisabledDark = Color(0xFF525252);

  // ── Sidebar & Navigation ───────────────────────────────────────────────────
  static const Color sidebarLight = Color(0xFFFFFFFF); // Clean white sidebar
  static const Color sidebarDark = Color(0xFF1A1A1A);
  static const Color sidebarIconLight = Color(0xFF6B7280);
  static const Color sidebarIconActive = Color(0xFF1A1A1A);
}
