import '../../onboarding/domain/onboarding_models.dart';

enum BriefStatus {
  open,
  cancelled;

  static BriefStatus fromString(String value) =>
      BriefStatus.values.firstWhere((s) => s.name == value,
          orElse: () => BriefStatus.open);
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

  /// True when this brief was published as a public job post (no specific
  /// contractor target). False when it was sent to one specific contractor.
  bool get isPost => targetContractorId == null;

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
        photoUrls:
            ((json['photo_urls'] as List?) ?? const []).cast<String>(),
        targetSpecialties:
            ((json['target_specialties'] as List?) ?? const []).cast<String>(),
        status: BriefStatus.fromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
