import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../router/routes.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

/// Item definition for the mobile Quick Actions command menu.
class BatshQuickActionItem {
  const BatshQuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.shortcutKey,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final String? shortcutKey;
}

/// Production-grade Mobile Quick Action Sheet / Command Menu (Pattern 3 & 4).
class BatshQuickActionsSheet extends StatelessWidget {
  const BatshQuickActionsSheet({
    super.key,
    required this.isContractor,
  });

  final bool isContractor;

  static Future<void> show(BuildContext context, {required bool isContractor}) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BatshColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BatshRadius.xl)),
      ),
      builder: (_) => BatshQuickActionsSheet(isContractor: isContractor),
    );
  }

  List<BatshQuickActionItem> _getItems() {
    if (isContractor) {
      return [
        BatshQuickActionItem(
          icon: Icons.add_photo_alternate_outlined,
          title: 'إضافة مشروع جديد',
          subtitle: 'أضف صور ومعلومات مشروع جديد لمعرض أعمالك',
          route: Routes.contractorPortfolioNew,
          shortcutKey: 'N',
        ),
        BatshQuickActionItem(
          icon: Icons.work_outline,
          title: 'تصفح فرص العمل',
          subtitle: 'استكشف أحدث طلبات التشطيب وقدم عروضك',
          route: Routes.contractorDashboard,
          shortcutKey: 'J',
        ),
        BatshQuickActionItem(
          icon: Icons.receipt_long_outlined,
          title: 'العروض المرسلة',
          subtitle: 'تابع حالة عروض الأسعار التي قدمتها',
          route: Routes.contractorMyQuotes,
          shortcutKey: 'Q',
        ),
        BatshQuickActionItem(
          icon: Icons.photo_library_outlined,
          title: 'معرض أعمالي',
          subtitle: 'إدارة وتعديل مشاريعك السابقة',
          route: Routes.contractorPortfolio,
          shortcutKey: 'P',
        ),
      ];
    } else {
      return [
        BatshQuickActionItem(
          icon: Icons.add_circle_outline,
          title: 'نشر طلب تشطيب جديد',
          subtitle: 'أضف مواصفات شقتك واستقبل عروض الأسعار',
          route: Routes.homeownerNewPost,
          shortcutKey: 'N',
        ),
        BatshQuickActionItem(
          icon: Icons.search_rounded,
          title: 'البحث عن محترفين',
          subtitle: 'استعرض أفضل المقاولين والشركات المعتمدة',
          route: Routes.homeownerDiscover,
          shortcutKey: 'F',
        ),
        BatshQuickActionItem(
          icon: Icons.assignment_outlined,
          title: 'طلباتي والعروض',
          subtitle: 'متابعة المشاريع الجارية والعروض المستلمة',
          route: Routes.homeownerRequests,
          shortcutKey: 'R',
        ),
        BatshQuickActionItem(
          icon: Icons.bookmark_outline,
          title: 'المحترفون المحفوظون',
          subtitle: 'قائمتك المفضلة للمقاولين المحفوظين',
          route: Routes.homeownerSaved,
          shortcutKey: 'S',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          BatshSpacing.gutter,
          BatshSpacing.md,
          BatshSpacing.gutter,
          BatshSpacing.lg + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Swipe grab handle (Pattern 10)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: BatshSpacing.md),
                decoration: BoxDecoration(
                  color: BatshColors.outlineVariant,
                  borderRadius: BatshRadius.brFull,
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: BatshColors.primary,
                  size: 24,
                ),
                const SizedBox(width: BatshSpacing.sm),
                Text(
                  S.quickActions,
                  style: BatshTypography.titleLg.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: S.close,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BatshSpacing.md),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
                child: Material(
                  color: BatshColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BatshRadius.brMd,
                    side: const BorderSide(color: BatshColors.outlineVariant),
                  ),
                  child: InkWell(
                    borderRadius: BatshRadius.brMd,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(item.route);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.md,
                        vertical: BatshSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: BatshColors.primaryFixed.withValues(alpha: 0.35),
                              borderRadius: BatshRadius.brMd,
                            ),
                            child: Icon(item.icon, color: BatshColors.primary, size: 22),
                          ),
                          const SizedBox(width: BatshSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: BatshTypography.titleMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: BatshTypography.bodySm.copyWith(
                                    color: BatshColors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (item.shortcutKey != null) ...[
                            const SizedBox(width: BatshSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: BatshColors.surfaceContainerHigh,
                                borderRadius: BatshRadius.brSm,
                              ),
                              child: Text(
                                item.shortcutKey!,
                                style: BatshTypography.labelSm.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: BatshColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
