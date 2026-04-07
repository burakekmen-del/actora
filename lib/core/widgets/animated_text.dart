import 'package:flutter/material.dart';

class AnimatedText extends StatelessWidget {
  const AnimatedText({
    super.key,
    required this.text,
    required this.visible,
    this.style,
    this.duration = const Duration(milliseconds: 260),
    this.offset = const Offset(0, 10),
    this.textAlign = TextAlign.center,
  });

  final String text;
  final bool visible;
  final TextStyle? style;
  final Duration duration;
  final Offset offset;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : offset,
        duration: duration,
        curve: Curves.easeOut,
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
        ),
      ),
    );
  }
}
