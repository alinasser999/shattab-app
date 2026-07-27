part of 'contractor_showcase.dart';

class _BioSection extends StatelessWidget {
  const _BioSection({required this.bio});
  final String bio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BatshSpacing.gutter),
        decoration: BoxDecoration(
          color: BatshColors.surfaceContainerLow,
          borderRadius: BatshRadius.brCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.aboutProfessional,
              style: BatshTypography.labelMd.copyWith(
                color: BatshColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(bio, style: BatshTypography.bodyLg),
          ],
        ),
      ),
    );
  }
}

/// Services as a scrollable row of icon tiles. Each specialty gets its own
/// glyph, so the row is scannable before it is read — the previous flat text
/// chips made "دهانات" and "سباكة" identical at a glance. Icon plus label, never
/// icon alone: the glyph is a scanning aid, not the meaning.
class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.specialtyKeys});

  final List<String> specialtyKeys;

  /// Specialty key → glyph. Same icon vocabulary as the opportunities filter
  /// sheet, so a contractor sees one consistent language for "كهرباء" whether
  /// they are filtering jobs or reading a profile.
  static const _icons = <String, IconData>{
    'paint': Icons.format_paint_outlined,
    'flooring': Icons.grid_on_outlined,
    'kitchen': Icons.countertops_outlined,
    'bathroom': Icons.bathtub_outlined,
    'electrical': Icons.electrical_services_outlined,
    'plumbing': Icons.plumbing_outlined,
    'carpentry': Icons.carpenter_outlined,
    'design': Icons.architecture_outlined,
    'full_reno': Icons.home_work_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (specialtyKeys.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: Text(
            S.specialtiesLabel,
            style: BatshTypography.titleLg.copyWith(
              color: BatshColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: _scaledStripHeight(context, 96, 2),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.marginMobile,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: specialtyKeys.length,
            separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.sm),
            itemBuilder: (_, i) {
              final key = specialtyKeys[i];
              return _ServiceTile(
                icon: _icons[key] ?? Icons.handyman_outlined,
                label: OnboardingCatalog.specialtiesCatalog[key] ?? key,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.xs,
        vertical: BatshSpacing.md,
      ),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: BatshColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: BatshIconSize.lg, color: BatshColors.primary),
          const SizedBox(height: BatshSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(
                color: BatshColors.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipsSection extends StatelessWidget {
  const _ChipsSection({required this.title, required this.labels});
  final String title;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BatshTypography.titleLg.copyWith(
              color: BatshColors.onSurface,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: [
              for (final label in labels)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BatshSpacing.gutter,
                    vertical: BatshSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: BatshColors.surfaceContainer,
                    borderRadius: BatshRadius.brFull,
                    border: Border.all(
                      color: BatshColors.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: BatshTypography.labelMd.copyWith(
                      color: BatshColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioSection extends StatelessWidget {
  const _PortfolioSection({
    required this.contractor,
    required this.projects,
    required this.isOwner,
    this.failed = false,
    this.onRetry,
  });
  final ContractorListing contractor;
  final List<PortfolioProject> projects;
  final bool isOwner;

  /// True when the fetch errored, as opposed to returning nothing.
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty && failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.marginMobile,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: BatshIconSize.md,
              color: BatshColors.onSurfaceVariant,
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Text(
                S.portfolioLoadFailed,
                style: BatshTypography.bodySm.copyWith(
                  color: BatshColors.onSurfaceVariant,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(S.tryAgain)),
          ],
        ),
      );
    }
    if (projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: Row(
            children: [
              Text(
                S.portfolioGalleryTitle,
                style: BatshTypography.titleLg.copyWith(
                  color: BatshColors.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => isOwner
                    ? context.go(Routes.contractorPortfolio)
                    : context.push(
                        Routes.homeownerContractorPortfolioPath(contractor.id),
                      ),
                child: Text(S.viewAll),
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: _scaledStripHeight(context, 234, 2),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.marginMobile,
            ),
            itemCount: projects.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: BatshSpacing.gutter),
            itemBuilder: (context, i) {
              final p = projects[i];
              return _PortfolioTile(
                project: p,
                onTap: () => isOwner
                    ? context.push(Routes.contractorPortfolioEditPath(p.id))
                    : context.push(
                        Routes.homeownerProjectDetailPath(contractor.id, p.id),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.project, required this.onTap});
  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BatshRadius.brXl,
          boxShadow: BatshShadows.soft,
        ),
        child: BatshPressable(
          onTap: onTap,
          semanticLabel: project.title,
          child: Material(
            color: BatshColors.surfaceContainerLowest,
            borderRadius: BatshRadius.brXl,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: CachedNetworkImage(
                    imageUrl: sizedImageUrl(project.coverPhotoUrl, width: 520),
                    fit: BoxFit.cover,
                    // Tile is 260px wide.
                    memCacheWidth: 520,
                    placeholder: (_, _) =>
                        const ColoredBox(color: BatshColors.surfaceContainer),
                    errorWidget: (_, _, _) => Container(
                      color: BatshColors.surfaceContainer,
                      child: const Icon(
                        Icons.image_outlined,
                        color: BatshColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(BatshSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (project.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          project.category!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.labelSm.copyWith(
                            color: BatshColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
