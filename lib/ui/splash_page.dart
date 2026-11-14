import 'dart:async';

import 'package:flutter/material.dart';

import 'home_page.dart';

/// Windows desktop splash screen for MealMate.
/// Automatically opens Guest Home after a short welcome display.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const Color _cream = Color(0xFFFFF8EF);
  static const Color _darkGreen = Color(0xFF06462A);
  static const Color _orange = Color(0xFFFF7900);

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final isMobile = width < 600;

          final contentWidth = isMobile
              ? (width * 0.88).clamp(0.0, 420.0).toDouble()
              : (width * 0.65).clamp(0.0, 800.0).toDouble();

          final logoSize = isMobile ? 105.0 : 145.0;
          final titleSize = isMobile ? 49.0 : 73.0;
          final taglineSize = isMobile ? 19.0 : 29.0;
          final bowlWidth = isMobile ? 310.0 : 485.0;
          final bowlHeight = isMobile ? 220.0 : 305.0;
          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Soft abstract background, drawn as vectors.
                Positioned(
                  right: -width * 0.08,
                  top: -height * 0.30,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      width: width * 0.38,
                      height: height * 0.37,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD5F0A4),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(500, 260),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -width * 0.10,
                  bottom: -height * 0.20,
                  child: Container(
                    width: width * 0.75,
                    height: height * 0.43,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4F5B9),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(900, 350),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -width * 0.18,
                  bottom: -height * 0.22,
                  child: Container(
                    width: width * 0.85,
                    height: height * 0.42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFBDEB6E),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(900, 350),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -width * 0.12,
                  bottom: -height * 0.26,
                  child: Container(
                    width: width * 0.72,
                    height: height * 0.33,
                    decoration: const BoxDecoration(
                      color: Color(0xFF99D83C),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(900, 350),
                      ),
                    ),
                  ),
                ),

                // Centered splash content using the two separate image assets.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/img/logo.png',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),

                            SizedBox(height: isMobile ? 8 : 12),

                            Text.rich(
                              const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Meal',
                                    style: TextStyle(color: _darkGreen),
                                  ),
                                  TextSpan(
                                    text: 'Mate',
                                    style: TextStyle(color: _orange),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: isMobile ? -1 : -2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),

                            Text(
                              'Plan · Eat · Save',
                              style: TextStyle(
                                fontSize: taglineSize,
                                fontWeight: FontWeight.w500,
                                color: _darkGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: isMobile ? 12 : 18),

                            Image.asset(
                              'assets/img/bowl.png',
                              width: bowlWidth,
                              height: bowlHeight,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
