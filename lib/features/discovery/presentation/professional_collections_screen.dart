import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../domain/contractor_listing.dart';
import 'providers/discovery_providers.dart';

enum ProfessionalCollectionKind { topRated, all, nearby }

/// Full professional result sets opened from a discover shelf's "عرض الكل".
///
/// The landing page is intentionally curated. These pages are not: they use
/// their own provider and pagination state so the action exposes the complete
/// matching collection instead of moving the user to another scroll position.
class ProfessionalCollectionsScreen extends ConsumerStatefulWidget {
  const ProfessionalCollectionsScreen({
    super.key,
    required this.kind,
    this.city,
  });

  final ProfessionalCollectionKind kind;
  final String? city;

  @override
  ConsumerState<ProfessionalCollectionsScreen> createState() =>
      _ProfessionalCollectionsScreenState();
}

class _ProfessionalCollectionsScreenState
    extends ConsumerState<ProfessionalCollectionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;
  Object? _paginationError;

  bool get _hasMore => switch (widget.kind) {
    ProfessionalCollectionKind.topRated =>
      ref.read(topRatedProfessionalsProvider.notifier).hasMore,
    ProfessionalCollectionKind.all =>
      ref.read(allProfessionalsProvider.notifier).hasMore,
    ProfessionalCollectionKind.nearby =>
      widget.city == null
          ? false
          : ref
                .read(nearbyProfessionalsProvider(widget.city!).notifier)
                .hasMore,
  };

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });

    try {
      switch (widget.kind) {
        case ProfessionalCollectionKind.topRated:
          await ref.read(topRatedProfessionalsProvider.notifier).loadMore();
        case ProfessionalCollectionKind.all:
          await ref.read(allProfessionalsProvider.notifier).loadMore();
        case ProfessionalCollectionKind.nearby:
          final city = widget.city;
          if (city != null && city.isNotEmpty) {
            await ref
                .read(nearbyProfessionalsProvider(city).notifier)
                .loadMore();
          }
      }
    } catch (error) {
      if (mounted) setState(() => _paginationError = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    switch (widget.kind) {
      case ProfessionalCollectionKind.topRated:
        ref.invalidate(topRatedProfessionalsProvider);
        await ref.read(topRatedProfessionalsProvider.future);
      case ProfessionalCollectionKind.all:
        ref.invalidate(allProfessionalsProvider);
        await ref.read(allProfessionalsProvider.future);
      case ProfessionalCollectionKind.nearby:
        final city = widget.city;
        if (city != null && city.isNotEmpty) {
          ref.invalidate(nearbyProfessionalsProvider(city));
          await ref.read(nearbyProfessionalsProvider(city).future);
        }
    }
  }

  AsyncValue<List<ContractorListing>> _professionals() {
    return switch (widget.kind) {
      ProfessionalCollectionKind.topRated => ref.watch(
        topRatedProfessionalsProvider,
      ),
      ProfessionalCollectionKind.all => ref.watch(allProfessionalsProvider),
      ProfessionalCollectionKind.nearby =>
        widget.city == null || widget.city!.isEmpty
            ? const AsyncData(<ContractorListing>[])
            : ref.watch(nearbyProfessionalsProvider(widget.city!)),
    };
  }

  String _title(BuildContext context) => switch (widget.kind) {
    ProfessionalCollectionKind.topRated => context.l10n.topRated,
    ProfessionalCollectionKind.all => context.l10n.allProfessionals,
    ProfessionalCollectionKind.nearby =>
      widget.city == null || widget.city!.isEmpty
          ? context.l10n.nearYou
          : context.l10n.nearYouIn(widget.city!),
  };

  String _emptyTitle(BuildContext context) => switch (widget.kind) {
    ProfessionalCollectionKind.topRated => context.l10n.noContractorsTitle,
    ProfessionalCollectionKind.all => context.l10n.noContractorsTitle,
    ProfessionalCollectionKind.nearby => context.l10n.noContractorsTitle,
  };

  String _emptyMessage(BuildContext context) => switch (widget.kind) {
    ProfessionalCollectionKind.topRated =>
      context.l10n.noRatedProfessionalsMessage,
    ProfessionalCollectionKind.all => context.l10n.noContractorsMessage,
    ProfessionalCollectionKind.nearby => context.l10n.noContractorsMessage,
  };

  String _description(BuildContext context) => switch (widget.kind) {
    ProfessionalCollectionKind.topRated =>
      context.l10n.topRatedCollectionDescription,
    ProfessionalCollectionKind.all =>
      context.l10n.allProfessionalsCollectionDescription,
    ProfessionalCollectionKind.nearby =>
      context.l10n.nearbyProfessionalsCollectionDescription,
  };

  void _open(String id) =>
      context.push(Routes.homeownerContractorProfilePath(id));

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 520) _loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = _professionals();
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? {};

    return BatshScaffold(
      title: _title(context),
      body: async.when(
        loading: () => const _ProfessionalCollectionSkeleton(),
        error: (error, _) =>
            BatshError(message: ErrorMapper.map(error), onRetry: _refresh),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: BatshEmptyState(
                    title: _emptyTitle(context),
                    message: _emptyMessage(context),
                    icon: widget.kind == ProfessionalCollectionKind.topRated
                        ? Icons.star_outline_rounded
                        : Icons.people_outline_rounded,
                    kind: BatshEmptyStateKind.noResults,
                    action: OutlinedButton(
                      onPressed: _refresh,
                      child: Text(context.l10n.tryAgain),
                    ),
                  ),
                ),
              ],
            );
          }

          final showFooter =
              _hasMore || _loadingMore || _paginationError != null;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: BatshSpacing.sm,
                bottom: BatshSpacing.xxl,
              ),
              itemCount: items.length + 1 + (showFooter ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CollectionLead(
                    title: _title(context),
                    description: _description(context),
                  );
                }
                final itemIndex = index - 1;
                if (itemIndex == items.length) {
                  return _CollectionFooter(
                    loading: _loadingMore,
                    error: _paginationError,
                    hasMore: _hasMore,
                    onRetry: _loadMore,
                  );
                }
                final listing = items[itemIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: BatshSpacing.lg),
                  child: ContractorCard(
                    listing: listing,
                    isSaved: savedIds.contains(listing.id),
                    onToggleSave: () => runSignedIn(
                      context,
                      ref,
                      reason: context.l10n.signInToSave,
                      action: () => ref
                          .read(savedControllerProvider.notifier)
                          .toggle(listing.id),
                    ),
                    onTap: () => _open(listing.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CollectionLead extends StatelessWidget {
  const _CollectionLead({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLow,
          borderRadius: BatshRadius.brLg,
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BatshSpacing.md),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    color: context.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: BatshTypography.labelLg),
                      const SizedBox(height: BatshSpacing.xxs),
                      Text(
                        description,
                        style: BatshTypography.bodySm.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
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

class _CollectionFooter extends StatelessWidget {
  const _CollectionFooter({
    required this.loading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
  });

  final bool loading;
  final Object? error;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.lg),
        child: Center(
          child: Semantics(
            label: context.l10n.loadingMore,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.tryAgain),
        ),
      );
    }
    if (!hasMore) return const SizedBox(height: BatshSpacing.md);
    return const SizedBox(height: BatshSpacing.md);
  }
}

class _ProfessionalCollectionSkeleton extends StatelessWidget {
  const _ProfessionalCollectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: BatshSpacing.sm,
        bottom: BatshSpacing.xxl,
      ),
      children: [
        for (var i = 0; i < 3; i++) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
              borderRadius: BatshRadius.brLg,
              boxShadow: BatshShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BatshShimmerBox(
                  height: 230,
                  borderRadius: BatshRadius.brLg,
                ),
                Padding(
                  padding: const EdgeInsets.all(BatshSpacing.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      BatshShimmerBox(width: 170, height: 20),
                      SizedBox(height: BatshSpacing.sm),
                      BatshShimmerBox(width: 120, height: 14),
                      SizedBox(height: BatshSpacing.sm),
                      BatshShimmerBox(width: 210, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
        ],
      ],
    );
  }
}
