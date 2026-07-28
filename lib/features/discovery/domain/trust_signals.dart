import 'package:flutter/material.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';

enum VerificationLevel { none, identity, business }

enum TrustSignalKind { projectsCompleted, yearsExperience }

enum TrustHighlight { topRated, established }

class TrustSignal {
  final TrustSignalKind kind;
  final String value;
  final String label;
  final String semanticLabel;

  TrustSignal({
    required this.kind,
    required this.value,
    required this.label,
    required this.semanticLabel,
  });
}

/// The trust story for one professional, reduced to what we can actually
/// evidence.
///
/// An earlier draft also carried response time, response rate and completion
/// rate. None of those exist: `response_rate` is `int not null default 100` in
/// migration 0003, so every row reports a perfect 100%, and the other two were
/// never columns at all. [ContractorListing] deleted the same fields for the
/// same reason — its `rating` doc records that a heuristic seeded from
/// `responseRate` was ranking unreviewed professionals by fiction.
///
/// A trust surface that invents its own evidence is worse than no trust
/// surface. Restore those signals only behind real instrumentation: a column
/// written from observed quote timestamps, not a default.
class TrustProfile {
  final VerificationLevel verification;
  final List<TrustSignal> metrics;
  final TrustHighlight? highlight;

  TrustProfile._({
    required this.verification,
    required this.metrics,
    this.highlight,
  });

  bool get hasMetrics => metrics.isNotEmpty;
  bool get isColdStart => metrics.isEmpty;

  static TrustProfile of(BuildContext context, ContractorListing listing) {
    // `business` stays unreachable until a business-verification column exists.
    // The listing knows only whether identity was checked.
    final verification = listing.verified
        ? VerificationLevel.identity
        : VerificationLevel.none;

    final metrics = <TrustSignal>[];
    if (listing.projectsCompleted > 0) {
      final n = listing.projectsCompleted;
      metrics.add(
        TrustSignal(
          kind: TrustSignalKind.projectsCompleted,
          value: '$n',
          label: context.l10n.projects,
          semanticLabel: '$n ${context.l10n.projectsCompleted}',
        ),
      );
    }
    final years = listing.yearsExperience;
    if (years != null && years > 0) {
      metrics.add(
        TrustSignal(
          kind: TrustSignalKind.yearsExperience,
          value: '$years',
          label: context.l10n.yearsExperience,
          semanticLabel: '$years ${context.l10n.yearsExperience}',
        ),
      );
    }

    TrustHighlight? highlight;
    // Guarded on reviewCount first: reviewAvg is 0 on an unreviewed profile,
    // and an unreviewed profile must not qualify as anything.
    if (listing.reviewCount >= 5 && listing.reviewAvg >= 4.9) {
      highlight = TrustHighlight.topRated;
    } else if (listing.projectsCompleted >= 10) {
      highlight = TrustHighlight.established;
    }

    return TrustProfile._(
      verification: verification,
      metrics: metrics,
      highlight: highlight,
    );
  }
}

String formatPercent(double fraction) {
  if (fraction < 0) return '0%';
  if (fraction > 1) return '100%';
  return '${(fraction * 100).round()}%';
}
