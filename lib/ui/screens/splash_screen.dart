import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _showButton = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    // Show "Get Started" after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F4C81);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    maxHeight: 300,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_logo.jpg',
                      // Removed explicit width/height to let aspect ratio govern
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                Text(
                  'Find your next home, hassle-free',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: primaryColor, // Adjusted to match brand
                  ),
                ),
                const SizedBox(height: 48),
                // Loading Animation (Bouncing Dots simulated)
                if (!_showButton)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return FadeTransition(
                        opacity: Tween(begin: 0.2, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Interval(
                              index * 0.2,
                              1.0,
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: primaryColor, // Changed to primaryColor
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),

          // Get Started Button
          if (_showButton)
            Positioned(
              bottom: 48,
              left: 24,
              right: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: 1.0,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/welcome');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, // Primary Background
                    foregroundColor: Colors.white, // White Text
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                  ),
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Version
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Text(
              'Version 1.0.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: primaryColor.withValues(alpha: 0.5),
              ), // Darker text
            ),
          ),
        ],
      ),
    );
  }
}
