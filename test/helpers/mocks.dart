import 'package:batsh/features/auth/domain/profile.dart';
import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:batsh/features/portfolio/domain/portfolio_project.dart';
import 'package:batsh/features/quotes/domain/quote.dart';

Profile createTestProfile({
  String id = 'test-profile-id',
  UserRole role = UserRole.homeowner,
  String fullName = 'أحمد علي',
  String phone = '+201001234567',
  bool onboardingComplete = true,
  String? avatarUrl,
}) => Profile(
  id: id,
  role: role,
  fullName: fullName,
  phone: phone,
  onboardingComplete: onboardingComplete,
  avatarUrl: avatarUrl,
);

Brief createTestBrief({
  String id = 'test-brief-id',
  String homeownerId = 'test-homeowner-id',
  String? targetContractorId,
  ApartmentType apartmentType = ApartmentType.studio,
  String city = 'القاهرة',
  String? district,
  String workDescription = 'دهان شقة كاملة',
  List<String> photoUrls = const [],
  List<String> targetSpecialties = const ['paint'],
  BriefStatus status = BriefStatus.open,
  DateTime? createdAt,
}) => Brief(
  id: id,
  homeownerId: homeownerId,
  targetContractorId: targetContractorId,
  apartmentType: apartmentType,
  city: city,
  district: district,
  workDescription: workDescription,
  photoUrls: photoUrls,
  targetSpecialties: targetSpecialties,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 6, 1),
);

Quote createTestQuote({
  String id = 'test-quote-id',
  String briefId = 'test-brief-id',
  String contractorId = 'test-contractor-id',
  int? priceMin = 50000,
  int? priceMax = 70000,
  String? durationText = 'أسبوعين',
  String note = 'عرض سعر شامل التشطيب',
  QuoteStatus status = QuoteStatus.sent,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => Quote(
  id: id,
  briefId: briefId,
  contractorId: contractorId,
  priceMin: priceMin,
  priceMax: priceMax,
  durationText: durationText,
  note: note,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 6, 1),
  updatedAt: updatedAt ?? DateTime(2026, 6, 1),
);

PortfolioProject createTestPortfolioProject({
  String id = 'test-project-id',
  String contractorId = 'test-contractor-id',
  String title = 'تشطيب شقة ١٥٠م',
  String? description,
  String coverPhotoUrl = 'https://example.com/cover.jpg',
  List<String> photoUrls = const ['https://example.com/photo1.jpg'],
  String? category,
  String? apartmentType,
  String? location,
  int? yearCompleted,
  int position = 0,
  DateTime? createdAt,
}) => PortfolioProject(
  id: id,
  contractorId: contractorId,
  title: title,
  description: description,
  coverPhotoUrl: coverPhotoUrl,
  photoUrls: photoUrls,
  category: category,
  apartmentType: apartmentType,
  location: location,
  yearCompleted: yearCompleted,
  position: position,
  createdAt: createdAt,
);
