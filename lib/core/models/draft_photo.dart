import 'dart:io';
import 'dart:typed_data';

class DraftPhoto {
  const DraftPhoto({this.file, this.bytes, this.url});

  final File? file;
  final Uint8List? bytes;
  final String? url;

  bool get isLocal => file != null || bytes != null;
}
