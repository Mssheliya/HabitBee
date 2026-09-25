import 'package:flutter/material.dart';
import 'package:habit_bee/src/features/navigation/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loaderController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: Initializing animations');
    
    // Logo animation controller - faster
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Loading animation controller
    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loaderController,
        curve: Curves.linear,
      ),
    );

    _logoController.forward();

    _navigateToHome();
  }

  void _navigateToHome() async {
    if (_isNavigating || !mounted) return;

    setState(() {
      _isNavigating = true;
    });

    // Let the logo animation play out briefly before moving on.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    debugPrint('SplashScreen: Navigating to MainShell');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        settings: const RouteSettings(name: '/home'),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_logoController, _loaderController]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo – primaryContainer chip, primary accent
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RotationTransition(
                              turns: _rotateAnimation,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.4),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.check_circle,
                              size: 50,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          colorScheme.primary,
                          Color.lerp(
                              colorScheme.primary, colorScheme.tertiary, 0.5)!,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'HabitBee',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build Better Habits',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.primary.withValues(alpha: 0.75),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _rotateAnimation,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary.withValues(alpha: 0.3),
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _loaderController,
                            builder: (context, child) {
                              final pulseValue = (0.5 +
                                      0.5 *
                                          (1 +
                                              (_loaderController.value * 2 - 1)
                                                  .abs()))
                                  .clamp(0.5, 1.0);
                              return Container(
                                width: 12 * pulseValue,
                                height: 12 * pulseValue,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.5),
                                      blurRadius: 10 * pulseValue,
                                      spreadRadius: 2 * pulseValue,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
