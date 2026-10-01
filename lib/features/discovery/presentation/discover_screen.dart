import 'package:flutter/material.dart';

import 'professional_directory_screen.dart';

/// Route-compatible entry point for the single authoritative directory.
///
/// Keeping this wrapper preserves the router and legacy imports while making
/// it impossible for the retired campaign composition to drift from the live
/// discovery workflow.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProfessionalDirectoryScreen();
}
