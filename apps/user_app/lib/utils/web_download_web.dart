import 'dart:html' as html;
import 'dart:typed_data';

void downloadBytes({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
