import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pre-set Festive & Organization Theme configurations.
class FestiveThemeData {
  final String id;
  final String name;
  final String emoji;
  final List<Color> gradient;
  final Color primaryColor;
  final Color accentColor;
  final String tagline;

  const FestiveThemeData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gradient,
    required this.primaryColor,
    required this.accentColor,
    required this.tagline,
  });
}

abstract final class FestiveThemes {
  static const ganeshUtsav = FestiveThemeData(
    id: 'ganesh_utsav',
    name: 'Ganesh Utsav',
    emoji: '🐘',
    gradient: [Color(0xFFFF6F00), Color(0xFFFF8F00), Color(0xFFFFB300)],
    primaryColor: Color(0xFFFF6F00),
    accentColor: Color(0xFFFFD54F),
    tagline: 'Mangal Murti Morya • Auspicious Saffron Gold',
  );

  static const diwali = FestiveThemeData(
    id: 'diwali',
    name: 'Diwali Lights',
    emoji: '🪔',
    gradient: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF8E24AA)],
    primaryColor: Color(0xFF8E24AA),
    accentColor: Color(0xFFFFD700),
    tagline: 'Festival of Lights • Sparkling Golden Violet',
  );

  static const durgaPuja = FestiveThemeData(
    id: 'durga_puja',
    name: 'Durga Puja',
    emoji: '🌺',
    gradient: [Color(0xFFB71C1C), Color(0xFFC62828), Color(0xFFD32F2F)],
    primaryColor: Color(0xFFD32F2F),
    accentColor: Color(0xFFFFEB3B),
    tagline: 'Joy of Sharadotsav • Festive Crimson & White',
  );

  static const sportsTournament = FestiveThemeData(
    id: 'sports',
    name: 'Youth & Sports',
    emoji: '🏆',
    gradient: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
    primaryColor: Color(0xFF00897B),
    accentColor: Color(0xFF80CBC4),
    tagline: 'Energy & Victory • Champion Emerald Teal',
  );

  static const generalTrust = FestiveThemeData(
    id: 'trust',
    name: 'Association / Trust',
    emoji: '🏛️',
    gradient: [Color(0xFF311B92), Color(0xFF4527A0), Color(0xFF512DA8)],
    primaryColor: Color(0xFF512DA8),
    accentColor: Color(0xFFB388FF),
    tagline: 'Transparent & Accountable • Royal Indigo',
  );

  static const List<FestiveThemeData> all = [
    ganeshUtsav,
    diwali,
    durgaPuja,
    sportsTournament,
    generalTrust,
  ];
}

/// StateNotifier managing active festive theme.
class FestiveThemeNotifier extends StateNotifier<FestiveThemeData> {
  FestiveThemeNotifier() : super(FestiveThemes.ganeshUtsav);

  void setTheme(FestiveThemeData theme) {
    state = theme;
  }
}

final festiveThemeProvider = StateNotifierProvider<FestiveThemeNotifier, FestiveThemeData>((ref) {
  return FestiveThemeNotifier();
});
