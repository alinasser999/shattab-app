import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState
    extends ConsumerState<CompanyProfileScreen> {
  final TextEditingController _bizCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  File? _logo;
  bool _hydrated = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _bizCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final result = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (result != null) {
        setState(() => _logo = File(result.path));
      }
    } catch (_) {}
  }

  Future<void> _next() async {
    final biz = _bizCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (biz.length < 2 || name.length < 2) {
      setState(() => _error = S.fillBothFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ctrl = ref.read(onboardingControllerProvider.notifier);
      await ctrl.setBusinessName(businessName: biz, displayName: name);
      if (_logo != null) {
        await ctrl.uploadLogo(_logo!);
      }
      if (!mounted) return;
      context.go(Routes.onboardingContractorServices);
    } catch (e) {
      setState(() => _error = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(contractorProfileProvider).value;
    final profile = ref.watch(currentProfileProvider).value;
    final existingLogo = existing?.logoUrl;
    if (!_hydrated) {
      if (existing?.businessName != null) {
        _bizCtrl.text = existing!.businessName!;
      }
      if (profile?.fullName.isNotEmpty ?? false) {
        _nameCtrl.text = profile!.fullName;
      }
      _hydrated = true;
    }
    return BatshScaffold(
      title: S.businessNameTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            BatshSectionHeader(title: S.companyData),
            const SizedBox(height: BatshSpacing.sm),
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 120,
                  height: 120,
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
                    child: _logo != null
                        ? Image.file(_logo!, fit: BoxFit.cover)
                        : (existingLogo != null
                            ? CachedNetworkImage(
                                imageUrl: existingLogo,
                                fit: BoxFit.cover,
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: BatshColors.onSurfaceVariant,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    S.chooseImage,
                                    style: BatshTypography.bodySm.copyWith(
                                      color: BatshColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              )),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshTextField(
              controller: _bizCtrl,
              label: S.businessNameTitle,
              hint: S.businessNameHint,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshTextField(
              controller: _nameCtrl,
              label: S.displayNameLabel,
              errorText: _error,
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.next,
              onPressed: _busy ? null : _next,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ].animate(interval: 60.ms).fadeIn(
            duration: BatshMotion.slow,
            curve: BatshMotion.easeOut,
          ).slideY(
            begin: 0.08,
            end: 0,
            curve: BatshMotion.easeOut,
          ),
        ),
      ),
    );
  }
}
