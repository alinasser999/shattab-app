import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/strings.dart';
import '../models/draft_photo.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';

/// Multi-photo picker (max [maxPhotos], default 5). Returns [DraftPhoto] entries
/// the caller persists later.
class PhotoPicker extends StatefulWidget {
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
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  late List<DraftPhoto> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.initial);
  }

  Future<void> _pick() async {
    if (_photos.length >= widget.maxPhotos) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      limit: widget.maxPhotos - _photos.length,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;
    final newPhotos = <DraftPhoto>[];
    for (final x in picked) {
      if (kIsWeb) {
        final bytes = await x.readAsBytes();
        newPhotos.add(DraftPhoto(bytes: bytes));
      } else {
        newPhotos.add(DraftPhoto(file: File(x.path)));
      }
    }
    setState(() => _photos = [..._photos, ...newPhotos]
        .take(widget.maxPhotos)
        .toList());
    widget.onChanged(_photos);
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
        Text(
          '${S.photos} (${_photos.length}/${widget.maxPhotos})',
          style: BatshTypography.labelMd
              .copyWith(color: BatshColors.onSurfaceVariant),
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
                  onTap: _photos.length >= widget.maxPhotos ? null : _pick,
                );
              }
              return _PhotoTile(
                  photo: _photos[i], onRemove: () => _remove(i));
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
    return Material(
      color: BatshColors.surfaceContainer,
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
                color: BatshColors.outlineVariant,
                style: disabled ? BorderStyle.solid : BorderStyle.solid),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.add_a_photo_outlined,
            color: disabled
                ? BatshColors.surfaceContainerHigh
                : BatshColors.primary,
            size: BatshIconSize.lg,
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
    } else if (photo.url != null) {
      image = CachedNetworkImage(
          imageUrl: photo.url!,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: BatshColors.surfaceContainer),
          errorWidget: (_, _, _) => Container(color: BatshColors.surfaceContainer));
    } else {
      image = const SizedBox.shrink();
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BatshRadius.brMd,
          child: SizedBox(width: 96, height: 96, child: image),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child:
                    Icon(Icons.close, size: BatshIconSize.sm, color: Colors.white),
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
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BatshRadius.brMd,
          child: Container(
            width: 200,
            height: 160,
            color: BatshColors.surfaceContainer,
            child: CachedNetworkImage(
                      imageUrl: urls[i],
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const SizedBox.shrink(),
                      errorWidget: (_, _, _) => const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
