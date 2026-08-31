import 'package:flutter/material.dart';

class AssistantAvatar extends StatelessWidget {
  final double size;

  const AssistantAvatar({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .045),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF103E31),
        border: Border.all(color: const Color(0xFF78D8B1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF176B4D).withValues(alpha: .22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/sasyam_assistant.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.eco_rounded, color: Color(0xFF8FE2B0)),
        ),
      ),
    );
  }
}
