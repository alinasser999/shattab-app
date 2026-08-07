import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ShattabPatternKind { lattice, terrazzo, arches, contour }

/// Small, scalable identity marks for quiet product surfaces and empty
/// states. They are intentionally drawn in code so they stay sharp in RTL,
/// dark mode, and at every device width.
class ShattabPattern extends StatelessWidget {
  const ShattabPattern({
    super.key,
    required this.kind,
    required this.color,
    this.opacity = 1,
    this.strokeWidth = 1,
  });

  final ShattabPatternKind kind;
  final Color color;
  final double opacity;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShattabPatternPainter(
        kind: kind,
        color: color.withValues(alpha: opacity),
        strokeWidth: strokeWidth,
      ),
    );
  }
}

enum ShattabMotif { arch, tile, compass, finish }

class ShattabMotifIcon extends StatelessWidget {
  const ShattabMotifIcon({
    super.key,
    required this.motif,
    required this.color,
    this.size = 24,
  });

  final ShattabMotif motif;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ShattabMotifPainter(motif: motif, color: color),
    );
  }
}

class _ShattabPatternPainter extends CustomPainter {
  _ShattabPatternPainter({
    required this.kind,
    required this.color,
    required this.strokeWidth,
  });

  final ShattabPatternKind kind;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (kind) {
      case ShattabPatternKind.lattice:
        _paintLattice(canvas, size, line);
      case ShattabPatternKind.terrazzo:
        _paintTerrazzo(canvas, size, line, fill);
      case ShattabPatternKind.arches:
        _paintArches(canvas, size, line);
      case ShattabPatternKind.contour:
        _paintContour(canvas, size, line);
    }
    canvas.restore();
  }

  void _paintLattice(Canvas canvas, Size size, Paint paint) {
    const step = 28.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(x + size.height, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _paintTerrazzo(Canvas canvas, Size size, Paint line, Paint fill) {
    const seeds = <Offset>[
      Offset(0.12, 0.2),
      Offset(0.38, 0.14),
      Offset(0.67, 0.28),
      Offset(0.84, 0.1),
      Offset(0.22, 0.63),
      Offset(0.51, 0.78),
      Offset(0.78, 0.62),
      Offset(0.94, 0.86),
      Offset(0.07, 0.9),
    ];
    for (var i = 0; i < seeds.length; i++) {
      final point = Offset(seeds[i].dx * size.width, seeds[i].dy * size.height);
      final radius = 2.5 + (i % 3) * 1.8;
      if (i.isEven) {
        canvas.drawCircle(point, radius, fill);
      } else {
        final path = Path()
          ..moveTo(point.dx - radius, point.dy + radius * 0.35)
          ..lineTo(point.dx - radius * 0.25, point.dy - radius)
          ..lineTo(point.dx + radius, point.dy - radius * 0.2)
          ..lineTo(point.dx + radius * 0.3, point.dy + radius)
          ..close();
        canvas.drawPath(path, line);
      }
    }
  }

  void _paintArches(Canvas canvas, Size size, Paint paint) {
    const step = 58.0;
    for (var x = -step; x < size.width + step; x += step) {
      final rect = Rect.fromLTWH(x, size.height * 0.2, 32, size.height * 0.62);
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
      canvas.drawLine(
        Offset(x, rect.top + rect.height * 0.42),
        Offset(x, rect.bottom),
        paint,
      );
      canvas.drawLine(
        Offset(x + rect.width, rect.top + rect.height * 0.42),
        Offset(x + rect.width, rect.bottom),
        paint,
      );
      canvas.drawLine(
        Offset(x + rect.width + 7, rect.bottom),
        Offset(x + rect.width + 7, rect.bottom - 18),
        paint,
      );
    }
  }

  void _paintContour(Canvas canvas, Size size, Paint paint) {
    for (var row = -1; row < 8; row++) {
      final path = Path()..moveTo(-8, row * 22.0);
      for (var x = 0.0; x <= size.width + 16; x += 16) {
        final y = row * 22.0 + math.sin((x / 38) + row * 0.8) * 7;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ShattabPatternPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _ShattabMotifPainter extends CustomPainter {
  _ShattabMotifPainter({required this.motif, required this.color});

  final ShattabMotif motif;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = size.center(Offset.zero);
    final unit = size.shortestSide;

    switch (motif) {
      case ShattabMotif.arch:
        final rect = Rect.fromLTWH(
          unit * 0.18,
          unit * 0.18,
          unit * 0.64,
          unit * 0.66,
        );
        canvas.drawArc(rect, math.pi, math.pi, false, stroke);
        canvas.drawLine(
          Offset(rect.left, rect.top + rect.height * 0.42),
          Offset(rect.left, rect.bottom),
          stroke,
        );
        canvas.drawLine(
          Offset(rect.right, rect.top + rect.height * 0.42),
          Offset(rect.right, rect.bottom),
          stroke,
        );
      case ShattabMotif.tile:
        final path = Path()
          ..moveTo(center.dx, unit * 0.08)
          ..lineTo(unit * 0.92, center.dy)
          ..lineTo(center.dx, unit * 0.92)
          ..lineTo(unit * 0.08, center.dy)
          ..close();
        canvas.drawPath(path, stroke);
        canvas.drawLine(
          Offset(unit * 0.28, unit * 0.28),
          Offset(unit * 0.72, unit * 0.72),
          stroke,
        );
        canvas.drawLine(
          Offset(unit * 0.72, unit * 0.28),
          Offset(unit * 0.28, unit * 0.72),
          stroke,
        );
      case ShattabMotif.compass:
        canvas.drawCircle(center, unit * 0.34, stroke);
        canvas.drawCircle(center, unit * 0.1, fill);
        for (var i = 0; i < 4; i++) {
          final angle = i * math.pi / 2;
          canvas.drawLine(
            center + Offset(math.cos(angle), math.sin(angle)) * unit * 0.43,
            center + Offset(math.cos(angle), math.sin(angle)) * unit * 0.56,
            stroke,
          );
        }
      case ShattabMotif.finish:
        final path = Path()
          ..moveTo(unit * 0.08, unit * 0.68)
          ..lineTo(unit * 0.33, unit * 0.43)
          ..lineTo(unit * 0.52, unit * 0.58)
          ..lineTo(unit * 0.9, unit * 0.2);
        canvas.drawPath(path, stroke);
        canvas.drawCircle(Offset(unit * 0.9, unit * 0.2), unit * 0.07, fill);
    }
  }

  @override
  bool shouldRepaint(_ShattabMotifPainter oldDelegate) =>
      oldDelegate.motif != motif || oldDelegate.color != color;
}
