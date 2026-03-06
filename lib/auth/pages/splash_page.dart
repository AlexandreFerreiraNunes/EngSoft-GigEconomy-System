import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/auth_storage.dart';
import '../../shell/pages/shell_page.dart';
import 'welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  bool? _isLoggedIn;
  bool _animationDone = false;

  @override
  void initState() {
    super.initState();

    // Animation: fade-in (0→1) then fade-out (1→0), total 2.4s
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _opacity = TweenSequence<double>([
      // 0–40%: fade in (0 → 1)
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      // 40–65%: hold at 1
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 25,
      ),
      // 65–100%: fade out (1 → 0)
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_ctrl);

    _scale = TweenSequence<double>([
      // 0–40%: scale up from 0.7 to 1.0
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      // 40–65%: hold at 1
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 25,
      ),
      // 65–100%: scale down slightly
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationDone = true;
        _tryNavigate();
      }
    });

    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await AuthStorage.isLoggedIn();
    _isLoggedIn = loggedIn;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!_animationDone || _isLoggedIn == null || !mounted) return;

    final destination = _isLoggedIn!
        ? const ShellPage()
        : const WelcomePage();

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimary, kPrimaryDark],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              'assets/logo_gig.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
