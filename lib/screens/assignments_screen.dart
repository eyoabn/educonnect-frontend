import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ASSIGNMENTS LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AssignmentsScreen extends StatefulWidget {
  final Course? course;
  const AssignmentsScreen({super.key, this.course});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final studentId = auth.id;

      List<Map<String, dynamic>> data = [];
      if (auth.isTeacher) {
        final submissions =
            await ApiService.getSubmissions(widget.course?.id ?? '');
        // Group all student records by assignment title
        final Map<String, Map<String, dynamic>> grouped = {};
        for (var s in submissions) {
          final title = s['assignment'] as String? ?? 'Assignment';
          if (!grouped.containsKey(title)) {
            grouped[title] = {
              'id': s['id'],
              'title': title,
              'course': s['course'] as String? ?? 'Course',
              'due': s['due'] as String? ?? s['time'] as String? ?? 'TBD',
              'points': s['points'] as int? ?? 100,
              'status': 'pending',
              'gi': s['gi'] as int? ?? s['gradientIndex'] as int? ?? 0,
              'description': s['description'] as String? ?? '',
              'attachmentUrl': s['attachmentUrl'] as String? ?? '',
              // list of ALL student records for this assignment
              'submissions': <Map<String, dynamic>>[],
            };
          }
          (grouped[title]!['submissions'] as List).add(s);
        }
        // Compute submitted counts for badge
        for (final entry in grouped.values) {
          final subs = entry['submissions'] as List;
          entry['total'] = subs.length;
          entry['submittedCount'] = subs.where((s) => s['status'] == 'submitted' || s['status'] == 'graded').length;
        }
        data = grouped.values.toList();
      } else {
        data = await ApiService.getAssignments(studentId);
      }

      if (widget.course != null) {
        data =
            data.where((a) => a['course'] == widget.course!.name).toList();
      }

      if (mounted) {
        setState(() {
          _assignments = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _assignments = [];
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _pending =>
      _assignments.where((a) => a['status'] == 'pending').toList();
  List<Map<String, dynamic>> get _done =>
      _assignments.where((a) => a['status'] != 'pending').toList();

  void _openAssignment(Map<String, dynamic> a) {
    final auth = context.read<AuthProvider>();
    if (auth.isTeacher) {
      // Show who has / hasn't submitted
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _TeacherSubmissionsScreen(assignment: a),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentDetailScreen(
          assignment: a,
          onSubmitted: _load,
        ),
      ),
    );
  }

  void _showCreateAssignment() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '100');
    String dueDate = '';
    bool loading = false;
    PlatformFile? pickedAttachment;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Row(children: [
                    GradientIconBox(
                        gradient: AppGradients.orange,
                        icon: Icons.add_task_rounded,
                        size: 42,
                        iconSize: 20),
                    SizedBox(width: 12),
                    Text('Create Assignment',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ]),
                  const SizedBox(height: 20),
                  _FormField(
                      controller: titleCtrl,
                      label: 'Title',
                      hint: 'e.g. Chapter 5 Problems',
                      icon: Icons.title_rounded),
                  const SizedBox(height: 14),
                  _FormField(
                      controller: descCtrl,
                      label: 'Description',
                      hint: 'Explain what students need to do...',
                      icon: Icons.description_rounded,
                      maxLines: 3),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _FormField(
                            controller: pointsCtrl,
                            label: 'Points',
                            hint: '100',
                            icon: Icons.stars_rounded,
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (d != null) {
                            setS(() =>
                                dueDate = '${d.day}/${d.month}/${d.year}');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border)),
                          child:
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Due Date',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: AppColors.orange),
                              const SizedBox(width: 6),
                              Text(
                                  dueDate.isEmpty ? 'Pick date' : dueDate,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: dueDate.isEmpty
                                          ? Colors.grey.shade400
                                          : AppColors.textPrimary)),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  const Text('Attachment (Optional)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();
                      if (result != null) {
                        setS(() => pickedAttachment = result.files.first);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                      decoration: BoxDecoration(
                        color: pickedAttachment != null
                            ? AppColors.cyan.withOpacity(0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: pickedAttachment != null
                                ? AppColors.cyan
                                : AppColors.border),
                      ),
                      child: Row(children: [
                        Icon(
                          pickedAttachment != null
                              ? Icons.check_circle_rounded
                              : Icons.attach_file_rounded,
                          color: pickedAttachment != null
                              ? AppColors.cyan
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pickedAttachment != null
                                ? pickedAttachment!.name
                                : 'Tap to attach a file',
                            style: TextStyle(
                              color: pickedAttachment != null
                                  ? AppColors.cyan
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Create Assignment',
                    gradient: AppGradients.orange,
                    isLoading: loading,
                    icon: Icons.check_rounded,
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty) return;
                      setS(() => loading = true);
                      try {
                        String attachmentUrl = '';
                        if (pickedAttachment != null) {
                          final uploadRes = await ApiService.uploadAssignmentFile(
                              pickedAttachment!);
                          if (uploadRes['success'] == true &&
                              uploadRes['data'] != null &&
                              uploadRes['data']['url'] != null) {
                            attachmentUrl =
                                uploadRes['data']['url'] as String;
                          } else {
                            final errMsg = uploadRes['message'] ??
                                'Failed to upload attachment';
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(errMsg),
                                      backgroundColor: Colors.red));
                            }
                            setS(() => loading = false);
                            return;
                          }
                        }
                        await ApiService.createAssignment(
                            widget.course?.id ?? '', {
                          'title': titleCtrl.text,
                          'description': descCtrl.text,
                          'points': int.tryParse(pointsCtrl.text) ?? 100,
                          'due': dueDate,
                          'attachmentUrl': attachmentUrl,
                        });
                        _load();
                      } catch (_) {}
                      setS(() => loading = false);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Assignment created!'),
                                backgroundColor: Colors.green));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pending = _pending;
    final done = _done;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        GradientHeader(
          gradient: AppGradients.primary,
          child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const AppBackButton(),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Assignments',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  widget.course?.name ?? 'All Courses',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.8),
                                      fontSize: 13)),
                            ])),
                        if (auth.isTeacher)
                          GestureDetector(
                            onTap: _showCreateAssignment,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Colors.white.withOpacity(0.4))),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text('Create',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ]),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        _StatPill(
                            label: '${pending.length} pending',
                            icon: Icons.pending_rounded),
                        const SizedBox(width: 10),
                        _StatPill(
                            label: '${done.length} completed',
                            icon: Icons.check_circle_rounded),
                      ]),
                    ]),
              )),
        ),

        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13),
            indicatorColor: AppColors.orange,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Completed (${done.length})'),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(controller: _tabCtrl, children: [
                  _AssignmentList(
                    items: pending,
                    onTap: _openAssignment,
                    isTeacher: auth.isTeacher,
                  ),
                  _AssignmentList(
                    items: done,
                    onTap: _openAssignment,
                    isTeacher: auth.isTeacher,
                  ),
                ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ASSIGNMENT DETAIL + SUBMISSION SCREEN (Student only)
// ─────────────────────────────────────────────────────────────────────────────
class AssignmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback? onSubmitted;
  const AssignmentDetailScreen(
      {super.key, required this.assignment, this.onSubmitted});

  @override
  State<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  PlatformFile? _pickedFile;
  bool _submitting = false;

  Map<String, dynamic> get a => widget.assignment;

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted':
        return AppColors.cyan;
      case 'graded':
        return AppColors.emerald;
      default:
        return AppColors.orange;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'submitted':
        return Icons.upload_file_rounded;
      case 'graded':
        return Icons.check_circle_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  Future<void> _safeLaunchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not open file: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a file first'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final uploadRes = await ApiService.uploadAssignmentFile(_pickedFile!);
      if (uploadRes['success'] == true &&
          uploadRes['data'] != null &&
          uploadRes['data']['url'] != null) {
        final fileUrl = uploadRes['data']['url'] as String;
        final res = await ApiService.submitAssignment(
          assignmentId: a['id'].toString(),
          content: fileUrl,
        );
        if (res['success'] == true) {
          widget.onSubmitted?.call();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Assignment submitted successfully! ✅'),
                  backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(res['message'] ?? 'Submission failed'),
                  backgroundColor: Colors.red),
            );
          }
        }
      } else {
        final errMsg = uploadRes['message'] ?? 'File upload failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errMsg), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = a['status'] as String? ?? 'pending';
    final isGraded = status == 'graded';
    final isSubmitted = status == 'submitted';
    final hasSubmission = (a['submissionContent'] as String? ?? '').isNotEmpty;
    final gi = (a['gi'] as int? ?? 0) % 4;
    final grad = AppGradients.courseGradients[gi];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        GradientHeader(
          gradient: AppGradients.primary,
          child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const AppBackButton(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            a['title'] as String? ?? 'Assignment',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        _HeaderBadge(
                            icon: Icons.calendar_today_rounded,
                            label:
                                'Due: ${a['due'] ?? 'TBD'}'),
                        const SizedBox(width: 8),
                        _HeaderBadge(
                            icon: Icons.stars_rounded,
                            label: '${a['points'] ?? 100} pts'),
                        const SizedBox(width: 8),
                        _HeaderBadge(
                            icon: _statusIcon(status),
                            label: status.toUpperCase()),
                      ]),
                    ]),
              )),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course name chip
                  Row(children: [
                    GradientIconBox(
                        gradient: grad,
                        icon: Icons.assignment_rounded,
                        size: 44,
                        iconSize: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                      a['course'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _statusColor(status)
                                  .withOpacity(0.35))),
                      child: Text(
                        status[0].toUpperCase() +
                            status.substring(1),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Description ──────────────────────────────────────
                  const _SectionTitle(title: 'Assignment Description'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]),
                    child: Text(
                      (a['description'] as String?)?.isNotEmpty == true
                          ? a['description'] as String
                          : 'No description provided.',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Teacher Attachment ───────────────────────────────
                  if ((a['attachmentUrl'] as String? ?? '').isNotEmpty) ...[
                    const _SectionTitle(title: 'Assignment File'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _safeLaunchUrl(
                          a['attachmentUrl'] as String),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.cyan.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: const Icon(Icons.download_rounded,
                                color: AppColors.cyan, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Download Assignment File',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.cyan)),
                                  SizedBox(height: 2),
                                  Text('Tap to open',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ]),
                          ),
                          const Icon(Icons.open_in_new_rounded,
                              color: AppColors.cyan, size: 18),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Grade box (if graded) ────────────────────────────
                  if (isGraded && a['grade'] != null) ...[
                    const _SectionTitle(title: 'Your Grade'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppGradients.emerald,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.emerald.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle),
                          child: Center(
                              child: Text('${a['grade']}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22))),
                        ),
                        const SizedBox(width: 16),
                        Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${a['grade']} / ${a['points'] ?? 100} points',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                  '${((a['grade'] as num) / (a['points'] as num? ?? 100) * 100).round()}% score',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.85),
                                      fontSize: 13)),
                            ]),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Current Submission (submitted or graded) ─────────
                  if (hasSubmission) ...[
                    _SectionTitle(
                        title: isGraded
                            ? 'Your Submitted File'
                            : 'Your Current Submission'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        final url =
                            a['submissionContent'] as String? ?? '';
                        if (url.startsWith('http')) {
                          _safeLaunchUrl(url);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.violet.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color:
                                    AppColors.violet.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: const Icon(
                                Icons.insert_drive_file_rounded,
                                color: AppColors.violet,
                                size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('View Submitted File',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.violet)),
                                  SizedBox(height: 2),
                                  Text('Tap to open your submission',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ]),
                          ),
                          const Icon(Icons.open_in_new_rounded,
                              color: AppColors.violet, size: 18),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ─────────────────────────────────────────────────────
                  // SUBMISSION SECTION — only show if not yet graded
                  // ─────────────────────────────────────────────────────
                  if (!isGraded) ...[
                    _SectionTitle(
                        title: hasSubmission
                            ? 'Update Your Submission'
                            : 'Submit Your Assignment'),
                    const SizedBox(height: 10),

                    // File picker area
                    GestureDetector(
                      onTap: () async {
                        final result =
                            await FilePicker.platform.pickFiles();
                        if (result != null) {
                          setState(
                              () => _pickedFile = result.files.first);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _pickedFile != null
                              ? AppColors.emerald.withOpacity(0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _pickedFile != null
                                ? AppColors.emerald
                                : AppColors.border,
                            width: _pickedFile != null ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: _pickedFile != null
                                  ? AppGradients.emerald
                                  : AppGradients.violet,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                    color: (_pickedFile != null
                                            ? AppColors.emerald
                                            : AppColors.violet)
                                        .withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Icon(
                              _pickedFile != null
                                  ? Icons.check_rounded
                                  : Icons.cloud_upload_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _pickedFile != null
                                ? _pickedFile!.name
                                : 'Tap to choose a file',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _pickedFile != null
                                  ? AppColors.emerald
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _pickedFile != null
                                ? 'File selected — tap Submit below'
                                : 'PDF, DOCX, images and more',
                            style: TextStyle(
                                fontSize: 12,
                                color: _pickedFile != null
                                    ? AppColors.emerald.withOpacity(0.7)
                                    : AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (_pickedFile != null) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _pickedFile = null),
                              child: Text('Remove file',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status indicator
                    if (isSubmitted && !hasSubmission)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.cyan.withOpacity(0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_rounded,
                              color: AppColors.cyan, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                            'Already submitted — upload a new file to update.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.cyan),
                          )),
                        ]),
                      ),
                    if (isSubmitted && !hasSubmission)
                      const SizedBox(height: 12),

                    // Submit button
                    GradientButton(
                      label: _submitting
                          ? 'Uploading & Submitting...'
                          : (hasSubmission
                              ? 'Update Submission'
                              : 'Submit Assignment'),
                      gradient: AppGradients.violet,
                      isLoading: _submitting,
                      icon: Icons.upload_rounded,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        hasSubmission
                            ? 'This will replace your previous submission'
                            : 'You can resubmit before the deadline',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ASSIGNMENT LIST WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _AssignmentList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onTap;
  final bool isTeacher;
  const _AssignmentList(
      {required this.items,
      required this.onTap,
      required this.isTeacher});

  Color _statusColor(String s) =>
      s == 'submitted'
          ? AppColors.cyan
          : s == 'graded'
              ? AppColors.emerald
              : AppColors.orange;

  @override
  Widget build(BuildContext context) => items.isEmpty
      ? EmptyState(
          icon: Icons.assignment_rounded,
          title: isTeacher
              ? 'No assignments created'
              : 'No assignments yet',
          subtitle: isTeacher
              ? 'Tap + Create to add one'
              : 'Assignments from your teacher will appear here',
          gradient: AppGradients.orange)
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final a = items[i];
            final gi = (a['gi'] as int? ?? 0) % 4;
            final status = a['status'] as String? ?? 'pending';
            final hasSubmission =
                (a['submissionContent'] as String? ?? '').isNotEmpty;

            return GlassCard(
              onTap: () => onTap(a),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                GradientIconBox(
                    gradient: AppGradients.courseGradients[gi],
                    icon: Icons.assignment_rounded,
                    size: 52,
                    iconSize: 24),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(a['title'] as String? ?? 'Assignment',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(a['course'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Due: ${a['due'] ?? 'TBD'}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 10),
                        const Icon(Icons.stars_rounded,
                            size: 12, color: AppColors.violet),
                        const SizedBox(width: 4),
                        Text('${a['points'] ?? 100} pts',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ]),
                      if (isTeacher) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.people_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${a['submittedCount'] ?? 0} / ${a['total'] ?? 0} submitted',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (a['submittedCount'] ?? 0) > 0
                                  ? AppColors.emerald
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          const Text('View',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ],
                      if (!isTeacher) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _statusColor(status)
                                      .withOpacity(0.35)),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    status == 'graded'
                                        ? Icons.check_circle_rounded
                                        : status == 'submitted'
                                            ? Icons.upload_file_rounded
                                            : Icons.pending_rounded,
                                    size: 11,
                                    color: _statusColor(status),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status[0].toUpperCase() +
                                        status.substring(1),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _statusColor(status)),
                                  ),
                                ]),
                          ),
                          if (hasSubmission) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text('File submitted',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                      ],
                    ])),
                const SizedBox(width: 10),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (status == 'graded' && a['grade'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              gradient: AppGradients.emerald,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('${a['grade']}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      const SizedBox(height: 6),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: AppColors.textSecondary),
                    ]),
              ]),
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary));
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderBadge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withOpacity(0.35))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ]),
      );
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatPill({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withOpacity(0.35))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ]),
      );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  const _FormField(
      {required this.controller,
      required this.label,
      required this.hint,
      required this.icon,
      this.maxLines = 1,
      this.keyboardType});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: 1,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppColors.orange, size: 18),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.orange, width: 2)),
          ),
        ),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// TEACHER: See who submitted vs who hasn't for a given assignment
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherSubmissionsScreen extends StatelessWidget {
  final Map<String, dynamic> assignment;
  const _TeacherSubmissionsScreen({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final title = assignment['title'] as String? ?? 'Assignment';
    final submissions = (assignment['submissions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final submitted = submissions.where((s) => s['status'] == 'submitted' || s['status'] == 'graded').toList();
    final awaiting  = submissions.where((s) => s['status'] == 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        GradientHeader(
          gradient: AppGradients.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Submissions',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(title,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _SubmStatPill(label: '${submitted.length} submitted', color: AppColors.emerald),
                  const SizedBox(width: 10),
                  _SubmStatPill(label: '${awaiting.length} awaiting', color: Colors.white),
                ]),
              ]),
            ),
          ),
        ),

        // List
        Expanded(
          child: submissions.isEmpty
              ? const EmptyState(
                  icon: Icons.people_rounded,
                  title: 'No students enrolled',
                  subtitle: 'Students will appear here once enrolled')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (submitted.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text('Submitted ✅',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emerald)),
                      ),
                      ...submitted.map((s) => _StudentSubmissionTile(record: s, submitted: true)),
                      const SizedBox(height: 20),
                    ],
                    if (awaiting.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text('Not submitted yet ⏳',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange)),
                      ),
                      ...awaiting.map((s) => _StudentSubmissionTile(record: s, submitted: false)),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }
}

class _SubmStatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _SubmStatPill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.45))),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      );
}

class _StudentSubmissionTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool submitted;
  const _StudentSubmissionTile({required this.record, required this.submitted});

  String get _initials {
    final name = record['student'] as String? ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _openFile(BuildContext context, String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionUrl = record['submissionContent'] as String? ?? '';
    final gi = (record['gradientIndex'] as int? ?? 0) % 4;
    final grad = AppGradients.courseGradients[gi];
    final submittedAt = record['time'] as String? ?? '';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        // Avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: submitted ? grad : const LinearGradient(colors: [Color(0xFFCCCCCC), Color(0xFFAAAAAA)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(_initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record['student'] as String? ?? 'Student',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            if (submitted && submittedAt.isNotEmpty)
              Text('Submitted: $submittedAt',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            if (!submitted)
              const Text('Has not submitted yet',
                  style: TextStyle(fontSize: 11, color: AppColors.orange)),
          ]),
        ),
        // View file button
        if (submitted && submissionUrl.isNotEmpty)
          GestureDetector(
            onTap: () => _openFile(context, submissionUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: AppGradients.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.open_in_new_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
          )
        else if (!submitted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.orange.withOpacity(0.3)),
            ),
            child: const Text('Pending',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.orange,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}
