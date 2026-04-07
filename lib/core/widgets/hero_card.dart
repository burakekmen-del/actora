import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}
