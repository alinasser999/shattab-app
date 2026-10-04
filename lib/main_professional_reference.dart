import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import 'app.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/discovery/data/discovery_repository.dart';
import 'features/discovery/domain/professional_reference_fixture.dart';
import 'features/portfolio/data/portfolio_repository.dart';
import 'features/reviews/data/reviews_repository.dart';
import 'features/saved/data/saved_repository.dart';
import 'features/saved/presentation/providers/saved_providers.dart';

const _fixtureSupabaseUrl = 'http://127.0.0.1:54321';
const _fixtureAnonKey = 'professional-reference-local-placeholder';

Future<void> main() async {
  if (!professionalReferenceEnabled) {
    throw StateError(
      'The professional reference entry point requires a debug build and '
      '--dart-define=SHATTAB_PROFESSIONAL_REFERENCE=true.',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();
  // flutter_dotenv 6 does not expose testLoad; loadFromString gives this
  // standalone debug target local placeholders without touching the real .env.
  dotenv.loadFromString(
    envString:
        'SUPABASE_URL=$_fixtureSupabaseUrl\nSUPABASE_ANON_KEY=$_fixtureAnonKey',
  );
  await Supabase.initialize(
    url: _fixtureSupabaseUrl,
    anonKey: _fixtureAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
  );

  final localClient = Supabase.instance.client;
  runApp(
    ProviderScope(
      overrides: [
        // Always remain a signed-out guest. This also keeps route guards on
        // the same public browsing path as a real signed-out homeowner.
        currentSessionProvider.overrideWith((_) => null),
        discoveryRepositoryProvider.overrideWithValue(
          ProfessionalReferenceDiscoveryRepository(localClient),
        ),
        portfolioRepositoryProvider.overrideWithValue(
          ProfessionalReferencePortfolioRepository(localClient),
        ),
        reviewsRepositoryProvider.overrideWithValue(
          ProfessionalReferenceReviewsRepository(localClient),
        ),
        savedRepositoryProvider.overrideWithValue(
          ProfessionalReferenceSavedRepository(localClient),
        ),
        savedContractorIdsProvider.overrideWith(
          (ref) async => ref.watch(professionalReferenceSavedIdsProvider),
        ),
        savedContractorsProvider.overrideWith(
          _ProfessionalReferenceSavedContractors.new,
        ),
        savedControllerProvider.overrideWith(
          _ProfessionalReferenceSavedController.new,
        ),
      ],
      child: const BatshApp(),
    ),
  );

  // MaterialApp's generated title is applied while its first frame builds.
  // Write the fixture label after that frame so the app title cannot replace it.
  if (kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(Duration.zero, () {
        web.document.title =
            'Shattab — Professional reference fixture (development)';
      });
    });
  }
}

/// Same saved-provider contract as production, but state stays in memory and
/// is shared by the discovery card and public profile.
class _ProfessionalReferenceSavedController extends SavedController {
  @override
  Future<void> toggle(String contractorId) async {
    if (!ProfessionalReferenceFixture.isFixtureId(contractorId)) return;
    ref
        .read(professionalReferenceSavedIdsProvider.notifier)
        .toggle(contractorId);
  }
}

/// Preserve the existing saved-screen data shape for any route reached during
/// fixture browsing, without reading the saved_contractors table.
class _ProfessionalReferenceSavedContractors extends SavedContractors {
  @override
  Future<SavedContractorsState> build() async {
    final savedIds = ref.watch(professionalReferenceSavedIdsProvider);
    return SavedContractorsState(
      items: ProfessionalReferenceFixture.listings
          .where((listing) => savedIds.contains(listing.id))
          .toList(growable: false),
      hasMore: false,
    );
  }

  @override
  Future<void> loadMore() async {}
}
