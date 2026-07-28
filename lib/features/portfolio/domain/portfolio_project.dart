class PortfolioProject {
  const PortfolioProject({
    required this.id,
    required this.contractorId,
    required this.title,
    required this.coverPhotoUrl,
    required this.photoUrls,
    required this.position,
    this.description,
    this.category,
    this.apartmentType,
    this.location,
    this.yearCompleted,
  });

  final String id;
  final String contractorId;
  final String title;
  final String? description;
  final String coverPhotoUrl;
  final List<String> photoUrls;
  final String? category;
  final String? apartmentType;
  final String? location;
  final int? yearCompleted;
  final int position;

  factory PortfolioProject.fromJson(Map<String, dynamic> json) =>
      PortfolioProject(
        id: json['id'] as String,
        contractorId: json['contractor_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        coverPhotoUrl: json['cover_photo_url'] as String,
        photoUrls: ((json['photo_urls'] as List?) ?? const []).cast<String>(),
        category: json['category'] as String?,
        apartmentType: json['apartment_type'] as String?,
        location: json['location'] as String?,
        yearCompleted: json['year_completed'] as int?,
        position: (json['position'] as int?) ?? 0,
      );
}
