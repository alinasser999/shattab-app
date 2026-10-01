import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Full-screen photo viewer: swipe between photos, pinch to zoom.
///
/// Any surface that shows a photo strip or grid opens this instead of
/// re-implementing its own lightbox. The counter is driven by the live page
/// position, so it can never disagree with what is on screen.
class BatshPhotoViewer extends StatefulWidget {
  const BatshPhotoViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });

  final List<String> urls;
  final int initialIndex;

  /// Pushes the viewer as an opaque full-screen route.
  static Future<void> show(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
  }) {
    if (urls.isEmpty) return Future.value();
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BatshPhotoViewer(
          urls: urls,
          initialIndex: initialIndex.clamp(0, urls.length - 1),
        ),
      ),
    );
  }

  @override
  State<BatshPhotoViewer> createState() => _BatshPhotoViewerState();
}

class _BatshPhotoViewerState extends State<BatshPhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.urls[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  placeholder: (_, _) => const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: BatshIconSize.xl,
                      ),
                      const SizedBox(height: BatshSpacing.sm),
                      Text(
                        context.l10n.imageUnavailable,
                        style: BatshTypography.labelMd.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(BatshSpacing.sm),
              child: Row(
                children: [
                  _Scrim(
                    child: IconButton(
                      tooltip: context.l10n.closePhotoViewer,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: BatshIconSize.md,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const Spacer(),
                  if (widget.urls.length > 1)
                    _Scrim(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BatshSpacing.md,
                          vertical: BatshSpacing.sm,
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            context.l10n.photoIndexOf(
                              _index + 1,
                              widget.urls.length,
                            ),
                            style: BatshTypography.labelMd.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.urls.length > 1) ...[
            PositionedDirectional(
              start: BatshSpacing.sm,
              top: MediaQuery.paddingOf(context).top + 170,
              child: _ViewerArrow(
                tooltip: context.l10n.previousPhoto,
                icon: Icons.chevron_left_rounded,
                onPressed: _index == 0
                    ? null
                    : () => _controller.previousPage(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                      ),
              ),
            ),
            PositionedDirectional(
              end: BatshSpacing.sm,
              top: MediaQuery.paddingOf(context).top + 170,
              child: _ViewerArrow(
                tooltip: context.l10n.nextPhoto,
                icon: Icons.chevron_right_rounded,
                onPressed: _index == widget.urls.length - 1
                    ? null
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                      ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 78,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.md,
                      vertical: BatshSpacing.sm,
                    ),
                    itemCount: widget.urls.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: BatshSpacing.xs),
                    itemBuilder: (_, i) => Semantics(
                      button: true,
                      selected: i == _index,
                      label: context.l10n.photoIndexOf(
                        i + 1,
                        widget.urls.length,
                      ),
                      child: GestureDetector(
                        onTap: () => _controller.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 64,
                          decoration: BoxDecoration(
                            borderRadius: BatshRadius.brSm,
                            border: Border.all(
                              color: i == _index
                                  ? Colors.white
                                  : Colors.white54,
                              width: i == _index ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: widget.urls[i],
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const ColoredBox(
                              color: Colors.black54,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ViewerArrow extends StatelessWidget {
  const _ViewerArrow({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .58),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: BatshIconSize.lg),
        ),
      ),
    );
  }
}

/// Dark pill behind the overlay controls so they stay legible on any photo.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.scrim.withValues(alpha: 0.55),
        borderRadius: BatshRadius.brFull,
      ),
      child: child,
    );
  }
}
