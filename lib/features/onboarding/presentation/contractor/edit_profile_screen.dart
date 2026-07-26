import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../discovery/domain/contractor_listing.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../providers/onboarding_provider.dart';

/// Edit the contractor showcase shown on their profile + in Discover.
/// Reads current values from [contractorByIdProvider] and writes through
/// [OnboardingController].
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _bizCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();

  /// Selected professional identity. Defaults to `contractor` to match the
  /// column default, and is replaced by the stored value once it loads.
  ProviderKind _kind = ProviderKind.contractor;
  final _bioCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();

  File? _cover;
  File? _logo;
  bool _hydrated = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _bizCtrl.dispose();
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _yearsCtrl.dispose();
    super.dispose();
  }

  String? get _myId => ref.read(currentSessionProvider)?.user.id;

  Future<File?> _pickImage() async {
    final r = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    return r == null ? null : File(r.path);
  }

  Future<void> _save() async {
    final myId = _myId;
    if (myId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ctrl = ref.read(onboardingControllerProvider.notifier);
      if (_logo != null) await ctrl.uploadLogo(_logo!);
      if (_cover != null) await ctrl.uploadCover(_cover!);
      final biz = _bizCtrl.text.trim();
      final years = int.tryParse(_yearsCtrl.text.trim());
      await ctrl.saveShowcase(
        businessName: biz.isEmpty ? null : biz,
        headline: _headlineCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        yearsExperience: years,
        providerKind: _kind,
      );
      // Refresh the showcase + discover list so edits show immediately.
      ref.invalidate(contractorByIdProvider(myId));
      ref.invalidate(discoverContractorsProvider);
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (mounted) setState(() => _error = S.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _myId;
    final existing =
        myId == null ? null : ref.watch(contractorByIdProvider(myId)).value;
    if (!_hydrated && existing != null) {
      _bizCtrl.text = existing.businessName;
      _headlineCtrl.text = existing.headline ?? '';
      _bioCtrl.text = existing.bio ?? '';
      if (existing.yearsExperience != null) {
        _yearsCtrl.text = '${existing.yearsExperience}';
      }
      _kind = existing.providerKind;
      _hydrated = true;
    }

    return BatshScaffold(
      title: S.editProfileButton,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(S.portfolioCoverLabel,
                style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: BatshSpacing.sm),
            _CoverPicker(
              file: _cover,
              existingUrl: existing?.coverPhotoUrl,
              onTap: () async {
                final f = await _pickImage();
                if (f != null) setState(() => _cover = f);
              },
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(S.logo,
                style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: BatshSpacing.sm),
            Center(
              child: _LogoPicker(
                file: _logo,
                existingUrl: existing?.logoUrl,
                onTap: () async {
                  final f = await _pickImage();
                  if (f != null) setState(() => _logo = f);
                },
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            // Self-declared identity. First field after the images because it
            // frames everything below it — and because being asked "what are
            // you?" rather than being told is the whole point.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child:
                  Text(S.providerKindQuestion, style: BatshTypography.labelLg),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                S.providerKindHelp,
                style: BatshTypography.bodySm
                    .copyWith(color: BatshColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
            Wrap(
              spacing: BatshSpacing.sm,
              runSpacing: BatshSpacing.sm,
              children: [
                for (final kind in ProviderKind.values)
                  ChoiceChip(
                    avatar: Icon(kind.icon, size: 16),
                    label: Text(kind.label),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshTextField(
              controller: _bizCtrl,
              label: S.businessNameTitle,
              maxLength: 60,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshTextField(
              controller: _headlineCtrl,
              label: S.professionalTitle,
              hint: S.professionalTitleHint,
              maxLength: 80,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshTextField(
              controller: _bioCtrl,
              label: S.bioLabel,
              hint: S.bioHint,
              maxLines: 5,
              maxLength: 400,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshTextField(
              controller: _yearsCtrl,
              label: S.yearsExperience,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              errorText: _error,
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.saveProfile,
              onPressed: _busy ? null : _save,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.file,
    required this.existingUrl,
    required this.onTap,
  });
  final File? file;
  final String? existingUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: BatshColors.surfaceContainer,
            borderRadius: BatshRadius.brLg,
            border: Border.all(color: BatshColors.outlineVariant, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: file != null
              ? Image.file(file!, fit: BoxFit.cover)
              : (existingUrl != null
                  ? CachedNetworkImage(imageUrl: existingUrl!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.add_photo_alternate_outlined,
                          size: 40, color: BatshColors.onSurfaceVariant),
                    )),
        ),
      ),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.file,
    required this.existingUrl,
    required this.onTap,
  });
  final File? file;
  final String? existingUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: BatshColors.surfaceContainer,
          shape: BoxShape.circle,
          border: Border.all(color: BatshColors.primary, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Image.file(file!, fit: BoxFit.cover)
            : (existingUrl != null
                ? CachedNetworkImage(imageUrl: existingUrl!, fit: BoxFit.cover)
                : const Icon(Icons.add_a_photo_outlined,
                    color: BatshColors.onSurfaceVariant, size: 30)),
      ),
    );
  }
}
