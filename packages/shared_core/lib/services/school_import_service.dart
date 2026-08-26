import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:http/http.dart' as http;

/// Result of a real backend bulk-import RPC call
/// (import_school_buildings_batch / import_school_rooms_batch /
/// import_school_devices_batch — see supabase/migrations/
/// 20260826150000_school_admin_bulk_import.sql).
class BulkImportResult {
  const BulkImportResult({
    required this.success,
    required this.insertedCount,
    required this.skipped,
  });

  factory BulkImportResult.fromJson(Map<String, dynamic> json) {
    final rawSkipped = json['skipped'];
    return BulkImportResult(
      success: json['success'] == true,
      insertedCount: (json['inserted_count'] as num?)?.toInt() ?? 0,
      skipped: rawSkipped is List
          ? rawSkipped
              .map((e) => SkippedRow.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }

  final bool success;
  final int insertedCount;
  final List<SkippedRow> skipped;
}

class SkippedRow {
  const SkippedRow({required this.row, required this.reason});

  factory SkippedRow.fromJson(Map<String, dynamic> json) => SkippedRow(
        row: (json['row'] as num?)?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? 'unknown',
      );

  final int row;
  final String reason;

  static String reasonLabel(String reason) => switch (reason) {
        'missing_required_field' => 'ข้อมูลที่จำเป็นไม่ครบ',
        'duplicate_code' => 'รหัสซ้ำกับข้อมูลที่มีอยู่',
        'duplicate_serial_no' => 'หมายเลขซีเรียลซ้ำกับข้อมูลที่มีอยู่',
        'building_not_found' => 'ไม่พบอาคารที่อ้างอิง',
        'invalid_device_type' => 'ประเภทอุปกรณ์ไม่ถูกต้อง',
        _ => reason,
      };
}

enum ImportRowStatus { ready, needsFix, warning }

/// One parsed, validated row — drives both the preview grid and the
/// exact payload sent to the backend RPC.
class ImportPreviewRow {
  const ImportPreviewRow({
    required this.rowNumber,
    required this.code,
    required this.name,
    required this.detail,
    required this.status,
    required this.payload,
    this.rowType,
  });

  final int rowNumber;
  final String code;
  final String name;
  final String detail;
  final ImportRowStatus status;
  final Map<String, dynamic> payload;

  /// For อาคารและห้อง only: 'อาคาร' or 'ห้อง'
  final String? rowType;
}

const Map<String, String> deviceTypeThaiLabels = {
  'mini_pc': 'มินิพีซี',
  'aiot_gateway': 'เกตเวย์ AIoT',
  'pm25_sensor': 'เซนเซอร์ PM2.5',
  'air_quality_sensor': 'เซนเซอร์คุณภาพอากาศ',
  'light_sensor': 'เซนเซอร์แสง',
  'energy_meter': 'มิเตอร์ไฟฟ้า',
  'camera': 'กล้อง',
  'relay': 'รีเลย์',
  'emergency_button': 'ปุ่มฉุกเฉิน',
  'warning_light': 'ไฟเตือน',
  'water_meter': 'มิเตอร์น้ำ',
};

class SchoolImportService {
  /// Parse a real uploaded .xlsx/.xls/.csv file into raw string-keyed rows,
  /// keyed by the header row. Returns an empty list if the file has no data
  /// rows below the header.
  static List<Map<String, String>> parseFile(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv')) {
      return _parseCsv(utf8.decode(bytes, allowMalformed: true));
    }
    return _parseExcel(bytes);
  }

  static List<Map<String, String>> _parseCsv(String content) {
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(content, eol: '\n');
    return _rowsToMaps(rows);
  }

  static List<Map<String, String>> _parseExcel(Uint8List bytes) {
    final workbook = xls.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) return [];
    final sheet = workbook.tables[workbook.tables.keys.first]!;
    final rows = sheet.rows
        .map((row) => row.map((cell) => cell?.value?.toString() ?? '').toList())
        .toList();
    return _rowsToMaps(rows);
  }

  static List<Map<String, String>> _rowsToMaps(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];
    final headers = rows.first.map((h) => h.toString().trim()).toList();
    final result = <Map<String, String>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final isBlank = row.every((c) => c.toString().trim().isEmpty);
      if (isBlank) continue;
      final map = <String, String>{};
      for (var col = 0; col < headers.length; col++) {
        map[headers[col]] = col < row.length ? row[col].toString().trim() : '';
      }
      result.add(map);
    }
    return result;
  }

  /// Fetch a Google Sheets "Publish to web → CSV" export link and parse it
  /// the same way as an uploaded .csv file. Only public published links are
  /// supported — no OAuth/private-sheet access.
  static Future<List<Map<String, String>>> fetchGoogleSheetCsv(String publishedUrl) async {
    final uri = Uri.tryParse(publishedUrl.trim());
    if (uri == null) {
      throw const FormatException('ลิงก์ Google Sheets ไม่ถูกต้อง');
    }
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('โหลดข้อมูลจาก Google Sheets ไม่สำเร็จ (HTTP ${response.statusCode})');
    }
    return _parseCsv(response.body);
  }

  /// Validate raw parsed rows for the given data type (the same Thai labels
  /// already used as SchoolImportPage's _dataType state), producing the rows
  /// the preview grid renders and the exact payload each RPC expects.
  static List<ImportPreviewRow> validateRows(
    String dataType,
    List<Map<String, String>> rawRows, {
    List<String> existingBuildingCodes = const [],
  }) {
    return switch (dataType) {
      'ครูและบุคลากร' => _validateUsers(rawRows, isTeacher: true),
      'อาคารและห้อง' => _validateBuildingsAndRooms(rawRows, existingBuildingCodes),
      'อุปกรณ์' => _validateDevices(rawRows, requireKitCode: false),
      'ชุดฝึก' => _validateDevices(rawRows, requireKitCode: true),
      _ => _validateUsers(rawRows, isTeacher: false),
    };
  }

  static final RegExp _emailRegex =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  static List<ImportPreviewRow> _validateUsers(
    List<Map<String, String>> rawRows, {
    required bool isTeacher,
  }) {
    final seenCodes = <String>{};
    final out = <ImportPreviewRow>[];
    for (var i = 0; i < rawRows.length; i++) {
      final r = rawRows[i];
      final code = (r['รหัสนักเรียน'] ?? r['รหัสประจำตัว'] ?? '').trim();
      final name = (r['ชื่อ-สกุล'] ?? r['ชื่อ'] ?? '').trim();
      final email = (r['อีเมล'] ?? '').trim();
      final building = (r['ห้องเรียน'] ?? r['ห้อง'] ?? '').trim();

      ImportRowStatus status = ImportRowStatus.ready;
      String detail = building.isEmpty ? '-' : building;

      if (name.isEmpty) {
        status = ImportRowStatus.needsFix;
        detail = 'ไม่มีชื่อ-สกุล';
      } else if (email.isNotEmpty && !_emailRegex.hasMatch(email)) {
        status = ImportRowStatus.needsFix;
        detail = 'รูปแบบอีเมลไม่ถูกต้อง';
      } else if (code.isNotEmpty && !seenCodes.add(code)) {
        status = ImportRowStatus.needsFix;
        detail = 'รหัสซ้ำในไฟล์นี้';
      } else if (email.isEmpty) {
        status = ImportRowStatus.warning;
        detail = 'ไม่มีอีเมล (ระบบจะสร้างให้อัตโนมัติ)';
      }

      out.add(ImportPreviewRow(
        rowNumber: i + 2,
        code: code.isEmpty ? '-' : code,
        name: name.isEmpty ? '(ไม่มีชื่อ)' : name,
        detail: detail,
        status: status,
        payload: {
          'name': name,
          if (email.isNotEmpty) 'email': email,
          'student_code': code,
          'building': building,
        },
      ));
    }
    return out;
  }

  static List<ImportPreviewRow> _validateBuildingsAndRooms(
    List<Map<String, String>> rawRows,
    List<String> existingBuildingCodes,
  ) {
    final seenBuildingCodes = <String>{...existingBuildingCodes};
    final seenRoomCodes = <String>{};
    final newBuildingCodesInFile = <String>{};
    final out = <ImportPreviewRow>[];

    for (var i = 0; i < rawRows.length; i++) {
      final r = rawRows[i];
      final type = (r['ประเภท'] ?? '').trim();
      final code = (r['รหัส'] ?? '').trim();
      final name = (r['ชื่อ'] ?? '').trim();

      if (type == 'อาคาร') {
        final floors = int.tryParse((r['จำนวนชั้น(สำหรับอาคาร)'] ?? r['จำนวนชั้น'] ?? '').trim());
        ImportRowStatus status = ImportRowStatus.ready;
        String detail = '${floors ?? 1} ชั้น';

        if (name.isEmpty || code.isEmpty) {
          status = ImportRowStatus.needsFix;
          detail = 'ข้อมูลไม่ครบ (ต้องมีรหัสและชื่ออาคาร)';
        } else if (!seenBuildingCodes.add(code)) {
          status = ImportRowStatus.needsFix;
          detail = 'รหัสอาคารซ้ำ';
        } else {
          newBuildingCodesInFile.add(code);
        }

        out.add(ImportPreviewRow(
          rowNumber: i + 2,
          code: code.isEmpty ? '-' : code,
          name: name.isEmpty ? '(ไม่มีชื่อ)' : name,
          detail: detail,
          status: status,
          rowType: 'อาคาร',
          payload: {'name': name, 'code': code, 'floors': floors ?? 1},
        ));
      } else if (type == 'ห้อง') {
        final buildingCode = (r['รหัสอาคาร(สำหรับห้องเท่านั้น)'] ?? r['รหัสอาคาร'] ?? '').trim();
        final floor = (r['ชั้นที่ตั้ง(สำหรับห้อง)'] ?? r['ชั้น'] ?? '').trim();
        final capacity = int.tryParse((r['ความจุ(สำหรับห้อง)'] ?? r['ความจุ'] ?? '').trim());

        ImportRowStatus status = ImportRowStatus.ready;
        String detail = 'อาคาร $buildingCode';

        if (name.isEmpty || code.isEmpty || buildingCode.isEmpty) {
          status = ImportRowStatus.needsFix;
          detail = 'ข้อมูลไม่ครบ (ต้องมีรหัสห้อง ชื่อห้อง และรหัสอาคาร)';
        } else if (!seenBuildingCodes.contains(buildingCode) &&
            !newBuildingCodesInFile.contains(buildingCode)) {
          status = ImportRowStatus.needsFix;
          detail = 'ไม่พบอาคารที่อ้างอิง ($buildingCode)';
        } else if (!seenRoomCodes.add(code)) {
          status = ImportRowStatus.needsFix;
          detail = 'รหัสห้องซ้ำ';
        }

        out.add(ImportPreviewRow(
          rowNumber: i + 2,
          code: code.isEmpty ? '-' : code,
          name: name.isEmpty ? '(ไม่มีชื่อ)' : name,
          detail: detail,
          status: status,
          rowType: 'ห้อง',
          payload: {
            'name': name,
            'code': code,
            'building_code': buildingCode,
            'floor': floor,
            'capacity': capacity ?? 30,
          },
        ));
      } else {
        out.add(ImportPreviewRow(
          rowNumber: i + 2,
          code: code.isEmpty ? '-' : code,
          name: name.isEmpty ? '(ไม่มีชื่อ)' : name,
          detail: 'คอลัมน์ "ประเภท" ต้องเป็น "อาคาร" หรือ "ห้อง" เท่านั้น',
          status: ImportRowStatus.needsFix,
          rowType: null,
          payload: const {},
        ));
      }
    }
    return out;
  }

  static List<ImportPreviewRow> _validateDevices(
    List<Map<String, String>> rawRows, {
    required bool requireKitCode,
  }) {
    final seenSerials = <String>{};
    final out = <ImportPreviewRow>[];

    for (var i = 0; i < rawRows.length; i++) {
      final r = rawRows[i];
      final name = (r['ชื่ออุปกรณ์'] ?? r['ชื่อชุดฝึก'] ?? '').trim();
      final typeRaw = (r['ประเภท'] ?? r['ประเภทอุปกรณ์หลัก'] ?? '').trim();
      final location = (r['ตำแหน่งติดตั้ง'] ?? '').trim();
      final serialNo = (r['หมายเลขซีเรียล'] ?? '').trim();
      final kitCode = (r['รหัสชุดฝึก'] ?? '').trim();

      final resolvedType = deviceTypeThaiLabels.entries
          .firstWhere(
            (e) => e.key == typeRaw || e.value == typeRaw,
            orElse: () => const MapEntry('', ''),
          )
          .key;

      ImportRowStatus status = ImportRowStatus.ready;
      String detail = [
        if (location.isNotEmpty) location,
        if (kitCode.isNotEmpty) 'ชุดฝึก: $kitCode',
      ].join(' • ');
      if (detail.isEmpty) detail = '-';

      if (name.isEmpty || typeRaw.isEmpty) {
        status = ImportRowStatus.needsFix;
        detail = 'ข้อมูลไม่ครบ (ต้องมีชื่อและประเภท)';
      } else if (resolvedType.isEmpty) {
        status = ImportRowStatus.needsFix;
        detail = 'ประเภทอุปกรณ์ไม่ถูกต้อง: $typeRaw';
      } else if (requireKitCode && kitCode.isEmpty) {
        status = ImportRowStatus.needsFix;
        detail = 'ชุดฝึกต้องระบุรหัสชุดฝึก';
      } else if (serialNo.isNotEmpty && !seenSerials.add(serialNo)) {
        status = ImportRowStatus.needsFix;
        detail = 'หมายเลขซีเรียลซ้ำในไฟล์นี้';
      } else if (serialNo.isEmpty) {
        status = ImportRowStatus.warning;
        detail = 'ไม่มีหมายเลขซีเรียล';
      }

      out.add(ImportPreviewRow(
        rowNumber: i + 2,
        code: serialNo.isEmpty ? '-' : serialNo,
        name: name.isEmpty ? '(ไม่มีชื่อ)' : name,
        detail: detail,
        status: status,
        payload: {
          'name': name,
          'type': resolvedType,
          if (location.isNotEmpty) 'location': location,
          if (serialNo.isNotEmpty) 'serial_no': serialNo,
          if (kitCode.isNotEmpty) 'kit_code': kitCode,
        },
      ));
    }
    return out;
  }

  /// Real downloadable CSV template per data type (UTF-8 with BOM so Thai
  /// text opens correctly in Excel).
  static Uint8List buildTemplateCsv(String dataType) {
    final List<List<String>> rows = switch (dataType) {
      'ครูและบุคลากร' => [
          ['รหัสประจำตัว', 'ชื่อ-สกุล', 'อีเมล', 'ห้องเรียน'],
          ['TC-2569-011', 'นางสาวสุดารัตน์ ใจดี', 'sudarat@school.ac.th', 'ฝ่ายวิชาการ'],
        ],
      'อาคารและห้อง' => [
          [
            'ประเภท',
            'รหัส',
            'ชื่อ',
            'รหัสอาคาร(สำหรับห้องเท่านั้น)',
            'จำนวนชั้น(สำหรับอาคาร)',
            'ชั้นที่ตั้ง(สำหรับห้อง)',
            'ความจุ(สำหรับห้อง)',
          ],
          ['อาคาร', 'BLD-A', 'อาคารเรียน A', '', '3', '', ''],
          ['ห้อง', 'ROOM-A101', 'ห้อง 101', 'BLD-A', '', '1', '30'],
        ],
      'อุปกรณ์' => [
          ['ชื่ออุปกรณ์', 'ประเภท', 'ตำแหน่งติดตั้ง', 'หมายเลขซีเรียล'],
          ['เซนเซอร์ PM2.5 ห้อง 101', 'pm25_sensor', 'อาคาร A ห้อง 101', 'SN-0001'],
        ],
      'ชุดฝึก' => [
          ['ชื่อชุดฝึก', 'ประเภทอุปกรณ์หลัก', 'ตำแหน่งติดตั้ง', 'รหัสชุดฝึก'],
          ['ชุดฝึก AIoT ห้อง 101', 'relay', 'Lab 3', 'KIT-001'],
        ],
      _ => [
          ['รหัสนักเรียน', 'ชื่อ-สกุล', 'อีเมล', 'ห้องเรียน'],
          ['ST-2569-0013', 'เด็กชายธีรภัทร ใจดี', 'theerapat@school.ac.th', 'ม.1/1'],
        ],
    };
    final csv = const ListToCsvConverter().convert(rows);
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
  }
}
