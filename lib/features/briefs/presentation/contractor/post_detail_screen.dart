import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/analytics/marketplace_events.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_photo_viewer.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../quotes/domain/quote.dart';
import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../../quotes/presentation/quote_sheet.dart';
import '../../domain/brief.dart';
import '../../domain/homeowner_profile_preview.dart';
import '../../domain/opportunity_experience.dart';
import '../providers/briefs_providers.dart';
import '../providers/opportunity_experience_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late final ScrollController _scrollController;
  bool _lightStatusIcons = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_updateStatusBarStyle);
    unawaited(AppAnalytics.track(MarketplaceEvents.opportunityOpened));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateStatusBarStyle)
      ..dispose();
    super.dispose();
  }

  void _updateStatusBarStyle() {
    if (!_scrollController.hasClients) return;
    final width = MediaQuery.sizeOf(context).width.clamp(0.0, 560.0);
    final heroBottom = width / 1.24 + 96;
    final nextValue = _scrollController.offset < heroBottom;
    if (nextValue != _lightStatusIcons && mounted) {
      setState(() => _lightStatusIcons = nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final briefAsync = ref.watch(briefByIdProvider(widget.postId));
    final quoteAsync = ref.watch(myQuoteForBriefProvider(widget.postId));
    final contractor = ref.watch(contractorProfileProvider).value;
    final interactions = ref.watch(opportunityInteractionsProvider);
    final saved = interactions.savedIds.contains(widget.postId);
    final overlayBase = _lightStatusIcons
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayBase.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SafeArea(
          top: false,
          bottom: false,
          child: briefAsync.when(
            loading: () => const _OpportunityDetailSkeleton(),
            error: (error, _) => BatshError(
              message: ErrorMapper.map(error),
              onRetry: () => ref.invalidate(briefByIdProvider(widget.postId)),
            ),
            data: (brief) {
              if (brief == null) {
                return BatshError(message: context.l10n.postNotFound);
              }
              return Consumer(
                builder: (context, ref, _) {
                  final homeownerAsync = ref.watch(
                    homeownerProfilePreviewProvider(brief.homeownerId),
                  );
                  return _OpportunityDetailBody(
                    brief: brief,
                    quote: quoteAsync.value,
                    quoteLoading: quoteAsync.isLoading,
                    quoteFailed: quoteAsync.hasError,
                    contractor: contractor,
                    homeowner: homeownerAsync.value,
                    homeownerLoading: homeownerAsync.isLoading,
                    saved: saved,
                    onSave: () => unawaited(_toggleSaved(brief.id)),
                    onApply: () => showQuoteSheet(
                      context,
                      briefId: brief.id,
                      existing: quoteAsync.value,
                    ),
                    onFollowQuote: () =>
                        context.push(Routes.contractorMyQuotes),
                    onCompleteProfile: () =>
                        context.push(Routes.contractorEditProfile),
                    onRetryQuoteState: () =>
                        ref.invalidate(myQuoteForBriefProvider(brief.id)),
                    onViewHomeowner: () => context.push(
                      Routes.contractorHomeownerProfilePath(brief.homeownerId),
                    ),
                    onOpenMap: () => unawaited(_openMap(brief)),
                    scrollController: _scrollController,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSaved(String briefId) async {
    try {
      final saved = await ref
          .read(opportunityInteractionsProvider.notifier)
          .toggleSaved(briefId);
      if (!mounted) return;
      BatshSnack.success(
        context,
        saved
            ? context.l10n.opportunitySaved
            : context.l10n.opportunityRemovedFromSaved,
      );
    } catch (_) {
      if (!mounted) return;
      BatshSnack.error(context, context.l10n.somethingWentWrong);
    }
  }

  Future<void> _openMap(Brief brief) async {
    final location = _rawLocation(brief);
    if (location.isEmpty) return;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        BatshSnack.error(context, context.l10n.opportunityDetailMapOpenError);
      }
    } catch (_) {
      if (mounted) {
        BatshSnack.error(context, context.l10n.opportunityDetailMapOpenError);
      }
    }
  }
}

class _OpportunityDetailBody extends StatelessWidget {
  const _OpportunityDetailBody({
    required this.brief,
    required this.quote,
    required this.quoteLoading,
    required this.quoteFailed,
    required this.contractor,
    required this.homeowner,
    required this.homeownerLoading,
    required this.saved,
    required this.onSave,
    required this.onApply,
    required this.onFollowQuote,
    required this.onCompleteProfile,
    required this.onRetryQuoteState,
    required this.onViewHomeowner,
    required this.onOpenMap,
    required this.scrollController,
  });

  final Brief brief;
  final Quote? quote;
  final bool quoteLoading;
  final bool quoteFailed;
  final ContractorProfile? contractor;
  final PublicHomeownerProfile? homeowner;
  final bool homeownerLoading;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onApply;
  final VoidCallback onFollowQuote;
  final VoidCallback onCompleteProfile;
  final VoidCallback onRetryQuoteState;
  final VoidCallback onViewHomeowner;
  final VoidCallback onOpenMap;
  final ScrollController scrollController;

  bool get _profileReady =>
      contractor != null &&
      contractor!.specialties.isNotEmpty &&
      contractor!.serviceAreas.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final photos = brief.photoUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 132),
            children: [
              _PageWidth(
                child: _OpportunityGallery(
                  photoUrls: photos,
                  saved: saved,
                  onBack: () => context.pop(),
                  onSave: onSave,
                  onShare: () => _shareOpportunity(context, brief),
                  onCopy: () => _copyOpportunitySummary(context, brief),
                ),
              ),
              _PageWidth(child: _OpportunityIdentity(brief: brief)),
              _PageWidth(child: _OpportunityQuickInfo(brief: brief)),
              _PageWidth(
                child: _OpportunityActivity(
                  brief: brief,
                  quote: quote,
                  quoteLoading: quoteLoading,
                  quoteFailed: quoteFailed,
                ),
              ),
              _PageWidth(child: _OpportunityDescription(brief: brief)),
              _PageWidth(child: _OpportunityScope(brief: brief)),
              _PageWidth(child: _ClientPhotoSection(photoUrls: photos)),
              _PageWidth(
                child: _OpportunityLocation(brief: brief, onOpenMap: onOpenMap),
              ),
              _PageWidth(child: _OpportunityTiming(brief: brief)),
              _PageWidth(
                child: _DetailSection(
                  title: context.l10n.opportunityDetailAdditional,
                  icon: Icons.description_outlined,
                ),
              ),
              _PageWidth(
                child: _DetailSection(
                  title: context.l10n.opportunityDetailRequirements,
                  icon: Icons.star_outline_rounded,
                ),
              ),
              _PageWidth(
                child: _OpportunityOwner(
                  profile: homeowner,
                  loading: homeownerLoading,
                  onTap: homeowner == null ? null : onViewHomeowner,
                ),
              ),
              _PageWidth(child: _OpportunityAdvice(onTap: onCompleteProfile)),
            ],
          ),
        ),
        _OpportunityStickyAction(
          brief: brief,
          quote: quote,
          quoteLoading: quoteLoading,
          quoteFailed: quoteFailed,
          profileReady: _profileReady,
          onApply: onApply,
          onFollowQuote: onFollowQuote,
          onCompleteProfile: onCompleteProfile,
          onRetryQuoteState: onRetryQuoteState,
        ),
      ],
    );
  }
}

class _PageWidth extends StatelessWidget {
  const _PageWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: child,
    ),
  );
}

class _OpportunityGallery extends StatefulWidget {
  const _OpportunityGallery({
    required this.photoUrls,
    required this.saved,
    required this.onBack,
    required this.onSave,
    required this.onShare,
    required this.onCopy,
  });

  final List<String> photoUrls;
  final bool saved;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  State<_OpportunityGallery> createState() => _OpportunityGalleryState();
}

class _OpportunityGalleryState extends State<_OpportunityGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.photoUrls.length;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.24,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (count == 0)
                const _UnavailablePhoto()
              else
                PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => Semantics(
                    button: true,
                    image: true,
                    label:
                        '${context.l10n.photoIndexOf(index + 1, count)} · ${context.l10n.openPhotoViewer}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => BatshPhotoViewer.show(
                        context,
                        urls: widget.photoUrls,
                        initialIndex: index,
                      ),
                      child: _RequestPhoto(url: widget.photoUrls[index]),
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          context.colorScheme.scrim.withValues(alpha: 0.48),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + BatshSpacing.xs,
                left: BatshSpacing.xs,
                child: _GalleryControl(
                  tooltip: context.l10n.back,
                  icon: Icons.chevron_left_rounded,
                  onPressed: widget.onBack,
                ),
              ),
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + BatshSpacing.xs,
                right: BatshSpacing.xs,
                child: Row(
                  textDirection: ui.TextDirection.ltr,
                  children: [
                    _GalleryControl(
                      tooltip: widget.saved
                          ? context.l10n.removeOpportunityFromSaved
                          : context.l10n.saveOpportunity,
                      icon: widget.saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      toggled: widget.saved,
                      onPressed: widget.onSave,
                    ),
                    const SizedBox(width: BatshSpacing.xxs),
                    _GalleryControl(
                      tooltip: context.l10n.share,
                      icon: Icons.ios_share_rounded,
                      onPressed: widget.onShare,
                    ),
                    const SizedBox(width: BatshSpacing.xxs),
                    PopupMenuButton<_DetailMoreAction>(
                      tooltip: context.l10n.opportunityDetailMoreActions,
                      onSelected: (action) {
                        if (action == _DetailMoreAction.copySummary) {
                          widget.onCopy();
                        }
                      },
                      color: context.colorScheme.surfaceContainerLowest,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BatshRadius.brMd,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _DetailMoreAction.copySummary,
                          child: Row(
                            children: [
                              const Icon(Icons.copy_outlined),
                              const SizedBox(width: BatshSpacing.sm),
                              Text(context.l10n.copyOpportunitySummary),
                            ],
                          ),
                        ),
                      ],
                      child: Semantics(
                        button: true,
                        label: context.l10n.opportunityDetailMoreActions,
                        child: const _GalleryControlSurface(
                          child: Icon(Icons.more_horiz_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Positioned(
                  left: BatshSpacing.md,
                  bottom: BatshSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.sm,
                      vertical: BatshSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.scrim.withValues(alpha: 0.68),
                      borderRadius: BatshRadius.brFull,
                    ),
                    child: Text(
                      context.l10n.photoIndexOf(_index + 1, count),
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
        if (count > 0)
          SizedBox(
            height: 96,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                BatshSpacing.md,
                BatshSpacing.sm,
                BatshSpacing.md,
                BatshSpacing.xs,
              ),
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: count > 3 ? 4 : count,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: BatshSpacing.xs),
                  itemBuilder: (context, index) {
                    if (count > 3 && index == 3) {
                      return _MorePhotosTile(
                        remaining: count - 3,
                        total: count,
                        onTap: () => BatshPhotoViewer.show(
                          context,
                          urls: widget.photoUrls,
                          initialIndex: 3,
                        ),
                      );
                    }
                    return _GalleryThumbnail(
                      url: widget.photoUrls[index],
                      index: index,
                      selected: index == _index,
                      reduceMotion: reduceMotion,
                      onTap: () {
                        _controller.animateToPage(
                          index,
                          duration: BatshMotion.durationFor(
                            reduceMotion,
                            BatshMotion.fast,
                          ),
                          curve: BatshMotion.curveFor(
                            reduceMotion,
                            BatshMotion.easeOut,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          )
        else
          const SizedBox(height: BatshSpacing.sm),
      ],
    );
  }
}

enum _DetailMoreAction { copySummary }

class _GalleryControl extends StatelessWidget {
  const _GalleryControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.toggled,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool? toggled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: toggled,
    label: tooltip,
    child: Tooltip(
      message: tooltip,
      child: Material(
        color: context.colorScheme.scrim.withValues(alpha: 0.56),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          tooltip: null,
          icon: Icon(icon, color: Colors.white, size: BatshIconSize.action),
          constraints: const BoxConstraints.tightFor(
            width: BatshSpacing.xxxl,
            height: BatshSpacing.xxxl,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.standard,
        ),
      ),
    ),
  );
}

class _GalleryControlSurface extends StatelessWidget {
  const _GalleryControlSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colorScheme.scrim.withValues(alpha: 0.56),
    shape: const CircleBorder(),
    child: SizedBox.square(
      dimension: BatshSpacing.xxxl,
      child: Center(
        child: IconTheme(
          data: const IconThemeData(
            color: Colors.white,
            size: BatshIconSize.action,
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({
    required this.url,
    required this.index,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final String url;
  final int index;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: context.l10n.opportunityDetailSelectPhoto(index + 1),
    child: Material(
      color: context.colorScheme.surfaceContainerLow,
      borderRadius: BatshRadius.brMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: BatshMotion.durationFor(reduceMotion, BatshMotion.fast),
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BatshRadius.brMd,
            border: Border.all(
              color: selected
                  ? context.colorScheme.primary
                  : context.colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BatshRadius.brMd,
            child: _RequestPhoto(url: url),
          ),
        ),
      ),
    ),
  );
}

class _MorePhotosTile extends StatelessWidget {
  const _MorePhotosTile({
    required this.remaining,
    required this.total,
    required this.onTap,
  });

  final int remaining;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${context.l10n.photosCount(total)} · ${context.l10n.openPhotoViewer}',
    child: Material(
      color: context.colorScheme.surfaceContainerLow,
      borderRadius: BatshRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+$remaining',
                style: BatshTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                ),
              ),
              Text(
                context.l10n.photosCount(total),
                textAlign: TextAlign.center,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _UnavailablePhoto extends StatelessWidget {
  const _UnavailablePhoto();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colorScheme.surfaceContainerLow,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: BatshIconSize.empty,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            context.l10n.opportunityDetailPhotosUnavailable,
            style: BatshTypography.bodyMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RequestPhoto extends StatelessWidget {
  const _RequestPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    memCacheWidth: 1200,
    placeholder: (_, _) => const _PhotoFallback(),
    errorWidget: (_, _, _) => const _PhotoFallback(),
  );
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colorScheme.surfaceContainerLow,
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: BatshIconSize.action,
        color: context.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _OpportunityIdentity extends StatelessWidget {
  const _OpportunityIdentity({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMMd(locale).format(brief.createdAt);
    final title = _opportunityTitle(context, brief);
    final location = _localizedLocation(context, brief);
    return _DetailSection(
      title: null,
      icon: null,
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.sm,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: ui.TextDirection.ltr,
            children: [
              Directionality(
                textDirection: ui.TextDirection.rtl,
                child: _StatusPill(active: brief.isActive),
              ),
              const Spacer(),
              Flexible(
                child: Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Text(
                    context.l10n.requestsPublishedOn(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelSm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Icon(
                Icons.calendar_today_outlined,
                size: BatshIconSize.xs,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
          Text(
            title,
            textAlign: TextAlign.start,
            style: BatshTypography.headlineSm.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.28,
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: BatshSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: BatshIconSize.sm,
                  color: context.colorScheme.secondary,
                ),
                const SizedBox(width: BatshSpacing.xxs),
                Expanded(
                  child: Text(
                    location,
                    style: BatshTypography.bodyMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: BatshSpacing.sm,
      vertical: BatshSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: active
          ? context.colorScheme.primaryContainer
          : context.colorScheme.surfaceContainerHigh,
      borderRadius: BatshRadius.brFull,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          active ? Icons.auto_awesome_rounded : Icons.lock_outline_rounded,
          size: BatshIconSize.xs,
          color: active
              ? context.colorScheme.primary
              : context.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: BatshSpacing.xxs),
        Text(
          active
              ? context.l10n.opportunityOpen
              : context.l10n.opportunityClosed,
          style: BatshTypography.labelSm.copyWith(
            color: active
                ? context.colorScheme.primary
                : context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _OpportunityQuickInfo extends StatelessWidget {
  const _OpportunityQuickInfo({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final area = brief.estimatedArea;
    final timing = _timingLabel(context, brief.startTiming);
    final unit = _apartmentLabel(context, brief.apartmentType);
    final location = _localizedLocation(context, brief);
    final items = [
      _QuickInfoItem(
        icon: Icons.location_on_outlined,
        label: context.l10n.opportunityDetailAreaLabel,
        value: location.isEmpty ? context.l10n.notSpecified : location,
      ),
      _QuickInfoItem(
        icon: Icons.home_work_outlined,
        label: context.l10n.apartmentTypeLabel,
        value: unit,
      ),
      _QuickInfoItem(
        icon: Icons.schedule_outlined,
        label: context.l10n.opportunityDetailStartLabel,
        value: timing,
      ),
      _QuickInfoItem(
        icon: Icons.crop_free_rounded,
        label: context.l10n.areaLabel,
        value: area == null || area <= 0
            ? context.l10n.notSpecified
            : context.l10n.workAreaSquareMeters(area),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.md,
        vertical: BatshSpacing.xxs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeText =
              MediaQuery.textScalerOf(context).scale(14) > 17 ||
              constraints.maxWidth < 340;
          if (largeText) {
            final width = (constraints.maxWidth - BatshSpacing.xs) / 2;
            return Wrap(
              spacing: BatshSpacing.xs,
              runSpacing: BatshSpacing.xs,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: _QuickInfoCard(item: item),
                  ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(width: BatshSpacing.xxs),
                Expanded(child: _QuickInfoCard(item: items[index])),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _QuickInfoItem {
  const _QuickInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _QuickInfoCard extends StatelessWidget {
  const _QuickInfoCard({required this.item});

  final _QuickInfoItem item;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '${item.label}: ${item.value}',
    child: Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.xxs,
        vertical: BatshSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest.withValues(
          alpha: 0.76,
        ),
        borderRadius: BatshRadius.brMd,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: BatshIconSize.action,
            color: context.colorScheme.primary,
          ),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.xxxs),
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OpportunityActivity extends StatelessWidget {
  const _OpportunityActivity({
    required this.brief,
    required this.quote,
    required this.quoteLoading,
    required this.quoteFailed,
  });

  final Brief brief;
  final Quote? quote;
  final bool quoteLoading;
  final bool quoteFailed;

  @override
  Widget build(BuildContext context) {
    final publishedActivity = _formatPublishedActivity(
      context,
      brief.createdAt,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.xs,
        BatshSpacing.md,
        BatshSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.sm),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest.withValues(
          alpha: 0.52,
        ),
        borderRadius: BatshRadius.brMd,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActivityMetric(
              icon: Icons.schedule_outlined,
              label: context.l10n.opportunityDetailActivityPublished,
              value: publishedActivity,
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: _ActivityMetric(
              icon: Icons.photo_library_outlined,
              label: context.l10n.opportunityDetailActivityPhotos,
              value: context.l10n.photosCount(
                brief.photoUrls.where((url) => url.trim().isNotEmpty).length,
              ),
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: _ActivityMetric(
              icon: quote == null
                  ? Icons.send_outlined
                  : Icons.check_circle_outline_rounded,
              label: context.l10n.opportunityDetailActivityQuote,
              value: quoteLoading
                  ? context.l10n.opportunityDetailQuoteStateLoading
                  : quoteFailed
                  ? context.l10n.opportunityDetailQuoteStateUnavailable
                  : quote == null
                  ? context.l10n.opportunityDetailQuoteNotSent
                  : context.l10n.quoteAlreadySent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 46,
    color: context.colorScheme.outlineVariant.withValues(alpha: 0.45),
  );
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xxs),
    child: Column(
      children: [
        Icon(icon, size: BatshIconSize.sm, color: context.colorScheme.primary),
        const SizedBox(height: BatshSpacing.xxxs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.xxxs),
        Text(
          value,
          textAlign: TextAlign.center,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _formatPublishedActivity(BuildContext context, DateTime publishedAt) {
  final elapsed = DateTime.now().difference(publishedAt);
  final l10n = context.l10n;
  if (elapsed.inMinutes < 60) {
    final minutes = elapsed.inMinutes;
    return minutes == 1 ? l10n.minAgo(minutes) : l10n.minsAgo(minutes);
  }
  if (elapsed.inHours < 24) {
    final hours = elapsed.inHours;
    return hours == 1 ? l10n.hourAgo(hours) : l10n.hoursAgo(hours);
  }
  if (elapsed.inDays < 7) {
    final days = elapsed.inDays;
    return days == 1 ? l10n.dayAgo(days) : l10n.daysAgo(days);
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(publishedAt);
}

class _OpportunityDescription extends StatelessWidget {
  const _OpportunityDescription({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) => _DetailSection(
    title: context.l10n.opportunityDetailDescription,
    icon: Icons.description_outlined,
    child: Text(
      brief.workDescription,
      textAlign: TextAlign.start,
      style: BatshTypography.bodyMd.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        height: 1.65,
      ),
    ),
  );
}

class _OpportunityScope extends StatelessWidget {
  const _OpportunityScope({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final specialties = brief.targetSpecialties
        .map((value) => localizedSpecialtyDisplayLabel(context, value))
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    return _DetailSection(
      title: context.l10n.opportunityDetailScope,
      icon: Icons.layers_outlined,
      child: specialties.isEmpty
          ? null
          : Wrap(
              spacing: BatshSpacing.xs,
              runSpacing: BatshSpacing.xs,
              children: [
                for (final specialty in specialties)
                  _ScopeChip(label: specialty),
              ],
            ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: BatshSpacing.sm,
      vertical: BatshSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: context.colorScheme.secondaryContainer.withValues(alpha: 0.46),
      borderRadius: BatshRadius.brFull,
    ),
    child: Text(
      label,
      style: BatshTypography.labelMd.copyWith(
        color: context.colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ClientPhotoSection extends StatelessWidget {
  const _ClientPhotoSection({required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) => _DetailSection(
    title: context.l10n.opportunityDetailClientPhotos,
    icon: Icons.photo_library_outlined,
    child: photoUrls.isEmpty
        ? Text(
            context.l10n.opportunityDetailPhotosUnavailable,
            style: BatshTypography.bodyMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          )
        : SizedBox(
            height: 94,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoUrls.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: BatshSpacing.xs),
                itemBuilder: (context, index) => Semantics(
                  button: true,
                  image: true,
                  label:
                      '${context.l10n.photoIndexOf(index + 1, photoUrls.length)} · ${context.l10n.openPhotoViewer}',
                  child: Material(
                    color: context.colorScheme.surfaceContainerLow,
                    borderRadius: BatshRadius.brMd,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => BatshPhotoViewer.show(
                        context,
                        urls: photoUrls,
                        initialIndex: index,
                      ),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: _RequestPhoto(url: photoUrls[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
  );
}

class _OpportunityLocation extends StatelessWidget {
  const _OpportunityLocation({required this.brief, required this.onOpenMap});

  final Brief brief;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final rawLocation = _rawLocation(brief);
    final location = _localizedLocation(context, brief);
    return _DetailSection(
      title: context.l10n.opportunityDetailLocation,
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BatshRadius.brMd,
            child: Semantics(
              label: context.l10n.opportunityDetailMapPreview,
              excludeSemantics: true,
              child: CustomPaint(
                painter: _SchematicMapPainter(
                  roadColor: context.colorScheme.surfaceContainerHigh,
                  landColor: context.colorScheme.surfaceContainerLow,
                ),
                child: const SizedBox(height: 112, width: double.infinity),
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.xs),
          if (location.isNotEmpty)
            Text(
              location,
              textAlign: TextAlign.center,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              context.l10n.opportunityDetailNoLocation,
              textAlign: TextAlign.center,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: BatshSpacing.xs),
          OutlinedButton.icon(
            onPressed: rawLocation.isEmpty ? null : onOpenMap,
            icon: const Icon(Icons.map_outlined),
            label: Text(context.l10n.opportunityDetailMapAction),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(BatshSpacing.xxxxl),
              foregroundColor: context.colorScheme.primary,
              side: BorderSide(
                color: context.colorScheme.primary.withValues(alpha: 0.28),
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BatshRadius.brMd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchematicMapPainter extends CustomPainter {
  const _SchematicMapPainter({
    required this.roadColor,
    required this.landColor,
  });

  final Color roadColor;
  final Color landColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = landColor);
    final road = Paint()
      ..color = roadColor.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final fineRoad = Paint()
      ..color = roadColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final horizontal = Path()
      ..moveTo(-8, size.height * 0.38)
      ..cubicTo(
        size.width * 0.27,
        size.height * 0.30,
        size.width * 0.58,
        size.height * 0.52,
        size.width + 8,
        size.height * 0.40,
      );
    final diagonal = Path()
      ..moveTo(size.width * 0.23, size.height + 8)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.70,
        size.width * 0.29,
        size.height * 0.30,
        size.width * 0.54,
        -8,
      );
    final side = Path()
      ..moveTo(size.width * 0.90, size.height + 8)
      ..cubicTo(
        size.width * 0.81,
        size.height * 0.70,
        size.width * 0.73,
        size.height * 0.36,
        size.width * 0.84,
        -8,
      );
    canvas.drawPath(horizontal, road);
    canvas.drawPath(diagonal, road);
    canvas.drawPath(side, fineRoad);
    final blocks = Paint()
      ..color = landColor.withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.62,
          size.height * 0.12,
          size.width * 0.12,
          size.height * 0.16,
        ),
        const Radius.circular(BatshRadius.xs),
      ),
      blocks,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.62,
          size.width * 0.16,
          size.height * 0.2,
        ),
        const Radius.circular(BatshRadius.xs),
      ),
      blocks,
    );
  }

  @override
  bool shouldRepaint(covariant _SchematicMapPainter oldDelegate) =>
      roadColor != oldDelegate.roadColor || landColor != oldDelegate.landColor;
}

class _OpportunityTiming extends StatelessWidget {
  const _OpportunityTiming({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final timing = brief.startTiming;
    return _DetailSection(
      title: context.l10n.opportunityDetailTiming,
      icon: Icons.schedule_outlined,
      child: _TimingTile(
        icon: Icons.calendar_month_outlined,
        label: context.l10n.opportunityDetailStartLabel,
        value: _timingLabel(context, timing),
      ),
    );
  }
}

class _TimingTile extends StatelessWidget {
  const _TimingTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(BatshSpacing.sm),
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerLow.withValues(alpha: 0.72),
      borderRadius: BatshRadius.brMd,
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: context.colorScheme.primary,
          size: BatshIconSize.action,
        ),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxxs),
              Text(
                value,
                style: BatshTypography.labelLg.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OpportunityOwner extends StatelessWidget {
  const _OpportunityOwner({
    required this.profile,
    required this.loading,
    required this.onTap,
  });

  final PublicHomeownerProfile? profile;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _DetailSection(
    title: context.l10n.opportunityDetailOwner,
    icon: Icons.person_outline_rounded,
    child: Material(
      color: context.colorScheme.surfaceContainerLow.withValues(alpha: 0.56),
      borderRadius: BatshRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.all(BatshSpacing.sm),
          child: loading
              ? const Row(
                  children: [
                    Expanded(child: BatshShimmerBox(width: 120, height: 18)),
                    SizedBox(width: BatshSpacing.sm),
                    BatshShimmerBox(
                      width: 52,
                      height: 52,
                      borderRadius: BatshRadius.brFull,
                    ),
                  ],
                )
              : _OwnerIdentity(profile: profile),
        ),
      ),
    ),
  );
}

class _OwnerIdentity extends StatelessWidget {
  const _OwnerIdentity({required this.profile});

  final PublicHomeownerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profileName = profile?.profile.fullName.trim() ?? '';
    final name = profileName.isEmpty
        ? context.l10n.opportunityPostedBy
        : profileName;
    final district = profile?.details?.district?.trim();
    final city = profile?.details?.city?.trim();
    final locationParts = [
      if (district != null && district.isNotEmpty)
        localizedOnboardingDistrictLabel(context, district),
      if (city != null && city.isNotEmpty)
        localizedOnboardingCityLabel(context, city),
    ];
    final location = locationParts.join('، ');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.opportunityPostedBy,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxxs),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.titleMd.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: BatshSpacing.xxxs),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: BatshSpacing.sm),
        AvatarWithInitials(
          imageUrl: profile?.profile.avatarUrl,
          name: name,
          radius: 26,
        ),
      ],
    );
  }
}

class _OpportunityAdvice extends StatelessWidget {
  const _OpportunityAdvice({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(
      BatshSpacing.md,
      BatshSpacing.xs,
      BatshSpacing.md,
      BatshSpacing.sm,
    ),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.colorScheme.primaryContainer,
      borderRadius: BatshRadius.brLg,
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          end: -BatshSpacing.xl,
          bottom: -BatshSpacing.lg,
          width: 164,
          height: 126,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.14,
              child: ShattabPattern(
                kind: ShattabPatternKind.arches,
                color: context.colorScheme.primary,
                strokeWidth: 1.1,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(BatshSpacing.sm),
          child: Row(
            children: [
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(92, BatshSpacing.xxxl),
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BatshRadius.brMd,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: BatshSpacing.xs,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.workUpdateProfile,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.xxs),
                    const Icon(Icons.chevron_left_rounded),
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Expanded(
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: context.colorScheme.primary,
                        size: BatshIconSize.xl,
                      ),
                      const SizedBox(width: BatshSpacing.xs),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.l10n.opportunityDetailAdviceTitle,
                              textAlign: TextAlign.end,
                              style: BatshTypography.titleMd.copyWith(
                                fontSize: 16,
                                height: 1.35,
                                color: context.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: BatshSpacing.xxxs),
                            Text(
                              context.l10n.opportunityDetailAdviceBody,
                              textAlign: TextAlign.end,
                              style: BatshTypography.labelSm.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    this.child,
    this.padding = const EdgeInsets.all(BatshSpacing.md),
  });

  final String? title;
  final IconData? icon;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(
      horizontal: BatshSpacing.md,
      vertical: BatshSpacing.xxs,
    ),
    padding: padding,
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerLowest.withValues(alpha: 0.74),
      borderRadius: BatshRadius.brLg,
      border: Border.all(
        color: context.colorScheme.outlineVariant.withValues(alpha: 0.38),
      ),
      boxShadow: BatshShadows.soft,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null && icon != null)
          Row(
            children: [
              Icon(
                icon,
                size: BatshIconSize.action,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Expanded(
                child: Text(
                  title!,
                  textAlign: TextAlign.start,
                  style: BatshTypography.titleMd.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        if (child != null) ...[
          if (title != null) const SizedBox(height: BatshSpacing.sm),
          child!,
        ],
      ],
    ),
  );
}

class _OpportunityStickyAction extends StatelessWidget {
  const _OpportunityStickyAction({
    required this.brief,
    required this.quote,
    required this.quoteLoading,
    required this.quoteFailed,
    required this.profileReady,
    required this.onApply,
    required this.onFollowQuote,
    required this.onCompleteProfile,
    required this.onRetryQuoteState,
  });

  final Brief brief;
  final Quote? quote;
  final bool quoteLoading;
  final bool quoteFailed;
  final bool profileReady;
  final VoidCallback onApply;
  final VoidCallback onFollowQuote;
  final VoidCallback onCompleteProfile;
  final VoidCallback onRetryQuoteState;

  @override
  Widget build(BuildContext context) {
    final String label;
    final VoidCallback? action;
    final bool loading;
    if (!brief.isActive) {
      label = context.l10n.opportunityClosed;
      action = null;
      loading = false;
    } else if (quoteLoading) {
      label = context.l10n.opportunityDetailQuoteStateLoading;
      action = null;
      loading = true;
    } else if (quoteFailed) {
      label = context.l10n.opportunityDetailRetryQuoteState;
      action = onRetryQuoteState;
      loading = false;
    } else if (quote != null) {
      label = context.l10n.followQuoteAction;
      action = onFollowQuote;
      loading = false;
    } else if (!profileReady) {
      label = context.l10n.completeProfileBeforeApplying;
      action = onCompleteProfile;
      loading = false;
    } else {
      label = context.l10n.opportunityDetailApplyAction;
      action = onApply;
      loading = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.48),
          ),
        ),
        boxShadow: BatshShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.md,
            BatshSpacing.sm,
            BatshSpacing.md,
            BatshSpacing.sm,
          ),
          child: _PageWidth(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: action,
                icon: loading
                    ? SizedBox.square(
                        dimension: BatshIconSize.action,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        quote != null && !quoteFailed
                            ? Icons.receipt_long_outlined
                            : quoteFailed
                            ? Icons.refresh_rounded
                            : Icons.send_rounded,
                      ),
                label: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelLg.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  disabledBackgroundColor:
                      context.colorScheme.surfaceContainerHigh,
                  disabledForegroundColor: context.colorScheme.onSurfaceVariant,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BatshRadius.brMd,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityDetailSkeleton extends StatelessWidget {
  const _OpportunityDetailSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: BatshSpacing.xxxxl),
    children: const [
      BatshShimmerBox(width: double.infinity, height: 286),
      SizedBox(height: BatshSpacing.md),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        child: BatshShimmerBox(width: 120, height: 24),
      ),
      SizedBox(height: BatshSpacing.sm),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        child: BatshShimmerBox(width: double.infinity, height: 28),
      ),
      SizedBox(height: BatshSpacing.md),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        child: BatshShimmerBox(
          width: double.infinity,
          height: 116,
          borderRadius: BatshRadius.brLg,
        ),
      ),
    ],
  );
}

String _opportunityTitle(BuildContext context, Brief brief) {
  final title = brief.projectTitle?.trim();
  if (title != null && title.isNotEmpty) return title;
  return opportunityHeadline(brief.workDescription, maxLength: 90);
}

String _rawLocation(Brief brief) => [brief.district, brief.city]
    .whereType<String>()
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .join('، ');

String _localizedLocation(BuildContext context, Brief brief) {
  final parts = <String>[];
  final district = brief.district?.trim();
  final city = brief.city.trim();
  if (district != null && district.isNotEmpty) {
    parts.add(localizedOnboardingDistrictLabel(context, district));
  }
  if (city.isNotEmpty) parts.add(localizedOnboardingCityLabel(context, city));
  return parts.join('، ');
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

String _timingLabel(BuildContext context, String? value) => switch (value) {
  'flexible' => context.l10n.startFlexible,
  'within_month' => context.l10n.startWithinMonth,
  'within_3_months' => context.l10n.startWithinThreeMonths,
  _ => context.l10n.notSpecified,
};

void _shareOpportunity(BuildContext context, Brief brief) {
  final title = _opportunityTitle(context, brief);
  final location = _localizedLocation(context, brief);
  final parts = [title, if (location.isNotEmpty) location];
  Share.share(parts.join('\n'), subject: title);
}

Future<void> _copyOpportunitySummary(BuildContext context, Brief brief) async {
  final title = _opportunityTitle(context, brief);
  final location = _localizedLocation(context, brief);
  final summary = [
    title,
    if (location.isNotEmpty) location,
    brief.workDescription,
  ].join('\n');
  try {
    await Clipboard.setData(ClipboardData(text: summary));
    if (context.mounted) {
      BatshSnack.info(context, context.l10n.copiedToast);
    }
  } catch (_) {
    if (context.mounted) {
      BatshSnack.error(context, context.l10n.somethingWentWrong);
    }
  }
}
