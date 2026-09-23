/// สิ่งที่อยู่ในคลังความรู้ของรายวิชา
///
/// 2026-09-23 คลังรับ "ลิงก์" ด้วย ไม่ใช่แค่ไฟล์ที่อัปขึ้นถัง — ลิงก์ไม่มี
/// [storagePath] และไม่มีขนาด ฉะนั้นสองฟิลด์นั้นจึงเป็น null ได้ อย่าอ่านตรง ๆ
/// โดยไม่ดู [kind] ก่อน
enum CourseFileKind { file, link }

class CourseFile {
  final String id;
  final CourseFileKind kind;

  /// มีค่าเมื่อ [kind] เป็น file เท่านั้น
  final String? storagePath;

  /// มีค่าเมื่อ [kind] เป็น link เท่านั้น
  final String? url;

  final String fileName;

  /// หมวด/บทเรียนที่ครูกรอก — ก่อน 2026-09-23 ช่องนี้มีให้กรอกในชีตอัปโหลด
  /// แต่ RPC ไม่มีพารามิเตอร์รับ ค่าที่พิมพ์จึงหายทุกครั้ง
  final String? category;

  final int? sizeBytes;
  final String uploadedBy;
  final String uploaderFirstName;
  final String uploaderLastName;
  final DateTime createdAt;

  const CourseFile({
    required this.id,
    required this.fileName,
    // ของเดิมทั้งหมดในคลังเป็นไฟล์ — ลิงก์เพิ่งมีเมื่อ 2026-09-23 ฉะนั้น
    // ค่าปริยายเป็น file ทำให้ตัวเรียกเดิมไม่ต้องแก้
    this.kind = CourseFileKind.file,
    required this.uploadedBy,
    required this.uploaderFirstName,
    required this.uploaderLastName,
    required this.createdAt,
    this.storagePath,
    this.url,
    this.category,
    this.sizeBytes,
  });

  factory CourseFile.fromRow(Map<String, dynamic> row) {
    final size = row['size_bytes'] as num?;
    return CourseFile(
      id: row['file_id'] as String,
      kind: (row['kind'] as String?) == 'link'
          ? CourseFileKind.link
          : CourseFileKind.file,
      storagePath: row['storage_path'] as String?,
      url: row['url'] as String?,
      fileName: row['file_name'] as String,
      category: (row['category'] as String?)?.trim().isEmpty ?? true
          ? null
          : (row['category'] as String).trim(),
      sizeBytes: size?.toInt(),
      uploadedBy: row['uploaded_by'] as String,
      uploaderFirstName: row['uploader_first_name'] as String,
      uploaderLastName: row['uploader_last_name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
    );
  }

  bool get isLink => kind == CourseFileKind.link;

  String get uploaderFullName => '$uploaderFirstName $uploaderLastName';

  /// 'บทที่ 1 · 1.2 MB' — ลิงก์ไม่มีขนาด จึงบอกว่าเป็นลิงก์แทน
  String get subtitle {
    final left = category ?? 'ยังไม่ระบุหมวด';
    return isLink ? '$left · ลิงก์' : '$left · $formattedSize';
  }

  String get formattedSize {
    final b = sizeBytes;
    if (b == null) return 'ไม่ทราบขนาด';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// ไฟล์ในคลังหนึ่งชิ้น ที่ถูกผูกเข้ากับใบงานหนึ่งใบ
///
/// ใบงานไม่ได้ถือสำเนาไฟล์เอง แค่ชี้ไปที่ของในคลัง — การ "เอาออกจากใบงาน"
/// จึงลบเฉพาะการผูกนี้ ไม่ได้ลบไฟล์
class AssignmentAttachment {
  final String id;
  final String courseFileId;
  final CourseFileKind kind;
  final String fileName;
  final String? url;
  final String? category;
  final int? sizeBytes;
  final int sortOrder;

  const AssignmentAttachment({
    required this.id,
    required this.courseFileId,
    required this.kind,
    required this.fileName,
    required this.sortOrder,
    this.url,
    this.category,
    this.sizeBytes,
  });

  factory AssignmentAttachment.fromRow(Map<String, dynamic> row) {
    final size = row['size_bytes'] as num?;
    return AssignmentAttachment(
      id: row['attachment_id'] as String,
      courseFileId: row['file_id'] as String,
      kind: (row['kind'] as String?) == 'link'
          ? CourseFileKind.link
          : CourseFileKind.file,
      fileName: row['file_name'] as String,
      url: row['url'] as String?,
      category: (row['category'] as String?)?.trim().isEmpty ?? true
          ? null
          : (row['category'] as String).trim(),
      sizeBytes: size?.toInt(),
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isLink => kind == CourseFileKind.link;

  /// รูปแสดงตัวอย่างได้ ไฟล์อื่นใช้ไอคอนแทน
  bool get isImage {
    final n = fileName.toLowerCase();
    return !isLink &&
        (n.endsWith('.png') ||
            n.endsWith('.jpg') ||
            n.endsWith('.jpeg') ||
            n.endsWith('.gif') ||
            n.endsWith('.webp') ||
            n.endsWith('.heic'));
  }

  String get typeLabel {
    if (isLink) return 'ลิงก์';
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return 'ไฟล์';
    return fileName.substring(dot + 1).toUpperCase();
  }

  String get sizeLabel {
    final b = sizeBytes;
    if (b == null) return '';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
