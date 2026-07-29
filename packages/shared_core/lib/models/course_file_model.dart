class CourseFile {
  final String id;
  final String storagePath;
  final String fileName;
  final int sizeBytes;
  final String uploadedBy;
  final String uploaderFirstName;
  final String uploaderLastName;
  final DateTime createdAt;

  const CourseFile({
    required this.id,
    required this.storagePath,
    required this.fileName,
    required this.sizeBytes,
    required this.uploadedBy,
    required this.uploaderFirstName,
    required this.uploaderLastName,
    required this.createdAt,
  });

  factory CourseFile.fromRow(Map<String, dynamic> row) => CourseFile(
    id: row['file_id'] as String,
    storagePath: row['storage_path'] as String,
    fileName: row['file_name'] as String,
    sizeBytes: (row['size_bytes'] as num).toInt(),
    uploadedBy: row['uploaded_by'] as String,
    uploaderFirstName: row['uploader_first_name'] as String,
    uploaderLastName: row['uploader_last_name'] as String,
    createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
  );

  String get uploaderFullName => '$uploaderFirstName $uploaderLastName';

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
