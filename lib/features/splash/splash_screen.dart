import 'dart:async';

import 'package:flutter/material.dart';

import 'splash_scene.dart';

/// Kirish (splash) darvozasi: ishga tushganda «Bilimdon» brend sahnasini
/// (SplashScene) ~2.2s ko'rsatadi, so'ng [child] ga yumshoq o'tadi. Nuqtalar
/// pulsi jonli. Manba dizayn: Matematika Oyini.dc.html «Splash — kirish oynasi».
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _done
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : Material(
              key: const ValueKey('splash'),
              child: AnimatedBuilder(
                animation: _dots,
                builder: (context, _) => SizedBox.expand(
                  child: SplashScene(dotPhase: _dots.value),
                ),
              ),
            ),
    );
  }
}
