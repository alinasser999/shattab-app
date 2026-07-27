import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';

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
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
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
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: BatshIconSize.xl,
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
                      tooltip: S.closePhotoViewer,
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: BatshIconSize.md),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const Spacer(),
                  if (widget.urls.length > 1)
                    _Scrim(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: BatshSpacing.md,
                            vertical: BatshSpacing.sm),
                        child: Text(
                          S.photoIndexOf(_index + 1, widget.urls.length),
                          style: BatshTypography.labelMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
        color: BatshColors.scrim.withValues(alpha: 0.55),
        borderRadius: BatshRadius.brFull,
      ),
      child: child,
    );
  }
}
