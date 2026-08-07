import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../../../core/widgets/photo_picker.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/models/draft_photo.dart';
import '../domain/portfolio_project.dart';
import 'providers/my_portfolio_providers.dart';
import 'providers/portfolio_providers.dart';
import '../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Create / edit one portfolio project. [projectId] null means a new project.
class ProjectEditorScreen extends ConsumerStatefulWidget {
  const ProjectEditorScreen({super.key, this.projectId});

  final String? projectId;
  bool get isEditing => projectId != null;

  @override
  ConsumerState<ProjectEditorScreen> createState() =>
      _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends ConsumerState<ProjectEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<DraftPhoto> _photos = const [];
  bool _hydrated = false;
  bool _busy = false;
  String? _titleError;
  String? _coverError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _yearCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _hydrate(PortfolioProject p) {
    _titleCtrl.text = p.title;
    _categoryCtrl.text = p.category ?? '';
    _yearCtrl.text = p.yearCompleted?.toString() ?? '';
    _locationCtrl.text = p.location ?? '';
    _descCtrl.text = p.description ?? '';
    _photos = p.photoUrls.map((u) => DraftPhoto(url: u)).toList();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = context.l10n.titleRequired;
        _coverError = null;
      });
      return;
    }
    if (_photos.isEmpty) {
      setState(() {
        _coverError = context.l10n.coverRequired;
        _titleError = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _titleError = null;
      _coverError = null;
    });
    try {
      await ref
          .read(portfolioControllerProvider.notifier)
          .save(
            projectId: widget.projectId,
            title: title,
            description: _nullIfEmpty(_descCtrl.text),
            category: _nullIfEmpty(_categoryCtrl.text),
            location: _nullIfEmpty(_locationCtrl.text),
            yearCompleted: int.tryParse(_yearCtrl.text.trim()),
            photos: _photos,
          );
      if (!mounted) return;
      BatshSnack.success(context, context.l10n.projectSavedSuccess);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _titleError = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _nullIfEmpty(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final projAsync = ref.watch(portfolioProjectProvider(widget.projectId!));
      return projAsync.when(
        loading: () => BatshScaffold(
          title: context.l10n.editWorkTitle,
          body: const _EditorSkeleton(),
        ),
        error: (e, _) => BatshScaffold(
          title: context.l10n.editWorkTitle,
          body: BatshError(
            message: ErrorMapper.map(e),
            onRetry: () =>
                ref.invalidate(portfolioProjectProvider(widget.projectId!)),
          ),
        ),
        data: (project) {
          if (project == null) {
            return BatshScaffold(
              title: context.l10n.editWorkTitle,
              body: const BatshError(message: 'Project not found'),
            );
          }
          if (!_hydrated) {
            _hydrate(project);
            _hydrated = true;
          }
          return _form(context.l10n.editWorkTitle);
        },
      );
    }
    return _form(context.l10n.newWorkTitle);
  }

  Widget _form(String title) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final items = <Widget>[
      const SizedBox(height: BatshSpacing.md),
      BatshTextField(
        controller: _titleCtrl,
        label: '${context.l10n.workTitleLabel} *',
        hint: context.l10n.workTitleHint,
        maxLength: 80,
        errorText: _titleError,
      ),
      const SizedBox(height: BatshSpacing.gutter),
      BatshTextField(
        controller: _categoryCtrl,
        label: context.l10n.workCategoryLabel,
        hint: context.l10n.workCategoryHint,
        maxLength: 40,
      ),
      const SizedBox(height: BatshSpacing.gutter),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BatshTextField(
              controller: _yearCtrl,
              label: context.l10n.workYearLabel,
              hint: context.l10n.workYearHint,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
          ),
          const SizedBox(width: BatshSpacing.gutter),
          Expanded(
            child: BatshTextField(
              controller: _locationCtrl,
              label: context.l10n.workLocationLabel,
              hint: context.l10n.workLocationHint,
              maxLength: 60,
            ),
          ),
        ],
      ),
      const SizedBox(height: BatshSpacing.gutter),
      BatshTextField(
        controller: _descCtrl,
        label: context.l10n.workDescriptionLabel,
        hint: context.l10n.workDescriptionHint,
        maxLines: 5,
        maxLength: 1000,
      ),
      const SizedBox(height: BatshSpacing.gutter),
      PhotoPicker(
        maxPhotos: 8,
        initial: _photos,
        onChanged: (p) => _photos = p,
      ),
      const SizedBox(height: BatshSpacing.sm),
      Text(
        context.l10n.coverPhotoHint,
        style: BatshTypography.labelSm.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      if (_coverError != null) ...[
        const SizedBox(height: BatshSpacing.sm),
        Text(
          _coverError!,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.error,
          ),
        ),
      ],
      const SizedBox(height: BatshSpacing.lg),
      BatshButton(
        label: context.l10n.saveWork,
        icon: Icons.check,
        isLoading: _busy,
        onPressed: _busy ? null : _submit,
      ),
      const SizedBox(height: BatshSpacing.lg),
    ];
    return BatshScaffold(
      title: title,
      body: ListView(
        children: reduced
            ? items
            : items
                  .animate(interval: BatshMotion.staggerBase)
                  .fadeIn(duration: BatshMotion.normal)
                  .slideY(begin: 0.06, end: 0, curve: BatshMotion.easeOut),
      ),
    );
  }
}

class _EditorSkeleton extends StatelessWidget {
  const _EditorSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: BatshSpacing.md),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: BatshShimmerBox(
            width: double.infinity,
            height: 56,
            borderRadius: BatshRadius.brMd,
          ),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: BatshShimmerBox(
            width: double.infinity,
            height: 56,
            borderRadius: BatshRadius.brMd,
          ),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: Row(
            children: [
              Expanded(
                child: BatshShimmerBox(
                  width: double.infinity,
                  height: 56,
                  borderRadius: BatshRadius.brMd,
                ),
              ),
              SizedBox(width: BatshSpacing.gutter),
              Expanded(
                child: BatshShimmerBox(
                  width: double.infinity,
                  height: 56,
                  borderRadius: BatshRadius.brMd,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: BatshShimmerBox(
            width: double.infinity,
            height: 140,
            borderRadius: BatshRadius.brMd,
          ),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: BatshShimmerBox(
            width: double.infinity,
            height: 120,
            borderRadius: BatshRadius.brLg,
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: BatshShimmerBox(
            width: double.infinity,
            height: 48,
            borderRadius: BatshRadius.brMd,
          ),
        ),
      ],
    );
  }
}
