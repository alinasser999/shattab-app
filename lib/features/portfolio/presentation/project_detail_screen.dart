import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/image_url.dart';
import '../../../core/widgets/avatar_with_initials.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_initial_plate.dart';
import '../../../core/widgets/batsh_photo_viewer.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';
import '../../discovery/domain/contractor_listing.dart';
import '../data/portfolio_repository.dart';
import '../domain/portfolio_project.dart';
import 'providers/portfolio_providers.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  int _selectedIndex = 0;
  bool _saved = false;
  bool _loadingSaved = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedState());
  }

  Future<void> _loadSavedState() async {
    if (ref.read(currentSessionProvider) == null) return;
    try {
      final value = await ref
          .read(portfolioRepositoryProvider)
          .isProjectSaved(widget.projectId);
      if (mounted) setState(() => _saved = value);
    } catch (_) {
      // The optional save migration may be behind the app in a staged
      // environment. The detail page itself remains fully browsable.
    }
  }

  Future<void> _toggleSaved(PortfolioProject project) async {
    if (_loadingSaved) return;
    setState(() {
      _loadingSaved = true;
      _saved = !_saved;
    });
    try {
      final repo = ref.read(portfolioRepositoryProvider);
      if (_saved) {
        await repo.saveProject(project.id);
      } else {
        await repo.unsaveProject(project.id);
      }
      if (mounted) {
        BatshSnack.success(
          context,
          _saved ? context.l10n.savedToast : context.l10n.unsavedToast,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saved = !_saved);
      BatshSnack.error(context, ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  void _openViewer(List<String> photos, int index) {
    unawaited(
      BatshPhotoViewer.show(context, urls: photos, initialIndex: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(portfolioProjectProvider(widget.projectId));
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: async.when(
        loading: () => const BatshHeroDetailSkeleton(),
        error: (error, _) => BatshError(
          message: ErrorMapper.map(error),
          onRetry: () =>
              ref.invalidate(portfolioProjectProvider(widget.projectId)),
        ),
        data: (project) {
          if (project == null) {
            return BatshError(message: context.l10n.projectNotFound);
          }
          return _buildDetails(context, project);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, PortfolioProject project) {
    final photos = <String>{
      if (isDisplayableImageUrl(project.coverPhotoUrl)) project.coverPhotoUrl,
      ...project.photoUrls.where(isDisplayableImageUrl),
    }.toList();
    if (photos.isEmpty) photos.add('');
    final selected = _selectedIndex.clamp(0, photos.length - 1).toInt();
    final contractor = ref
        .watch(contractorByIdProvider(project.contractorId))
        .value;
    final professionalName = contractor == null
        ? null
        : contractor.businessName.trim().isNotEmpty
        ? contractor.businessName.trim()
        : contractor.fullName.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProjectHeader(
              title: project.title,
              onBack: () => Navigator.of(context).maybePop(),
              onShare: () => Share.share(project.title),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.sectionH,
              ),
              child: _ProjectImageStage(
                project: project,
                photo: photos[selected],
                saved: _saved,
                onSave: () => runSignedIn(
                  context,
                  ref,
                  reason: context.l10n.signInToSave,
                  action: () => unawaited(_toggleSaved(project)),
                ),
                onOpen: photos[selected].isEmpty
                    ? null
                    : () => _openViewer(photos, selected),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BatshSpacing.sectionH,
                BatshSpacing.sm,
                BatshSpacing.sectionH,
                0,
              ),
              child: _ProjectThumbnailStrip(
                photos: photos,
                selectedIndex: selected,
                onSelect: (index) => setState(() => _selectedIndex = index),
                onOpen: (index) => _openViewer(photos, index),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.sectionH,
              BatshSpacing.lg,
              BatshSpacing.sectionH,
              BatshSpacing.xxl,
            ),
            sliver: SliverList.list(
              children: [
                _ProjectMetaLine(project: project),
                if (professionalName != null) ...[
                  const SizedBox(height: BatshSpacing.sm),
                  _ProfessionalAssociation(
                    name: professionalName,
                    contractor: contractor!,
                  ),
                ],
                if (project.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: BatshSpacing.xl),
                  Text(
                    'وصف المشروع',
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Text(
                    project.description!.trim(),
                    style: BatshTypography.bodyLg.copyWith(height: 1.6),
                  ),
                ],
                if (project.category != null ||
                    project.apartmentType != null) ...[
                  const SizedBox(height: BatshSpacing.xl),
                  Text(
                    'تصنيف المشروع',
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Wrap(
                    spacing: BatshSpacing.xs,
                    runSpacing: BatshSpacing.xs,
                    children: [
                      if (project.category?.trim().isNotEmpty == true)
                        _Tag(label: project.category!.trim()),
                      if (project.apartmentType?.trim().isNotEmpty == true)
                        _Tag(label: project.apartmentType!.trim()),
                    ],
                  ),
                ],
                const SizedBox(height: BatshSpacing.xl),
                BatshButton(
                  label: 'عرض الصور',
                  icon: Icons.photo_library_outlined,
                  onPressed: photos.first.isEmpty
                      ? null
                      : () => _openViewer(photos, selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.title,
    required this.onBack,
    required this.onShare,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.sectionH,
          BatshSpacing.sm,
          BatshSpacing.sectionH,
          BatshSpacing.md,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            const SizedBox(width: BatshSpacing.xs),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: BatshTypography.titleLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.share,
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectImageStage extends StatelessWidget {
  const _ProjectImageStage({
    required this.project,
    required this.photo,
    required this.saved,
    required this.onSave,
    required this.onOpen,
  });

  final PortfolioProject project;
  final String photo;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: SizedBox(
        height: 306,
        child: ClipRRect(
          borderRadius: BatshRadius.brLg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ProjectHero(project: project, photo: photo),
              PositionedDirectional(
                top: BatshSpacing.sm,
                start: BatshSpacing.sm,
                child: Material(
                  color: context.colorScheme.surfaceContainerLowest,
                  borderRadius: BatshRadius.brMd,
                  elevation: 2,
                  child: InkWell(
                    onTap: onSave,
                    borderRadius: BatshRadius.brMd,
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: saved
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({required this.project, required this.photo});

  final PortfolioProject project;
  final String photo;

  @override
  Widget build(BuildContext context) {
    final image = photo.isEmpty
        ? BatshInitialPlate(name: project.title)
        : CachedNetworkImage(
            imageUrl: sizedImageUrl(photo, width: 1200),
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => BatshInitialPlate(name: project.title),
          );
    return ClipRRect(
      borderRadius: BatshRadius.brXxl,
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: BatshShadows.soft),
        child: image,
      ),
    );
  }
}

class _ProjectThumbnailStrip extends StatelessWidget {
  const _ProjectThumbnailStrip({
    required this.photos,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpen,
  });

  final List<String> photos;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
        itemBuilder: (_, index) {
          final url = photos[index];
          return Semantics(
            button: true,
            selected: index == selectedIndex,
            label: context.l10n.photoIndexOf(index + 1, photos.length),
            child: GestureDetector(
              onTap: () {
                onSelect(index);
                if (url.isNotEmpty) onOpen(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 86,
                decoration: BoxDecoration(
                  borderRadius: BatshRadius.brMd,
                  border: Border.all(
                    color: index == selectedIndex
                        ? context.colorScheme.primary
                        : context.colorScheme.outlineVariant,
                    width: index == selectedIndex ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: url.isEmpty
                    ? BatshInitialPlate(name: context.l10n.projectDetailsTitle)
                    : CachedNetworkImage(
                        imageUrl: sizedImageUrl(url, width: 260),
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfessionalAssociation extends StatelessWidget {
  const _ProfessionalAssociation({
    required this.name,
    required this.contractor,
  });

  final String name;
  final ContractorListing contractor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarWithInitials(
          imageUrl: contractor.logoUrl,
          name: name,
          radius: 20,
        ),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: BatshTypography.labelLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(
          contractor.providerKind.icon,
          size: BatshIconSize.md,
          color: context.colorScheme.primary,
        ),
      ],
    );
  }
}

class _ProjectMetaLine extends StatelessWidget {
  const _ProjectMetaLine({required this.project});

  final PortfolioProject project;

  @override
  Widget build(BuildContext context) {
    final category = project.category?.trim();
    final location = project.location?.trim();
    final items = <Widget>[];
    if (category != null && category.isNotEmpty) {
      items.add(_MetaLineItem(icon: Icons.home_work_outlined, label: category));
    }
    if (location != null && location.isNotEmpty) {
      if (items.isNotEmpty) {
        items.add(
          Container(
            height: 28,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
            color: context.colorScheme.outlineVariant,
          ),
        );
      }
      items.add(
        _MetaLineItem(icon: Icons.location_on_outlined, label: location),
      );
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}

class _MetaLineItem extends StatelessWidget {
  const _MetaLineItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: context.colorScheme.tertiary,
            size: BatshIconSize.md,
          ),
          const SizedBox(width: BatshSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.bodyLg.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer,
        borderRadius: BatshRadius.brFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.md,
          vertical: BatshSpacing.xs,
        ),
        child: Text(label, style: BatshTypography.labelMd),
      ),
    );
  }
}
