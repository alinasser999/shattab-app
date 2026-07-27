import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/models/draft_photo.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/photo_picker.dart';
import '../data/verification_repository.dart';
import '../../../core/theme/batsh_icon_size.dart';

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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(S.verifyDocsRequired)));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(verificationRepositoryProvider).submit(
            docs: _docs,
            note: _noteController.text,
          );
      ref.invalidate(verificationStatusProvider);
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(S.verifyError)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(verificationStatusProvider).value;
    return Scaffold(
      backgroundColor: BatshColors.surface,
      appBar: AppBar(title: Text(S.verifyTitle)),
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
              color: BatshColors.surfaceContainerLowest,
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
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          BatshColors.tertiaryContainer,
                          BatshColors.tertiary,
                        ]),
                      ),
                      child: const Icon(Icons.verified_rounded,
                          color: BatshColors.onTertiaryContainer, size: BatshIconSize.lg),
                    ),
                    const SizedBox(width: BatshSpacing.md),
                    Expanded(
                      child: Text(S.verifyHeadline,
                          style: BatshTypography.titleMd
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.md),
                _Bullet(S.verifyBenefitTrust),
                _Bullet(S.verifyBenefitRanking),
                _Bullet(S.verifyBenefitFree),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          Text(S.verifyUploadLabel, style: BatshTypography.labelLg),
          const SizedBox(height: BatshSpacing.xxs),
          Text(S.verifyUploadHint,
              style: BatshTypography.bodySm
                  .copyWith(color: BatshColors.onSurfaceVariant)),
          const SizedBox(height: BatshSpacing.sm),
          PhotoPicker(
            maxPhotos: 3,
            onChanged: (photos) => setState(() => _docs = photos),
          ),
          const SizedBox(height: BatshSpacing.lg),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(labelText: S.verifyNoteLabel),
          ),
          const SizedBox(height: BatshSpacing.xl),
          BatshButton(
            label: S.verifySubmit,
            icon: Icons.send_rounded,
            isLoading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(S.verifyPrivacyNote,
              textAlign: TextAlign.center,
              style: BatshTypography.labelSm
                  .copyWith(color: BatshColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _pending() => _StatusView(
        icon: Icons.hourglass_top_rounded,
        color: BatshColors.tertiary,
        title: S.verifyPendingTitle,
        body: S.verifyPendingBody,
      );

  Widget _approved() => _StatusView(
        icon: Icons.verified_rounded,
        color: BatshColors.secondary,
        title: S.verifyApprovedTitle,
        body: S.verifyApprovedBody,
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
          const Icon(Icons.check_circle_rounded,
              size: BatshIconSize.md, color: BatshColors.secondary),
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
            Text(title,
                textAlign: TextAlign.center,
                style: BatshTypography.headlineSm),
            const SizedBox(height: BatshSpacing.sm),
            Text(body,
                textAlign: TextAlign.center,
                style: BatshTypography.bodyMd
                    .copyWith(color: BatshColors.onSurfaceVariant)),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.verifyDone,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
