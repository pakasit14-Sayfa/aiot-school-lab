import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorCctvPage extends StatefulWidget {
  const DirectorCctvPage({super.key});

  @override
  State<DirectorCctvPage> createState() => _DirectorCctvPageState();
}

class _DirectorCctvPageState extends State<DirectorCctvPage> {
  String searchText = '';
  String selectedBuilding = 'ทุกอาคาร';
  String selectedStatus = 'ทุกสถานะ';
  String selectedAi = 'ทั้งหมด';

  final List<String> buildings = const [
    'ทุกอาคาร',
    'อาคาร 1',
    'อาคาร 2',
    'อาคาร 3',
    'สนามกีฬา',
    'ทางเข้าโรงเรียน',
  ];

  final List<String> statuses = const [
    'ทุกสถานะ',
    'Online',
    'Offline',
  ];

  final List<String> aiFilters = const [
    'ทั้งหมด',
    'เปิด AI',
    'ปิด AI',
  ];

  final List<_CameraData> cameras = const [
    _CameraData(
      id: 'CAM-B1-01',
      name: 'ทางเข้าอาคาร 1',
      building: 'อาคาร 1',
      location: 'ชั้น 1 • ทางเข้าอาคาร',
      status: 'Online',
      aiEnabled: true,
      recording: true,
      lastUpdate: 'เมื่อ 5 วินาทีที่แล้ว',
      aiMode: 'ตรวจจับบุคคล / ล้ม',
      alertCount: 0,
      color: AppPalette.learningBlue,
    ),
    _CameraData(
      id: 'CAM-B1-02',
      name: 'ทางเดินชั้น 2',
      building: 'อาคาร 1',
      location: 'ชั้น 2 • โถงกลาง',
      status: 'Online',
      aiEnabled: true,
      recording: true,
      lastUpdate: 'เมื่อ 8 วินาทีที่แล้ว',
      aiMode: 'ตรวจจับล้ม / พฤติกรรมเสี่ยง',
      alertCount: 1,
      color: AppPalette.chartPink,
    ),
    _CameraData(
      id: 'CAM-B2-01',
      name: 'ทางเข้าอาคาร 2',
      building: 'อาคาร 2',
      location: 'ชั้น 1 • ทางเข้าอาคาร',
      status: 'Online',
      aiEnabled: true,
      recording: true,
      lastUpdate: 'เมื่อ 3 วินาทีที่แล้ว',
      aiMode: 'ตรวจจับบุคคล',
      alertCount: 0,
      color: AppPalette.environmentGreen,
    ),
    _CameraData(
      id: 'CAM-B2-03',
      name: 'ทางเดินชั้น 3',
      building: 'อาคาร 2',
      location: 'ชั้น 3 • หน้าห้อง ม.5',
      status: 'Online',
      aiEnabled: true,
      recording: true,
      lastUpdate: 'เมื่อ 2 วินาทีที่แล้ว',
      aiMode: 'ทะเลาะวิวาท / ล้ม',
      alertCount: 2,
      color: AppPalette.danger,
    ),
    _CameraData(
      id: 'CAM-B3-01',
      name: 'โถงอาคาร 3',
      building: 'อาคาร 3',
      location: 'ชั้น 1 • โถงกลาง',
      status: 'Offline',
      aiEnabled: true,
      recording: false,
      lastUpdate: 'ขาดการเชื่อมต่อ 7 นาที',
      aiMode: 'ตรวจจับบุคคล / ล้ม',
      alertCount: 0,
      color: AppPalette.warning,
    ),
    _CameraData(
      id: 'CAM-B3-04',
      name: 'ทางเดินชั้น 2',
      building: 'อาคาร 3',
      location: 'ชั้น 2 • ห้อง ม.3/2',
      status: 'Online',
      aiEnabled: true,
      recording: true,
      lastUpdate: 'เมื่อ 4 วินาทีที่แล้ว',
      aiMode: 'ทะเลาะวิวาท / ล้ม',
      alertCount: 1,
      color: AppPalette.primaryPink,
    ),
    _CameraData(
      id: 'CAM-SP-01',
      name: 'สนามกีฬา',
      building: 'สนามกีฬา',
      location: 'ฝั่งอัฒจันทร์',
      status: 'Online',
      aiEnabled: false,
      recording: true,
      lastUpdate: 'เมื่อ 6 วินาทีที่แล้ว',
      aiMode: 'ปิด AI',
      alertCount: 0,
      color: AppPalette.chartCream,
    ),
    _CameraData(
      id: 'CAM-GATE-01',
      name: 'ประตูหน้าโรงเรียน',
      building: 'ทางเข้าโรงเรียน',
      location: 'ประตูหลัก',
      status: 'Online',
      aiEnabled: true,
      recording: true,
      lastUpdate: 'เมื่อ 2 วินาทีที่แล้ว',
      aiMode: 'ตรวจจับบุคคล / รถ',
      alertCount: 0,
      color: AppPalette.learningBlue,
    ),
  ];

  final List<_CameraAlert> alerts = const [
    _CameraAlert(
      cameraId: 'CAM-B2-03',
      title: 'ตรวจพบพฤติกรรมเสี่ยง',
      detail: 'กล้อง AI ตรวจพบการเคลื่อนไหวที่เข้าข่ายทะเลาะวิวาท',
      location: 'อาคาร 2 • ชั้น 3',
      time: 'วันนี้ 10:24 น.',
      status: 'กำลังตรวจสอบ',
      icon: Icons.warning_amber_rounded,
      color: AppPalette.danger,
    ),
    _CameraAlert(
      cameraId: 'CAM-B3-04',
      title: 'ตรวจพบนักเรียนล้ม',
      detail: 'ตรวจพบคนนอนอยู่บริเวณทางเดินเกินเวลาที่กำหนด',
      location: 'อาคาร 3 • ชั้น 2',
      time: 'วันนี้ 09:51 น.',
      status: 'รับทราบแล้ว',
      icon: Icons.personal_injury_rounded,
      color: AppPalette.warning,
    ),
    _CameraAlert(
      cameraId: 'CAM-B1-02',
      title: 'ตรวจพบการรวมกลุ่มหนาแน่น',
      detail: 'จำนวนบุคคลบริเวณทางเดินสูงกว่าค่าปกติช่วงเปลี่ยนคาบ',
      location: 'อาคาร 1 • ชั้น 2',
      time: 'วันนี้ 08:18 น.',
      status: 'ปิดเหตุแล้ว',
      icon: Icons.groups_rounded,
      color: AppPalette.learningBlue,
    ),
  ];

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
                'ดูสถานะกล้อง จุดติดตั้ง การบันทึก และเหตุจาก AI Camera พร้อมเปิดดูรายละเอียดของแต่ละกล้อง',
          ),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    _aiAlertsCard(),
                    const SizedBox(height: 16),
                    _systemHealthCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _aiAlertsCard(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _systemHealthCard(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _cameraSection(filtered),
        ],
      ),
    );
  }

  List<_CameraData> _filteredCameras() {
    final query = searchText.trim().toLowerCase();

    return cameras.where((camera) {
      final matchesSearch = query.isEmpty ||
          camera.id.toLowerCase().contains(query) ||
          camera.name.toLowerCase().contains(query) ||
          camera.location.toLowerCase().contains(query) ||
          camera.building.toLowerCase().contains(query);

      final matchesBuilding =
          selectedBuilding == 'ทุกอาคาร' ||
          camera.building == selectedBuilding;

      final matchesStatus =
          selectedStatus == 'ทุกสถานะ' ||
          camera.status == selectedStatus;

      final matchesAi = selectedAi == 'ทั้งหมด' ||
          (selectedAi == 'เปิด AI' && camera.aiEnabled) ||
          (selectedAi == 'ปิด AI' && !camera.aiEnabled);

      return matchesSearch &&
          matchesBuilding &&
          matchesStatus &&
          matchesAi;
    }).toList();
  }

  Widget _summaryCards() {
    const items = [
      _CameraSummary(
        title: 'กล้องทั้งหมด',
        value: '24',
        subtitle: 'ทุกจุดติดตั้ง',
        icon: Icons.videocam_rounded,
        color: AppPalette.softPink,
      ),
      _CameraSummary(
        title: 'Online',
        value: '22',
        subtitle: '91.7%',
        icon: Icons.cloud_done_rounded,
        color: AppPalette.softMint,
      ),
      _CameraSummary(
        title: 'Offline',
        value: '2',
        subtitle: 'ควรตรวจสอบ',
        icon: Icons.cloud_off_rounded,
        color: AppPalette.softCream,
      ),
      _CameraSummary(
        title: 'เปิด AI',
        value: '19',
        subtitle: 'ตรวจจับอัตโนมัติ',
        icon: Icons.sensors_rounded,
        color: AppPalette.softBlue,
      ),
      _CameraSummary(
        title: 'แจ้งเตือนจาก AI',
        value: '3',
        subtitle: 'วันนี้',
        icon: Icons.warning_amber_rounded,
        color: AppPalette.softPink2,
      ),
      _CameraSummary(
        title: 'พื้นที่จัดเก็บ',
        value: '76%',
        subtitle: 'เหลือประมาณ 8 วัน',
        icon: Icons.storage_rounded,
        color: AppPalette.softBlue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 6;

        if (constraints.maxWidth < 700) {
          columns = 2;
        } else if (constraints.maxWidth < 1120) {
          columns = 3;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: columns == 2 ? 126 : 116,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color:
                          AppPalette.tint(Colors.white, 0.82),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: AppPalette.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.2,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.2,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _aiAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แจ้งเตือนล่าสุดจาก AI Camera',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เหตุที่ระบบกล้องตรวจจับได้และส่งเข้าหน้าฉุกเฉิน',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...alerts.map(_alertTile),
        ],
      ),
    );
  }

  Widget _alertTile(_CameraAlert item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppPalette.tint(item.color, 0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.tint(item.color, 0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              item.icon,
              size: 18,
              color: item.color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.6,
                    height: 1.35,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.location} • ${item.time} • ${item.cameraId}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            item.status,
            style: TextStyle(
              fontSize: 8.2,
              fontWeight: FontWeight.w700,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemHealthCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะระบบกล้อง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'สถานะการบันทึก เครือข่าย และพื้นที่จัดเก็บ',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _healthRow(
            'กล้อง Online',
            '22 / 24',
            22 / 24,
            AppPalette.environmentGreen,
            Icons.videocam_rounded,
          ),
          _healthRow(
            'กำลังบันทึก',
            '21 / 24',
            21 / 24,
            AppPalette.learningBlue,
            Icons.fiber_manual_record_rounded,
          ),
          _healthRow(
            'AI Detection',
            '19 / 24',
            19 / 24,
            AppPalette.primaryPink,
            Icons.sensors_rounded,
          ),
          _healthRow(
            'พื้นที่จัดเก็บ',
            '76%',
            0.76,
            AppPalette.warning,
            Icons.storage_rounded,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color:
                  AppPalette.tint(AppPalette.warning, 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'ควรตรวจสอบ CAM-B3-01 ที่ Offline และพื้นที่จัดเก็บเมื่อเกิน 85%',
              style: TextStyle(
                fontSize: 8.8,
                height: 1.4,
                color: AppPalette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthRow(
    String title,
    String value,
    double progress,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: AppPalette.tint(color, 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppPalette.softTag,
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'กดที่กล้องเพื่อดูภาพขนาดใหญ่ สถานะ และเหตุ AI ล่าสุด',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
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
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 15,
                  ),
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
                    for (int i = 0;
                        i < filtered.length;
                        i++) ...[
                      SizedBox(
                        height: 276,
                        child: _cameraCard(filtered[i]),
                      ),
                      if (i != filtered.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              final columns =
                  constraints.maxWidth < 1050 ? 2 : 3;

              return GridView.builder(
                itemCount: filtered.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
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
            hintText:
                'ค้นหารหัสกล้อง จุดติดตั้ง อาคาร...',
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
              borderSide:
                  const BorderSide(color: AppPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppPalette.border),
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

        final ai = _dropdown(
          value: selectedAi,
          items: aiFilters,
          icon: Icons.sensors_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedAi = value);
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
              const SizedBox(height: 8),
              ai,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: search,
            ),
            const SizedBox(width: 9),
            Expanded(child: building),
            const SizedBox(width: 9),
            Expanded(child: status),
            const SizedBox(width: 9),
            Expanded(child: ai),
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
          Icon(
            icon,
            size: 16,
            color: AppPalette.primaryPink,
          ),
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
                      (item) =>
                          DropdownMenuItem<String>(
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _miniTag(
                          camera.aiEnabled
                              ? 'AI เปิด'
                              : 'AI ปิด',
                          camera.aiEnabled
                              ? AppPalette.primaryPink
                              : AppPalette.textMuted,
                        ),
                        _miniTag(
                          camera.recording
                              ? 'REC'
                              : 'ไม่บันทึก',
                          camera.recording
                              ? AppPalette.danger
                              : AppPalette.textMuted,
                        ),
                        if (camera.alertCount > 0)
                          _miniTag(
                            '${camera.alertCount} แจ้งเตือน',
                            AppPalette.warning,
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      camera.lastUpdate,
                      style: const TextStyle(
                        fontSize: 7.9,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraPreview(
    _CameraData camera, {
    required double height,
  }) {
    final online = camera.status == 'Online';

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: online
              ? const [
                  Color(0xFF36363D),
                  Color(0xFF17171B),
                ]
              : const [
                  Color(0xFF68656A),
                  Color(0xFF3C393E),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Icon(
                online
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
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
                    color: online
                        ? AppPalette.success
                        : AppPalette.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  online ? 'LIVE' : 'OFFLINE',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (camera.recording)
            const Positioned(
              right: 10,
              top: 9,
              child: Row(
                children: [
                  Icon(
                    Icons.fiber_manual_record_rounded,
                    size: 12,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'REC',
                    style: TextStyle(
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
          Positioned(
            right: 10,
            bottom: 9,
            child: Text(
              camera.status == 'Online'
                  ? '21/08/2569 14:36:24'
                  : 'No signal',
              style: const TextStyle(
                fontSize: 7.8,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7.8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return searchText.isNotEmpty ||
        selectedBuilding != 'ทุกอาคาร' ||
        selectedStatus != 'ทุกสถานะ' ||
        selectedAi != 'ทั้งหมด';
  }

  void _clearFilters() {
    setState(() {
      searchText = '';
      selectedBuilding = 'ทุกอาคาร';
      selectedStatus = 'ทุกสถานะ';
      selectedAi = 'ทั้งหมด';
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
            constraints: const BoxConstraints(
              maxWidth: 900,
              maxHeight: 790,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: AppPalette.tint(
                            camera.color,
                            0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.videocam_rounded,
                          color: camera.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              camera.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${camera.id} • ${camera.location}',
                              style: const TextStyle(
                                fontSize: 9,
                                color:
                                    AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext),
                        icon:
                            const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(18),
                            child: _cameraPreview(
                              camera,
                              height: 360,
                            ),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth <
                                  650) {
                                return Column(
                                  children: [
                                    _cameraInfoCard(camera),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    _cameraAiCard(camera),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child:
                                        _cameraInfoCard(camera),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                        _cameraAiCard(camera),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _showMessage(
                            'ตัวอย่าง: บันทึกภาพจาก ${camera.id}',
                          );
                        },
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                        ),
                        label: const Text('บันทึกภาพ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showMessage(
                            'ตัวอย่าง: เปิด Playback ของ ${camera.id}',
                          );
                        },
                        icon: const Icon(
                          Icons.history_rounded,
                          size: 16,
                        ),
                        label: const Text('Playback'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              AppPalette.primaryPink,
                        ),
                        onPressed: () {
                          _showMessage(
                            'เปิดกล้อง ${camera.id} แบบเต็มจอ',
                          );
                        },
                        icon: const Icon(
                          Icons.fullscreen_rounded,
                          size: 17,
                        ),
                        label: const Text('เต็มจอ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cameraInfoCard(_CameraData camera) {
    final online = camera.status == 'Online';

    return Container(
      padding: const EdgeInsets.all(13),
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
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          _detailRow('รหัสกล้อง', camera.id),
          _detailRow('อาคาร', camera.building),
          _detailRow('จุดติดตั้ง', camera.location),
          _detailRow('สถานะ', camera.status),
          _detailRow(
            'การบันทึก',
            camera.recording
                ? 'กำลังบันทึก'
                : 'ไม่ได้บันทึก',
          ),
          _detailRow(
            'อัปเดตล่าสุด',
            camera.lastUpdate,
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppPalette.tint(
                online
                    ? AppPalette.environmentGreen
                    : AppPalette.warning,
                0.08,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
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
    );
  }

  Widget _cameraAiCard(_CameraData camera) {
    final relatedAlerts = alerts
        .where((alert) => alert.cameraId == camera.id)
        .toList();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Detection',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          _detailRow(
            'สถานะ AI',
            camera.aiEnabled ? 'เปิดใช้งาน' : 'ปิดใช้งาน',
          ),
          _detailRow(
            'โหมด',
            camera.aiMode,
          ),
          _detailRow(
            'แจ้งเตือนวันนี้',
            '${camera.alertCount} รายการ',
          ),
          const SizedBox(height: 6),
          if (relatedAlerts.isEmpty)
            const Text(
              'วันนี้ยังไม่มีเหตุจาก AI ของกล้องนี้',
              style: TextStyle(
                fontSize: 8.5,
                color: AppPalette.textMuted,
              ),
            )
          else
            ...relatedAlerts.map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      AppPalette.tint(alert.color, 0.06),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    Icon(
                      alert.icon,
                      size: 15,
                      color: alert.color,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _CameraSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CameraSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _CameraData {
  final String id;
  final String name;
  final String building;
  final String location;
  final String status;
  final bool aiEnabled;
  final bool recording;
  final String lastUpdate;
  final String aiMode;
  final int alertCount;
  final Color color;

  const _CameraData({
    required this.id,
    required this.name,
    required this.building,
    required this.location,
    required this.status,
    required this.aiEnabled,
    required this.recording,
    required this.lastUpdate,
    required this.aiMode,
    required this.alertCount,
    required this.color,
  });
}

class _CameraAlert {
  final String cameraId;
  final String title;
  final String detail;
  final String location;
  final String time;
  final String status;
  final IconData icon;
  final Color color;

  const _CameraAlert({
    required this.cameraId,
    required this.title,
    required this.detail,
    required this.location,
    required this.time,
    required this.status,
    required this.icon,
    required this.color,
  });
}
