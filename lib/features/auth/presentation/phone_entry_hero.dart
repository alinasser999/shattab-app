part of 'phone_entry_screen.dart';

class _BackgroundLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/login_bg.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
  }
}

/// Warm wash over the photo. Two jobs: a soft cream lift behind the headline so
/// legibility is owned by the layout (not borrowed from whatever crop the image
/// happens to show), and a stronger cream base that fuses the login card into
/// the scene instead of leaving it a white rectangle pasted on a photo.
class _ScrimLayer extends StatelessWidget {
  const _ScrimLayer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.16, 0.44, 0.66, 1.0],
          colors: [
            context.colorScheme.surface.withValues(alpha: 0.0),
            context.colorScheme.surface.withValues(alpha: 0.0),
            context.colorScheme.surface.withValues(alpha: 0.32),
            context.colorScheme.surface.withValues(alpha: 0.86),
            context.colorScheme.surface,
          ],
        ),
      ),
    );
  }
}

// ─── Logo & Tagline ──────────────────────────────────────────────────────────

class _LogoTagline extends StatelessWidget {
  const _LogoTagline({required this.disableMotion});
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/logo_wordmark.png',
      height: 88,
      fit: BoxFit.contain,
    );
    final tagline = Text(
      context.l10n.taglineNew,
      style: BatshTypography.labelMd.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );

    if (disableMotion) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          const SizedBox(height: BatshSpacing.sm),
          tagline,
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo settles in: soft fade + gentle scale-down, no bounce.
        logo
            .animate()
            .fadeIn(duration: 600.ms, curve: BatshMotion.easeOut)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 700.ms,
              curve: BatshMotion.heroEase,
            )
            .slideY(
              begin: -0.14,
              end: 0,
              duration: 700.ms,
              curve: BatshMotion.heroEase,
            ),
        const SizedBox(height: BatshSpacing.sm),
        tagline
            .animate()
            .fadeIn(duration: 500.ms, delay: 320.ms, curve: BatshMotion.easeOut)
            .slideY(
              begin: 0.6,
              end: 0,
              duration: 500.ms,
              delay: 320.ms,
              curve: BatshMotion.easeOut,
            ),
      ],
    );
  }
}

// ─── Hero Headline ───────────────────────────────────────────────────────────

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({required this.disableMotion});
  final bool disableMotion;

  // Word-reveal cadence.
  static const int _baseDelayMs = 420;
  static const int _stepMs = 95;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 480;
    final base =
        (isMobile ? BatshTypography.headlineLg : BatshTypography.displayMd)
            .copyWith(fontWeight: FontWeight.w800, height: 1.18);

    final line1 = context.l10n.heroLine1.split(' ');
    final line2 = context.l10n.heroLine2.split(' ');
    final line2Start = _baseDelayMs + line1.length * _stepMs + 140;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WordLine(
          words: line1,
          style: base.copyWith(color: context.colorScheme.onSurface),
          startMs: _baseDelayMs,
          stepMs: _stepMs,
          disableMotion: disableMotion,
        ),
        const SizedBox(height: 8),
        _WordLine(
          words: line2,
          style: base.copyWith(color: context.colorScheme.primary),
          startMs: line2Start,
          stepMs: _stepMs,
          disableMotion: disableMotion,
        ),
      ],
    );
  }
}

/// One headline line whose words fade + rise + sharpen in sequence,
/// so the sentence reads itself in rather than popping as a block.
class _WordLine extends StatelessWidget {
  const _WordLine({
    required this.words,
    required this.style,
    required this.startMs,
    required this.stepMs,
    required this.disableMotion,
  });

  final List<String> words;
  final TextStyle style;
  final int startMs;
  final int stepMs;
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        for (var i = 0; i < words.length; i++)
          disableMotion
              ? Text(words[i], style: style)
              : Text(words[i], style: style)
                    .animate()
                    .fadeIn(
                      duration: 460.ms,
                      delay: (startMs + i * stepMs).ms,
                      curve: BatshMotion.easeOut,
                    )
                    .slideY(
                      begin: 0.7,
                      end: 0,
                      duration: 520.ms,
                      delay: (startMs + i * stepMs).ms,
                      curve: BatshMotion.heroEase,
                    )
                    .blurXY(
                      begin: 6,
                      end: 0,
                      duration: 460.ms,
                      delay: (startMs + i * stepMs).ms,
                      curve: BatshMotion.easeOut,
                    ),
      ],
    );
  }
}

// ─── Hero Subtitle ───────────────────────────────────────────────────────────

class _HeroSubtitle extends StatelessWidget {
  const _HeroSubtitle({required this.disableMotion});
  final bool disableMotion;

  @override
  Widget build(BuildContext context) {
    // Cap the measure so the subtitle reads as a set line, not text poured
    // edge-to-edge under the headline.
    final child = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Text(
        context.l10n.heroSubtitle,
        textAlign: TextAlign.center,
        style: BatshTypography.bodyLg.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
    if (disableMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 500.ms, delay: 1080.ms, curve: BatshMotion.easeOut)
        .slideY(
          begin: 0.5,
          end: 0,
          duration: 500.ms,
          delay: 1080.ms,
          curve: BatshMotion.easeOut,
        );
  }
}

// ─── Login Card ──────────────────────────────────────────────────────────────

/// Normalises an Egyptian phone entry to E.164 (`+20xxxxxxxxxx`).
String normalizeEgyptPhoneToE164(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0020')) digits = digits.substring(4);
  if (digits.startsWith('20')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '+20$digits';
}
