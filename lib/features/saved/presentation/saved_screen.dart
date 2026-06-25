import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_loading.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/contractor_card.dart';
import 'providers/saved_providers.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedContractorsProvider);

    return BatshScaffold(
      title: S.tabSaved,
      body: async.when(
        loading: () => const BatshLoading(),
        error: (e, _) => BatshError(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const BatshEmptyState(
              title: 'مفيش مقاولين محفوظين لسه',
              message: 'اضغط على القلب جنب أي مقاول عشان تحفظه هنا.',
              icon: Icons.favorite_border,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: BatshSpacing.md),
            itemBuilder: (context, i) {
              final c = list[i];
              return ContractorCard(
                listing: c,
                isSaved: true,
                onToggleSave: () =>
                    ref.read(savedControllerProvider.notifier).toggle(c.id),
                onTap: () => context
                    .push(Routes.homeownerContractorProfilePath(c.id)),
              );
            },
          );
        },
      ),
    );
  }
}
