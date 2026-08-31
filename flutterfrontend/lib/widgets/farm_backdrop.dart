import 'package:flutter/material.dart';

/// Cinematic farming backdrop used on the entry screens.
class FarmBackdrop extends StatelessWidget {
  final Widget child;

  const FarmBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/farm_hero.png', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB8123E31), Color(0x8F103E31), Color(0xDE08251D)],
              stops: [0, .46, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
