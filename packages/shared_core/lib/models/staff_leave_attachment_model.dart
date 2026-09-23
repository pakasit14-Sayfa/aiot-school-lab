/// A file attached to a `staff_leave_requests` row — ใบรับรองแพทย์ and the
/// like. Distinct from `leave_requests`' own attachments, which belong to
/// the unrelated parent-submitted *student* leave feature.
class StaffLeaveAttachment {
  const StaffLeaveAttachment({
    required this.attachmentId,
    required this.fileName,
    required this.fileType,
    required this.sizeBytes,
    required this.uploaderName,
    required this.uploadedAt,
  });

  final String attachmentId;
  final String fileName;

  /// `pdf` · `excel` · `word` · `image` · `other`, derived from the
  /// extension by the server.
  final String fileType;
  final int sizeBytes;
  final String uploaderName;
  final DateTime uploadedAt;

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory StaffLeaveAttachment.fromRow(Map<String, dynamic> row) =>
      StaffLeaveAttachment(
        attachmentId: row['attachment_id'].toString(),
        fileName: row['file_name']?.toString() ?? '',
        fileType: row['file_type']?.toString() ?? 'other',
        sizeBytes: _int(row['size_bytes']),
        uploaderName: row['uploader_name']?.toString().trim() ?? '',
        uploadedAt:
            DateTime.tryParse(
              row['uploaded_at']?.toString() ?? '',
            )?.toLocal() ??
            DateTime.now(),
      );
}
