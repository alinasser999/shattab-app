import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/contact_buttons.dart';
import '../domain/contractor_listing.dart';
import 'providers/discovery_providers.dart';
import 'widgets/contractor_showcase.dart';

/// Public contractor profile — what a homeowner sees from Discover.
/// The rich body lives in [ContractorShowcase]; this screen resolves the
/// listing, supplies the [Scaffold], and pins the contact CTA to the bottom so
/// the primary action stays reachable no matter how far the user scrolls.
class ContractorProfileScreen extends ConsumerWidget {
  const ContractorProfileScreen({super.key, required this.contractorId});

  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contractorByIdProvider(contractorId));

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: BatshColors.background,
        body: BatshProfileSkeleton(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: BatshColors.background,
        body: BatshError(
          message: ErrorMapper.map(e),
          onRetry: () =>
              ref.invalidate(contractorByIdProvider(contractorId)),
        ),
      ),
      data: (c) {
        if (c == null) {
          return Scaffold(
            backgroundColor: BatshColors.background,
            body: BatshEmptyState(
              title: S.contractorNotFound,
              message: S.contractorNotFoundMsg,
              icon: Icons.person_off_outlined,
            ),
          );
        }
        return Scaffold(
          backgroundColor: BatshColors.background,
          body: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(contractorByIdProvider(contractorId)),
            child: ContractorShowcase(
              listing: c,
              mode: ShowcaseMode.public,
              showInlineContact: false,
            ),
          ),
          bottomNavigationBar: _StickyContactBar(listing: c),
        );
      },
    );
  }
}

/// Pinned bottom contact bar — primary "send brief" CTA plus WhatsApp/Call.
/// Sits above the gesture/safe area; the showcase reserves trailing scroll
/// space so nothing is hidden behind it.
class _StickyContactBar extends StatelessWidget {
  const _StickyContactBar({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: BatshColors.outlineVariant),
        ),
        boxShadow: BatshShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.marginMobile,
            BatshSpacing.md,
            BatshSpacing.marginMobile,
            BatshSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BatshButton(
                label: S.sendProjectDetails,
                onPressed: () =>
                    context.push(Routes.homeownerSendBriefPath(listing.id)),
              ),
              const SizedBox(height: BatshSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: WhatsAppButton(
                      phone: listing.phone,
                      message: S.profileGreeting,
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.sm),
                  Expanded(child: CallButton(phone: listing.phone)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
