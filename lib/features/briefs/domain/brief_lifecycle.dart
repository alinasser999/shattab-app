import 'brief.dart';

enum BriefLifecycleStep { requestPosted, quotes, work, completion }

enum BriefLifecycleStepState { complete, current, upcoming }

/// Derives the visible request journey from persisted request state.
///
/// This is intentionally small and pure so the UI cannot quietly invent a
/// status. A request only advances when the corresponding database-backed
/// timestamp exists; the quotes flag is supplied by the real quotes query.
class BriefLifecycle {
  const BriefLifecycle._();

  static BriefLifecycleStep currentStep(
    Brief brief, {
    required bool hasQuotes,
  }) {
    if (brief.stage == BriefStage.completed) {
      return BriefLifecycleStep.completion;
    }
    if (brief.stage == BriefStage.completionRequested) {
      return BriefLifecycleStep.completion;
    }
    if (brief.stage == BriefStage.hired) {
      return BriefLifecycleStep.work;
    }
    // Both an empty quote list and a list of received offers belong to the
    // same decision step. The UI changes the copy, not the chronology.
    return BriefLifecycleStep.quotes;
  }

  static BriefLifecycleStepState state(
    Brief brief,
    BriefLifecycleStep step, {
    required bool hasQuotes,
  }) {
    if (brief.status == BriefStatus.cancelled) {
      return BriefLifecycleStepState.upcoming;
    }

    final current = currentStep(brief, hasQuotes: hasQuotes).index;
    if (step.index < current) return BriefLifecycleStepState.complete;
    if (step.index == current && brief.stage != BriefStage.completed) {
      return BriefLifecycleStepState.current;
    }
    return brief.stage == BriefStage.completed
        ? BriefLifecycleStepState.complete
        : BriefLifecycleStepState.upcoming;
  }
}
