import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/l10n/catalog_labels.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/image_url.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_initial_plate.dart';
import '../../../core/widgets/batsh_pressable.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../discovery/domain/contractor_listing.dart';
import 'providers/saved_providers.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  final Set<String> _removed = {};
  final Set<String> _busy = {};

  Future<void> _remove(ContractorListing contractor) async {
    if (_busy.contains(contractor.id)) return;
    setState(() {
      _busy.add(contractor.id);
      _removed.add(contractor.id);
    });
    try {
      await ref.read(savedControllerProvider.notifier).toggle(contractor.id);
      if (!mounted) return;
      setState(() => _busy.remove(contractor.id));
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('تمت إزالة المحترف من المحفوظات'),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () => unawaited(_undo(contractor)),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy.remove(contractor.id);
        _removed.remove(contractor.id);
      });
      BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  Future<void> _undo(ContractorListing contractor) async {
    if (_busy.contains(contractor.id)) return;
    setState(() {
      _busy.add(contractor.id);
      _removed.remove(contractor.id);
    });
    try {
      await ref.read(savedControllerProvider.notifier).toggle(contractor.id);
      if (mounted) {
        setState(() => _busy.remove(contractor.id));
        BatshSnack.success(context, 'تمت إعادة المحترف إلى المحفوظات');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy.remove(contractor.id);
        _removed.add(contractor.id);
      });
      BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(savedContractorsProvider);
    final isGuest = ref.watch(currentSessionProvider) == null;

    return BatshScaffold(
      title: context.l10n.tabSaved,
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: async.when(
        loading: () => const BatshListSkeleton(count: 3),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(savedContractorsProvider),
        ),
        data: (collection) {
          final list = collection.items
              .where((item) => !_removed.contains(item.id))
              .toList();
          return RefreshIndicator(
            backgroundColor: context.colorScheme.surfaceContainerLowest,
            onRefresh: () async {
              final refresh = ref.refresh(savedContractorsProvider.future);
              await refresh;
            },
            child: list.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.md,
                      BatshSpacing.sm,
                      BatshSpacing.md,
                      128,
                    ),
                    children: [
                      _SavedEmptyState(
                        isGuest: isGuest,
                        onDiscover: () => context.go(Routes.homeownerDiscover),
                        onSignIn: () => showSignInSheet(
                          context,
                          reason: context.l10n.signInToSeeSaved,
                        ),
                        onBackToAccount: () =>
                            context.go(Routes.homeownerProfile),
                      ),
                    ],
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 360 &&
                          collection.hasMore &&
                          !collection.isLoadingMore) {
                        ref.read(savedContractorsProvider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        BatshSpacing.md,
                        BatshSpacing.sm,
                        BatshSpacing.md,
                        128,
                      ),
                      itemCount:
                          list.length +
                          (collection.hasMore ||
                                  collection.isLoadingMore ||
                                  collection.loadMoreError != null
                              ? 1
                              : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: BatshSpacing.sm),
                      itemBuilder: (context, i) {
                        if (i == list.length) {
                          return _SavedLoadMoreFooter(
                            collection: collection,
                            onRetry: () => ref
                                .read(savedContractorsProvider.notifier)
                                .loadMore(),
                          );
                        }
                        final contractor = list[i];
                        final reduced = MediaQuery.disableAnimationsOf(context);
                        final card = _SavedProfessionalCard(
                          key: ValueKey(contractor.id),
                          listing: contractor,
                          busy: _busy.contains(contractor.id),
                          onToggleSave: () => _remove(contractor),
                          onTap: () => context.push(
                            Routes.homeownerContractorProfilePath(
                              contractor.id,
                            ),
                          ),
                        );
                        if (reduced) return card;
                        return card
                            .animate(delay: (55 * i.clamp(0, 6)).ms)
                            .fadeIn(
                              duration: 240.ms,
                              curve: BatshMotion.easeOut,
                            )
                            .slideY(begin: 0.03, end: 0);
                      },
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _SavedProfessionalCard extends StatelessWidget {
  const _SavedProfessionalCard({
    super.key,
    required this.listing,
    required this.busy,
    required this.onToggleSave,
    required this.onTap,
  });

  final ContractorListing listing;
  final bool busy;
  final VoidCallback onToggleSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.trim().isNotEmpty
        ? listing.businessName.trim()
        : listing.fullName.trim();
    final specialty = listing.specialties.isEmpty
        ? context.l10n.providerKindContractor
        : localizedSpecialtyLabel(context, listing.specialties.first);
    final area = listing.serviceAreas.isEmpty
        ? context.l10n.notSpecified
        : listing.serviceAreas.first;
    final cover = listing.coverPhotoUrl;

    return Semantics(
      button: true,
      label: context.l10n.homeViewProfile,
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: name,
        child: Container(
          constraints: const BoxConstraints(minHeight: 156),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brLg,
            border: Border.all(color: context.colorScheme.outlineVariant),
            boxShadow: BatshShadows.soft,
          ),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              SizedBox(
                width: 142,
                height: 156,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(BatshRadius.lg),
                      ),
                      child: isDisplayableImageUrl(cover)
                          ? CachedNetworkImage(
                              imageUrl: sizedImageUrl(cover!, width: 520),
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) =>
                                  BatshInitialPlate(name: name),
                            )
                          : BatshInitialPlate(name: name),
                    ),
                    PositionedDirectional(
                      start: BatshSpacing.xs,
                      bottom: BatshSpacing.xs,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .68),
                          borderRadius: BatshRadius.brFull,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BatshSpacing.xs,
                            vertical: 3,
                          ),
                          child: Text(
                            'محفوظ',
                            style: BatshTypography.labelSm.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Padding(
                    padding: const EdgeInsets.all(BatshSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: BatshTypography.titleMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: context.l10n.unsaveTooltip,
                              onPressed: busy ? null : onToggleSave,
                              icon: Icon(
                                Icons.bookmark_rounded,
                                color: context.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          specialty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.bodyMd.copyWith(
                            color: context.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: BatshSpacing.xxs),
                            Expanded(
                              child: Text(
                                area,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BatshTypography.bodySm.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            if (listing.rating != null)
                              Text(
                                listing.rating!.toStringAsFixed(1),
                                style: BatshTypography.labelLg.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (listing.rating != null)
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: Colors.amber,
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: onTap,
                              child: Text(context.l10n.homeViewProfile),
                            ),
                          ],
                        ),
                      ],
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

class _SavedLoadMoreFooter extends StatelessWidget {
  const _SavedLoadMoreFooter({required this.collection, required this.onRetry});

  final SavedContractorsState collection;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (collection.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(BatshSpacing.md),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (collection.loadMoreError != null) {
      return Semantics(
        liveRegion: true,
        label: context.l10n.loadMoreError,
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.retry),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SavedEmptyState extends StatelessWidget {
  const _SavedEmptyState({
    required this.isGuest,
    required this.onDiscover,
    required this.onSignIn,
    required this.onBackToAccount,
  });

  final bool isGuest;
  final VoidCallback onDiscover;
  final VoidCallback onSignIn;
  final VoidCallback onBackToAccount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXxl,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.xl,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        child: Column(
          children: [
            CustomPaint(
              size: const Size(180, 150),
              painter: _SavedEmptyIllustrationPainter(
                color: context.colorScheme.primary,
              ),
            ),
            Text(
              isGuest
                  ? context.l10n.signInToSeeSaved
                  : context.l10n.homeownerSavedEmptyTitle,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              isGuest
                  ? context.l10n.signInEmptyMessage
                  : context.l10n.homeownerSavedEmptyMessage,
              textAlign: TextAlign.center,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshButton(
              label: isGuest
                  ? context.l10n.signInSheetTitle
                  : context.l10n.homeownerSavedDiscoverAction,
              onPressed: isGuest ? onSignIn : onDiscover,
            ),
            const SizedBox(height: BatshSpacing.xs),
            TextButton(
              onPressed: onBackToAccount,
              child: Text(context.l10n.homeownerOrdersBackToAccount),
            ),
            if (!isGuest) ...[
              const SizedBox(height: BatshSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLow,
                  borderRadius: BatshRadius.brLg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BatshSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: BatshSpacing.sm),
                      Expanded(
                        child: Text(
                          context.l10n.homeownerSavedHint,
                          style: BatshTypography.labelSm.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedEmptyIllustrationPainter extends CustomPainter {
  const _SavedEmptyIllustrationPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final soft = Paint()
      ..color = color.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    final bookmark = Path()
      ..moveTo(size.width * 0.32, 20)
      ..lineTo(size.width * 0.68, 20)
      ..lineTo(size.width * 0.68, 116)
      ..lineTo(size.width * 0.50, 96)
      ..lineTo(size.width * 0.32, 116)
      ..close();
    canvas.drawPath(bookmark, soft);
    canvas.drawPath(bookmark, ink);
    canvas.drawLine(
      Offset(size.width * 0.18, 126),
      Offset(size.width * 0.82, 126),
      ink,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, 136),
      Offset(size.width * 0.78, 136),
      ink,
    );
    canvas.drawCircle(Offset(size.width * 0.2, 44), 14, soft);
    canvas.drawCircle(Offset(size.width * 0.8, 58), 18, soft);
  }

  @override
  bool shouldRepaint(covariant _SavedEmptyIllustrationPainter oldDelegate) =>
      oldDelegate.color != color;
}
