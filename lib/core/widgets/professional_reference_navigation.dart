import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import '../theme/professional_reference_theme.dart';

class ProfessionalReferenceNavigation extends StatelessWidget {
  const ProfessionalReferenceNavigation({
    super.key,
    required this.onTap,
    this.index = 1,
    this.labels,
    this.readable = false,
  });
  final ValueChanged<int> onTap;
  final int index;
  final List<String>? labels;
  final bool readable;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final tabLabels =
            labels ??
            [
              context.l10n.tabHome,
              context.l10n.referenceProfessionalsTitle,
              context.l10n.referenceMyProjects,
              context.l10n.tabCommunity,
              context.l10n.tabProfile,
            ];
        final scaler = MediaQuery.textScalerOf(context);
        final equalSlotWidth = constraints.maxWidth / 5 - 8;
        final compact =
            readable &&
            tabLabels.any((label) {
              final painter = TextPainter(
                text: TextSpan(
                  text: label,
                  style: ProfessionalReferenceTheme.text(
                    14,
                    weight: FontWeight.w700,
                  ),
                ),
                textDirection: Directionality.of(context),
                textScaler: scaler,
                locale: Localizations.localeOf(context),
              )..layout();
              final fits = painter.width <= equalSlotWidth;
              painter.dispose();
              return !fits;
            });
        final minimumWidth = compact ? 288.0 : 240.0;
        final barWidth = constraints.maxWidth < minimumWidth
            ? minimumWidth
            : constraints.maxWidth;
        final bar = Container(
          width: barWidth,
          height:
              (readable ? 74.0 : 53.0) *
              scaler.scale(1).clamp(1.0, double.infinity),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xffe6e6e8), width: .6),
            ),
          ),
          child: Row(
            children: List.generate(5, (i) {
              final selected = i == index;
              return Expanded(
                flex: compact && selected ? 2 : 1,
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: tabLabels[i],
                  excludeSemantics: true,
                  onTap: () => onTap(i),
                  child: Tooltip(
                    message: tabLabels[i],
                    excludeFromSemantics: true,
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 23,
                            height: 23,
                            child: CustomPaint(
                              painter: _ReferenceNavPainter(
                                i,
                                selected
                                    ? ProfessionalReferenceTheme.orange
                                    : const Color(0xff76767c),
                              ),
                            ),
                          ),
                          if (!compact || selected) ...[
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                tabLabels[i],
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: ProfessionalReferenceTheme.text(
                                  readable ? 14 : 10,
                                  color: selected
                                      ? (readable
                                            ? ProfessionalReferenceTheme.action
                                            : ProfessionalReferenceTheme.orange)
                                      : const Color(0xff343438),
                                  weight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Container(
                            width: 3.5,
                            height: 3.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? ProfessionalReferenceTheme.orange
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
        if (barWidth > constraints.maxWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: bar,
          );
        }
        return bar;
      },
    ),
  );
}

/// Simple reference silhouettes are real vector controls, not screenshot cuts.
class _ReferenceNavPainter extends CustomPainter {
  const _ReferenceNavPainter(this.index, this.color);
  final int index;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final line = Paint()
      ..color = color
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    switch (index) {
      case 0:
        canvas.drawPath(
          Path()
            ..moveTo(3, 10)
            ..lineTo(12, 2)
            ..lineTo(21, 10)
            ..lineTo(21, 22)
            ..lineTo(15, 22)
            ..lineTo(15, 15)
            ..lineTo(9, 15)
            ..lineTo(9, 22)
            ..lineTo(3, 22)
            ..close(),
          line,
        );
      case 1:
        canvas.drawPath(
          Path()
            ..moveTo(6, 8)
            ..quadraticBezierTo(6, 3, 11, 2)
            ..lineTo(11, 7)
            ..lineTo(13, 7)
            ..lineTo(13, 2)
            ..quadraticBezierTo(18, 3, 18, 8)
            ..close(),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 8, 16, 2),
            const Radius.circular(1),
          ),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 11)
            ..quadraticBezierTo(8, 16, 12, 16)
            ..quadraticBezierTo(16, 16, 16, 11)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(2, 23)
            ..lineTo(3, 19)
            ..quadraticBezierTo(4, 17, 8, 16)
            ..lineTo(12, 19)
            ..lineTo(16, 16)
            ..quadraticBezierTo(20, 17, 21, 19)
            ..lineTo(22, 23)
            ..close(),
          fill,
        );
        canvas.drawLine(
          const Offset(7, 20),
          const Offset(17, 20),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.1,
        );
      case 2:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 3, 14, 20),
            const Radius.circular(2),
          ),
          line,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(9, 1, 6, 4),
            const Radius.circular(1.5),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(9, 1, 6, 4),
            const Radius.circular(1.5),
          ),
          line,
        );
        for (final y in [10.0, 14.0, 18.0]) {
          canvas.drawLine(Offset(8, y), Offset(16, y), line);
        }
      case 3:
        canvas.drawOval(const Rect.fromLTWH(4, 2, 7, 8), line);
        canvas.drawOval(const Rect.fromLTWH(14, 2, 7, 8), line);
        canvas.drawPath(
          Path()
            ..moveTo(1, 22)
            ..lineTo(1, 19)
            ..quadraticBezierTo(1, 13, 7, 12)
            ..quadraticBezierTo(13, 12, 13, 19)
            ..lineTo(13, 22)
            ..close(),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(13, 22)
            ..lineTo(23, 22)
            ..lineTo(23, 19)
            ..quadraticBezierTo(23, 13, 17, 12)
            ..quadraticBezierTo(14, 12, 12, 14),
          line,
        );
      case 4:
        canvas.drawCircle(const Offset(12, 12), 10.5, line);
        canvas.drawOval(const Rect.fromLTWH(8, 5, 8, 9), line);
        canvas.drawPath(
          Path()
            ..moveTo(5, 20)
            ..quadraticBezierTo(5, 14, 12, 14)
            ..quadraticBezierTo(19, 14, 19, 20),
          line,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ReferenceNavPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.color != color;
}
