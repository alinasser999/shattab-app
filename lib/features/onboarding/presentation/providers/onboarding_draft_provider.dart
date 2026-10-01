import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../discovery/domain/contractor_listing.dart';
import '../../domain/onboarding_models.dart';

/// In-session onboarding answers. The provider is bound to the authenticated
/// account and deliberately does not persist drafts to disk.
class OnboardingDraft {
  const OnboardingDraft({
    required this.accountId,
    this.role,
    this.fullName = '',
    this.fullNameEdited = false,
    this.apartmentType,
    this.renovationInterests = const {},
    this.homeownerDetailsEdited = false,
    this.city,
    this.district,
    this.homeownerLocationEdited = false,
    this.providerKind,
    this.businessName = '',
    this.contractorLogoFile,
    this.contractorIdentityEdited = false,
    this.specialties = const [],
    this.serviceAreas = const {},
    this.contractorServicesEdited = false,
  });

  final String? accountId;
  final UserRole? role;
  final String fullName;
  final bool fullNameEdited;
  final ApartmentType? apartmentType;
  final Set<String> renovationInterests;
  final bool homeownerDetailsEdited;
  final String? city;
  final String? district;
  final bool homeownerLocationEdited;
  final ProviderKind? providerKind;
  final String businessName;
  final File? contractorLogoFile;
  final bool contractorIdentityEdited;
  final List<String> specialties;
  final Set<String> serviceAreas;
  final bool contractorServicesEdited;

  OnboardingDraft copyWith({
    UserRole? role,
    String? fullName,
    bool? fullNameEdited,
    ApartmentType? apartmentType,
    Set<String>? renovationInterests,
    bool? homeownerDetailsEdited,
    String? city,
    bool clearCity = false,
    String? district,
    bool clearDistrict = false,
    bool? homeownerLocationEdited,
    ProviderKind? providerKind,
    String? businessName,
    File? contractorLogoFile,
    bool clearContractorLogoFile = false,
    bool? contractorIdentityEdited,
    List<String>? specialties,
    Set<String>? serviceAreas,
    bool? contractorServicesEdited,
  }) => OnboardingDraft(
    accountId: accountId,
    role: role ?? this.role,
    fullName: fullName ?? this.fullName,
    fullNameEdited: fullNameEdited ?? this.fullNameEdited,
    apartmentType: apartmentType ?? this.apartmentType,
    renovationInterests: renovationInterests ?? this.renovationInterests,
    homeownerDetailsEdited:
        homeownerDetailsEdited ?? this.homeownerDetailsEdited,
    city: clearCity ? null : city ?? this.city,
    district: clearDistrict ? null : district ?? this.district,
    homeownerLocationEdited:
        homeownerLocationEdited ?? this.homeownerLocationEdited,
    providerKind: providerKind ?? this.providerKind,
    businessName: businessName ?? this.businessName,
    contractorLogoFile: clearContractorLogoFile
        ? null
        : contractorLogoFile ?? this.contractorLogoFile,
    contractorIdentityEdited:
        contractorIdentityEdited ?? this.contractorIdentityEdited,
    specialties: specialties ?? this.specialties,
    serviceAreas: serviceAreas ?? this.serviceAreas,
    contractorServicesEdited:
        contractorServicesEdited ?? this.contractorServicesEdited,
  );
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftController, OnboardingDraft>(
      OnboardingDraftController.new,
    );

class OnboardingDraftController extends Notifier<OnboardingDraft> {
  String? _accountId;
  bool _initialized = false;

  @override
  OnboardingDraft build() {
    final accountId = ref.watch(currentSessionProvider)?.user.id;
    if (!_initialized || accountId != _accountId) {
      _initialized = true;
      _accountId = accountId;
      return OnboardingDraft(accountId: accountId);
    }
    return state;
  }

  void updateRole(UserRole role) => state = state.copyWith(role: role);

  void updateFullName(String fullName) =>
      state = state.copyWith(fullName: fullName, fullNameEdited: true);

  void updateHomeownerDetails({
    required ApartmentType? apartmentType,
    required Set<String> interests,
  }) => state = state.copyWith(
    apartmentType: apartmentType,
    renovationInterests: Set.unmodifiable(interests),
    homeownerDetailsEdited: true,
  );

  void updateHomeownerLocation({
    String? city,
    String? district,
    bool clearDistrict = false,
  }) => state = state.copyWith(
    city: city,
    district: district,
    clearDistrict: clearDistrict,
    homeownerLocationEdited: true,
  );

  void updateContractorIdentity({
    required ProviderKind providerKind,
    required String businessName,
    File? logoFile,
    bool clearLogoFile = false,
  }) => state = state.copyWith(
    providerKind: providerKind,
    businessName: businessName,
    contractorLogoFile: logoFile,
    clearContractorLogoFile: clearLogoFile,
    contractorIdentityEdited: true,
  );

  void updateContractorServices({
    required List<String> specialties,
    required Set<String> serviceAreas,
  }) => state = state.copyWith(
    specialties: List.unmodifiable(specialties),
    serviceAreas: Set.unmodifiable(serviceAreas),
    contractorServicesEdited: true,
  );

  void clearAfterCompletion() => state = OnboardingDraft(accountId: _accountId);
}
