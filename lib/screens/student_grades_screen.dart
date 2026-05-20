import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class StudentGradesScreen extends StatefulWidget {
  final Course? course; // null = all courses
  const StudentGradesScreen({super.key, this.course});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  final List<Map<String, dynamic>> _grades = [];
  bool _loading = true;
  int _filterIndex = 0;
  final _filters = ['All', 'Graded', 'Pending'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API
    if (mounted) {
      setState(() {
        _grades.clear();
        _grades.addAll([
          {'id': '1', 'assignment': 'Math Assignment 1', 'course': 'Mathematics 101', 'grade': 88,  'maxGrade': 100, 'feedback': 'Good work! Strong understanding of derivatives.', 'status': 'graded',  'date': 'Apr 10, 2026', 'gi': 0},
          {'id': '2', 'assignment': 'Math Assignment 2', 'course': 'Mathematics 101', 'grade': 92,  'maxGrade': 100, 'feedback': 'Excellent! Perfect score on integration.', 'status': 'graded',  'date': 'Apr 18, 2026', 'gi': 0},
          {'id': '3', 'assignment': 'Math Assignment 3', 'course': 'Mathematics 101', 'grade': null, 'maxGrade': 100, 'feedback': '', 'status': 'pending', 'date': 'Apr 26, 2026', 'gi': 0},
          {'id': '4', 'assignment': 'Physics Lab Report', 'course': 'Physics Advanced', 'grade': 78, 'maxGrade': 100, 'feedback': 'Good effort. Work on your error analysis section.', 'status': 'graded',  'date': 'Apr 12, 2026', 'gi': 1},
          {'id': '5', 'assignment': 'Newton\'s Laws Quiz', 'course': 'Physics Advanced', 'grade': 95, 'maxGrade': 100, 'feedback': 'Excellent understanding!', 'status': 'graded',  'date': 'Apr 20, 2026', 'gi': 1},
          {'id': '6', 'assignment': 'CS Project Phase 1', 'course': 'Computer Science', 'grade': 90, 'maxGrade': 100, 'feedback': 'Great implementation. Clean code.', 'status': 'graded',  'date': 'Apr 08, 2026', 'gi': 2},
          {'id': '7', 'assignment': 'CS Project Phase 2', 'course': 'Computer Science', 'grade': null, 'maxGrade': 100, 'feedback': '', 'status': 'pending', 'date': 'Apr 28, 2026', 'gi': 2},
          {'id': '8', 'assignment': 'Shakespeare Essay',  'course': 'English Literature', 'grade': 85, 'maxGrade': 100, 'feedback': 'Very insightful analysis!', 'status': 'graded',  'date': 'Apr 15, 2026', 'gi': 3},
        ]);
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = widget.course != null
        ? _grades.where((g) => g['course'] == widget.course!.name).toList().cast<Map<String, dynamic>>()
        : List<Map<String, dynamic>>.from(_grades);
    if (_filterIndex == 1) return list.where((g) => g['status'] == 'graded').toList().cast<Map<String, dynamic>>();
    if (_filterIndex == 2) return list.where((g) => g['status'] == 'pending').toList().cast<Map<String, dynamic>>();
    return list.cast<Map<String, dynamic>>();
  }

  double get _gpa {
    final graded = _grades.where((g) => g['grade'] != null).toList();
    if (graded.isEmpty) return 0;
    return graded.fold(0.0, (s, g) => s + (g['grade'] as int)) / graded.length;
  }

  String _letterGrade(int g) => g >= 90 ? 'A' : g >= 80 ? 'B' : g >= 70 ? 'C' : g >= 60 ? 'D' : 'F';
  Color _gradeColor(int g) => g >= 80 ? AppColors.emerald : g >= 60 ? AppColors.orange : AppColors.rose;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final gradedCount = _grades.where((g) => g['grade'] != null).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        GradientHeader(
          gradient: AppGradients.purple,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppBackButton(),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('My Grades', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(widget.course?.name ?? 'All Courses',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              // GPA card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.25))),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Average Score', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${_gpa.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_gpa >= 90 ? 'Excellent 🏆' : _gpa >= 80 ? 'Great 🌟' : _gpa >= 70 ? 'Good 👍' : 'Needs work 📚',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                  ])),
                  Container(width: 1, height: 60, color: Colors.white.withOpacity(0.25)),
                  Expanded(child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _MiniStat2(label: 'Graded', value: '$gradedCount'),
                      _MiniStat2(label: 'Pending', value: '${_grades.length - gradedCount}'),
                    ]),
                  ])),
                ]),
              ),
            ]),
          )),
        ),

        // Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: FilterBar(
            labels: _filters, selectedIndex: _filterIndex,
            onSelected: (i) => setState(() => _filterIndex = i),
            activeGradient: AppGradients.purple,
          ),
        ),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const EmptyState(icon: Icons.grade_rounded, title: 'No grades yet',
                      subtitle: 'Your grades will appear here', gradient: AppGradients.purple)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final g = filtered[i];
                          final grade = g['grade'] as int?;
                          final gi = (g['gi'] as int) % 4;
                          return GlassCard(
                            onTap: grade != null ? () => _showDetail(g) : null,
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              GradientIconBox(
                                gradient: AppGradients.courseGradients[gi],
                                icon: Icons.assignment_rounded, size: 48, iconSize: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(g['assignment'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(g['course'] as String,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(g['date'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ]),
                                if (grade != null) ...[
                                  const SizedBox(height: 8),
                                  GradientProgressBar(
                                    progress: grade / 100,
                                    gradient: LinearGradient(colors: [_gradeColor(grade), _gradeColor(grade).withOpacity(0.7)]),
                                    height: 5,
                                  ),
                                ],
                              ])),
                              const SizedBox(width: 12),
                              if (grade != null)
                                Column(children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [_gradeColor(grade), _gradeColor(grade).withOpacity(0.7)]),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: _gradeColor(grade).withOpacity(0.35), blurRadius: 10)],
                                    ),
                                    child: Center(child: Text('$grade', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_letterGrade(grade), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _gradeColor(grade))),
                                ])
                              else
                                Column(children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle,
                                        border: Border.all(color: Colors.orange.shade200, width: 2)),
                                    child: const Center(child: Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 22)),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Pending', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                ]),
                            ]),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  void _showDetail(Map<String, dynamic> g) {
    final grade = g['grade'] as int;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(g['assignment'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(g['course'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_gradeColor(grade), _gradeColor(grade).withOpacity(0.7)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _gradeColor(grade).withOpacity(0.4), blurRadius: 16)],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$grade', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(_letterGrade(grade), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GradientProgressBar(
                progress: grade / 100,
                gradient: LinearGradient(colors: [_gradeColor(grade), _gradeColor(grade).withOpacity(0.7)]),
                height: 10,
              ),
              const SizedBox(height: 8),
              Text('$grade out of ${g['maxGrade']} points',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
          ]),
          if ((g['feedback'] as String).isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.comment_rounded, size: 15, color: AppColors.violet),
                  SizedBox(width: 6),
                  Text('Teacher Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.violet)),
                ]),
                const SizedBox(height: 8),
                Text(g['feedback'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
              ]),
            ),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _MiniStat2 extends StatelessWidget {
  final String label, value;
  const _MiniStat2({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
  ]);
}
