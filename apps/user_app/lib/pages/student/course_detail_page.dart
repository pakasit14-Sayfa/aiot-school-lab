import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'student_main_nav.dart';
import 'lesson_view_page.dart';

/// Professional Enterprise Course Detail Page (Clean, Emoji-Free Layout)
class CourseDetailPage extends StatefulWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int _currentTabIndex = 0;
  final TextEditingController _chatController = TextEditingController();
  final GlobalKey<_PostsFeedSectionState> _postsFeedKey = GlobalKey();

  CourseDetail? _course;
  bool _isLoadingCourse = true;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoadingCourse = true);
    try {
      final result = await CourseService.getCourse(widget.courseId);
      if (!mounted) return;
      setState(() => _course = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดข้อมูลรายวิชาไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingCourse = false);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentMainNav()),
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    try {
      await PostService.createPost(courseId: widget.courseId, body: text);
      _chatController.clear();
      await _postsFeedKey.currentState?.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โพสต์ข้อความเรียบร้อยแล้ว'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โพสต์ไม่สำเร็จ: $e')));
    }
  }

  void _openFloatingChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.forum_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('สร้างข้อความสนทนาใหม่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                      SizedBox(height: 2),
                      Text('ส่งคำถามหรือข้อสงสัยถึงครูและเพื่อนในคลาส', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _chatController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความของคุณที่นี่...',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleSendMessage();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('ส่งข้อความ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabHeader() {
    final tabs = [
      {'icon': Icons.forum_rounded, 'title': 'กระดานสนทนา'},
      {'icon': Icons.menu_book_rounded, 'title': 'บทเรียน'},
      {'icon': Icons.assignment_outlined, 'title': 'การบ้าน'},
      {'icon': Icons.folder_open_rounded, 'title': 'ไฟล์เอกสาร'},
    ];

    return Container(
      height: 50,
      color: const Color(0xFF0F172A),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _currentTabIndex == index;
          final tab = tabs[index];

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _currentTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab['title'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTabContent(String teacher, Color themeColor, String room) {
    switch (_currentTabIndex) {
      case 0:
        return _PostsFeedSection(key: _postsFeedKey, courseId: widget.courseId);
      case 1:
        return _LessonsSection(courseId: widget.courseId);
      case 2:
        return _AssignmentsSection(courseId: widget.courseId);
      case 3:
        return _FilesSection(courseId: widget.courseId);
      default:
        return _PostsFeedSection(key: _postsFeedKey, courseId: widget.courseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLoadingCourse
        ? 'กำลังโหลด...'
        : (_course?.subjectName ?? 'ไม่พบรายวิชานี้');
    final code = _course?.gradeLevel ?? '';
    final teacher = _course?.teacherNames ?? 'ยังไม่ได้กำหนดครูผู้สอน';
    final room = _course?.room ?? '-';
    const themeColor = Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 68,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: _handleBackNavigation,
        ),
        title: Row(
          children: [
            if (code.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ผู้สอน: $teacher • ห้องเรียน $room',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StudentMainNav()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openFloatingChatModal,
        backgroundColor: const Color(0xFF0284C7),
        elevation: 4,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 19),
        label: const Text(
          'โพสต์ข้อความใหม่',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),

      body: Column(
        children: [
          _buildCustomTabHeader(),
          Expanded(
            child: _buildActiveTabContent(teacher, themeColor, room),
          ),
        ],
      ),
    );
  }
}

/// Decoupled Posts Feed Widget
class _PostsFeedSection extends StatefulWidget {
  final String courseId;

  const _PostsFeedSection({super.key, required this.courseId});

  @override
  State<_PostsFeedSection> createState() => _PostsFeedSectionState();
}

class _PostsFeedSectionState extends State<_PostsFeedSection> {
  List<CoursePost> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await PostService.listPosts(widget.courseId);
      if (!mounted) return;
      setState(() => _posts = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'โหลดกระดานสนทนาไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openReplyModal(CoursePost post) {
    final replyController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ตอบกลับความคิดเห็นของ ${post.authorFullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              TextField(
                controller: replyController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'พิมพ์ความเห็นของคุณที่นี่...',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final txt = replyController.text.trim();
                    if (txt.isEmpty) return;
                    try {
                      await PostService.createReply(postId: post.id, body: txt);
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      await reload();
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(content: Text('ส่งความเห็นไม่สำเร็จ: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ส่งความเห็น', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: reload, child: const Text('ลองใหม่')),
            ],
          ),
        ),
      );
    }
    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีโพสต์ในกระดานสนทนานี้',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final currentUserId = currentUserModel?.uid;

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final isPin = post.isPinned;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isPin ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                width: isPin ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.push_pin_rounded, color: Color(0xFF0284C7), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'โพสต์ปักหมุดประจำรายวิชา',
                          style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: post.authorId == currentUserId
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0284C7),
                      child: Icon(
                        post.authorId == currentUserId
                            ? Icons.account_circle_rounded
                            : Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorId == currentUserId
                              ? '${post.authorFullName} (คุณ)'
                              : post.authorFullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year + 543}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  post.body,
                  style: const TextStyle(fontSize: 14.5, height: 1.6, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _openReplyModal(post),
                      icon: const Icon(Icons.reply_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: Text('ตอบกลับ (${post.replies.length})', style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12.5)),
                    ),
                  ],
                ),
                if (post.replies.isNotEmpty) ...[
                  const Divider(height: 20),
                  ...post.replies.map((r) => Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${r.authorFullName}: ${r.body}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Lessons Section — ต่อ LessonService จริง (list_lessons RPC)
class _LessonsSection extends StatefulWidget {
  const _LessonsSection({required this.courseId});

  final String courseId;

  @override
  State<_LessonsSection> createState() => _LessonsSectionState();
}

class _LessonsSectionState extends State<_LessonsSection> {
  List<LessonSummary> _lessons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await LessonService.listLessons(widget.courseId);
      if (!mounted) return;
      setState(() => _lessons = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'โหลดบทเรียนไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('ลองใหม่')),
            ],
          ),
        ),
      );
    }
    if (_lessons.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีบทเรียนที่เผยแพร่ในรายวิชานี้',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final lesson = _lessons[index];

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonViewPage(lessonId: lesson.id),
                  ),
                );
                await _load();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lesson.isPublished ? 'เผยแพร่แล้ว' : 'ฉบับร่าง',
                            style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('เข้าเรียน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Assignments Section (PBL) — real data via [AssignmentService]
class _AssignmentsSection extends StatefulWidget {
  const _AssignmentsSection({required this.courseId});

  final String courseId;

  @override
  State<_AssignmentsSection> createState() => _AssignmentsSectionState();
}

class _AssignmentsSectionState extends State<_AssignmentsSection> {
  List<AssignmentSummary> _assignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await AssignmentService.listAssignments(
        widget.courseId,
      );
      if (!mounted) return;
      setState(() => _assignments = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'โหลดงานไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAssignment(AssignmentSummary summary) async {
    AssignmentDetail detail;
    List<SubmissionVersion> versions;
    try {
      final results = await Future.wait([
        AssignmentService.getAssignment(summary.id),
        AssignmentService.listMySubmissionVersions(summary.id),
      ]);
      detail = results[0] as AssignmentDetail;
      versions = results[1] as List<SubmissionVersion>;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดรายละเอียดงานไม่สำเร็จ: $e')));
      return;
    }

    if (!mounted) return;
    final contentController = TextEditingController(
      text: versions.isEmpty ? '' : versions.first.content ?? '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                detail.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail.dueAt == null
                    ? 'ยังไม่กำหนดวันส่ง'
                    : 'กำหนดส่ง: ${detail.dueAt!.day}/${detail.dueAt!.month}/${detail.dueAt!.year + 543}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              if (detail.instructions != null &&
                  detail.instructions!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(detail.instructions!),
              ],
              if (detail.sensorDatasets.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'ข้อมูลเซนเซอร์ที่ครูผูกไว้',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...detail.sensorDatasets.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.sensors, size: 16, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${d.metric}${d.label != null ? " • ${d.label}" : ""}')),
                      ],
                    ),
                  ),
                ),
              ],
              if (versions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'ประวัติการส่งงาน',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...versions.map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'เวอร์ชัน ${v.version} • ${v.submittedAt.day}/${v.submittedAt.month}/${v.submittedAt.year + 543}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: versions.isEmpty ? 'ส่งงาน' : 'ส่งงานใหม่ (แก้ไข)',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;
                    try {
                      await AssignmentService.submitAssignment(
                        assignmentId: summary.id,
                        content: contentController.text.trim(),
                      );
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ส่งงานแล้ว'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(content: Text('ส่งงานไม่สำเร็จ: $e')),
                      );
                    }
                  },
                  child: Text(versions.isEmpty ? 'ส่งงาน' : 'ส่งใหม่'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('ลองใหม่')),
            ],
          ),
        ),
      );
    }
    if (_assignments.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีงานที่เผยแพร่ในรายวิชานี้',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final assignment = _assignments[index];

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openAssignment(assignment),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_rounded, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            assignment.dueAt == null
                                ? 'ยังไม่กำหนดวันส่ง'
                                : 'กำหนดส่ง: ${assignment.dueAt!.day}/${assignment.dueAt!.month}/${assignment.dueAt!.year + 543}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Clean Files Section
class _FilesSection extends StatefulWidget {
  const _FilesSection({required this.courseId});

  final String courseId;

  @override
  State<_FilesSection> createState() => _FilesSectionState();
}

class _FilesSectionState extends State<_FilesSection> {
  List<CourseFile> _files = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _downloadingFileId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await CourseFileService.listFiles(widget.courseId);
      if (!mounted) return;
      setState(() => _files = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'โหลดรายชื่อไฟล์ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _download(CourseFile file) async {
    setState(() => _downloadingFileId = file.id);
    try {
      final url = await CourseFileService.getDownloadUrl(file.id);
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!launched) throw Exception('launch_failed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ดาวน์โหลดไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _downloadingFileId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('ลองใหม่')),
            ],
          ),
        ),
      );
    }
    if (_files.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีไฟล์เอกสารในรายวิชานี้',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final f = _files[index];
          final isDownloading = _downloadingFileId == f.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0284C7), size: 22),
              ),
              title: Text(f.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              subtitle: Text('ขนาด: ${f.formattedSize} • อัปโหลดโดย ${f.uploaderFullName}'),
              trailing: GestureDetector(
                onTap: isDownloading ? null : () => _download(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('ดาวน์โหลด', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Clean Telemetry Section
class _TelemetrySection extends StatelessWidget {
  final String room;
  const _TelemetrySection({required this.room});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ข้อมูลเซนเซอร์สิ่งแวดล้อมห้อง $room', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(12)),
                      child: const Text('เชื่อมต่อข้อมูลเรียบร้อย', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatTile('ฝุ่น PM2.5', '14 µg/m³', 'คุณภาพอากาศดี', const Color(0xFF059669))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatTile('ก๊าซ CO2', '420 ppm', 'การถ่ายเทอากาศปกติ', const Color(0xFF0284C7))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatTile('อุณหภูมิ', '25.8°C', 'อยู่ในเกณฑ์ปกติ', const Color(0xFFD97706))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
