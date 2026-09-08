import 'dart:convert';
import 'package:shared_core/models/meeting_model.dart';
import 'meeting_actions.dart';

/// Printable UTF-8 document. All user-authored fields are escaped as text.
String meetingDocument(MeetingDetail data) {
  String e(Object? value) => htmlEscape.convert(value?.toString() ?? '');
  String paragraph(Object? value) =>
      '<p>${e(value).replaceAll('\n', '<br>')}</p>';
  final m = data.meeting;
  return '''<!doctype html><html lang="th"><meta charset="utf-8">
  <title>${e(m.title)}</title><style>
  body{font:16px/1.7 sans-serif;max-width:850px;margin:36px auto;padding:24px;color:#172333}
  h1{font-size:25px}h2{font-size:20px;border-bottom:1px solid #bbb;margin-top:28px}
  table{width:100%;border-collapse:collapse}td,th{border:1px solid #ccc;padding:8px;text-align:left}
  p{overflow-wrap:anywhere} @media print{body{margin:0;padding:0}button{display:none}tr{break-inside:avoid}}
  </style><button onclick="window.print()">พิมพ์ / บันทึก PDF</button>
  <h1>${e(m.title)}</h1>
  ${paragraph('${m.numberLabel} · ${meetingStatus(m.status)}')}
  ${m.isPrivate ? paragraph('เอกสารลับ — เฉพาะคู่สนทนาและผู้ดูแลโรงเรียน') : ''}
  ${paragraph('เริ่ม ${meetingDate(m.startAt)}${m.endAt == null ? '' : ' ถึง ${meetingDate(m.endAt!)}'}')}
  ${paragraph('สถานที่: ${m.location ?? 'ไม่ระบุ'} · ผู้จัด: ${m.organizer ?? 'ไม่ระบุ'}')}
  ${paragraph(m.description)}
  <h2>ผู้เข้าร่วม</h2><table><tr><th>ชื่อ / ต้นสังกัด</th><th>ตอบรับ</th><th>เช็คชื่อ</th></tr>
  ${[...data.people, ...data.guests].map((p) => '<tr><td>${e(p.name)}${p.external ? ' (ภายนอก) — ${e(p.organization)}' : ''}</td><td>${e(p.external ? 'ไม่ใช้ระบบตอบรับ' : meetingStatus(p.response ?? 'pending'))}</td><td>${e(attendanceLabel(p.attended))}</td></tr>').join()}
  </table><h2>วาระประชุม</h2>
  ${data.agenda.isEmpty ? paragraph('ยังไม่มีวาระ') : data.agenda.map((a) => paragraph('${a.order}. ${a.title}${a.presenter == null ? '' : ' — ${a.presenter}'}') + paragraph(a.detail)).join()}
  <h2>รายงานประชุม — ${e(m.minutesLabel)}</h2>
  ${data.minutes == null ? paragraph(m.minutesExpected ? 'ยังไม่มีรายงานที่คุณมีสิทธิ์อ่าน' : 'ไม่ต้องมีบันทึก') : paragraph(data.minutes!.body)}
  ${data.minutes?.cancelledAt == null ? '' : paragraph('เอกสารยกเลิก: ${data.minutes!.cancelReason}')}
  ${data.addenda.map((a) => paragraph('เพิ่มเติมโดย ${a.author ?? 'ไม่ระบุ'} · ${meetingDate(a.createdAt)}') + paragraph(a.body)).join()}
  <h2>มติและงานที่มอบหมาย</h2>
  ${data.resolutions.isEmpty ? paragraph('ยังไม่มีมติ') : data.resolutions.map((r) => paragraph(r.body) + paragraph('ผู้รับผิดชอบ: ${r.assignee ?? 'ยังไม่ระบุ'} · กำหนด: ${r.dueDate?.toIso8601String().substring(0, 10) ?? 'ยังไม่ระบุ'} · ${meetingStatus(r.status)}')).join()}
  <h2>รายการไฟล์แนบ</h2>
  ${data.attachments.isEmpty ? paragraph('ยังไม่มีไฟล์แนบ') : data.attachments.map((a) => paragraph('${a.name} (${a.size} bytes)')).join()}
  </html>''';
}
