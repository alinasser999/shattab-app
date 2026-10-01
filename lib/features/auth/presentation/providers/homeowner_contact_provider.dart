import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';

typedef HomeownerContact = ({String name, String phone});

/// Contact is looked up by brief only; the RPC owns the authorization rule.
final homeownerContactForBriefProvider = FutureProvider.autoDispose
    .family<HomeownerContact?, String>(
      (ref, briefId) => ref
          .watch(authRepositoryProvider)
          .fetchHomeownerContactForBrief(briefId),
    );
