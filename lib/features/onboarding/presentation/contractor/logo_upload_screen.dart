import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../providers/onboarding_provider.dart';

class LogoUploadScreen extends ConsumerStatefulWidget {
  const LogoUploadScreen({super.key});

  @override
  ConsumerState<LogoUploadScreen> createState() => _LogoUploadScreenState();
}

class _LogoUploadScreenState extends ConsumerState<LogoUploadScreen> {
  File? _picked;
  bool _busy = false;

  Future<void> _pick() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (result != null) {
      setState(() => _picked = File(result.path));
    }
  }

  Future<void> _next({bool skip = false}) async {
    setState(() => _busy = true);
    try {
      if (!skip && _picked != null) {
        await ref
            .read(onboardingControllerProvider.notifier)
            .uploadLogo(_picked!);
      }
      if (!mounted) return;
      context.go(Routes.onboardingContractorExperience);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(contractorProfileProvider).value;
    final existingUrl = existing?.logoUrl;
    final isMobile = context.isMobile;

    return BatshScaffold(
      title: S.logoUploadTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.logoUploadTitle,
              style: isMobile
                  ? BatshTypography.headlineLgMobile
                  : BatshTypography.headlineLg,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              S.logoUploadHint,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Center(
              child: GestureDetector(
                onTap: _pick,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: BatshColors.surfaceContainer,
                    borderRadius: BatshRadius.brXl,
                    border: Border.all(
                      color: BatshColors.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BatshRadius.brXl,
                    child: _picked != null
                        ? Image.file(_picked!, fit: BoxFit.cover)
                        : (existingUrl != null
                            ? CachedNetworkImage(
                                imageUrl: existingUrl,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  color: BatshColors.onSurfaceVariant,
                                  size: 36,
                                ),
                              )),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Center(
              child: TextButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.image_outlined),
                label: const Text(S.chooseImage),
              ),
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.next,
              onPressed: _busy ? null : () => _next(),
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.md),
            BatshButton(
              label: S.skip,
              style: BatshButtonStyle.ghost,
              onPressed: _busy ? null : () => _next(skip: true),
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}
