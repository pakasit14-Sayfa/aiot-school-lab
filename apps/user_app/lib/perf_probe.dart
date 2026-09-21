// ชั่วคราวสำหรับวัดผลบนเครื่องจริง — ห้าม commit
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PerfProbe {
  static File? _f;
  static Future<void> mark(String line) async {
    try {
      _f ??= File('${(await getApplicationDocumentsDirectory()).path}/perf.log');
      await _f!.writeAsString(
        '${DateTime.now().toIso8601String()} $line\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }
}
