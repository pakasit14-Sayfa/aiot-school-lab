void downloadBytes({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) {
  // No-op on VM/non-web platforms (e.g. unit tests)
}
