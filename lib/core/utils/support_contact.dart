import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extension.dart';
import '../widgets/batsh_snack.dart';

/// Single support entry point used by recovery states and account settings.
/// Replace this one value with the production support number before launch.
const String shattabSupportPhone = '201000000000';

void openShattabSupport(BuildContext context) {
  unawaited(_openShattabSupport(context));
}

Future<void> _openShattabSupport(BuildContext context) async {
  final uri = Uri.parse('https://wa.me/$shattabSupportPhone');
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    BatshSnack.error(context, context.l10n.couldNotOpenApp);
  }
}
