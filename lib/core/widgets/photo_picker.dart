import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'professional_reference_states.dart';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../cache/media_cache.dart';
import '../utils/image_url.dart';
import 'package:image_picker/image_picker.dart';

import '../models/draft_photo.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';
import 'package:batsh/core/theme/theme_extension.dart';
import 'batsh_photo_viewer.dart';
import 'batsh_pressable.dart';

/// Multi-photo picker (max [maxPhotos], default 5). Returns [DraftPhoto] entries
/// the caller persists later.
final photoPickerCallbackProvider = Provider<Future<List<XFile>> Function(int)>(
  (ref) =>
      (limit) => ImagePicker().pickMultiImage(
        limit: limit,
        maxWidth: 1600,
        imageQuality: 85,
      ),
);

class PhotoPicker extends ConsumerStatefulWidget {
  const PhotoPicker({
    super.key,
    required this.onChanged,
    this.maxPhotos = 5,
    this.initial = const [],
  });

  final ValueChanged<List<DraftPhoto>> onChanged;
  final int maxPhotos;
  final List<DraftPhoto> initial;

  @override
  ConsumerState<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends ConsumerState<PhotoPicker> {
  late List<DraftPhoto> _photos;
  bool _picking = false;
  bool _pickerFailed = false;

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.initial);
  }

  Future<void> _pick() async {
    if (_picking || _photos.length >= widget.maxPhotos) return;
    setState(() {
      _picking = true;
      _pickerFailed = false;
    });
    try {
      final picked = await ref.read(photoPickerCallbackProvider)(
        widget.maxPhotos - _photos.length,
      );
      if (picked.isEmpty) return;
      final newPhotos = <DraftPhoto>[];
      for (final x in picked) {
        if (kIsWeb) {
          newPhotos.add(DraftPhoto(bytes: await x.readAsBytes()));
        } else {
          newPhotos.add(DraftPhoto(file: File(x.path)));
        }
      }
      if (!mounted) return;
      if (newPhotos.isNotEmpty) {
        setState(
          () => _photos = [
            ..._photos,
            ...newPhotos,
          ].take(widget.maxPhotos).toList(),
        );
        widget.onChanged(_photos);
      }
    } catch (_) {
      if (mounted) setState(() => _pickerFailed = true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _remove(int i) {
    setState(() => _photos = [..._photos]..removeAt(i));
    widget.onChanged(_photos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_pickerFailed) ...[
          ProfessionalReferenceInlineStatus(
            message: context.l10n.statePickerGuidance,
            retryLabel: context.l10n.tryAgain,
            onRetry: _picking ? null : _pick,
          ),
          const SizedBox(height: BatshSpacing.sm),
        ],
        Text(
          '${context.l10n.photos} (${_photos.length}/${widget.maxPhotos})',
          style: BatshTypography.labelMd.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
            itemBuilder: (context, i) {
              if (i == _photos.length) {
                return _AddTile(
                  onTap: _picking || _photos.length >= widget.maxPhotos
                      ? null
                      : _pick,
                );
              }
              return _PhotoTile(photo: _photos[i], onRemove: () => _remove(i));
            },
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Semantics(
      label: context.l10n.addPhotos,
      child: Material(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BatshRadius.brMd,
        child: InkWell(
          borderRadius: BatshRadius.brMd,
          onTap: onTap,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brMd,
              border: Border.all(
                color: context.colorScheme.outlineVariant,
                style: disabled ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.add_a_photo_outlined,
              color: disabled
                  ? context.colorScheme.surfaceContainerHigh
                  : context.colorScheme.primary,
              size: BatshIconSize.lg,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onRemove});
  final DraftPhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (photo.file != null) {
      image = Image.file(photo.file!, fit: BoxFit.cover);
    } else if (photo.bytes != null) {
      image = Image.memory(photo.bytes!, fit: BoxFit.cover);
    } else if (isDisplayableImageUrl(photo.url)) {
      image = CachedNetworkImage(
        imageUrl: sizedImageUrl(photo.url!, width: 288),
        cacheManager: mediaCacheManager,
        fit: BoxFit.cover,
        memCacheWidth: 288,
        placeholder: (_, _) => const _PhotoFallback(),
        errorWidget: (_, _, _) => const _PhotoFallback(),
      );
    } else {
      image = const _PhotoFallback();
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BatshRadius.brMd,
          child: SizedBox(width: 96, height: 96, child: image),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: context.l10n.removePhoto,
              onPressed: onRemove,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: BatshIconSize.md,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple read-only horizontal photo strip for viewing existing photo URLs.
class PhotoGallery extends StatelessWidget {
  const PhotoGallery({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
        itemBuilder: (context, i) => BatshPressable(
          onTap: () =>
              BatshPhotoViewer.show(context, urls: urls, initialIndex: i),
          semanticLabel: context.l10n.photoIndexOf(i + 1, urls.length),
          child: ClipRRect(
            borderRadius: BatshRadius.brMd,
            child: Container(
              width: 200,
              height: 160,
              color: context.colorScheme.surfaceContainer,
              child: isDisplayableImageUrl(urls[i])
                  ? CachedNetworkImage(
                      imageUrl: sizedImageUrl(urls[i], width: 600),
                      cacheManager: mediaCacheManager,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      placeholder: (_, _) => const _PhotoFallback(),
                      errorWidget: (_, _, _) => const _PhotoFallback(),
                    )
                  : const _PhotoFallback(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
