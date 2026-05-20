import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class GradingScreen extends StatefulWidget {
  final Course? course;
  const GradingScreen({super.key, this.course});

  @override
  State<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends State<GradingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;
  Map<String, dynamic>? _selected;
  int _gradeValue = 80;
  final _feedbackCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadSubmissions();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getSubmissions(widget.course?.id ?? '');
      if (mounted) setState(() {
        _submissions = data.map((s) => {
          'id': (s['_id'] ?? s['id'] ?? 'unknown').toString(),
          'student': s['student'] as String? ?? 'Unknown',
          'assignment': s['assignment'] as String? ?? 'Unknown Assignment',
          'course': s['course']?.toString() ?? '',
          'time': s['time'] as String? ?? 'Recently',
          'gradientIndex': (s['gradientIndex'] as num?)?.toInt() ?? 0,
          'status': s['status'] as String? ?? 'pending',
          'grade': s['grade'] as int?,
          'feedback': s['feedback'] as String? ?? '',
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _submissions = [
          {'id': '1', 'student': 'Alice Johnson',  'assignment': 'Math Project',      'time': '2 hours ago', 'status': 'pending', 'grade': null, 'feedback': '', 'gradientIndex': 0},
          {'id': '2', 'student': 'Bob Smith',       'assignment': 'Math Project',      'time': '5 hours ago', 'status': 'pending', 'grade': null, 'feedback': '', 'gradientIndex': 1},
          {'id': '3', 'student': 'Carol White',     'assignment': 'Lab Report',        'time': '1 day ago',   'status': 'graded',  'grade': 92,  'feedback': 'Great work! Well organized.', 'gradientIndex': 2},
          {'id': '4', 'student': 'David Brown',     'assignment': 'Lab Report',        'time': '1 day ago',   'status': 'graded',  'grade': 85,  'feedback': 'Good effort. Focus on details.', 'gradientIndex': 3},
          {'id': '5', 'student': 'Emma Wilson',     'assignment': 'Chapter Summary',   'time': '3 hours ago', 'status': 'pending', 'grade': null, 'feedback': '', 'gradientIndex': 0},
          {'id': '6', 'student': 'Frank Davis',     'assignment': 'Chapter Summary',   'time': '6 hours ago', 'status': 'pending', 'grade': null, 'feedback': '', 'gradientIndex': 1},
          {'id': '7', 'student': 'Grace Lee',       'assignment': 'Problem Set 4',     'time': '2 days ago',  'status': 'graded',  'grade': 78,  'feedback': 'Needs improvement on section 3.', 'gradientIndex': 2},
        ];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _pending => _submissions.where((s) => s['status'] == 'pending' || s['status'] == 'submitted').toList();
  List<Map<String, dynamic>> get _graded  => _submissions.where((s) => s['status'] == 'graded').toList();

  void _openGrading(Map<String, dynamic> sub) {
    setState(() {
      _selected    = sub;
      _gradeValue  = (sub['grade'] as int?) ?? 80;
      _feedbackCtrl.text = sub['feedback'] ?? '';
    });
    _showGradingSheet();
  }

  void _showGradingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),

            // Student info
            Row(children: [
              GradientIconBox(
                gradient: AppGradients.courseGradients[(_selected!['gradientIndex'] as int) % 4],
                icon: Icons.person_rounded, size: 48, iconSize: 22,
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_selected!['student'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(_selected!['assignment'] as String,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 3),
                Text('Submitted: ${_selected!['time']}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
            ]),
            const SizedBox(height: 24),

            // Grade slider
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: _gradeColor(_gradeValue),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0,3))],
                ),
                child: Text('$_gradeValue / 100',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ]),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.violet,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.violet,
                overlayColor: AppColors.violet.withOpacity(0.15),
                trackHeight: 6,
              ),
              child: Slider(
                value: _gradeValue.toDouble(), min: 0, max: 100, divisions: 100,
                onChanged: (v) => setS(() { _gradeValue = v.toInt(); setState(() => _gradeValue = v.toInt()); }),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('0', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              _GradeLabel(grade: _gradeValue),
              Text('100', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
            const SizedBox(height: 20),

            // Feedback
            const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _feedbackCtrl,
              maxLines: 4, minLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Write constructive feedback for the student...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true, fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.violet, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // Quick feedback chips
            const Text('Quick Feedback', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              'Excellent work!', 'Good effort', 'Needs improvement',
              'Well structured', 'Missing key points', 'Creative approach',
            ].map((q) => GestureDetector(
              onTap: () {
                final cur = _feedbackCtrl.text;
                _feedbackCtrl.text = cur.isEmpty ? q : '$cur $q';
                _feedbackCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _feedbackCtrl.text.length));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.violet.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(q, style: const TextStyle(fontSize: 12, color: AppColors.violet, fontWeight: FontWeight.w500)),
              ),
            )).toList()),
            const SizedBox(height: 24),

            GradientButton(
              label: _submitting ? 'Submitting...' : 'Submit Grade',
              gradient: AppGradients.violet,
              isLoading: _submitting,
              icon: Icons.check_circle_rounded,
              onPressed: () async {
                setS(() => _submitting = true);
                try {
                  await ApiService.gradeSubmission(
                    submissionId: _selected!['id'].toString(),
                    score: _gradeValue,
                    feedback: _feedbackCtrl.text,
                  );
                } catch (_) {
                  await Future.delayed(const Duration(milliseconds: 500));
                }
                // Update local state
                final idx = _submissions.indexWhere((s) => s['id'] == _selected!['id']);
                if (idx >= 0) {
                  _submissions[idx]['grade']    = _gradeValue;
                  _submissions[idx]['feedback'] = _feedbackCtrl.text;
                  _submissions[idx]['status']   = 'graded';
                }
                setS(() => _submitting = false);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _selected = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Grade submitted!'), backgroundColor: Colors.green));
                }
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  LinearGradient _gradeColor(int g) {
    if (g >= 90) return AppGradients.emerald;
    if (g >= 75) return AppGradients.cyan;
    if (g >= 60) return AppGradients.orange;
    return AppGradients.red;
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final graded  = _graded;
    final avg = graded.isEmpty ? 0
        : (graded.fold(0, (s, g) => s + (g['grade'] as int? ?? 0)) / graded.length).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ─────────────────────────────────────────────────────────
        GradientHeader(
          gradient: AppGradients.fuchsia,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppBackButton(),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Grade Work', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(widget.course?.name ?? "All Courses", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ])),
                // Refresh
                GestureDetector(
                  onTap: _loadSubmissions,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.3))),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              // Stats
              Row(children: [
                Expanded(child: _HeaderStat(label: 'Pending', value: '${pending.length}', gradient: AppGradients.orange)),
                const SizedBox(width: 10),
                Expanded(child: _HeaderStat(label: 'Graded',  value: '${graded.length}',  gradient: AppGradients.emerald)),
                const SizedBox(width: 10),
                Expanded(child: _HeaderStat(label: 'Avg Grade', value: graded.isEmpty ? '—' : '$avg%', gradient: AppGradients.violet)),
              ]),
            ]),
          )),
        ),

        // ── Tabs ─────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.violet,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            indicatorColor: AppColors.violet,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Graded (${graded.length})'),
            ],
          ),
        ),

        // ── Content ──────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(controller: _tabCtrl, children: [
                  // Pending tab
                  pending.isEmpty
                      ? const EmptyState(icon: Icons.check_circle_rounded,
                          title: 'All caught up!', subtitle: 'No pending submissions',
                          gradient: AppGradients.emerald)
                      : RefreshIndicator(
                          onRefresh: _loadSubmissions,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: pending.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _SubmissionCard(
                              submission: pending[i],
                              onGrade: () => _openGrading(pending[i]),
                            ),
                          ),
                        ),

                  // Graded tab
                  graded.isEmpty
                      ? const EmptyState(icon: Icons.assignment_rounded,
                          title: 'No graded work', subtitle: 'Grade a submission first')
                      : RefreshIndicator(
                          onRefresh: _loadSubmissions,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: graded.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _SubmissionCard(
                              submission: graded[i],
                              onGrade: () => _openGrading(graded[i]),
                            ),
                          ),
                        ),
                ]),
        ),
      ]),
    );
  }
}

// ── Submission Card ─────────────────────────────────────────────────────────
class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> submission;
  final VoidCallback onGrade;
  const _SubmissionCard({required this.submission, required this.onGrade});

  String get _initials => (submission['student'] as String)
      .split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase();

  bool get _isGraded => submission['status'] == 'graded';

  @override
  Widget build(BuildContext context) {
    final gi   = (submission['gradientIndex'] as int? ?? 0) % 4;
    final grad = AppGradients.courseGradients[gi];

    return GlassCard(
      onTap: onGrade,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        // Avatar
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: grad.colors.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0,3))]),
          child: Center(child: Text(_initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(submission['student'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(submission['assignment'] as String,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(submission['time'] as String,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
          if (_isGraded && submission['feedback'] != null && (submission['feedback'] as String).isNotEmpty)...[
            const SizedBox(height: 6),
            Text('"${submission['feedback']}"',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        const SizedBox(width: 10),
        // Status / grade
        Column(children: [
          if (_isGraded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: submission['grade'] != null && (submission['grade'] as int) >= 90
                    ? AppGradients.emerald : AppGradients.violet,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${submission['grade']}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Text('Grade', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          if (_isGraded) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onGrade,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.violet.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_rounded, color: AppColors.violet, size: 14),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label, value;
  final LinearGradient gradient;
  const _HeaderStat({required this.label, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
    ]),
  );
}

class _GradeLabel extends StatelessWidget {
  final int grade;
  const _GradeLabel({required this.grade});

  String get _letter => grade >= 90 ? 'A' : grade >= 80 ? 'B' : grade >= 70 ? 'C' : grade >= 60 ? 'D' : 'F';
  Color  get _color  => grade >= 80 ? AppColors.emerald : grade >= 60 ? AppColors.orange : Colors.red;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(_letter, style: TextStyle(fontWeight: FontWeight.bold, color: _color, fontSize: 13)),
  );
}
