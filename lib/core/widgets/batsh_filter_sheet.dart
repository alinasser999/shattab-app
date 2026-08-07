import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';
import 'batsh_sheet.dart';

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
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = activeCount > 0
        ? context.colorScheme.primaryFixed
        : context.colorScheme.surfaceContainer;
    final fgColor = activeCount > 0
        ? context.colorScheme.primary
        : context.colorScheme.onSurfaceVariant;
    final borderColor = activeCount > 0
        ? context.colorScheme.primary.withValues(alpha: 0.3)
        : context.colorScheme.outlineVariant.withValues(alpha: 0.6);
    return Material(
      color: bgColor,
      borderRadius: BatshRadius.brFull,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BatshRadius.brFull,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BatshRadius.brFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: BatshIconSize.md, color: fgColor),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                activeCount > 0
                    ? context.l10n.filterWithCount(activeCount)
                    : context.l10n.filter,
                style: BatshTypography.labelMd.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Container(
      height: 30,
      padding: const EdgeInsets.only(right: BatshSpacing.xs),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryFixed,
        borderRadius: BatshRadius.brFull,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: BatshSpacing.xs),
            child: Text(
              label,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 22,
            height: 22,
            child: Material(
              color: context.colorScheme.primary.withValues(alpha: 0.12),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onRemove();
                },
                child: Icon(
                  Icons.close_rounded,
                  size: BatshIconSize.sm,
                  color: context.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
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
            GestureDetector(
              onTap: () {
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
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _toggle(opt.value, section.singleSelect);
              },
              child: AnimatedContainer(
                duration: BatshMotion.fast,
                curve: BatshMotion.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.md,
                  vertical: BatshSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colorScheme.primaryFixed
                      : context.colorScheme.surfaceContainer,
                  borderRadius: BatshRadius.brFull,
                  border: Border.all(
                    color: isSelected
                        ? context.colorScheme.primary.withValues(alpha: 0.4)
                        : context.colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (opt.icon != null) ...[
                      Icon(
                        opt.icon,
                        size: BatshIconSize.sm,
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: BatshSpacing.xs),
                    ],
                    Text(
                      opt.label,
                      style: BatshTypography.labelMd.copyWith(
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.lg,
        BatshSpacing.md,
        BatshSpacing.lg,
        BatshSpacing.xxl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BatshRadius.brMd,
              child: InkWell(
                borderRadius: BatshRadius.brMd,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BatshRadius.brMd,
                    border: Border.all(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.l10n.cancel,
                    style: BatshTypography.labelMd.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: BatshSpacing.md),
          Expanded(
            flex: 2,
            child: Material(
              color: context.colorScheme.primary,
              borderRadius: BatshRadius.brMd,
              child: InkWell(
                borderRadius: BatshRadius.brMd,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(_selected);
                },
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '${context.l10n.apply} (${_selected.length})',
                    style: BatshTypography.labelMd.copyWith(
                      color: context.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
