import 'dart:ui';

import 'package:flutter/material.dart';

class ImpactOverlay extends StatelessWidget {
  const ImpactOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.seconds = 0,
    this.label = 'Focus',
  });

  final bool visible;
  final Widget child;
  final int seconds;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: visible ? 1.015 : 1,
      curve: Curves.easeOut,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: visible ? 1 : 0,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      '$label ${_format(seconds)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
