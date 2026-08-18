// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// LRN-12: ครูยืนยันคะแนนสะสม G-Score ก่อนแสดงผลให้นักเรียน — ระบบ (LRN-11)
// สะสมยอดรอยืนยันไว้เมื่อนักเรียนเรียนจบบทเรียน/ส่งงานตรงเวลา แต่ต้องผ่าน
// หน้านี้ก่อนนักเรียนถึงจะเห็นคะแนนจริง สอดคล้องหลักการ "ครูยืนยันขั้นสุดท้าย
// เสมอ" ที่ล็อกไว้ในวอลต์ — เพิ่มเมื่อ 2026-08-16 หลังพบว่า G-Score เดิมให้
// คะแนนอัตโนมัติทันทีไม่มีขั้นตอนนี้เลย (ดู student_redesign_prototype/
// NOTES.md และวอลต์ LRN-11/LRN-12 สำหรับที่มา)

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherSectionCard;


class TeacherGScoreConfirmPage extends StatelessWidget {
  const TeacherGScoreConfirmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'ยืนยันคะแนน G-Score',
      activeMenuLabel: 'ยืนยัน G-Score',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'หมายเหตุ: ฟีเจอร์สะสมแต้ม G-Score (Gamification) ยังไม่มีตารางหรือ RPC รองรับในระบบฐานข้อมูล Supabase',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TeacherSectionCard(
              title: 'รายการรออนุมัติคะแนน G-Score',
              icon: Icons.stars_rounded,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stars_outlined,
                        size: 56,
                        color: Colors.amber.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ยังไม่มีข้อมูลรายการรออนุมัติ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ระบบ Gamification (G-Score) อยู่ระหว่างรอการพัฒนาตารางและ RPC ในฐานข้อมูล',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: TeacherPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
