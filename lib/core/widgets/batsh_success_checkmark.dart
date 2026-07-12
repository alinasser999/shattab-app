import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_motion.dart';

class BatshSuccessCheckmark extends StatefulWidget {
  const BatshSuccessCheckmark({
    super.key,
    this.size = 80,
    this.message,
  });

  final double size;
  final String? message;

  @override
  State<BatshSuccessCheckmark> createState() => _BatshSuccessCheckmarkState();
}

class _BatshSuccessCheckmarkState extends State<BatshSuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: BatshMotion.slower,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
  ));

  late final Animation<double> _check = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
  ));

  @override
  void initState() {
    super.initState();
    if (!MediaQuery.of(context).disableAnimations) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: BatshColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: CustomPaint(
                painter: _CheckPainter(
                  progress: _check.value,
                  color: BatshColors.success,
                  strokeWidth: 4,
                ),
              ),
            ),
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BatshColors.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final start = Offset(size.width * 0.25, size.height * 0.5);
    final mid = Offset(size.width * 0.45, size.height * 0.68);
    final end = Offset(size.width * 0.75, size.height * 0.32);

    path.moveTo(start.dx, start.dy);
    path.lineTo(mid.dx, mid.dy);
    path.lineTo(end.dx, end.dy);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extract = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
