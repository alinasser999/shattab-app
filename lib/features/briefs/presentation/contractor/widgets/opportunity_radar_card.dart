import 'package:flutter/material.dart';

import '../../../domain/opportunity_experience.dart';
import 'opportunity_summary.dart';

/// Compatibility wrapper for older consumers of the former radar component.
/// The feed now uses [OpportunitySummary], which keeps the same metric data
/// but presents it as the approved asymmetric opportunity composition.
class OpportunityRadarCard extends StatelessWidget {
  const OpportunityRadarCard({
    super.key,
    required this.metrics,
    required this.preferencesCompletion,
    required this.onPreferencesTap,
    this.animationKey,
  });

  final OpportunityRadarMetrics metrics;
  final int preferencesCompletion;
  final VoidCallback onPreferencesTap;
  final Object? animationKey;

  @override
  Widget build(BuildContext context) {
    return OpportunitySummary(
      metrics: metrics,
      preferencesCompletion: preferencesCompletion,
      onPreferencesTap: onPreferencesTap,
      animationKey: animationKey,
    );
  }
}
