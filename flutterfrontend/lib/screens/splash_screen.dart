import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/farm_backdrop.dart';
import 'auth/login_screen.dart';
import 'chat/chat_screen.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.init();

    if (!mounted) return;

    if (auth.isAuthenticated) {
      if (auth.isOnboarded) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FarmBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 40, fontSize: 22, light: true),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x2215D9C1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x884FE1CF)),
                  ),
                  child: const Text(
                    'FARM INTELLIGENCE, SIMPLIFIED',
                    style: TextStyle(
                      color: Color(0xFFB9F4E9),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Grow smarter.\nEvery season.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.03,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Personal crop guidance, disease support, and market insights for your farm.',
                  style: TextStyle(
                    color: Color(0xFFD5E6DE),
                    height: 1.45,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 38),
                const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF61DEC5),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Preparing your farm workspace',
                      style: TextStyle(color: Color(0xFFD5E6DE), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
