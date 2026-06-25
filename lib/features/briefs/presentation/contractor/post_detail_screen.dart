import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../providers/briefs_providers.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  Future<({String name, String phone})?> _fetchHomeowner(
      SupabaseClient client, String id) async {
    final row = await client
        .from('profiles')
        .select('full_name, phone')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return (
      name: (row['full_name'] as String?) ?? '',
      phone: (row['phone'] as String?) ?? ''
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(briefByIdProvider(postId));

    return BatshScaffold(
      title: 'تفاصيل البوست',
      body: async.when(
        loading: () => const BatshLoading(),
        error: (e, _) => BatshError(message: e.toString()),
        data: (brief) {
          if (brief == null) {
            return const BatshError(message: 'البوست مش موجود');
          }
          final client = ref.watch(supabaseClientProvider);
          return FutureBuilder(
            future: _fetchHomeowner(client, brief.homeownerId),
            builder: (context, snap) {
              final homeowner = snap.data;
              final date = intl.DateFormat.yMMMd('ar').format(brief.createdAt);
              return ListView(
                children: [
                  const SizedBox(height: BatshSpacing.md),
                  if (brief.photoUrls.isNotEmpty) ...[
                    PhotoGallery(urls: brief.photoUrls),
                    const SizedBox(height: BatshSpacing.lg),
                  ],
                  BatshCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وصف الشغل',
                            style: BatshTypography.labelMd.copyWith(
                                color: BatshColors.onSurfaceVariant)),
                        const SizedBox(height: BatshSpacing.sm),
                        Text(brief.workDescription,
                            style: BatshTypography.bodyLg),
                      ],
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.gutter),
                  BatshCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تفاصيل المكان',
                            style: BatshTypography.labelMd.copyWith(
                                color: BatshColors.onSurfaceVariant)),
                        const SizedBox(height: BatshSpacing.sm),
                        Text(
                          '${OnboardingCatalog.apartmentLabels[brief.apartmentType] ?? brief.apartmentType.name} · ${brief.city}${brief.district != null ? ' · ${brief.district}' : ''}',
                          style: BatshTypography.bodyLg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.gutter),
                  BatshCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('صاحب البوست',
                            style: BatshTypography.labelMd.copyWith(
                                color: BatshColors.onSurfaceVariant)),
                        const SizedBox(height: BatshSpacing.sm),
                        Text(homeowner?.name ?? '...',
                            style: BatshTypography.bodyLg),
                        const SizedBox(height: BatshSpacing.xs),
                        Text('اتنشر: $date',
                            style: BatshTypography.labelMd.copyWith(
                                color: BatshColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xl),
                  if (homeowner != null && homeowner.phone.isNotEmpty) ...[
                    WhatsAppButton(
                      phone: homeowner.phone,
                      message:
                          'السلام عليكم، شفت بوستك على شطب وحبيت أعرف أكتر عن الشغل',
                    ),
                    const SizedBox(height: BatshSpacing.sm),
                    CallButton(phone: homeowner.phone),
                  ],
                  const SizedBox(height: BatshSpacing.lg),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
