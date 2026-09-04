import 'package:flutter/material.dart';

import '../models/device_control_models.dart';
import '../theme/app_palette.dart';
import 'dev_ui.dart';

/// Shared drop shadow used by the device-control summary/section cards.
const List<BoxShadow> deviceControlCardShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x0B000000),
    blurRadius: 22,
    offset: Offset(0, 10),
  ),
];

Widget deviceControlSchoolMiniStat(
  String value,
  String label,
  IconData icon,
) {
  return Container(
    constraints: const BoxConstraints(minWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppPalette.softBeige),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: AppPalette.deepBlue, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget deviceControlMetric(IconData icon, String value, String label) {
  return Container(
    constraints: const BoxConstraints(minHeight: 116),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F8FC),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppPalette.deepBlue.withValues(alpha: 0.10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppPalette.circusYellow.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppPalette.deepBlue, size: 19),
        ),
        const SizedBox(height: 11),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppPalette.deepBlue,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppPalette.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget deviceControlSummaryCard(
  IconData icon,
  String title,
  String value,
  String detail,
  Color color,
) {
  return Container(
    constraints: const BoxConstraints(minHeight: 165),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: deviceControlCardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 21,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: const TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 9.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget deviceControlDropdown(
  String label,
  IconData icon,
  String value,
  List<String> items,
  ValueChanged<String> onChanged,
) {
  return DropdownButtonFormField<String>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    items:
        items
            .map(
              (String item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
    onChanged: (String? value) {
      if (value != null) {
        onChanged(value);
      }
    },
  );
}

Widget deviceControlPermissionRow(String email, String detail, Color color) {
  return Row(
    children: <Widget>[
      CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.person_rounded, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              email,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget deviceControlLogRow(ActionLog log) {
  final Color color =
      log.success ? AppPalette.gardenGreen : AppPalette.carnivalRed;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          log.success ? Icons.check_rounded : Icons.close_rounded,
          color: color,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              log.title,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              log.detail,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${log.actor} • ${log.time}',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget deviceControlDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget deviceControlPanel({
  required String title,
  required Widget child,
  Widget? trailing,
}) {
  return AppPanel(title: title, trailing: trailing, child: child);
}

Widget deviceControlBadge(String label, Color color) {
  return StatusBadge(label: label, color: color);
}

Widget deviceControlEmpty(IconData icon, String title, String subtitle) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
    decoration: BoxDecoration(
      color: AppPalette.softBeige.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: <Widget>[
        CircleAvatar(
          radius: 27,
          backgroundColor: AppPalette.deepBlue.withValues(alpha: 0.1),
          child: Icon(icon, color: AppPalette.deepBlue),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppPalette.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}
