import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/l10n_extension.dart';
import '../../../../../core/theme/batsh_icon_size.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/batsh_card.dart';
import '../../../../../core/widgets/contact_buttons.dart';
import '../../../../auth/presentation/providers/homeowner_contact_provider.dart';

/// Shared contractor-only contact UI for brief details. The server RPC is the
/// sole source of entitlement; this widget never guesses from the local plan.
class ContractorHomeownerContact extends ConsumerWidget {
  const ContractorHomeownerContact({super.key, required this.briefId});

  final String briefId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(homeownerContactForBriefProvider(briefId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.sm,
      ),
      child: BatshCard(
        child: contactAsync.when(
          loading: () => Semantics(
            liveRegion: true,
            label: context.l10n.contactLoading,
            child: Row(
              children: [
                SizedBox.square(
                  dimension: BatshIconSize.sm,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.contactLoading,
                    textAlign: TextAlign.end,
                    style: BatshTypography.bodyMd,
                  ),
                ),
              ],
            ),
          ),
          error: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  context.l10n.contactLoadFailed,
                  textAlign: TextAlign.end,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: BatshSpacing.sm),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(homeownerContactForBriefProvider(briefId)),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.tryAgain),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
                ),
              ),
            ],
          ),
          data: (contact) {
            final phone = contact?.phone.trim() ?? '';
            if (contact == null || phone.isEmpty) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: BatshIconSize.md,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: BatshSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.requestsProtectedContact,
                          textAlign: TextAlign.end,
                          style: BatshTypography.titleMd,
                        ),
                        const SizedBox(height: BatshSpacing.xs),
                        Text(
                          context.l10n.contactAccessHint,
                          textAlign: TextAlign.end,
                          style: BatshTypography.bodySm.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.contactClient,
                  textAlign: TextAlign.end,
                  style: BatshTypography.titleMd,
                ),
                if (contact.name.trim().isNotEmpty) ...[
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    contact.name.trim(),
                    textAlign: TextAlign.end,
                    style: BatshTypography.bodyMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: BatshSpacing.md),
                WhatsAppButton(phone: phone),
                const SizedBox(height: BatshSpacing.sm),
                CallButton(phone: phone),
              ],
            );
          },
        ),
      ),
    );
  }
}
