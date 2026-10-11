import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';
import 'batsh_sheet.dart';
import 'batsh_chip.dart';
import 'batsh_button.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class FilterOption {
  const FilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.group,
  });

  final String value;
  final String label;
  final IconData? icon;
  final String? group;
}

class FilterSheetResult {
  const FilterSheetResult({
    required this.selectedValues,
    required this.isActive,
  });

  final Set<String> selectedValues;
  final bool isActive;
}

class BatshFilterButton extends StatelessWidget {
  const BatshFilterButton({
    super.key,
    required this.activeCount,
    required this.onTap,
    this.height = 42,
  });

  final int activeCount;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return BatshChip(
      label: activeCount > 0
          ? context.l10n.filterWithCount(activeCount)
          : context.l10n.filter,
      icon: Icons.tune_rounded,
      selected: activeCount > 0,
      onTap: onTap,
    );
  }
}

class BatshActiveFilterChip extends StatelessWidget {
  const BatshActiveFilterChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onRemove,
      deleteButtonTooltipMessage: context.l10n.removeFilter(label),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
  }
}

class BatshFilterSheetSection {
  const BatshFilterSheetSection({
    required this.title,
    required this.options,
    this.icon,
    this.singleSelect = false,
  });

  final String title;
  final IconData? icon;
  final List<FilterOption> options;
  final bool singleSelect;
}

class BatshFilterSheet extends StatefulWidget {
  const BatshFilterSheet({
    super.key,
    required this.sections,
    required this.initialSelected,
  });

  final List<BatshFilterSheetSection> sections;
  final Set<String> initialSelected;

  static Future<Set<String>?> show(
    BuildContext context, {
    required List<BatshFilterSheetSection> sections,
    Set<String> initialSelected = const {},
  }) {
    return BatshSheet.show<Set<String>>(
      context,
      contentPadding: EdgeInsets.zero,
      builder: (_) => BatshFilterSheet(
        sections: sections,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  State<BatshFilterSheet> createState() => _BatshFilterSheetState();
}

class _BatshFilterSheetState extends State<BatshFilterSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  void _toggle(String value, bool singleSelect) {
    setState(() {
      if (singleSelect) {
        _selected = {value};
        return;
      }
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  void _clear() => setState(() => _selected = {});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.lg,
              0,
              BatshSpacing.lg,
              BatshSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in widget.sections) ...[
                  _buildSection(section),
                  const SizedBox(height: BatshSpacing.lg),
                ],
              ],
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.lg,
        BatshSpacing.md,
        BatshSpacing.lg,
        BatshSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            context.l10n.filter,
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _clear();
              },
              child: Text(
                context.l10n.clearAll,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(BatshFilterSheetSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (section.icon != null) ...[
              Icon(
                section.icon,
                size: BatshIconSize.sm,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: BatshSpacing.xs),
            ],
            Text(
              section.title,
              style: BatshTypography.titleMd.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.sm),
        Wrap(
          spacing: BatshSpacing.sm,
          runSpacing: BatshSpacing.sm,
          children: section.options.map((opt) {
            final isSelected = _selected.contains(opt.value);
            return BatshChip(
              label: opt.label,
              icon: opt.icon,
              selected: isSelected,
              singleSelection: section.singleSelect,
              onTap: () => _toggle(opt.value, section.singleSelect),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() => Padding(
    padding: const EdgeInsets.all(BatshSpacing.md),
    child: Row(
      children: [
        Expanded(
          child: BatshButton(
            label: context.l10n.cancel,
            style: BatshButtonStyle.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          flex: 2,
          child: BatshButton(
            label: '${context.l10n.apply} (${_selected.length})',
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ),
      ],
    ),
  );
}
