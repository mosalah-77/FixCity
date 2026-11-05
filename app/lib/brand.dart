import 'package:flutter/material.dart';
import 'theme.dart';

class FixCityMark extends StatelessWidget {
  final double size;
  const FixCityMark({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: const _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 48, 48),
        const Radius.circular(12),
      ),
      Paint()..color = kDark,
    );
    final pin = Path()
      ..moveTo(24, 8)
      ..cubicTo(15, 8, 11, 14, 11, 21)
      ..cubicTo(11, 29, 24, 40, 24, 40)
      ..cubicTo(24, 40, 37, 29, 37, 21)
      ..cubicTo(37, 14, 33, 8, 24, 8)
      ..close();
    canvas.drawPath(pin, Paint()..color = kAccent);
    final road = Path()
      ..moveTo(21, 15)
      ..lineTo(27, 15)
      ..lineTo(27, 20)
      ..lineTo(31, 20)
      ..lineTo(31, 25)
      ..lineTo(27, 25)
      ..lineTo(27, 31)
      ..lineTo(21, 31)
      ..close();
    canvas.drawPath(road, Paint()..color = kDark);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) => false;
}

class FixCityWordmark extends StatelessWidget {
  final bool light;
  const FixCityWordmark({super.key, this.light = false});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'FixCity',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FixCityMark(),
        const SizedBox(width: 12),
        Text(
          'FixCity',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: light
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );
}
