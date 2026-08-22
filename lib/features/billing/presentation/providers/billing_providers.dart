import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/payment_repository.dart';
import '../../domain/billing_state.dart';

final billingStateProvider = FutureProvider.autoDispose<BillingState>((ref) {
  return ref.watch(paymentRepositoryProvider).fetchBillingState();
});
