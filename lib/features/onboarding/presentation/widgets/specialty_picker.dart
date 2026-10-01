import 'package:flutter/material.dart';

import '../../../../core/catalog/specialty_catalog.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/batsh_pressable.dart';

/// Shared root/child specialty selection for professionals and homeowner
/// requests. The callback always receives the normalized stored array.
class SpecialtyPicker extends StatefulWidget {
  const SpecialtyPicker({
    super.key,
    required this.initialSelection,
    required this.onChanged,
    this.showChildren = true,
    this.requirePrimary = true,
  });

  final List<String> initialSelection;
  final ValueChanged<List<String>> onChanged;
  final bool showChildren;
  final bool requirePrimary;

  @override
  State<SpecialtyPicker> createState() => _SpecialtyPickerState();
}

class _SpecialtyPickerState extends State<SpecialtyPicker> {
  late List<String> _selection;

  @override
  void initState() {
    super.initState();
    _selection = SpecialtyCatalog.normalizeSelection(widget.initialSelection);
  }

  @override
  void didUpdateWidget(covariant SpecialtyPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = SpecialtyCatalog.normalizeSelection(widget.initialSelection);
    if (!_sameValues(_selection, next)) _selection = next;
  }

  bool _isSelected(String key) =>
      _selection.any((value) => SpecialtyCatalog.rootKeyFor(value) == key);

  void _toggleRoot(String key) {
    final values = [..._selection];
    if (_isSelected(key)) {
      values.removeWhere((value) => SpecialtyCatalog.rootKeyFor(value) == key);
    } else {
      values.add(key);
    }
    _update(values);
  }

  void _toggleChild(String key, String parent) {
    if (!_isSelected(parent)) return;
    final values = [..._selection];
    if (!values.remove(key)) values.add(key);
    _update(values);
  }

  void _makePrimary(String key) {
    _update(_selection, primary: key);
  }

  void _update(Iterable<String> values, {String? primary}) {
    final next = SpecialtyCatalog.normalizeSelection(values, primary: primary);
    setState(() => _selection = next);
    widget.onChanged(List.unmodifiable(next));
  }

  @override
  Widget build(BuildContext context) {
    final roots = SpecialtyCatalog.roots;
    final primary = SpecialtyCatalog.rootKeys(_selection).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.requirePrimary
              ? context.l10n.specialtyPickerHint
              : context.l10n.specialtyRequestHint,
          style: BatshTypography.bodySm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        Wrap(
          spacing: BatshSpacing.sm,
          runSpacing: BatshSpacing.sm,
          children: [
            for (final root in roots) ...[
              _SpecialtyOption(
                label: localizedSpecialtyLabel(context, root.key),
                icon: specialtyIcon(root.key),
                selected: _isSelected(root.key),
                semanticLabel: _semanticLabel(
                  context,
                  root.key,
                  primary == root.key,
                ),
                onTap: () => _toggleRoot(root.key),
              ),
              if (widget.requirePrimary &&
                  _isSelected(root.key) &&
                  primary != root.key)
                _PrimaryAction(
                  specialtyLabel: localizedSpecialtyLabel(context, root.key),
                  onTap: () => _makePrimary(root.key),
                ),
              if (widget.showChildren &&
                  root.hasChildren &&
                  _isSelected(root.key))
                _ChildOptions(
                  parent: root.key,
                  children: root.children,
                  selected: _selection,
                  onToggle: _toggleChild,
                ),
            ],
          ],
        ),
      ],
    );
  }

  String _semanticLabel(BuildContext context, String key, bool primary) {
    final label = localizedSpecialtyLabel(context, key);
    if (!widget.requirePrimary || !primary) return label;
    return '$label, ${context.l10n.primarySpecialtyLabel}';
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.specialtyLabel, required this.onTap});

  final String specialtyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${context.l10n.makePrimarySpecialty}: $specialtyLabel',
      onTap: onTap,
      child: ExcludeSemantics(
        child: BatshPressable(
          onTap: onTap,
          semanticLabel:
              '${context.l10n.makePrimarySpecialty}: $specialtyLabel',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xs),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Center(
                child: Text(
                  context.l10n.makePrimarySpecialty,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildOptions extends StatelessWidget {
  const _ChildOptions({
    required this.parent,
    required this.children,
    required this.selected,
    required this.onToggle,
  });

  final String parent;
  final List<String> children;
  final List<String> selected;
  final void Function(String key, String parent) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.only(top: BatshSpacing.xs),
      padding: const EdgeInsetsDirectional.fromSTEB(
        BatshSpacing.sm,
        BatshSpacing.xs,
        0,
        BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(
            color: context.colorScheme.primary.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
      ),
      child: Wrap(
        spacing: BatshSpacing.xs,
        runSpacing: BatshSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            context.l10n.specialtyDetailsLabel,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final child in children)
            _SpecialtyOption(
              label: localizedSpecialtyChildLabel(context, child),
              selected: selected.contains(child),
              compact: true,
              semanticLabel: localizedSpecialtyDisplayLabel(context, child),
              onTap: () => onToggle(child, parent),
            ),
        ],
      ),
    );
  }
}

class _SpecialtyOption extends StatelessWidget {
  const _SpecialtyOption({
    required this.label,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: BatshPressable(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? BatshSpacing.sm : BatshSpacing.md,
              vertical: BatshSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? context.colorScheme.primaryContainer
                  : context.colorScheme.surfaceContainer,
              borderRadius: BatshRadius.brFull,
              border: Border.all(
                color: selected
                    ? context.colorScheme.primary
                    : context.colorScheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: BatshIconSize.action,
                    color: selected
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: BatshSpacing.xs),
                ],
                Text(
                  label,
                  style: BatshTypography.labelMd.copyWith(
                    color: selected
                        ? context.colorScheme.onPrimaryContainer
                        : context.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: BatshSpacing.xs),
                  Icon(
                    Icons.check_rounded,
                    size: BatshIconSize.sm,
                    color: context.colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameValues(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
