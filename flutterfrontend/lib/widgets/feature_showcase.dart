import 'package:flutter/material.dart';

import '../config/theme.dart';

class FarmFeature {
  final String title;
  final String subtitle;
  final String image;
  final String prompt;
  final Color color;

  const FarmFeature({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.prompt,
    required this.color,
  });
}

const farmFeatures = [
  FarmFeature(
    title: 'Crop advice',
    subtitle: 'Best crop for your soil',
    image: 'assets/images/feature_crops.png',
    prompt: 'Recommend crops for my farm',
    color: Color(0xFF176B4D),
  ),
  FarmFeature(
    title: 'Leaf diagnosis',
    subtitle: 'Scan plant photos',
    image: 'assets/images/feature_disease.png',
    prompt: 'How to manage yellow leaf disease?',
    color: Color(0xFFD9763A),
  ),
  FarmFeature(
    title: 'Mandi prices',
    subtitle: 'Today’s market bhav',
    image: 'assets/images/feature_mandi.png',
    prompt: 'Check mandi price of wheat',
    color: Color(0xFFE8A317),
  ),
  FarmFeature(
    title: 'Govt schemes',
    subtitle: 'Subsidies & yojana',
    image: 'assets/images/feature_schemes.png',
    prompt: 'Government subsidies for drip irrigation',
    color: Color(0xFF1A9B8E),
  ),
  FarmFeature(
    title: 'Voice helper',
    subtitle: 'Talk in your language',
    image: 'assets/images/feature_voice.png',
    prompt: 'Help me with farm advisory in simple words',
    color: Color(0xFF2F8FDB),
  ),
  FarmFeature(
    title: 'Farm care',
    subtitle: 'Water, soil & pests',
    image: 'assets/images/feature_advisory.png',
    prompt: 'How to improve soil fertility?',
    color: Color(0xFF2D9A6A),
  ),
];

class FeatureShowcase extends StatelessWidget {
  final String farmerName;
  final ValueChanged<String> onFeatureSelected;

  const FeatureShowcase({
    super.key,
    required this.farmerName,
    required this.onFeatureSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
        children: [
          Text(
            'Namaste${farmerName.isEmpty ? '' : ', $farmerName'}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your farm companion is ready. Tap a feature or type below.',
            style: TextStyle(
              fontSize: 14.5,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: farmFeatures.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final feature = farmFeatures[index];
              return _FeatureCard(
                feature: feature,
                delayMs: 70 * index,
                onTap: () => onFeatureSelected(feature.prompt),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final FarmFeature feature;
  final VoidCallback onTap;
  final int delayMs;

  const _FeatureCard({
    required this.feature,
    required this.onTap,
    required this.delayMs,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: feature.color.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: feature.color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(feature.image, fit: BoxFit.cover),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    feature.color.withValues(alpha: 0.18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      feature.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: feature.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
