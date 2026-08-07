import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import 'providers/discovery_providers.dart';
import 'widgets/public_professional_profile.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Public contractor profile — what a homeowner sees from Discover.
/// Resolves the listing and hosts the focused customer-facing profile.
class ContractorProfileScreen extends ConsumerWidget {
  const ContractorProfileScreen({super.key, required this.contractorId});

  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contractorByIdProvider(contractorId));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: BatshProfileSkeleton(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(contractorByIdProvider(contractorId)),
        ),
      ),
      data: (c) {
        if (c == null) {
          return Scaffold(
            backgroundColor: context.colorScheme.surface,
            body: BatshEmptyState(
              title: context.l10n.contractorNotFound,
              message: context.l10n.contractorNotFoundMsg,
              icon: Icons.person_off_outlined,
            ),
          );
        }
        return Scaffold(
          backgroundColor: context.colorScheme.surface,
          body: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(contractorByIdProvider(contractorId)),
            child: PublicProfessionalProfile(listing: c),
          ),
          bottomNavigationBar: ProfessionalProfileActionBar(listing: c),
        );
      },
    );
  }
}
