import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a real browser download of [bytes] as [filename]. Web-only —
/// this app only ships to `flutter build web` (see CLAUDE.md). Needed
/// because `file_picker`'s `saveFile()` has no web implementation as of
/// v8.3.7 — it falls through to the base class's
/// `UnimplementedError('saveFile() has not been implemented.')` on web,
/// confirmed live while building the AIoT dashboard's CSV/Excel export.
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
