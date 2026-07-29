import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// รายชื่อนักเรียนที่ส่งงานพร้อมเนื้อหาล่าสุด + ให้ Feedback (PBL)
class SubmissionReviewPage extends StatefulWidget {
  const SubmissionReviewPage({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  State<SubmissionReviewPage> createState() => _SubmissionReviewPageState();
}

class _SubmissionReviewPageState extends State<SubmissionReviewPage> {
  List<SubmissionRoster> submissions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await AssignmentService.listSubmissions(
        widget.assignmentId,
      );
      if (!mounted) return;
      setState(() => submissions = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = 'โหลดรายชื่อไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openSubmission(SubmissionRoster submission) async {
    List<AssignmentFeedback> feedback = [];
    try {
      feedback = await AssignmentService.listFeedback(
        submission.submissionId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลด Feedback ไม่สำเร็จ: $e')));
      return;
    }

    if (!mounted) return;
    final feedbackController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                submission.studentFullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('เวอร์ชันล่าสุด: v${submission.currentVersion}'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(submission.latestContent ?? '-'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Feedback',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (feedback.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'ยังไม่มี feedback',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...feedback.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.authorFullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(f.body),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'เขียน feedback ให้นักเรียน',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (feedbackController.text.trim().isEmpty) return;
                    try {
                      await AssignmentService.giveFeedback(
                        submissionId: submission.submissionId,
                        body: feedbackController.text,
                      );
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(content: Text('ส่ง feedback ไม่สำเร็จ: $e')),
                      );
                    }
                  },
                  child: const Text('ส่ง Feedback'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('งานที่ส่งแล้ว'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: load)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: load, child: const Text('ลองใหม่')),
                  ],
                ),
              ),
            )
          : submissions.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีนักเรียนส่งงานนี้',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final submission = submissions[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment_turned_in),
                    title: Text(submission.studentFullName),
                    subtitle: Text('เวอร์ชัน ${submission.currentVersion}'),
                    onTap: () => openSubmission(submission),
                  ),
                );
              },
            ),
    );
  }
}
