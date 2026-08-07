import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// The single application logging entry point.
///
/// Production logs start at warning level. Error values are sanitized before
/// they reach the console or a log collector so auth material and personal
/// fields are not copied into diagnostics by accident.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    level: kDebugMode ? Level.debug : Level.warning,
    printer: SimplePrinter(printTime: true, colors: false),
  );

  static void debug(String event, {Map<String, Object?> context = const {}}) {
    _logger.d(_format(event, context));
  }

  static void info(String event, {Map<String, Object?> context = const {}}) {
    _logger.i(_format(event, context));
  }

  static void warning(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _logger.w(
      _format(event, context),
      error: _sanitize(error),
      stackTrace: stackTrace,
    );
  }

  static void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _logger.e(
      _format(event, context),
      error: _sanitize(error),
      stackTrace: stackTrace,
    );
  }

  @visibleForTesting
  static String sanitizeForLog(Object? value) => _sanitize(value) ?? '';

  static String? _sanitize(Object? value) {
    if (value == null) return null;
    return _redact(value.toString());
  }

  static String _format(String event, Map<String, Object?> context) {
    if (context.isEmpty) return event;
    final values = context.map(
      (key, value) => MapEntry(key, _redact(value?.toString() ?? 'null')),
    );
    return '$event ${values.entries.map((entry) => '${entry.key}=${entry.value}').join(' ')}';
  }

  static String _redact(String value) {
    final redacted = value.replaceAllMapped(
      RegExp(
        r'(password|token|secret|api[_-]?key|authorization|bearer|phone|email)\s*[:=]\s*[^,;\s]+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=[REDACTED]',
    );
    if (redacted.length <= 500) return redacted;
    return '${redacted.substring(0, 500)}...';
  }
}
