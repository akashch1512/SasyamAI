import 'package:flutter/material.dart';

import '../config/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;
  final bool light;

  const AppLogo({
    super.key,
    this.size = 36.0,
    this.showText = true,
    this.fontSize = 20.0,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.paleGreen,
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(
              color: AppTheme.accentGreen.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.eco_rounded,
                  color: AppTheme.primaryGreen,
                  size: size * 0.65,
                );
              },
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Sasyam',
                  style: TextStyle(
                    color: light ? Colors.white : AppTheme.textDark,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
