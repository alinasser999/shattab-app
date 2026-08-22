import 'package:flutter/widgets.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';

import '../domain/app_notification.dart';

/// Resolves server-side localization keys at the presentation boundary.
///
/// Notifications store keys rather than rendered text so the same event can be
/// shown in Arabic or English. Keeping this mapping outside the tile lets
/// other live surfaces, such as the homeowner home activity card, show the
/// exact same copy instead of inventing a second summary.
String notificationTitle(BuildContext context, AppNotification item) =>
    switch (item.titleKey) {
      'notificationNewQuoteTitle' => context.l10n.notificationNewQuoteTitle,
      'notificationQuoteDecisionTitle' =>
        context.l10n.notificationQuoteDecisionTitle,
      'notificationCompletionTitle' => context.l10n.notificationCompletionTitle,
      'notificationNewReviewTitle' => context.l10n.notificationNewReviewTitle,
      'notificationVerificationTitle' =>
        context.l10n.notificationVerificationTitle,
      'notificationPaymentTitle' => context.l10n.notificationPaymentTitle,
      'notificationCommunityTitle' => context.l10n.notificationCommunityTitle,
      _ => context.l10n.notificationsTitle,
    };

String notificationBody(
  BuildContext context,
  AppNotification item,
) => switch (item.bodyKey) {
  'notificationNewQuoteBody' => context.l10n.notificationNewQuoteBody,
  'notificationQuoteAcceptedBody' => context.l10n.notificationQuoteAcceptedBody,
  'notificationQuoteDeclinedBody' => context.l10n.notificationQuoteDeclinedBody,
  'notificationCompletionRequestedBody' =>
    context.l10n.notificationCompletionRequestedBody,
  'notificationJobCompletedBody' => context.l10n.notificationJobCompletedBody,
  'notificationNewReviewBody' => context.l10n.notificationNewReviewBody,
  'notificationVerificationApprovedBody' =>
    context.l10n.notificationVerificationApprovedBody,
  'notificationVerificationRejectedBody' =>
    context.l10n.notificationVerificationRejectedBody,
  'notificationPaymentApprovedBody' =>
    context.l10n.notificationPaymentApprovedBody,
  'notificationPaymentRejectedBody' =>
    context.l10n.notificationPaymentRejectedBody,
  'notificationPostLikedBody' => context.l10n.notificationPostLikedBody,
  'notificationPostCommentedBody' => context.l10n.notificationPostCommentedBody,
  'notificationCommentRepliedBody' =>
    context.l10n.notificationCommentRepliedBody,
  'notificationCommentLikedBody' => context.l10n.notificationCommentLikedBody,
  _ => context.l10n.notificationsSubtitle,
};
