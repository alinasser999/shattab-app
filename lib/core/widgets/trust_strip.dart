import 'package:flutter/material.dart';
import 'package:batsh/features/discovery/domain/trust_signals.dart';

class TrustStrip extends StatelessWidget {
  final TrustProfile profile;

  const TrustStrip({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
