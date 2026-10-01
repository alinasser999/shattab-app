import 'package:web/web.dart' as web;

Uri? _capturedBrowserUri;

Uri? _readBrowserUri() {
  final href = web.window.location.href;
  return href.isEmpty ? null : Uri.tryParse(href);
}

void captureInitialBrowserUri() {
  _capturedBrowserUri = _readBrowserUri();
}

Uri? currentBrowserUri() => _capturedBrowserUri ?? _readBrowserUri();
