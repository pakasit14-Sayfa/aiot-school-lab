import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_core/models/school_device_identity.dart';
import '../controllers/director_scan_controller.dart';
import '../widgets/director_workspace_widgets.dart';
import '../theme/app_palette.dart';

class DirectorScanPage extends StatefulWidget {
  const DirectorScanPage({super.key, this.controller});
  final DirectorScanController? controller;
  @override
  State<DirectorScanPage> createState() => _DirectorScanPageState();
}

class _DirectorScanPageState extends State<DirectorScanPage> {
  late final controller = widget.controller ?? DirectorScanController();
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  Future<void> scan() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _DeviceCameraDialog(),
    );
    if (result == null || !mounted) return;
    code.text = result;
    await controller.search(result);
  }

  Widget card(
    String title,
    List<Widget> children, {
    Color accent = AppPalette.primaryPinkDark,
    Color surface = Colors.white,
    IconData icon = Icons.qr_code_2,
  }) => DirectorWorkspaceCard(
    title: title,
    icon: icon,
    accent: accent,
    surface: surface,
    children: children,
  );
  String known(String? value) =>
      value == null || value.trim().isEmpty ? 'ยังไม่มีข้อมูล' : value;
  @override
  Widget build(BuildContext context) => DirectorWorkspace(
    child: Scaffold(
      backgroundColor: AppPalette.pageBg,
      appBar: AppBar(title: const Text('สแกน / ค้นหาอุปกรณ์')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final SchoolDeviceIdentity? device = controller.device;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DirectorWorkspaceHero(
                  title: 'รู้จักอุปกรณ์ในโรงเรียน',
                  subtitle:
                      'สแกนรหัสหรือค้นหา เพื่อดูรายละเอียดจากทะเบียนอุปกรณ์',
                  icon: Icons.qr_code_scanner,
                ),
                const SizedBox(height: 20),
                DirectorWorkspaceGrid(
                  children: [
                    card('ค้นหาอุปกรณ์ของโรงเรียน', [
                      const Text(
                        'ใช้รหัสอุปกรณ์ รหัสชุดฝึก หรือ ID จากทะเบียนอุปกรณ์',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: code,
                        onChanged: (_) => controller.clear(),
                        onSubmitted: controller.search,
                        decoration: const InputDecoration(
                          labelText: 'รหัสอุปกรณ์',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: controller.loading
                                ? null
                                : () => controller.search(code.text),
                            icon: const Icon(Icons.search),
                            label: const Text('ค้นหา'),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.loading ? null : scan,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('เปิดกล้องสแกนรหัส'),
                          ),
                        ],
                      ),
                    ]),
                    if (controller.loading)
                      card('กำลังค้นหาอุปกรณ์', [
                        const LinearProgressIndicator(),
                      ])
                    else if (controller.error != null)
                      card('ค้นหาไม่สำเร็จ', [
                        Text(controller.error!),
                        TextButton(
                          onPressed: () => controller.search(code.text),
                          child: const Text('ลองอีกครั้ง'),
                        ),
                      ])
                    else if (device != null)
                      card(
                        'พบอุปกรณ์ในทะเบียน',
                        [
                          Text(
                            device.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppPalette.softBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'รหัสอุปกรณ์: ${known(device.deviceCode)}',
                                ),
                                Text('รหัสชุดฝึก: ${known(device.kitCode)}'),
                                SelectableText('ID: ${device.id}'),
                                Text('ประเภท: ${device.type}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          DirectorStatusPill(
                            icon: Icons.circle,
                            color: switch (device.status) {
                              'online' => AppPalette.success,
                              'maintenance' => AppPalette.warning,
                              _ => AppPalette.textMuted,
                            },
                            label:
                                'สถานะในทะเบียน: ${switch (device.status) {
                                  'online' => 'ออนไลน์',
                                  'offline' => 'ออฟไลน์',
                                  'maintenance' => 'ซ่อมบำรุง',
                                  _ => device.status,
                                }}',
                          ),
                          const SizedBox(height: 12),
                          Text('สถานที่: ${known(device.location)}'),
                          Text(
                            'อาคาร: ${known(device.building)} · ห้อง: ${known(device.room)}',
                          ),
                        ],
                        accent: const Color(0xFF356A9A),
                        icon: Icons.devices_outlined,
                      )
                    else if (controller.searched)
                      card('ไม่พบอุปกรณ์ในโรงเรียน', [
                        Text('รหัสที่ค้นหา: ${controller.code}'),
                        const Text(
                          'ตรวจสอบรหัสบนป้ายหรือทะเบียนอุปกรณ์แล้วลองใหม่',
                        ),
                      ])
                    else
                      card(
                        'ยังไม่ได้ค้นหาอุปกรณ์',
                        [
                          const Text(
                            'กรอกรหัสหรือเปิดกล้องสแกนเพื่ออ่านข้อมูลจากทะเบียน',
                          ),
                        ],
                        accent: const Color(0xFF356A9A),
                        surface: AppPalette.softBlue,
                        icon: Icons.manage_search,
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'บริการเพิ่มเติม · ยังไม่เปิดใช้งาน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
                DirectorWorkspaceGrid(
                  children: [
                    card(
                      'บัตรบุคลากร',
                      [
                        const Text(
                          'ยังไม่มีระบบเชื่อมรหัสบนบัตรกับตัวบุคลากร จึงยังยืนยันตัวตนหรือบันทึกเวลาเข้างานจากหน้านี้ไม่ได้',
                        ),
                        const OutlinedButton(
                          onPressed: null,
                          child: Text('สแกนบัตร / บันทึกเวลาเข้างาน'),
                        ),
                      ],
                      accent: AppPalette.textMuted,
                      surface: AppPalette.softTag,
                      icon: Icons.badge_outlined,
                    ),
                    card(
                      'ยืม–คืนและประวัติการสแกน',
                      [
                        const Text(
                          'ยังไม่มีทะเบียนยืม–คืนและระบบบันทึกประวัติการสแกน การค้นหานี้แสดงข้อมูลอุปกรณ์เท่านั้น',
                        ),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: null,
                              child: Text('บันทึกยืม–คืน'),
                            ),
                            OutlinedButton(
                              onPressed: null,
                              child: Text('ประวัติการสแกน'),
                            ),
                          ],
                        ),
                      ],
                      accent: AppPalette.textMuted,
                      surface: AppPalette.softTag,
                      icon: Icons.history,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _DeviceCameraDialog extends StatefulWidget {
  const _DeviceCameraDialog();
  @override
  State<_DeviceCameraDialog> createState() => _DeviceCameraDialogState();
}

class _DeviceCameraDialogState extends State<_DeviceCameraDialog> {
  final scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
    ],
  );
  bool completed = false;
  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }

  void detect(BarcodeCapture capture) {
    if (completed || !mounted) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        completed = true;
        Navigator.pop(context, value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('สแกนรหัสอุปกรณ์'),
    content: SizedBox(
      width: 480,
      height: 320,
      child: MobileScanner(
        controller: scanner,
        onDetect: detect,
        errorBuilder: (_, _, _) => const Center(
          child: Text(
            'ไม่สามารถเปิดกล้องได้ กรุณาตรวจสิทธิ์กล้องหรือใช้การกรอกรหัส',
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ปิดกล้อง'),
      ),
    ],
  );
}
