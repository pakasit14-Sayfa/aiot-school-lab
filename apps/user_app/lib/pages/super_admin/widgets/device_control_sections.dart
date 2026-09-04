import 'package:flutter/material.dart';

import '../models/device_control_models.dart';
import '../theme/app_palette.dart';
import 'device_control_widgets.dart';

/// One device tile inside the "ควบคุมรายเครื่อง" list — shows online/power/
/// mode badges, the latest reading, and the mode dropdown + power switch.
class DeviceControlDeviceCard extends StatelessWidget {
  const DeviceControlDeviceCard({
    super.key,
    required this.item,
    required this.onShowDetails,
    required this.onChangeMode,
    required this.onToggle,
  });

  final DeviceItem item;
  final void Function(DeviceItem item) onShowDetails;
  final void Function(DeviceItem item, bool autoMode) onChangeMode;
  final void Function(DeviceItem item, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final Color stateColor =
        !item.online
            ? AppPalette.carnivalRed
            : item.isOn
            ? AppPalette.gardenGreen
            : AppPalette.deepBlue;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color:
              item.online
                  ? AppPalette.softBeige.withValues(alpha: 0.7)
                  : AppPalette.carnivalRed.withValues(alpha: 0.5),
        ),
        boxShadow: deviceControlCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(item.icon, color: stateColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.id} • ${item.type}',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'ดูรายละเอียด',
                onPressed: () => onShowDetails(item),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              deviceControlBadge(
                item.online ? 'ออนไลน์' : 'ออฟไลน์',
                item.online ? AppPalette.gardenGreen : AppPalette.carnivalRed,
              ),
              deviceControlBadge(
                item.isOn ? 'กำลังเปิด' : 'ปิดอยู่',
                item.isOn ? AppPalette.gardenGreen : AppPalette.deepBlue,
              ),
              deviceControlBadge(
                item.autoMode ? 'อัตโนมัติ' : 'ควบคุมเอง',
                item.autoMode ? AppPalette.circusYellow : AppPalette.deepBlue,
              ),
              if (item.commandPending)
                deviceControlBadge('รออุปกรณ์รับคำสั่ง', AppPalette.circusYellow),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppPalette.softBeige.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${item.school} • ${item.building} • ${item.room}',
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.reading,
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.updated,
                  style: TextStyle(
                    color:
                        item.online
                            ? AppPalette.textSecondary
                            : AppPalette.carnivalRed,
                    fontSize: 10,
                  ),
                ),
                if (!item.online) ...<Widget>[
                  const SizedBox(height: 6),
                  const Text(
                    'ยังส่งคำขอเปิด–ปิดได้ โดยคำสั่งจะรอ '
                    'จนกว่า MiniPC หรือ Gateway จะเชื่อมต่อ',
                    style: TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 9.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: item.autoMode ? 'อัตโนมัติ' : 'ควบคุมเอง',
                  decoration: const InputDecoration(
                    labelText: 'โหมดทำงาน',
                    prefixIcon: Icon(Icons.tune_rounded),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'อัตโนมัติ',
                      child: Text('อัตโนมัติ'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'ควบคุมเอง',
                      child: Text('ควบคุมเอง'),
                    ),
                  ],
                  onChanged:
                      item.commandPending
                          ? null
                          : (String? value) {
                            if (value == null) {
                              return;
                            }

                            onChangeMode(item, value == 'อัตโนมัติ');
                          },
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: <Widget>[
                  Text(
                    item.isOn ? 'เปิด' : 'ปิด',
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Switch.adaptive(
                    value: item.isOn,
                    onChanged:
                        item.commandPending
                            ? null
                            : (bool value) => onToggle(item, value),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One row inside the "คำขออนุมัติการเปิด–ปิด" panel.
class DeviceControlApprovalTile extends StatelessWidget {
  const DeviceControlApprovalTile({
    super.key,
    required this.item,
    required this.canDecide,
    required this.onReject,
    required this.onApprove,
  });

  final ApprovalItem item;
  final bool canDecide;
  final void Function(ApprovalItem item) onReject;
  final void Function(ApprovalItem item) onApprove;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (item.status) {
      'approved' => AppPalette.gardenGreen,
      'rejected' => AppPalette.carnivalRed,
      'expired' => AppPalette.textSecondary,
      _ => AppPalette.circusYellow,
    };

    final String statusLabel = switch (item.status) {
      'approved' => 'อนุมัติแล้ว',
      'rejected' => 'ไม่อนุมัติ',
      'expired' => 'หมดเวลา',
      _ => 'รออนุมัติ',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget information = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  item.turnOn
                      ? Icons.power_settings_new_rounded
                      : Icons.power_off_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${item.turnOn ? 'ขอเปิด' : 'ขอปิด'} '
                      '${item.scopeLabel}',
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.schoolName} • '
                      '${item.targetCount} อุปกรณ์',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'ผู้ขอ: ${item.requesterName} • '
                      '${item.requestedLabel}',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    if (item.reason.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'เหตุผล: ${item.reason}',
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (item.approverName != null) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'ผู้พิจารณา: ${item.approverName}',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final Widget actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canDecide) ...<Widget>[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => onReject(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.carnivalRed,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('ไม่อนุมัติ'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => onApprove(item),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.gardenGreen,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.password_rounded, size: 17),
                  label: const Text('ยืนยันด้วยรหัสผ่าน'),
                ),
              ],
            ],
          );

          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                information,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: actions,
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: information),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }
}
