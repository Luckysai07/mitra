import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Preset Festival & Event Theme configurations for 3D visual showcase.
class FestivalThemeConfig {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final String offerTitle;
  final String offerDetail;
  final double progress;
  final String collectedAmount;
  final String targetAmount;

  const FestivalThemeConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
    required this.offerTitle,
    required this.offerDetail,
    required this.progress,
    required this.collectedAmount,
    required this.targetAmount,
  });
}

const List<FestivalThemeConfig> kFestivalThemes = [
  FestivalThemeConfig(
    id: 'ganesh_utsav',
    title: 'Ganesh Utsav 2026',
    subtitle: 'Grand Utsav Committee Ledger',
    emoji: '🐘',
    icon: Icons.temple_hindu_rounded,
    gradientColors: [Color(0xFFFF5722), Color(0xFFFF9800), Color(0xFFE91E63)],
    accentColor: Color(0xFFFFD700),
    offerTitle: '3D Mandap & Puja Donation Tracker',
    offerDetail: 'Zero error accounting for Chanda, Prasad & Sound Setup',
    progress: 0.78,
    collectedAmount: '₹1,85,000',
    targetAmount: '₹2,50,000',
  ),
  FestivalThemeConfig(
    id: 'diwali_dhamaka',
    title: 'Diwali Dhamaka Fest',
    subtitle: 'Lighting & Cultural Event Budget',
    emoji: '🪔',
    icon: Icons.light_mode_rounded,
    gradientColors: [Color(0xFF8E24AA), Color(0xFFD81B60), Color(0xFFFF6F00)],
    accentColor: Color(0xFFFFEA00),
    offerTitle: 'Diwali Festive Bonus Offer',
    offerDetail: 'Track Light Decor, Sweet Boxes & Fireworks transparently',
    progress: 0.64,
    collectedAmount: '₹95,000',
    targetAmount: '₹1,50,000',
  ),
  FestivalThemeConfig(
    id: 'new_year',
    title: 'New Year 2027 Carnival',
    subtitle: 'Youth Party & DJ Night Ledger',
    emoji: '🎉',
    icon: Icons.celebration_rounded,
    gradientColors: [Color(0xFF00E5FF), Color(0xFF2979FF), Color(0xFF651FFF)],
    accentColor: Color(0xFF00E676),
    offerTitle: '3D Neon Ticket & Entry Passes',
    offerDetail: 'Instant QR Scanner & Live Bar Chart Analytics',
    progress: 0.90,
    collectedAmount: '₹3,20,000',
    targetAmount: '₹3,50,000',
  ),
  FestivalThemeConfig(
    id: 'sports_league',
    title: 'Premier Cricket League',
    subtitle: 'Sports & Tournament Fees',
    emoji: '🏆',
    icon: Icons.sports_cricket_rounded,
    gradientColors: [Color(0xFF00C853), Color(0xFF64DD17), Color(0xFF00B0FF)],
    accentColor: Color(0xFFFFFF00),
    offerTitle: 'Match Fee & Trophy Sponsorship',
    offerDetail: 'Automatic team ledger split & live receipt generation',
    progress: 0.52,
    collectedAmount: '₹42,000',
    targetAmount: '₹80,000',
  ),
];

/// A spectacular 3D Animated Card with interactive Theme Switcher and 3D Bar effects.
class Festive3DThemeShowcase extends StatefulWidget {
  final ValueChanged<FestivalThemeConfig>? onThemeChanged;

  const Festive3DThemeShowcase({
    super.key,
    this.onThemeChanged,
  });

  @override
  State<Festive3DThemeShowcase> createState() => _Festive3DThemeShowcaseState();
}

class _Festive3DThemeShowcaseState extends State<Festive3DThemeShowcase>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _pulseAnim;
  Timer? _autoRotateTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Auto-cycle themes to captivate users
    _autoRotateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % kFestivalThemes.length;
        });
        if (widget.onThemeChanged != null) {
          widget.onThemeChanged!(kFestivalThemes[_currentIndex]);
        }
      }
    });
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = kFestivalThemes[_currentIndex];

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Theme Selector Pill Bar ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(kFestivalThemes.length, (idx) {
                    final isSelected = idx == _currentIndex;
                    final item = kFestivalThemes[idx];

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _currentIndex = idx);
                          if (widget.onThemeChanged != null) {
                            widget.onThemeChanged!(item);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? item.gradientColors.first
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? item.accentColor
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: item.gradientColors.first.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                item.title.split(' ')[0],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade300,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 3D Glassmorphic Hero Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: theme.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: theme.gradientColors.first.withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with 3D Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.5)),
                              ),
                              child: Icon(theme.icon, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theme.title,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  theme.subtitle,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // 3D Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Text(
                            'LIVE 3D',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Offer Highlight Box
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 24),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theme.offerTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  theme.offerDetail,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 3D Progress Bar & Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Collection Target: ${theme.targetAmount}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          theme.collectedAmount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Animated Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            height: 12,
                            color: Colors.black.withOpacity(0.2),
                          ),
                          FractionallySizedBox(
                            widthFactor: theme.progress,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [theme.accentColor, Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.accentColor.withOpacity(0.8),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
