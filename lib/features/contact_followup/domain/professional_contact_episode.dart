class ProfessionalContactEpisode {
  const ProfessionalContactEpisode({
    required this.id,
    required this.contractorId,
    required this.contractorName,
    required this.firstContactedAt,
  });

  final String id;
  final String contractorId;
  final String contractorName;
  final DateTime firstContactedAt;

  factory ProfessionalContactEpisode.fromJson(Map<String, dynamic> json) =>
      ProfessionalContactEpisode(
        id: json['episode_id'] as String,
        contractorId: json['contractor_id'] as String,
        contractorName: (json['contractor_name'] as String?)?.trim() ?? '',
        firstContactedAt: DateTime.parse(json['first_contacted_at'] as String),
      );
}
