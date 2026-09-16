import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:shared_core/models/school_device_identity.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorCctvPage extends StatefulWidget {
  const DirectorCctvPage({super.key, this.listSchoolDevices, this.loadDeviceDetail});

  /// Injectable seam so widget tests can control the camera inventory
  /// without initializing a real Supabase client. Defaults to the real
  /// service call used in production.
  final Future<List<DeviceOption>> Function()? listSchoolDevices;

  /// Heartbeat facts for one camera (`get_school_device_detail`: last seen,
  /// firmware, IP) shown in the detail dialog. Injectable for tests.
  final Future<SchoolDeviceDetail?> Function(String deviceId)? loadDeviceDetail;

  @override
  State<DirectorCctvPage> createState() => _DirectorCctvPageState();
}

class _DirectorCctvPageState extends State<DirectorCctvPage> {
  String searchText = '';
  String selectedBuilding = 'ทุกอาคาร';
  String selectedStatus = 'ทุกสถานะ';

  List<CameraAccessGrantItem> _grants = [];
  bool _loadingGrants = false;
  // A failed load must not read as "no grants" — the two look identical
  // without this flag.
  bool _grantsFailed = false;

  // เดิมทั้ง 8 กล้อง/สถานะ/เวลาอัปเดตเป็นค่าคงที่ปลอมทั้งหมด (aiEnabled/
  // recording/alertCount/lastUpdate ก็เช่นกัน) ทำให้ ผอ. เข้าใจว่ากำลังดู
  // ข้อมูลกล้องสด ตอนนี้โหลดรายชื่อกล้องจริงจาก devices (type='camera')
  // ผ่าน list_school_devices ที่มี executive เข้าถึงได้อยู่แล้ว — ฟิลด์ที่
  // ไม่มีข้อมูลจริงรองรับเลย (AI/บันทึก/แจ้งเตือน/เวลาอัปเดต) ใส่ค่ากลาง
  // ที่สื่อว่า "ไม่มีข้อมูล" แทนการแต่งค่าที่ดูสมจริงขึ้นมา
  bool _camerasLoading = true;
  // Same reason as _grantsFailed: a backend that is down used to render as
  // "ยังไม่มีกล้องในระบบนี้", which is the opposite of what the director
  // needs to know.
  bool _camerasFailed = false;
  List<_CameraData> cameras = const [];

  @override
  void initState() {
    super.initState();
    _loadGrants();
    _loadCameras();
  }

  Future<void> _loadGrants() async {
    setState(() {
      _loadingGrants = true;
      _grantsFailed = false;
    });
    try {
      final list = await ExecutiveService.listCameraAccessGrants();
      if (mounted) {
        setState(() {
          _grants = list;
          _loadingGrants = false;
        });
      }
    } catch (e) {
      debugPrint('DirectorCctvPage grants load failed: $e');
      if (mounted) {
        setState(() {
          _loadingGrants = false;
          _grantsFailed = true;
        });
      }
    }
  }

  Future<void> _loadCameras() async {
    setState(() {
      _camerasLoading = true;
      _camerasFailed = false;
    });
    try {
      final listDevices =
          widget.listSchoolDevices ?? LessonService.listSchoolDevices;
      final devices = await listDevices();
      final cameraDevices = devices.where((d) => d.type == 'camera').toList();
      if (!mounted) return;
      setState(() {
        cameras = cameraDevices
            .map(
              (d) => _CameraData(
                id: d.id,
                name: d.name,
                building: d.location ?? 'ไม่ระบุอาคาร',
                location: d.location ?? 'ไม่ระบุตำแหน่ง',
                status: d.status == 'online' ? 'Online' : 'Offline',
                // aiEnabled / recording / aiMode / alertCount / lastUpdate
                // used to be hardcoded here (false / "ไม่มีข้อมูล") and then
                // rendered as "AI ปิด", "ไม่บันทึก", "ไม่ได้บันทึก" — claims
                // about a state no table records. Gone; the detail dialog
                // shows the real heartbeat (last seen / firmware / IP).
                color: AppPalette.learningBlue,
              ),
            )
            .toList();
        _camerasLoading = false;
        // The building options are derived from `cameras`; a stale choice
        // would leave the dropdown holding a value it no longer offers.
        if (!buildings.contains(selectedBuilding)) {
          selectedBuilding = 'ทุกอาคาร';
        }
      });
    } catch (e) {
      debugPrint('DirectorCctvPage cameras load failed: $e');
      if (mounted) {
        setState(() {
          _camerasLoading = false;
          _camerasFailed = true;
          cameras = const [];
        });
      }
    }
  }

  // Was a const list ('อาคาร 1', 'อาคาร 2', 'สนามกีฬา', ...) compared with
  // `device.location`, whose real values look like
  // 'อาคาร 3 (วิทยาศาสตร์) · ทางเข้าหลัก' — so picking any building hid every
  // camera. The options now come from the cameras actually loaded, so each
  // one matches at least one camera by construction.
  List<String> get buildings => [
    'ทุกอาคาร',
    ...{for (final c in cameras) c.building}.toList()..sort(),
  ];

  final List<String> statuses = const ['ทุกสถานะ', 'Online', 'Offline'];

  // "แจ้งเตือนจาก AI Camera" / "พื้นที่จัดเก็บ & AI Detection" cards and the
  // per-camera AI panel are gone: no RPC reads security_events and nothing
  // stores recording/storage state, so there was nothing to show but the
  // sentence saying so.

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCameras();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'กล้องวงจรปิด',
            subtitle:
                'สถานะออนไลน์ จุดติดตั้ง และการรายงานตัวล่าสุดของกล้องแต่ละตัว',
          ),
          const SizedBox(height: 14),
          _heroSection(),
          const SizedBox(height: 16),
          _cameraSection(filtered),
          const SizedBox(height: 16),
          _accessGrantsSection(),
        ],
      ),
    );
  }

  List<_CameraData> _filteredCameras() {
    final query = searchText.trim().toLowerCase();

    return cameras.where((camera) {
      final matchesSearch =
          query.isEmpty ||
          camera.id.toLowerCase().contains(query) ||
          camera.name.toLowerCase().contains(query) ||
          camera.location.toLowerCase().contains(query) ||
          camera.building.toLowerCase().contains(query);

      final matchesBuilding =
          selectedBuilding == 'ทุกอาคาร' || camera.building == selectedBuilding;

      final matchesStatus =
          selectedStatus == 'ทุกสถานะ' || camera.status == selectedStatus;

      return matchesSearch && matchesBuilding && matchesStatus;
    }).toList();
  }

  // V2 (เลือกจาก mockup 2 แบบ, director-cctv-redesign.html) — เดิมหน้านี้
  // แบ่งเป็น 3 การ์ดแยก (สถิติ 6 ช่อง / แจ้งเตือน AI / สถานะระบบ) ให้น้ำหนัก
  // เท่ากับกล้องทั้งที่กล้องคือเนื้อหาเดียวที่มีรายละเอียดจริงให้กดดู — ยุบ
  // เหลือสรุปเดียว (วงแหวน Online/ทั้งหมด + ประโยคสถานะ + การ์ดเล็ก 2 ใบ
  // สำหรับสิ่งที่ยังไม่รองรับ) ไม่มีตัวเลข/เงื่อนไขไหนถูกแต่งขึ้นใหม่เลย ทุก
  // ค่ายังมาจาก cameras/alerts เดิมทั้งหมด แค่จัดลำดับความสำคัญใหม่
  Widget _heroSection() {
    final total = cameras.length;
    final online = cameras.where((c) => c.status == 'Online').length;
    final offline = total - online;
    final offlineCameras = cameras.where((c) => c.status == 'Offline').toList();
    final ratio = total == 0 ? 0.0 : online / total;
    final statusColor = total == 0
        ? AppPalette.textMuted
        : offline == 0
        ? AppPalette.success
        : online == 0
        ? AppPalette.danger
        : AppPalette.warning;
    final String headline = _camerasFailed
        ? 'โหลดรายชื่อกล้องไม่สำเร็จ'
        : total == 0
        ? 'ยังไม่มีกล้องในระบบนี้'
        : offline == 0
        ? 'กล้องทั้งหมด $total ตัว ทำงานออนไลน์ครบ'
        : offline == 1
        ? '$total กล้องทั้งหมด · ${offlineCameras.first.name} กำลัง Offline'
        : '$total กล้องทั้งหมด · $offline กล้อง Offline';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: _camerasLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, box) {
                    final ring = SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(88, 88),
                            painter: _CctvRingPainter(
                              ratio: ratio,
                              color: statusColor,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                total == 0 ? '—' : '$online/$total',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                    final textCol = Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: box.maxWidth < 500 ? 14 : 0,
                          left: box.maxWidth < 500 ? 0 : 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (total > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.tint(statusColor, 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      offline == 0
                                          ? Icons.check_circle_rounded
                                          : Icons.warning_amber_rounded,
                                      size: 13,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      offline == 0
                                          ? 'ทำงานปกติ'
                                          : (offline == total
                                                ? 'ควรตรวจสอบ — กล้องทุกตัว Offline'
                                                : 'ควรตรวจสอบ — $offline กล้อง Offline'),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              headline,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (offlineCameras.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${offlineCameras.map((c) => c.name).join(', ')} '
                                'ไม่ได้รายงานตัวเข้ามา ควรตรวจสอบไฟเลี้ยงหรือเครือข่าย',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppPalette.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                    return box.maxWidth < 500
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [ring, textCol],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [ring, textCol],
                          );
                  },
                ),
              ],
            ),
    );
  }

  Widget _cameraSection(List<_CameraData> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กล้องทั้งหมด',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'กดที่กล้องเพื่อดูสถานะและการรายงานตัวล่าสุด (ยังไม่มีภาพสดในแอปนี้)',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          if (_camerasLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_camerasFailed)
            _loadFailedBox(
              'โหลดรายชื่อกล้องไม่สำเร็จ — ยังไม่ทราบว่ามีกล้องกี่ตัว',
              onRetry: _loadCameras,
            )
          else ...[
            _filters(),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'พบ ${filtered.length} กล้อง',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textMuted,
                  ),
                ),
                const Spacer(),
                if (_hasActiveFilters())
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('ล้างตัวกรอง'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 620) {
                  return Column(
                    children: [
                      for (int i = 0; i < filtered.length; i++) ...[
                        SizedBox(height: 276, child: _cameraCard(filtered[i])),
                        if (i != filtered.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  );
                }

                final columns = constraints.maxWidth < 1050 ? 2 : 3;

                return GridView.builder(
                  itemCount: filtered.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 276,
                  ),
                  itemBuilder: (context, index) {
                    return _cameraCard(filtered[index]);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _filters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;

        final search = TextField(
          onChanged: (value) {
            setState(() => searchText = value);
          },
          decoration: InputDecoration(
            hintText: 'ค้นหารหัสกล้อง จุดติดตั้ง อาคาร...',
            hintStyle: const TextStyle(fontSize: 9.4),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppPalette.primaryPink,
            ),
            filled: true,
            fillColor: AppPalette.pageBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppPalette.border),
            ),
          ),
        );

        final building = _dropdown(
          value: selectedBuilding,
          items: buildings,
          icon: Icons.apartment_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedBuilding = value);
          },
        );

        final status = _dropdown(
          value: selectedStatus,
          items: statuses,
          icon: Icons.wifi_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedStatus = value);
          },
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: building),
                  const SizedBox(width: 8),
                  Expanded(child: status),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: search),
            const SizedBox(width: 9),
            Expanded(child: building),
            const SizedBox(width: 9),
            Expanded(child: status),
          ],
        );
      },
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppPalette.primaryPink),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 9.3,
                  color: AppPalette.textDark,
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraCard(_CameraData camera) {
    final online = camera.status == 'Online';
    final statusColor = online
        ? AppPalette.environmentGreen
        : AppPalette.danger;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showCameraDetail(camera),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cameraPreview(camera, height: 145),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            camera.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          camera.status,
                          style: TextStyle(
                            fontSize: 8.3,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${camera.id} • ${camera.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.3,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraPreview(_CameraData camera, {required double height}) {
    final online = camera.status == 'Online';

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: online
              ? const [Color(0xFF36363D), Color(0xFF17171B)]
              : const [Color(0xFF68656A), Color(0xFF3C393E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Icon(
                online ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                size: height > 200 ? 64 : 42,
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 9,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: online ? AppPalette.success : AppPalette.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  // "LIVE" implied a stream; this is a status tile.
                  online ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            bottom: 9,
            child: Text(
              camera.id,
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return searchText.isNotEmpty ||
        selectedBuilding != 'ทุกอาคาร' ||
        selectedStatus != 'ทุกสถานะ';
  }

  void _clearFilters() {
    setState(() {
      searchText = '';
      selectedBuilding = 'ทุกอาคาร';
      selectedStatus = 'ทุกสถานะ';
    });
  }

  void _showCameraDetail(_CameraData camera) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 790),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      // เดิมสถานะ Offline ฝังอยู่แค่ 1 แถวในตาราง "ข้อมูลกล้อง"
                      // ด้านล่าง ทั้งที่เป็นเรื่องสำคัญที่สุด — ดึงขึ้นมาเป็น
                      // แบดจ์ที่หัวไดอะล็อกให้เห็นทันที (mockup V3,
                      // director-cctv-redesign.html)
                      final online = camera.status == 'Online';
                      final statusColor = online
                          ? AppPalette.success
                          : AppPalette.danger;
                      return Row(
                        children: [
                          Container(
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: AppPalette.tint(statusColor, 0.10),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.videocam_rounded,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        camera.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppPalette.tint(
                                          statusColor,
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            camera.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  // building กับ location มาจาก field เดียวกัน
                                  // (d.location ใน _loadCameras) เลยมีค่า
                                  // เหมือนกันเป๊ะเสมอ — ใส่ทั้งคู่ไปแล้วออกมา
                                  // เป็นข้อความซ้ำ "อาคาร 3... • ทางเข้าหลัก"
                                  // 2 รอบ (เห็นจากสกรีนช็อตจริง) โชว์แค่ตัวเดียว
                                  '${camera.id} • ${camera.location}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 13),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _cameraPreview(camera, height: 360),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 650) {
                                return Column(
                                  children: [
                                    _cameraInfoCard(camera),
                                    const SizedBox(height: 12),
                                    _cameraHeartbeatCard(camera),
                                  ],
                                );
                              }

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _cameraInfoCard(camera)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _cameraHeartbeatCard(camera)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // บันทึกภาพ / Playback / เต็มจอ used to sit here as live
                  // buttons that only raised a "ยังไม่มีระบบ…" snackbar. There
                  // is no recording, playback or stream backend, so per the
                  // DoD they are gone rather than clickable-and-inert.
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // สถานะ/รหัสกล้องย้ายขึ้นไปเป็นแบดจ์ที่หัวไดอะล็อกแล้ว (ดู _showCameraDetail)
  // การ์ดนี้เลยเหลือแค่รายละเอียดที่ไม่ได้อยู่ในหัวเรื่องแล้ว — เปลี่ยนจาก
  // แถวข้อความล้วนๆ (label ซ้าย/value ซ้ายติดกัน) เป็นคู่ label/value ชิดขอบ
  // ซ้าย-ขวาคั่นเส้นบางๆ อ่านไวกว่า (mockup V3, director-cctv-redesign.html)
  Widget _cameraInfoCard(_CameraData camera) {
    final online = camera.status == 'Online';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลกล้อง',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          // อาคาร/จุดติดตั้งเดิมเป็น 2 แถวแยกกัน แต่ทั้งคู่มาจาก field เดียวกัน
          // (d.location ใน _loadCameras — ยังไม่มีการแยกอาคารออกจากจุดติดตั้ง
          // ในระบบจริง) โชว์แยก 2 แถวเลยออกมาเป็นค่าเดียวกันเป๊ะ ดูเหมือนบั๊ก
          // (เห็นจากสกรีนช็อตจริง) — รวมเป็นแถวเดียว ไม่ทำเป็นข้อมูล 2 ชิ้นที่
          // ไม่มีอยู่จริง
          _detailRow('อาคาร/จุดติดตั้ง', camera.location, last: true),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppPalette.tint(
                online ? AppPalette.environmentGreen : AppPalette.danger,
                0.08,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  online
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 13,
                  color: online
                      ? AppPalette.environmentGreen
                      : AppPalette.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    online
                        ? 'กล้องเชื่อมต่อระบบกลางตามปกติ'
                        : 'กล้องไม่ตอบสนอง ควรตรวจสอบไฟเลี้ยงหรือเครือข่าย',
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Real heartbeat facts from `get_school_device_detail` — last report,
  /// firmware, IP. Replaces the "AI Detection" panel, whose every value was
  /// a hardcoded placeholder.
  Widget _cameraHeartbeatCard(_CameraData camera) {
    final load = widget.loadDeviceDetail ??
        (String id) => SchoolAdminPlatformService().getDeviceDetail(id);
    String stamp(DateTime? t) {
      if (t == null) return 'ยังไม่เคยรายงาน';
      final l = t.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(l.day)}/${two(l.month)}/${l.year + 543} ${two(l.hour)}:${two(l.minute)}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การรายงานตัวของอุปกรณ์',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          FutureBuilder<SchoolDeviceDetail?>(
            future: load(camera.id),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Text(
                  'กำลังโหลด…',
                  style: TextStyle(fontSize: 9, color: AppPalette.textMuted),
                );
              }
              if (snap.hasError || snap.data == null) {
                return const Text(
                  'โหลดข้อมูลการรายงานตัวไม่สำเร็จ',
                  style: TextStyle(fontSize: 9, color: AppPalette.danger),
                );
              }
              final d = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('รายงานตัวล่าสุด', stamp(d.lastSeenAt)),
                  _detailRow('เฟิร์มแวร์', d.firmwareVersion ?? 'ยังไม่เคยรายงาน'),
                  _detailRow('IP', d.ipAddress ?? 'ยังไม่เคยรายงาน', last: true),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value, {
    bool muted = false,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppPalette.border)),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 9, color: AppPalette.textMuted),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: muted ? AppPalette.textMuted : AppPalette.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadFailedBox(String text, {required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppPalette.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: AppPalette.danger),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }

  Widget _accessGrantsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppPalette.tint(AppPalette.learningBlue, 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: AppPalette.learningBlue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การจัดการสิทธิ์การเข้าถึงกล้อง (Camera Access Grants)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ตรวจสอบและจัดการสิทธิ์การดูข้อมูลกล้องวงจรปิดตามนโยบาย PDPA',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_loadingGrants)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _loadGrants,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'รีเฟรชสิทธิ์',
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_grantsFailed && !_loadingGrants)
            _loadFailedBox(
              'โหลดรายการสิทธิ์ไม่สำเร็จ — ยังไม่ทราบว่ามีสิทธิ์ค้างอยู่หรือไม่',
              onRetry: _loadGrants,
            )
          else if (_grants.isEmpty && !_loadingGrants)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.pageBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.border),
              ),
              child: const Text(
                'ไม่มีรายการสิทธิ์การเข้าถึงกล้องที่บันทึกไว้ในระบบ',
                style: TextStyle(fontSize: 11, color: AppPalette.textMuted),
              ),
            )
          else
            Column(
              children: [
                for (final grant in _grants)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppPalette.pageBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: grant.isActive
                                ? AppPalette.tint(AppPalette.success, 0.12)
                                : AppPalette.tint(AppPalette.danger, 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            grant.isActive
                                ? Icons.verified_user_rounded
                                : Icons.gpp_bad_rounded,
                            color: grant.isActive
                                ? AppPalette.success
                                : AppPalette.danger,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    grant.userName,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppPalette.softTag,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      grant.userRole,
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '• กล้อง: ${grant.cameraName}',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'เหตุผล: ${grant.reason} • ใช้ได้ถึง ${grant.validUntil.day}/${grant.validUntil.month}/${grant.validUntil.year + 543}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppPalette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (grant.isActive)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppPalette.danger,
                              side: const BorderSide(color: AppPalette.danger),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                    'ยกเลิกสิทธิ์การเข้าถึงกล้อง',
                                  ),
                                  content: Text(
                                    'คุณต้องการยกเลิกสิทธิ์ของ ${grant.userName} สำหรับกล้อง ${grant.cameraName} หรือไม่?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('ยกเลิก'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppPalette.danger,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('ยืนยันเพิกถอน'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ExecutiveService.revokeCameraAccess(
                                  grant.grantId,
                                );
                                _loadGrants();
                              }
                            },
                            icon: const Icon(Icons.block_rounded, size: 14),
                            label: const Text(
                              'เพิกถอนสิทธิ์',
                              style: TextStyle(fontSize: 9.5),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// วาดวงแหวนสรุป Online/ทั้งหมดในการ์ดสรุปด้านบน (_heroSection) — ส่วนที่ปิด
// เป็นสีเทาอ่อน (border) ส่วนที่เปิด (ตามสัดส่วน online/total) เป็นสีตาม
// สถานะจริง (เขียว=ครบ, เหลือง=บางส่วน offline, แดง=ทุกตัว offline)
class _CctvRingPainter extends CustomPainter {
  const _CctvRingPainter({required this.ratio, required this.color});
  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 9.0;
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppPalette.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    final sweep = ratio.clamp(0.0, 1.0) * 2 * pi;
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CctvRingPainter oldDelegate) =>
      oldDelegate.ratio != ratio || oldDelegate.color != color;
}

class _CameraData {
  final String id;
  final String name;
  final String building;
  final String location;
  final String status;
  final Color color;

  const _CameraData({
    required this.id,
    required this.name,
    required this.building,
    required this.location,
    required this.status,
    required this.color,
  });
}

