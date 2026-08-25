import 'package:flutter/material.dart';

/// Mitra app color palette — Vibrant, bright, festive and energetic.
abstract final class AppColors {
  // ── Vibrant Primary & Festive Accents ──
  static const Color primary = Color(0xFF6366F1); // Royal Indigo
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFFF59E0B); // Festive Amber / Gold
  static const Color secondaryContainer = Color(0xFFFEF3C7);

  static const Color accentDiwali = Color(0xFFFF6F00); // Diwali Gold Saffron
  static const Color accentGanesh = Color(0xFFE11D48); // Festive Crimson / Rose

  // ── Crisp Light Backgrounds ──
  static const Color background = Color(0xFFF8FAFC); // Clean Slate White
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF1F5F9);

  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);

  // ── Financial Semantics ──
  static const Color income = Color(0xFF10B981); // Bright Emerald Green
  static const Color incomeLight = Color(0xFFD1FAE5);
  static const Color expense = Color(0xFFEF4444); // Bright Red
  static const Color expenseLight = Color(0xFFFEE2E2);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color pending = Color(0xFFF59E0B); // Bright Gold/Amber
  static const Color approved = Color(0xFF059669);
  static const Color rejected = Color(0xFFDC2626);

  // ── Dark Mode Backups ──
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color backgroundDark = Color(0xFF0F172A);

  // ── Convenience Brightness Aware Getters ──
  static Color incomeColor(Brightness brightness) => income;
  static Color expenseColor(Brightness brightness) => expense;
  static Color pendingColor(Brightness brightness) => pending;
}
