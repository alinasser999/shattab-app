import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../explore/presentation/widgets/contractor_community_posts.dart';
import '../../domain/homeowner_profile_preview.dart';
import '../providers/briefs_providers.dart';

class HomeownerProfilePreviewScreen extends ConsumerWidget {
  const HomeownerProfilePreviewScreen({super.key, required this.homeownerId});

  final String homeownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(
      homeownerProfilePreviewProvider(homeownerId),
    );

    return BatshScaffold(
      title: context.l10n.homeownerProfileTitle,
      padding: EdgeInsets.zero,
      body: profileAsync.when(
        loading: () => const _HomeownerProfileSkeleton(),
        error: (error, _) => BatshError(
          message: ErrorMapper.map(error),
          onRetry: () =>
              ref.invalidate(homeownerProfilePreviewProvider(homeownerId)),
        ),
        data: (profile) {
          if (profile == null) {
            return BatshError(
              message: context.l10n.homeownerProfileUnavailable,
            );
          }
          return _HomeownerProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _HomeownerProfileBody extends StatelessWidget {
  const _HomeownerProfileBody({required this.profile});

  final PublicHomeownerProfile profile;

  @override
  Widget build(BuildContext context) {
    final details = profile.details;
    final interests = details?.renovationInterests ?? const <String>[];
    final location = [
      details?.district,
      details?.city,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join('، ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.sm,
        BatshSpacing.md,
        BatshSpacing.xxl,
      ),
      children: [
        _PublicProfileHero(profile: profile),
        const SizedBox(height: BatshSpacing.lg),
        Text(
          context.l10n.homeownerProfileDetailsTitle,
          style: BatshTypography.titleMd.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: BatshSpacing.sm),
        _DetailsCard(
          details: details,
          location: location,
          interests: interests,
        ),
        const SizedBox(height: BatshSpacing.lg),
        Text(
          context.l10n.communityPostsTitle,
          style: BatshTypography.titleMd.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: BatshSpacing.sm),
        ContractorCommunityPosts(
          contractorId: profile.profile.id,
          authorRole: 'homeowner',
        ),
        const SizedBox(height: BatshSpacing.md),
        _PrivacyNote(),
      ],
    );
  }
}

class _PublicProfileHero extends StatelessWidget {
  const _PublicProfileHero({required this.profile});

  final PublicHomeownerProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.profile.fullName.trim().isEmpty
        ? context.l10n.opportunityPostedBy
        : profile.profile.fullName;

    return Container(
      padding: const EdgeInsets.all(BatshSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(BatshRadius.xl),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colorScheme.primaryContainer,
            ),
            child: AvatarWithInitials(
              imageUrl: profile.profile.avatarUrl,
              name: name,
              radius: 42,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.headlineSm.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.homeownerProfileSubtitle,
            textAlign: TextAlign.center,
            style: BatshTypography.bodyMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.details,
    required this.location,
    required this.interests,
  });

  final HomeownerProfile? details;
  final String location;
  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    if (details == null || (location.isEmpty && interests.isEmpty)) {
      return _EmptyDetailsCard();
    }

    final tiles = <Widget>[];
    if (details?.apartmentType != null) {
      tiles.add(
        _ProfileDetailTile(
          icon: Icons.home_outlined,
          label: context.l10n.homeownerApartmentLabel,
          value: _apartmentLabel(context, details!.apartmentType!),
        ),
      );
    }
    if (location.isNotEmpty) {
      tiles.add(
        _ProfileDetailTile(
          icon: Icons.location_on_outlined,
          label: context.l10n.homeownerLocationLabel,
          value: location,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(BatshRadius.lg),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = tiles.length > 1
                  ? (constraints.maxWidth - BatshSpacing.sm) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: BatshSpacing.sm,
                runSpacing: BatshSpacing.sm,
                children: [
                  for (final tile in tiles) SizedBox(width: width, child: tile),
                ],
              );
            },
          ),
          if (interests.isNotEmpty) ...[
            const SizedBox(height: BatshSpacing.md),
            Text(
              context.l10n.homeownerInterestsLabel,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Wrap(
              spacing: BatshSpacing.xs,
              runSpacing: BatshSpacing.xs,
              children: [
                for (final interest in interests)
                  Chip(
                    avatar: Icon(
                      Icons.check_rounded,
                      size: BatshIconSize.xs,
                      color: context.colorScheme.secondary,
                    ),
                    label: Text(localizedSpecialtyLabel(context, interest)),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: context.colorScheme.secondaryContainer,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  const _ProfileDetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.sm),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(BatshRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: BatshIconSize.sm,
            color: context.colorScheme.primary,
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            label,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDetailsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(BatshRadius.lg),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        context.l10n.homeownerProfileNoDetails,
        style: BatshTypography.bodyMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(BatshRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: BatshIconSize.sm,
            color: context.colorScheme.secondary,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.homeownerProfilePrivacyHint,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeownerProfileSkeleton extends StatelessWidget {
  const _HomeownerProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(BatshSpacing.md),
      children: const [
        BatshShimmerBox(width: double.infinity, height: 230),
        SizedBox(height: BatshSpacing.lg),
        BatshShimmerBox(width: 180, height: 24),
        SizedBox(height: BatshSpacing.sm),
        BatshShimmerBox(width: double.infinity, height: 180),
      ],
    );
  }
}

String _apartmentLabel(BuildContext context, ApartmentType type) =>
    switch (type) {
      ApartmentType.studio => context.l10n.apartmentStudio,
      ApartmentType.oneBedroom => context.l10n.apartmentOneBedroom,
      ApartmentType.twoBedroom => context.l10n.apartmentTwoBedroom,
      ApartmentType.threeBedroomPlus => context.l10n.apartmentThreeBedroomPlus,
      ApartmentType.duplex => context.l10n.apartmentDuplex,
      ApartmentType.villa => context.l10n.apartmentVilla,
      ApartmentType.penthouse => context.l10n.apartmentPenthouse,
    };
