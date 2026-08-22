import 'package:batsh/features/portfolio/data/portfolio_repository.dart';
import 'package:batsh/features/portfolio/domain/portfolio_project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('portfolio cursor is derived from the database ordering tuple', () {
    final createdAt = DateTime.utc(2026, 8, 14, 10, 30);
    final project = PortfolioProject(
      id: 'project-2',
      contractorId: 'contractor-1',
      title: 'Kitchen',
      coverPhotoUrl: 'https://example.com/kitchen.jpg',
      photoUrls: const [],
      position: 0,
      createdAt: createdAt,
    );

    final cursor = PortfolioCursor.fromProject(project);

    expect(cursor.id, 'project-2');
    expect(cursor.createdAt, createdAt);
  });

  test('legacy fixtures without created_at stay constructible', () {
    final project = PortfolioProject.fromJson({
      'id': 'legacy-project',
      'contractor_id': 'contractor-1',
      'title': 'Legacy',
      'cover_photo_url': 'https://example.com/legacy.jpg',
      'photo_urls': <String>[],
      'position': 0,
    });

    expect(project.createdAt, isNull);
  });
}
