import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_shimmer.dart';
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
          // Same widget the showcase renders inline, so the two cannot drift.
          bottomNavigationBar: ContractorContactBar(listing: c, sticky: true),
        );
      },
    );
  }
}
