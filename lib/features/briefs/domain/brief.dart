import '../../onboarding/domain/onboarding_models.dart';

enum BriefStatus {
  open,
  cancelled;

  static BriefStatus fromString(String value) => BriefStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => BriefStatus.open,
  );
}

/// Where a brief sits in the hire-to-completion lifecycle.
///
/// Derived from three timestamps so the UI branches on one value instead of
/// re-deriving the combination at every call site.
enum BriefStage {
  /// Still taking quotes, or cancelled — nobody hired yet.
  open,

  /// A quote was accepted. Work is presumed underway.
  hired,

  /// The contractor says the work is finished. Not proof — a nudge waiting on
  /// the homeowner.
  completionRequested,

  /// The homeowner confirmed the work is done. Unlocks reviews.
  completed,
}

class Brief {
  const Brief({
    required this.id,
    required this.homeownerId,
    required this.apartmentType,
    required this.city,
    required this.workDescription,
    required this.photoUrls,
    required this.targetSpecialties,
    required this.status,
    required this.createdAt,
    this.targetContractorId,
    this.district,
    this.hiredAt,
    this.completionRequestedAt,
    this.completedAt,
    this.editedAt,
  });

  final String id;
  final String homeownerId;
  final String? targetContractorId;
  final ApartmentType apartmentType;
  final String city;
  final String? district;
  final String workDescription;
  final List<String> photoUrls;
  final List<String> targetSpecialties;
  final BriefStatus status;
  final DateTime createdAt;

  /// Set once the homeowner accepts a quote (migration 0009). A hired brief is
  /// closed: no more quotes, no accept/decline.
  final DateTime? hiredAt;

  /// Set when the hired contractor signals the work is finished (0019). A
  /// request only — it does not complete the job on its own.
  final DateTime? completionRequestedAt;

  /// Set when the homeowner confirms the work is done (0019). This is the
  /// transition that unlocks reviews and increments the contractor's
  /// projects_completed.
  final DateTime? completedAt;

  /// Set by the database (migration 0020) whenever the homeowner changes the
  /// scope: description, unit type, location, specialties, or photos.
  final DateTime? editedAt;

  /// True when the scope changed after posting. Contractors see this, because
  /// a quote written against the original wording may no longer fit.
  bool get isEdited => editedAt != null;

  /// True while the homeowner can still change the scope. Once hired, the brief
  /// describes work in progress and the database rejects scope edits.
  bool get canBeEdited => !isHired && status == BriefStatus.open;

  /// True when this brief was published as a public job post (no specific
  /// contractor target). False when it was sent to one specific contractor.
  bool get isPost => targetContractorId == null;

  /// True once a quote has been accepted on this brief.
  bool get isHired => hiredAt != null;

  /// True once the homeowner has confirmed the work is done.
  bool get isCompleted => completedAt != null;

  /// True while the brief is still taking quotes.
  bool get isActive => status == BriefStatus.open && !isHired;

  /// Lifecycle position.
  ///
  /// Ordered most-advanced first: a completed brief reads as completed even if
  /// the timestamps below it are inconsistent. `completed_at` without
  /// `hired_at` should be impossible (the RPC requires a hire), but data can
  /// outlive the code that guarded it, and reporting the furthest state reached
  /// is safer than reporting a job as still open.
  BriefStage get stage {
    if (completedAt != null) return BriefStage.completed;
    if (completionRequestedAt != null) return BriefStage.completionRequested;
    if (hiredAt != null) return BriefStage.hired;
    return BriefStage.open;
  }

  /// True when the homeowner still owes a completion confirmation.
  bool get awaitsCompletionConfirmation =>
      stage == BriefStage.hired || stage == BriefStage.completionRequested;

  /// True once a review may be written. Mirrors the RLS insert policy in
  /// migration 0019, so the UI never offers a button the database rejects.
  bool get canBeReviewed => isCompleted;

  factory Brief.fromJson(Map<String, dynamic> json) => Brief(
    id: json['id'] as String,
    homeownerId: json['homeowner_id'] as String,
    targetContractorId: json['target_contractor_id'] as String?,
    apartmentType:
        ApartmentType.fromString(json['apartment_type'] as String?) ??
        ApartmentType.studio,
    city: json['city'] as String,
    district: json['district'] as String?,
    workDescription: json['work_description'] as String,
    photoUrls: ((json['photo_urls'] as List?) ?? const []).cast<String>(),
    targetSpecialties: ((json['target_specialties'] as List?) ?? const [])
        .cast<String>(),
    status: BriefStatus.fromString(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    hiredAt: json['hired_at'] == null
        ? null
        : DateTime.parse(json['hired_at'] as String),
    // Absent on rows written before migration 0019, so both stay nullable.
    completionRequestedAt: json['completion_requested_at'] == null
        ? null
        : DateTime.parse(json['completion_requested_at'] as String),
    completedAt: json['completed_at'] == null
        ? null
        : DateTime.parse(json['completed_at'] as String),
    editedAt: json['edited_at'] == null
        ? null
        : DateTime.parse(json['edited_at'] as String),
  );
}
