import 'package:flutter/foundation.dart';
import 'package:shared_core/services/lesson_service.dart';
import 'package:shared_core/models/school_device_identity.dart';
import 'package:shared_core/services/supabase_config.dart'
    show PostgrestException;

class DirectorScanController extends ChangeNotifier {
  DirectorScanController({
    Future<SchoolDeviceIdentity?> Function(String)? lookup,
  }) : _lookup = lookup ?? LessonService.getSchoolDeviceByCode;
  final Future<SchoolDeviceIdentity?> Function(String) _lookup;
  SchoolDeviceIdentity? device;
  String code = '';
  String? error;
  bool loading = false, searched = false, _disposed = false;
  int _generation = 0;
  void clear() {
    ++_generation;
    device = null;
    error = null;
    loading = false;
    searched = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> search(String value) async {
    if (_disposed) return;
    final generation = ++_generation;
    code = value.trim();
    device = null;
    error = null;
    searched = false;
    if (code.isEmpty) {
      loading = false;
      error = 'กรุณาระบุรหัสอุปกรณ์';
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    try {
      final found = await _lookup(code);
      if (_disposed || generation != _generation) return;
      device = found;
      searched = true;
    } catch (e) {
      if (_disposed || generation != _generation) return;
      error = e is PostgrestException && e.message == 'ambiguous_device_code'
          ? 'รหัสตรงกับอุปกรณ์มากกว่าหนึ่งรายการ กรุณาใช้รหัสอุปกรณ์หรือ ID ที่ไม่ซ้ำ'
          : 'ไม่สามารถค้นหาอุปกรณ์ได้ กรุณาลองอีกครั้ง';
    }
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
