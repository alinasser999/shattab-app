import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/connectivity.dart';
import '../l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import '../theme/professional_reference_theme.dart';
import 'professional_reference_primitives.dart';

enum ProfessionalReferenceStateKind { empty, noResults, access, error, offline }

enum ProfessionalReferenceMotif {
  house,
  quotes,
  saved,
  savedLocked,
  search,
  people,
  portfolio,
  publicPortfolio,
  reviews,
  notifications,
  community,
  error,
  offline,
  identity,
  services,
  location,
}

class ProfessionalReferenceStateIllustration extends StatelessWidget {
  const ProfessionalReferenceStateIllustration({
    super.key,
    required this.motif,
    this.size = 136,
  });
  final ProfessionalReferenceMotif motif;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _StatePainter(motif)),
    ),
  );
}

class ProfessionalReferenceState extends StatelessWidget {
  const ProfessionalReferenceState({
    super.key,
    required this.title,
    required this.message,
    required this.motif,
    this.kind = ProfessionalReferenceStateKind.empty,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
  });
  final String title, message;
  final ProfessionalReferenceMotif motif;
  final ProfessionalReferenceStateKind kind;
  final String? primaryLabel, secondaryLabel;
  final VoidCallback? onPrimary, onSecondary;
  final bool compact;
  @override
  Widget build(BuildContext context) => Theme(
    data: ProfessionalReferenceTheme.scopedTheme(Theme.of(context)),
    child: ColoredBox(
      color: ProfessionalReferenceTheme.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: compact ? 16 : 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ProfessionalReferenceStateIllustration(
                    motif: motif,
                    size: compact ? 92 : 136,
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  liveRegion:
                      kind == ProfessionalReferenceStateKind.error ||
                      kind == ProfessionalReferenceStateKind.offline,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: ProfessionalReferenceTheme.text(
                      24,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: ProfessionalReferenceTheme.text(
                    16,
                    color: ProfessionalReferenceTheme.muted,
                  ),
                ),
                if (primaryLabel != null && onPrimary != null) ...[
                  const SizedBox(height: 24),
                  ProfessionalReferencePrimaryButton(
                    label: primaryLabel!,
                    onPressed: onPrimary,
                  ),
                ],
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: onSecondary,
                    child: Text(
                      secondaryLabel!,
                      textAlign: TextAlign.center,
                      style: ProfessionalReferenceTheme.text(
                        16,
                        color: ProfessionalReferenceTheme.action,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
          return constraints.hasBoundedHeight
              ? SingleChildScrollView(child: content)
              : content;
        },
      ),
    ),
  );
}

class ProfessionalReferenceWelcome extends StatelessWidget {
  const ProfessionalReferenceWelcome({
    super.key,
    required this.title,
    required this.message,
    required this.motif,
  });
  final String title, message;
  final ProfessionalReferenceMotif motif;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: ProfessionalReferenceStateIllustration(motif: motif, size: 112),
      ),
      const SizedBox(height: 16),
      Semantics(
        header: true,
        child: Text(
          title,
          style: ProfessionalReferenceTheme.text(24, weight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        message,
        style: ProfessionalReferenceTheme.text(
          16,
          color: ProfessionalReferenceTheme.muted,
        ),
      ),
      const SizedBox(height: 24),
    ],
  );
}

class ProfessionalReferenceInlineStatus extends StatelessWidget {
  const ProfessionalReferenceInlineStatus({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });
  final String message;
  final String? retryLabel, secondaryLabel;
  final VoidCallback? onRetry, onSecondary;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfessionalReferenceTheme.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe7e5e0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: ProfessionalReferenceTheme.navy,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: ProfessionalReferenceTheme.text(16),
                ),
              ),
            ],
          ),
          if (retryLabel != null && onRetry != null)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onRetry,
              child: Text(
                retryLabel!,
                style: ProfessionalReferenceTheme.text(
                  16,
                  color: ProfessionalReferenceTheme.action,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          if (secondaryLabel != null && onSecondary != null)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onSecondary,
              child: Text(
                secondaryLabel!,
                style: ProfessionalReferenceTheme.text(
                  16,
                  color: ProfessionalReferenceTheme.action,
                  weight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _StatePainter extends CustomPainter {
  const _StatePainter(this.motif);
  final ProfessionalReferenceMotif motif;

  static const _wash = Color(0xffffedde);
  static const _botanical = Color(0xff9aabc1);
  static const _leafFill = Color(0xffdce3ed);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 136, size.height / 136);
    canvas.drawCircle(const Offset(68, 68), 64, Paint()..color = _wash);
    _drawBotanicalSprigs(canvas);
    final ink = Paint()
      ..color = ProfessionalReferenceTheme.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accent = Paint()
      ..color = ProfessionalReferenceTheme.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    if (motif == ProfessionalReferenceMotif.location) {
      canvas.drawRect(const Rect.fromLTWH(28, 57, 24, 47), ink);
      canvas.drawRect(const Rect.fromLTWH(59, 35, 30, 69), ink);
      canvas.drawRect(const Rect.fromLTWH(95, 68, 15, 36), ink);
      for (final y in [47.0, 62.0, 77.0]) {
        canvas.drawLine(Offset(68, y), Offset(80, y), accent);
      }
      canvas.drawLine(const Offset(35, 70), const Offset(45, 70), ink);
    } else if (motif == ProfessionalReferenceMotif.house) {
      canvas.drawRect(const Rect.fromLTWH(43, 39, 10, 23), ink);
      canvas.drawPath(
        Path()
          ..moveTo(28, 66)
          ..lineTo(68, 31)
          ..lineTo(108, 66),
        accent,
      );
      canvas.drawPath(
        Path()
          ..moveTo(37, 62)
          ..lineTo(37, 103)
          ..lineTo(99, 103)
          ..lineTo(99, 62)
          ..close(),
        ink,
      );
      canvas.drawRect(const Rect.fromLTWH(59, 77, 18, 26), accent);
      canvas.drawRect(const Rect.fromLTWH(43, 72, 9, 12), ink);
      canvas.drawRect(const Rect.fromLTWH(84, 72, 9, 12), ink);
    } else if (motif == ProfessionalReferenceMotif.saved ||
        motif == ProfessionalReferenceMotif.savedLocked) {
      canvas.drawPath(
        Path()
          ..moveTo(68, 101)
          ..lineTo(36, 72)
          ..cubicTo(12, 46, 43, 26, 68, 48)
          ..cubicTo(93, 26, 124, 46, 100, 72)
          ..close(),
        ink,
      );
      if (motif == ProfessionalReferenceMotif.savedLocked) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(55, 64, 26, 25),
            const Radius.circular(4),
          ),
          Paint()..color = _wash,
        );
        canvas.drawArc(
          const Rect.fromLTWH(60, 55, 16, 20),
          3.14,
          3.14,
          false,
          ink,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(55, 64, 26, 25),
            const Radius.circular(4),
          ),
          accent,
        );
        canvas.drawCircle(const Offset(68, 75), 2, ink);
        canvas.drawLine(const Offset(68, 77), const Offset(68, 82), ink);
      }
    } else if (motif == ProfessionalReferenceMotif.search) {
      canvas.drawCircle(const Offset(61, 58), 27, ink);
      canvas.drawLine(const Offset(81, 79), const Offset(104, 102), accent);
      canvas.drawPath(
        Path()
          ..moveTo(49, 60)
          ..lineTo(61, 50)
          ..lineTo(73, 60),
        accent,
      );
      canvas.drawPath(
        Path()
          ..moveTo(52, 59)
          ..lineTo(52, 69)
          ..lineTo(70, 69)
          ..lineTo(70, 59),
        ink,
      );
      canvas.drawRect(const Rect.fromLTWH(59, 62, 5, 7), ink);
    } else if (motif == ProfessionalReferenceMotif.people) {
      canvas.drawCircle(const Offset(68, 47), 10, ink);
      canvas.drawCircle(const Offset(43, 59), 8, accent);
      canvas.drawCircle(const Offset(93, 59), 8, accent);
      canvas.drawArc(
        const Rect.fromLTWH(48, 57, 40, 43),
        3.14,
        3.14,
        false,
        ink,
      );
      canvas.drawArc(
        const Rect.fromLTWH(25, 70, 37, 32),
        3.14,
        3.14,
        false,
        accent,
      );
      canvas.drawArc(
        const Rect.fromLTWH(74, 70, 37, 32),
        3.14,
        3.14,
        false,
        accent,
      );
    } else if (motif == ProfessionalReferenceMotif.notifications) {
      canvas.drawPath(
        Path()
          ..moveTo(43, 87)
          ..lineTo(47, 58)
          ..quadraticBezierTo(68, 24, 89, 58)
          ..lineTo(93, 87)
          ..close(),
        ink,
      );
      canvas.drawArc(
        const Rect.fromLTWH(58, 84, 20, 20),
        0,
        3.14,
        false,
        accent,
      );
    } else if (motif == ProfessionalReferenceMotif.offline) {
      canvas.drawArc(const Rect.fromLTWH(27, 42, 82, 65), 3.5, 2.4, false, ink);
      canvas.drawArc(const Rect.fromLTWH(45, 61, 46, 40), 3.5, 2.4, false, ink);
      canvas.drawCircle(const Offset(68, 93), 3, ink);
      canvas.drawLine(const Offset(34, 34), const Offset(105, 105), accent);
    } else if (motif == ProfessionalReferenceMotif.quotes) {
      canvas.drawPath(
        Path()
          ..moveTo(42, 30)
          ..lineTo(83, 30)
          ..lineTo(99, 46)
          ..lineTo(99, 103)
          ..lineTo(42, 103)
          ..close(),
        ink,
      );
      canvas.drawLine(const Offset(55, 51), const Offset(77, 51), ink);
      canvas.drawLine(const Offset(55, 65), const Offset(83, 65), ink);
      canvas.drawCircle(
        const Offset(91, 89),
        14,
        Paint()..color = ProfessionalReferenceTheme.orange,
      );
      final plus = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(84, 89), const Offset(98, 89), plus);
      canvas.drawLine(const Offset(91, 82), const Offset(91, 96), plus);
    } else if (motif == ProfessionalReferenceMotif.error) {
      canvas.drawPath(
        Path()
          ..moveTo(42, 30)
          ..lineTo(83, 30)
          ..lineTo(99, 46)
          ..lineTo(99, 103)
          ..lineTo(42, 103)
          ..close(),
        ink,
      );
      canvas.drawLine(const Offset(55, 51), const Offset(77, 51), ink);
      canvas.drawLine(const Offset(55, 65), const Offset(83, 65), ink);
      canvas.drawPath(
        Path()
          ..moveTo(37, 73)
          ..lineTo(55, 81)
          ..lineTo(67, 73)
          ..lineTo(80, 81)
          ..lineTo(103, 73),
        accent,
      );
    } else if (motif == ProfessionalReferenceMotif.reviews) {
      for (final x in [33.0, 68.0, 103.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 47)
            ..lineTo(x + 5, 60)
            ..lineTo(x + 19, 61)
            ..lineTo(x + 8, 70)
            ..lineTo(x + 12, 84)
            ..lineTo(x, 76)
            ..lineTo(x - 12, 84)
            ..lineTo(x - 8, 70)
            ..lineTo(x - 19, 61)
            ..lineTo(x - 5, 60)
            ..close(),
          x == 68 ? accent : ink,
        );
      }
    } else if (motif == ProfessionalReferenceMotif.community) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(28, 29, 80, 77),
          const Radius.circular(8),
        ),
        ink,
      );
      canvas.drawRect(const Rect.fromLTWH(39, 42, 25, 20), accent);
      canvas.drawLine(const Offset(75, 44), const Offset(97, 44), ink);
      canvas.drawLine(const Offset(75, 56), const Offset(97, 56), ink);
      canvas.drawLine(const Offset(40, 78), const Offset(96, 78), ink);
      canvas.drawLine(const Offset(40, 91), const Offset(84, 91), ink);
    } else if (motif == ProfessionalReferenceMotif.identity) {
      canvas.drawRect(const Rect.fromLTWH(36, 44, 64, 62), ink);
      canvas.drawPath(
        Path()
          ..moveTo(30, 44)
          ..lineTo(68, 25)
          ..lineTo(106, 44),
        ink,
      );
      for (final y in [57.0, 72.0]) {
        for (final x in [48.0, 68.0, 88.0]) {
          canvas.drawRect(Rect.fromLTWH(x - 4, y - 4, 8, 8), ink);
        }
      }
      canvas.drawRect(const Rect.fromLTWH(60, 86, 16, 20), accent);
    } else if (motif == ProfessionalReferenceMotif.portfolio ||
        motif == ProfessionalReferenceMotif.publicPortfolio) {
      if (motif == ProfessionalReferenceMotif.publicPortfolio) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(40, 29, 66, 51),
            const Radius.circular(4),
          ),
          ink,
        );
        canvas.drawPath(
          Path()
            ..moveTo(47, 70)
            ..lineTo(63, 54)
            ..lineTo(75, 66)
            ..lineTo(89, 49)
            ..lineTo(99, 59),
          ink,
        );
        canvas.drawCircle(const Offset(55, 42), 4, accent);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(28, 42, 68, 51),
          const Radius.circular(4),
        ),
        ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(35, 83)
          ..lineTo(54, 64)
          ..lineTo(67, 78)
          ..lineTo(82, 60)
          ..lineTo(91, 70),
        ink,
      );
      canvas.drawCircle(const Offset(45, 56), 5, accent);
      if (motif == ProfessionalReferenceMotif.portfolio) {
        canvas.drawLine(const Offset(52, 34), const Offset(105, 34), ink);
        canvas.drawLine(const Offset(105, 34), const Offset(105, 82), ink);
        canvas.drawCircle(
          const Offset(97, 97),
          15,
          Paint()..color = ProfessionalReferenceTheme.orange,
        );
        final plus = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(89, 97), const Offset(105, 97), plus);
        canvas.drawLine(const Offset(97, 89), const Offset(97, 105), plus);
      }
    } else if (motif == ProfessionalReferenceMotif.services) {
      canvas.drawPath(
        Path()
          ..moveTo(42, 30)
          ..lineTo(58, 30)
          ..lineTo(58, 55)
          ..lineTo(50, 65)
          ..lineTo(50, 100)
          ..lineTo(42, 100)
          ..lineTo(42, 65)
          ..lineTo(34, 55)
          ..lineTo(34, 30),
        ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(77, 32)
          ..lineTo(97, 32)
          ..lineTo(105, 44)
          ..lineTo(87, 44)
          ..lineTo(87, 103)
          ..lineTo(77, 103)
          ..close(),
        accent,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 35, 76, 57),
          const Radius.circular(9),
        ),
        ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(47, 92)
          ..lineTo(47, 107)
          ..lineTo(64, 92),
        ink,
      );
      canvas.drawLine(const Offset(45, 53), const Offset(91, 53), accent);
      canvas.drawLine(const Offset(45, 68), const Offset(80, 68), ink);
    }
    canvas.drawLine(const Offset(23, 115), const Offset(113, 115), ink);
    canvas.drawCircle(const Offset(112, 29), 4, accent);
  }

  void _drawBotanicalSprigs(Canvas canvas) {
    final stemPaint = Paint()
      ..color = _botanical
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = _leafFill;
    final veinPaint = Paint()
      ..color = _botanical
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (final isLeft in [true, false]) {
      final x = isLeft ? 21.0 : 115.0;
      final direction = isLeft ? 1.0 : -1.0;
      canvas.drawPath(
        Path()
          ..moveTo(x, 108)
          ..cubicTo(
            x + direction * 7,
            87,
            x - direction * 2,
            64,
            x + direction * 5,
            43,
          ),
        stemPaint,
      );
      for (final y in [91.0, 74.0, 57.0]) {
        final leaf = Path()
          ..moveTo(x + direction * 2, y + 5)
          ..cubicTo(
            x + direction * 10,
            y + 9,
            x + direction * 20,
            y + 1,
            x + direction * 17,
            y - 8,
          )
          ..cubicTo(
            x + direction * 8,
            y - 8,
            x + direction * 1,
            y - 3,
            x + direction * 2,
            y + 5,
          )
          ..close();
        canvas.drawPath(leaf, leafPaint);
        canvas.drawPath(
          Path()
            ..moveTo(x + direction * 3, y + 4)
            ..quadraticBezierTo(
              x + direction * 9,
              y + 1,
              x + direction * 15,
              y - 6,
            ),
          veinPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StatePainter oldDelegate) =>
      oldDelegate.motif != motif;
}

/// Opted-in read failure presentation retaining the existing reconnect behavior.
class ProfessionalReferenceReadError extends ConsumerWidget {
  const ProfessionalReferenceReadError({
    super.key,
    this.message,
    this.onRetry,
    this.compact = false,
  });
  final String? message;
  final VoidCallback? onRetry;
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(connectivityProvider, (previous, next) {
      if (previous?.value == false && next.value == true) onRetry?.call();
    });
    final offline = ref.watch(connectivityProvider).value == false;
    return ProfessionalReferenceState(
      kind: offline
          ? ProfessionalReferenceStateKind.offline
          : ProfessionalReferenceStateKind.error,
      motif: offline
          ? ProfessionalReferenceMotif.offline
          : ProfessionalReferenceMotif.error,
      title: offline
          ? context.l10n.stateOfflineTitle
          : context.l10n.stateReadErrorTitle,
      message: offline
          ? context.l10n.errNetwork
          : message ?? context.l10n.unknownErrorRetry,
      primaryLabel: context.l10n.tryAgain,
      onPrimary: onRetry,
      compact: compact,
    );
  }
}
