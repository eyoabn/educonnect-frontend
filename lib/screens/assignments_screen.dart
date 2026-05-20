import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class AssignmentsScreen extends StatefulWidget {
  final Course? course;
  const AssignmentsScreen({super.key, this.course});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> with SingleTickerProviderStateMixin {
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
        data = await ApiService.getSubmissions(widget.course?.id ?? '');
      } else {
        data = await ApiService.getAssignments(studentId);
      }

      if (widget.course != null) {
        data = data.where((a) => a['course'] == widget.course!.name).toList();
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

  List<Map<String, dynamic>> get _pending  => _assignments.where((a) => a['status'] == 'pending').toList();
  List<Map<String, dynamic>> get _done     => _assignments.where((a) => a['status'] != 'pending').toList();

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted': return AppColors.cyan;
      case 'graded':    return AppColors.emerald;
      default:          return AppColors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'submitted': return Icons.upload_file_rounded;
      case 'graded':    return Icons.check_circle_rounded;
      default:          return Icons.pending_rounded;
    }
  }

  void _showDetail(Map<String, dynamic> a) {
    final auth = context.read<AuthProvider>();
    final notesCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                GradientIconBox(gradient: AppGradients.courseGradients[(a['gi'] as int) % 4],
                    icon: Icons.assignment_rounded, size: 48, iconSize: 22),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(a['course'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 18),

              // Info row
              Row(children: [
                _InfoBadge(icon: Icons.calendar_today_rounded, label: 'Due ${a['due']}', color: AppColors.orange),
                const SizedBox(width: 8),
                _InfoBadge(icon: Icons.stars_rounded, label: '${a['points']} pts', color: AppColors.violet),
                const SizedBox(width: 8),
                _InfoBadge(icon: _statusIcon(a['status']), label: a['status'].toString().toUpperCase(),
                    color: _statusColor(a['status'])),
              ]),
              const SizedBox(height: 18),

              // Description
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                child: Text(a['description'] as String,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.6)),
              ),
              const SizedBox(height: 18),

              // Grade (if graded)
              if (a['status'] == 'graded' && a['grade'] != null) ...[
                const Text('Your Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppGradients.emerald,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppColors.emerald.withOpacity(0.3), blurRadius: 10)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                      child: Center(child: Text('${a['grade']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${a['grade']} / ${a['points']} points',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${((a['grade'] as int) / (a['points'] as int) * 100).round()}% score',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 18),
              ],

              // Submission notes (if pending)
              if (!auth.isTeacher && a['status'] == 'pending') ...[
                const Text('Submission Notes (optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 3, minLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add any notes for your teacher...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.violet, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ]),
          )),

          // Submit button
          if (!auth.isTeacher && a['status'] == 'pending')
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: GradientButton(
                label: submitting ? 'Submitting...' : 'Submit Assignment',
                gradient: AppGradients.violet,
                isLoading: submitting,
                icon: Icons.upload_rounded,
                onPressed: () async {
                  setS(() => submitting = true);
                  try {
                    final res = await ApiService.submitAssignment(
                      assignmentId: int.parse(a['id']),
                      content: notesCtrl.text,
                    );
                    if (res['success'] == true) {
                      _load();
                    }
                  } catch (_) {}
                  setS(() => submitting = false);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assignment submitted!'), backgroundColor: Colors.green));
                  }
                },
              ),
            ),
        ]),
      )),
    );
  }

  void _showCreateAssignment() {
    final titleCtrl   = TextEditingController();
    final descCtrl    = TextEditingController();
    final pointsCtrl  = TextEditingController(text: '100');
    String dueDate    = '';
    bool loading      = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              GradientIconBox(gradient: AppGradients.orange, icon: Icons.add_task_rounded, size: 42, iconSize: 20),
              const SizedBox(width: 12),
              const Text('Create Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 20),
            _FormField(controller: titleCtrl, label: 'Title', hint: 'e.g. Chapter 5 Problems', icon: Icons.title_rounded),
            const SizedBox(height: 14),
            _FormField(controller: descCtrl, label: 'Description', hint: 'Explain what students need to do...', icon: Icons.description_rounded, maxLines: 3),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _FormField(controller: pointsCtrl, label: 'Points', hint: '100', icon: Icons.stars_rounded, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setS(() => dueDate = '${d.day}/${d.month}/${d.year}');
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.orange),
                      const SizedBox(width: 6),
                      Text(dueDate.isEmpty ? 'Pick date' : dueDate,
                          style: TextStyle(fontSize: 13, color: dueDate.isEmpty ? Colors.grey.shade400 : AppColors.textPrimary)),
                    ]),
                  ]),
                ),
              )),
            ]),
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
                  final res = await ApiService.createAssignment(widget.course?.id ?? '', {
                    'title': titleCtrl.text,
                    'description': descCtrl.text,
                    'points': int.tryParse(pointsCtrl.text) ?? 100,
                    'due': dueDate,
                  });
                  if (res['success'] == true) {
                    _load();
                  }
                } catch (_) {}
                setS(() => loading = false);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assignment created!'), backgroundColor: Colors.green));
                }
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pending = _pending;
    final done    = _done;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        GradientHeader(
          gradient: AppGradients.orange,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppBackButton(),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Assignments', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(widget.course?.name ?? 'All Courses',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ])),
                if (auth.isTeacher)
                  GestureDetector(
                    onTap: _showCreateAssignment,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.4))),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _StatPill(label: '${pending.length} pending', icon: Icons.pending_rounded),
                const SizedBox(width: 10),
                _StatPill(label: '${done.length} completed', icon: Icons.check_circle_rounded),
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
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                  _AssignmentList(items: pending, onTap: _showDetail),
                  _AssignmentList(items: done,    onTap: _showDetail),
                ]),
        ),
      ]),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onTap;
  const _AssignmentList({required this.items, required this.onTap});

  Color _statusColor(String s) => s == 'submitted' ? AppColors.cyan : s == 'graded' ? AppColors.emerald : AppColors.orange;

  @override
  Widget build(BuildContext context) => items.isEmpty
      ? const EmptyState(icon: Icons.assignment_rounded, title: 'No assignments', subtitle: 'Nothing here yet', gradient: AppGradients.orange)
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final a = items[i];
            final gi = (a['gi'] as int) % 4;
            final status = a['status'] as String;
            return GlassCard(
              onTap: () => onTap(a),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                GradientIconBox(gradient: AppGradients.courseGradients[gi], icon: Icons.assignment_rounded, size: 50, iconSize: 24),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(a['course'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Due: ${a['due']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 10),
                    const Icon(Icons.stars_rounded, size: 12, color: AppColors.violet),
                    const SizedBox(width: 4),
                    Text('${a['points']} pts', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ])),
                const SizedBox(width: 10),
                Column(children: [
                  if (status == 'graded' && a['grade'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(gradient: AppGradients.emerald, borderRadius: BorderRadius.circular(20)),
                      child: Text('${a['grade']}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor(status).withOpacity(0.4))),
                      child: Text(status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  const SizedBox(height: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                ]),
              ]),
            );
          },
        );
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoBadge({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatPill({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.35))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 14),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    ]),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  const _FormField({required this.controller, required this.label, required this.hint,
      required this.icon, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    const SizedBox(height: 6),
    TextFormField(
      controller: controller,
      maxLines: maxLines, minLines: 1,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppColors.orange, size: 18),
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.orange, width: 2)),
      ),
    ),
  ]);
}
