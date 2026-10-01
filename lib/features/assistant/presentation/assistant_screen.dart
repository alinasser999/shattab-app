// Arabic-first in-app assistant surface.
//
// The assistant explains and narrows the request. Real professionals are
// always loaded from DiscoveryRepository and never invented by the model.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/analytics/app_analytics.dart';
import 'package:batsh/core/analytics/marketplace_events.dart';
import 'package:batsh/core/l10n/catalog_labels.dart';
import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/core/router/routes.dart';
import 'package:batsh/core/theme/batsh_icon_size.dart';
import 'package:batsh/core/theme/batsh_spacing.dart';
import 'package:batsh/core/theme/batsh_typography.dart';
import 'package:batsh/core/theme/theme_extension.dart';
import 'package:batsh/core/widgets/avatar_with_initials.dart';
import 'package:batsh/core/widgets/batsh_badge.dart';
import 'package:batsh/core/widgets/batsh_button.dart';
import 'package:batsh/core/widgets/batsh_card.dart';
import 'package:batsh/core/widgets/batsh_chip.dart';
import 'package:batsh/core/widgets/batsh_pressable.dart';
import 'package:batsh/core/widgets/batsh_scaffold.dart';
import 'package:batsh/core/widgets/batsh_text_field.dart';
import 'package:batsh/features/auth/presentation/providers/auth_provider.dart';
import 'package:batsh/features/auth/presentation/sign_in_sheet.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';

import '../domain/assistant_message.dart';
import '../domain/specialty_catalog.dart';
import 'providers/assistant_providers.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.isHomeowner = true});

  final bool isHomeowner;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  String? _lastSubmittedText;

  bool get _isHomeowner => widget.isHomeowner;

  @override
  void initState() {
    super.initState();
    AppAnalytics.track(
      MarketplaceEvents.assistantOpened,
      properties: {'audience_homeowner': widget.isHomeowner},
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend({
    String? presetText,
    bool isQuickPrompt = false,
  }) async {
    final text = (presetText ?? _inputController.text).trim();
    if (text.isEmpty) return;

    _lastSubmittedText = text;
    if (isQuickPrompt) {
      AppAnalytics.track(
        MarketplaceEvents.assistantQuickPromptSelected,
        properties: const {},
      );
    }

    if (ref.read(currentSessionProvider) == null) {
      final completed = await showSignInSheet(
        context,
        reason: context.l10n.assistantSignInRequired,
      );
      if (!completed || !mounted || ref.read(currentSessionProvider) == null) {
        return;
      }
    }

    if (presetText == null) _inputController.clear();
    await ref
        .read(assistantChatProvider.notifier)
        .sendMessage(
          text,
          resolveContractors: _isHomeowner,
          audience: _isHomeowner ? 'homeowner' : 'contractor',
        );
    if (mounted) _scrollToBottom();
  }

  void _handleHelpAction(String actionId) {
    AppAnalytics.track(
      MarketplaceEvents.assistantHelpActionSelected,
      properties: {'action': actionId},
    );

    final route = SpecialtyCatalog.resolveHelpActionRoute(
      actionId,
      isHomeowner: _isHomeowner,
    );
    if (route != null) context.push(route);
  }

  void _openDiscovery({String? specialty, String? city}) {
    if (!_isHomeowner) return;
    final filters = ref.read(discoveryFiltersControllerProvider.notifier);
    filters.setSpecialty(specialty);
    filters.setCity(city);
    context.push(Routes.homeownerDiscover);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantChatProvider);
    final l10n = context.l10n;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BatshScaffold(
        title: l10n.assistantTitle,
        padding: EdgeInsets.zero,
        showPattern: false,
        actions: [
          Tooltip(
            message: l10n.assistantClear,
            child: BatshPressable(
              onTap: () => ref.read(assistantChatProvider.notifier).clearChat(),
              semanticLabel: l10n.assistantClear,
              child: SizedBox(
                width: BatshSpacing.xxxl,
                height: BatshSpacing.xxxl,
                child: Icon(
                  Icons.refresh_rounded,
                  size: BatshIconSize.nav,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            _buildPrivacyBanner(context),
            if (state.errorMessage != null) _buildErrorCard(context),
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyState(context)
                  : _buildMessageList(context, state),
            ),
            _buildComposer(context, state.isThinking),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyBanner(BuildContext context) {
    return Semantics(
      label: context.l10n.assistantPrivacyNotice,
      child: Container(
        width: double.infinity,
        color: context.colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.md,
          vertical: BatshSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: BatshIconSize.inline,
              color: context.colorScheme.secondary,
            ),
            const SizedBox(width: BatshSpacing.xs),
            Flexible(
              child: Text(
                context.l10n.assistantPrivacyNotice,
                textAlign: TextAlign.center,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final prompts = [
      context.l10n.assistantQuickPromptPlumber,
      context.l10n.assistantQuickPromptFinishing,
      context.l10n.assistantQuickPromptPaint,
      context.l10n.assistantQuickPromptKitchen,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(BatshSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BatshCard(
            primary: true,
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: BatshIconSize.empty,
                  color: context.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: BatshSpacing.md),
                Text(
                  context.l10n.assistantEmptyTitle,
                  textAlign: TextAlign.center,
                  style: BatshTypography.headlineSm.copyWith(
                    color: context.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  context.l10n.assistantEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.xl),
          Text(
            context.l10n.assistantStarterHeading,
            style: BatshTypography.titleMd.copyWith(
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          for (var index = 0; index < prompts.length; index++) ...[
            BatshCard(
              onTap: () =>
                  _handleSend(presetText: prompts[index], isQuickPrompt: true),
              padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.md,
                vertical: BatshSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: BatshIconSize.action,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: BatshSpacing.sm),
                  Expanded(
                    child: Text(
                      prompts[index],
                      style: BatshTypography.bodyMd.copyWith(
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    size: BatshIconSize.inline,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            if (index != prompts.length - 1)
              const SizedBox(height: BatshSpacing.xs),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, AssistantChatState state) {
    final itemCount = state.messages.length + (state.isThinking ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.sm,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == state.messages.length && state.isThinking) {
          return _buildThinkingCard(context);
        }
        final message = state.messages[index];
        return message.isUser
            ? _buildUserCard(context, message)
            : _buildAssistantCard(context, message);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, AssistantMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
          child: BatshCard(
            primary: true,
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.md,
              vertical: BatshSpacing.sm,
            ),
            child: Text(
              message.content,
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantCard(BuildContext context, AssistantMessage message) {
    final envelope = message.envelope;
    final contractors = message.matchingContractors;
    final actionId = envelope?.helpActionId;
    final actionRoute = SpecialtyCatalog.resolveHelpActionRoute(
      actionId,
      isHomeowner: _isHomeowner,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.only(bottom: BatshSpacing.lg),
          child: BatshCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: BatshIconSize.action,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Text(
                      context.l10n.assistantTitle,
                      style: BatshTypography.labelLg.copyWith(
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  message.content,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.onSurface,
                  ),
                ),
                if (envelope?.nextQuestion != null) ...[
                  const SizedBox(height: BatshSpacing.md),
                  BatshCard(
                    primary: true,
                    padding: const EdgeInsets.all(BatshSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: BatshIconSize.action,
                          color: context.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: BatshSpacing.xs),
                        Expanded(
                          child: Text(
                            envelope!.nextQuestion!,
                            style: BatshTypography.bodyMd.copyWith(
                              color: context.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_isHomeowner && contractors.isNotEmpty) ...[
                  const SizedBox(height: BatshSpacing.md),
                  Text(
                    context.l10n.assistantFoundContractors,
                    style: BatshTypography.titleMd.copyWith(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  for (final contractor in contractors)
                    _buildContractorPreview(context, contractor),
                  const SizedBox(height: BatshSpacing.xs),
                  BatshButton(
                    label: context.l10n.assistantShowResults,
                    style: BatshButtonStyle.secondary,
                    onPressed: () => _openDiscovery(
                      specialty: envelope?.specialtyKey,
                      city: envelope?.cityKey,
                    ),
                  ),
                ],
                if (actionId != null && actionRoute != null) ...[
                  const SizedBox(height: BatshSpacing.sm),
                  BatshButton(
                    label: _actionLabel(context, actionId),
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => _handleHelpAction(actionId),
                  ),
                ],
                if (envelope != null && envelope.quickReplies.isNotEmpty) ...[
                  const SizedBox(height: BatshSpacing.sm),
                  Wrap(
                    spacing: BatshSpacing.xs,
                    runSpacing: BatshSpacing.xs,
                    children: [
                      for (final reply in envelope.quickReplies)
                        BatshChip(
                          label: reply,
                          compact: true,
                          onTap: () => _handleSend(
                            presetText: reply,
                            isQuickPrompt: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContractorPreview(
    BuildContext context,
    ContractorListing contractor,
  ) {
    final name = contractor.businessName.trim().isNotEmpty
        ? contractor.businessName
        : contractor.fullName.trim().isNotEmpty
        ? contractor.fullName
        : context.l10n.professionalSingular;
    final trade = contractor.specialties.isNotEmpty
        ? localizedSpecialtyLabel(context, contractor.specialties.first)
        : contractor.providerKind.label(context);
    final area = contractor.serviceAreas.isNotEmpty
        ? contractor.serviceAreas.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.xs),
      child: BatshCard(
        onTap: _isHomeowner
            ? () => context.push(
                Routes.homeownerContractorProfilePath(contractor.id),
              )
            : null,
        padding: const EdgeInsets.all(BatshSpacing.sm),
        child: Row(
          children: [
            AvatarWithInitials(
              imageUrl: contractor.logoUrl,
              name: name,
              radius: BatshSpacing.lg,
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelLg.copyWith(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    [trade, area]
                        .whereType<String>()
                        .where((value) => value.trim().isNotEmpty)
                        .join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (contractor.verified || contractor.hasReviews)
                    Padding(
                      padding: const EdgeInsets.only(top: BatshSpacing.xs),
                      child: Wrap(
                        spacing: BatshSpacing.xs,
                        runSpacing: BatshSpacing.xs,
                        children: [
                          if (contractor.verified)
                            BatshBadge(
                              label: context.l10n.verifiedStatus,
                              tone: BatshBadgeTone.brand,
                              compact: true,
                            ),
                          if (contractor.hasReviews)
                            BatshBadge(
                              label:
                                  '${contractor.reviewAvg.toStringAsFixed(1)} (${contractor.reviewCount})',
                              icon: Icons.star_rounded,
                              tone: BatshBadgeTone.warning,
                              compact: true,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (_isHomeowner)
              Icon(
                Icons.arrow_back_ios_rounded,
                size: BatshIconSize.inline,
                color: context.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingCard(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: BatshSpacing.md),
        child: BatshCard(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.md,
            vertical: BatshSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz_rounded,
                size: BatshIconSize.action,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                context.l10n.assistantThinking,
                style: BatshTypography.bodySm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.sm,
        BatshSpacing.md,
        0,
      ),
      child: BatshCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.assistantErrorFallback,
                style: BatshTypography.bodySm.copyWith(
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: BatshButton(
                label: context.l10n.assistantRetry,
                style: BatshButtonStyle.ghost,
                fullWidth: false,
                onPressed: _lastSubmittedText == null
                    ? null
                    : () => _handleSend(presetText: _lastSubmittedText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context, bool isThinking) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.sm),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: BatshTextField(
              controller: _inputController,
              hint: context.l10n.assistantInputHint,
              maxLines: 3,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: BatshSpacing.xs),
          SizedBox(
            width: 112,
            child: BatshButton(
              label: context.l10n.assistantSend,
              icon: Icons.send_rounded,
              fullWidth: false,
              isLoading: isThinking,
              onPressed: isThinking ? null : () => _handleSend(),
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(BuildContext context, String actionId) {
    return switch (actionId) {
      'post_brief' => context.l10n.assistantActionPostBrief,
      'browse_contractors' => context.l10n.assistantActionBrowse,
      'view_portfolio' => context.l10n.assistantActionViewPortfolio,
      'pricing_info' => context.l10n.assistantActionPricing,
      'contact_support' => context.l10n.assistantActionSupport,
      _ => context.l10n.assistantActionBrowse,
    };
  }
}
