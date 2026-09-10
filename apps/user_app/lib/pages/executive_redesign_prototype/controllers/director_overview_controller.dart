import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

class DirectorOverviewData {
  const DirectorOverviewData({
    required this.counts,
    required this.devices,
    required this.incidents,
    required this.tracks,
    required this.notices,
    required this.energy,
    required this.water,
  });
  final Map<String, int> counts;
  final List<DeviceOption> devices;
  final List<IncidentSummaryItem> incidents;
  final List<LearningTrackOverview> tracks;
  final List<AppNotification> notices;
  final List<UtilityTrendPoint> energy, water;
  bool get isEmpty =>
      counts.values.every((n) => n == 0) &&
      devices.isEmpty &&
      incidents.isEmpty &&
      tracks.isEmpty &&
      notices.isEmpty &&
      energy.isEmpty &&
      water.isEmpty;
}

class DirectorOverviewController extends ChangeNotifier {
  DirectorOverviewController({this.loader});
  final Future<DirectorOverviewData> Function(int days)? loader;
  DirectorOverviewData? data;
  DateTime? loadedAt;
  bool loading = true, _disposed = false;
  String? error;
  int days = 7, _generation = 0;

  static Future<DirectorOverviewData> fetch(int days) async {
    if (AuthService.sessionToken == null) throw StateError('not_signed_in');
    final r = await Future.wait<Object>([
      UserAdminService.countUsersByRole(),
      LessonService.listSchoolDevices(),
      IncidentService.getIncidentSummary(),
      LearningTrackService.getOverview(),
      NotificationService.listMyNotifications(),
      UtilityService.getEnergyUsageTrend(days: days),
      UtilityService.getWaterUsageTrend(days: days),
    ]);
    return DirectorOverviewData(
      counts: r[0] as Map<String, int>,
      devices: r[1] as List<DeviceOption>,
      incidents: r[2] as List<IncidentSummaryItem>,
      tracks: r[3] as List<LearningTrackOverview>,
      notices: r[4] as List<AppNotification>,
      energy: r[5] as List<UtilityTrendPoint>,
      water: r[6] as List<UtilityTrendPoint>,
    );
  }

  Future<void> load({int? period}) async {
    days = period ?? days;
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await (loader ?? fetch)(days);
      if (_disposed || generation != _generation) return;
      data = result;
      loadedAt = DateTime.now();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      data = null;
      error = 'โหลดภาพรวมไม่สำเร็จ กรุณาลองอีกครั้ง';
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
