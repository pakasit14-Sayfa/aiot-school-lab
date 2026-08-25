# Brief for agy: teacher lesson editor silently destroys real lesson content — fix before anything else

## Found while verifying the lesson-material upload/download system, 2026-08-25

This is **not** a bug in the file upload/download feature itself — that part
(`lesson-material-upload`/`-download` Edge Functions, the `lesson-materials`
storage bucket, `add_lesson_material`/`get_lesson_material_for_download`
RPCs) was independently verified end-to-end and is solid: real upload, real
download, byte-identical file, correct role/tenant/publish-status gating,
clean rejection on garbage tokens. Don't touch that part.

**What's actually broken is one level up**: opening an *existing, already
published* lesson in the teacher's lesson editor, then making almost any
edit, silently wipes the lesson's real content. Confirmed live against the
real seeded lesson (`afd03f9d-80b2-4137-819f-c569d2733726`, "บทที่ 1:
รู้จักเซนเซอร์ PM2.5") — typed one extra character into the title field,
autosave fired, and the lesson's real body text
("เซนเซอร์ PM2.5 วัดค่าฝุ่นละอองขนาดเล็ก...") was replaced in the database
with an empty string. I restored the original content/title by hand
afterward so the seed data is intact, but this will happen to any real
teacher who edits any real lesson today.

## Root cause

`apps/user_app/lib/pages/teacher_redesign_prototype/teacher_lesson_editor_page.dart`,
`_TeacherLessonListPageState._loadRealLessons()` (around line 463-505):

```dart
Future<void> _loadRealLessons() async {
  ...
  final summaries = await LessonService.listLessons(courseId);
  ...
  _lessons = summaries.map((s) {
    return LessonModel(
      id: s.id,
      ...
      materialsCount: 0,
      sensorChartsCount: 0,
      blocks: [
        ContentBlockModel(id: 'b1', type: ContentBlockType.heading, text: s.title),
      ],
      materials: [],
      sensorLinks: [],
    );
  }).toList();
  ...
}
```

`LessonService.listLessons()` calls the `list_lessons` RPC, which only
returns `id/title/status/published_at` (a lightweight summary — see
`LessonSummary` in `packages/shared_core/lib/models/lesson_model.dart`).
It does **not** include `content`, `materials`, or `sensor_links`. This
function then papers over that gap by hardcoding `materials: []`,
`sensorLinks: []`, and a single synthetic heading block instead of the
lesson's real content blocks.

That `LessonModel` object is what gets passed straight into
`TeacherLessonEditorPage(lesson: les)` (line ~1099) when the teacher taps
"แก้ไขบทเรียน". The editor's `initState()` (line 1380-1387) just does
`_blocks = List.from(widget.lesson.blocks)` — no fetch of its own. So the
editor opens already missing the real content and every existing material.

Then `_triggerAutoSave()` (line 1389+), which fires on almost any edit —
title `onChanged` (line 2347), adding/removing a block, attaching a
material, linking a sensor — calls:

```dart
await LessonService.updateLesson(
  lessonId: widget.lesson.id,
  title: _titleController.text,
  content: _serializeBlocksToContent(_blocks),
);
```

`LessonService.updateLesson` always passes a non-null `content`. The
`update_lesson` RPC does a **full replace**: `content = coalesce(p_content,
content)`. Since `p_content` is never null here, the real content is always
overwritten — with whatever `_blocks` was seeded with, i.e. the fake
single-heading placeholder. Existing `lesson_materials` rows aren't deleted
(they're a separate table), but they become invisible to the teacher (the
"คลังสื่อแนบ (N)" counter reads `widget.lesson.materials.length`, which is
always `[]` from this path) and the real lesson body is gone.

## The fix

`get_lesson(p_token, p_lesson_id)` already exists and already returns
everything needed: `content`, `materials` (full array with id/type/title/
url/sort_order), `sensor_links`. `LessonDetail.fromRow()` in
`packages/shared_core/lib/models/lesson_model.dart` already parses this
shape correctly. The gap is purely on the UI side, in two places:

1. **`TeacherLessonListPage`** (the course's lesson list) needs real
   `materialsCount`/`sensorChartsCount` for its cards too — right now
   those show 0 for the same reason. Cheapest fix: after loading
   `list_lessons` summaries for the list view, either (a) call
   `get_lesson` per lesson to get real counts (fine for the realistic
   scale here — a course has a handful of lessons, not hundreds), or
   (b) extend `list_lessons` server-side to also return
   `materials_count`/`sensor_links_count` per lesson (cheaper, one RPC
   change, no N+1). Prefer (b) — add a migration that adds two count
   columns to `list_lessons`'s return, same tenant/role-gate logic it
   already has, just add two subquery counts alongside the existing
   columns.
2. **`TeacherLessonEditorPage`** must never open with a placeholder. When
   navigating to the editor for an *existing* lesson (i.e. not the
   "create new lesson" path at line ~705), call `LessonService.getLesson`
   (wrap `get_lesson` RPC — check if this wrapper already exists in
   `LessonService`, add it if not, matching `LessonDetail.fromRow`) and
   populate `_blocks`/`materials`/`sensorLinks` from the real response
   before rendering the editor and before any autosave can fire. Show a
   loading state while this fetch is in flight (there's already an
   `_isLoading` flag in the editor state — wire the real fetch into it
   instead of the current `Future.delayed(500ms)` placeholder at line
   1384-1386).

**Do not change `update_lesson`'s full-replace semantics** — that's a
reasonable contract for an editor that actually has the full content
loaded. The bug is that the editor is being handed incomplete data, not
that the RPC's replace-on-save behavior is wrong.

## Also worth fixing in the same pass (found during the same verification)

- Seed row `lesson_materials.id = 'f57f10d4-3af3-4597-bdf6-4f905d369f91'`
  (`type='file'`, title "คู่มือการใช้งานเซนเซอร์ PM2.5 (PDF)") has
  `url = 'https://example.com/materials/pm25_manual.pdf'` — not a real
  storage object, so `lesson-material-download` always 500s on it.
  Either point it at a real uploaded file or change its `type` to `link`
  (matching how the other fake-URL seed row, `7313cc20...`, is already
  correctly typed `link` and works fine via direct browser navigation
  instead of the signed-download path).
- When `LessonService.getMaterialDownloadUrl` throws, the student-facing
  `student_lesson_view_page.dart` currently shows the raw exception
  string to the user: `ไม่สามารถเปิดไฟล์ได้: FunctionException(status: 500,
  details: {error: download_url_unavailable}, ...)`. Catch this and show
  a plain Thai message instead (e.g. "ไม่สามารถเปิดไฟล์นี้ได้ในขณะนี้ กรุณาแจ้งครูผู้สอน").

## Verify

1. Real RPC/browser test, not just agy's say-so (standard for this
   project). Specifically: open an existing published lesson with real
   materials attached, confirm the editor shows the real body text and
   the real material count/list on open — *before* making any edit.
2. Make one small edit (e.g. add a space to the title), let autosave
   fire, then re-open the lesson (or query `lessons.content` directly)
   and confirm the real body text is still there, unchanged apart from
   the intended edit.
3. Confirm the course lesson-list cards show correct non-zero
   materials/sensor counts for lessons that actually have them.
4. `flutter analyze` clean.
