import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/models/draft_photo.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/photo_picker.dart';
import '../data/verification_repository.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Free "Verified" flow: contractor uploads ID + optional trade licence, we file
/// a pending request, a founder reviews it and flips the badge. Mirrors the
/// InstaPay manual-verify pattern.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _noteController = TextEditingController();
  List<DraftPhoto> _docs = const [];
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_docs.isEmpty) {
      BatshSnack.error(context, context.l10n.verifyDocsRequired);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(verificationRepositoryProvider)
          .submit(docs: _docs, note: _noteController.text);
      ref.invalidate(verificationStatusProvider);
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        BatshSnack.error(context, context.l10n.verifyError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(verificationStatusProvider).value;
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(title: Text(context.l10n.verifyTitle)),
      body: _submitted || status == VerificationStatus.pending
          ? _pending()
          : status == VerificationStatus.approved
          ? _approved()
          : _form(),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // What the badge is + why it earns trust.
          Container(
            padding: const EdgeInsets.all(BatshSpacing.lg),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
              borderRadius: BatshRadius.brLg,
              boxShadow: BatshShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            context.colorScheme.tertiaryContainer,
                            context.colorScheme.tertiary,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        color: context.colorScheme.onTertiaryContainer,
                        size: BatshIconSize.lg,
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.md),
                    Expanded(
                      child: Text(
                        context.l10n.verifyHeadline,
                        style: BatshTypography.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.md),
                _Bullet(context.l10n.verifyBenefitTrust),
                _Bullet(context.l10n.verifyBenefitRanking),
                _Bullet(context.l10n.verifyBenefitFree),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Text(context.l10n.verifyUploadLabel, style: BatshTypography.labelLg),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            context.l10n.verifyUploadHint,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          PhotoPicker(
            maxPhotos: 3,
            onChanged: (photos) => setState(() => _docs = photos),
          ),
          const SizedBox(height: BatshSpacing.lg),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.l10n.verifyNoteLabel,
            ),
          ),
          const SizedBox(height: BatshSpacing.xl),
          BatshButton(
            label: context.l10n.verifySubmit,
            icon: Icons.send_rounded,
            isLoading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            context.l10n.verifyPrivacyNote,
            textAlign: TextAlign.center,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pending() => _StatusView(
    icon: Icons.hourglass_top_rounded,
    color: context.colorScheme.tertiary,
    title: context.l10n.verifyPendingTitle,
    body: context.l10n.verifyPendingBody,
  );

  Widget _approved() => _StatusView(
    icon: Icons.verified_rounded,
    color: context.colorScheme.secondary,
    title: context.l10n.verifyApprovedTitle,
    body: context.l10n.verifyApprovedBody,
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BatshSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: BatshIconSize.md,
            color: context.colorScheme.secondary,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(child: Text(text, style: BatshTypography.bodyMd)),
        ],
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: BatshIconSize.xxl, color: color),
            const SizedBox(height: BatshSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineSm,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: context.l10n.verifyDone,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
