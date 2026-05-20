import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class StudentListScreen extends StatefulWidget {
  final Course? course;
  const StudentListScreen({super.key, this.course});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _filterIndex = 0;
  final _filters = ['All', 'High Performers', 'At Risk'];

  List<Map<String, dynamic>> _students = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    if (widget.course != null) {
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final courseData = await ApiService.getCourse(widget.course!.id);
      final rawStudents = List<dynamic>.from(courseData['studentsList'] ?? []);
      
      final mapped = rawStudents.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return {
          'id': s['_id']?.toString() ?? i.toString(),
          'name': s['name'] ?? 'Unknown',
          'email': s['email'] ?? '',
          'avg': 75 + (i % 20), // Mock data for now since backend doesn't provide it
          'submitted': 8,
          'total': 8,
          'lastActive': '1 hour ago',
          'gi': i % 4,
        };
      }).toList();
      
      setState(() {
        _students = mapped;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_students);
    if (_query.isNotEmpty) {
      list = list.where((s) =>
          (s['name'] as String).toLowerCase().contains(_query.toLowerCase()) ||
          (s['email'] as String).toLowerCase().contains(_query.toLowerCase())).toList();
    }
    if (_filterIndex == 1) list = list.where((s) => (s['avg'] as int) >= 85).toList();
    if (_filterIndex == 2) list = list.where((s) => (s['avg'] as int) < 65).toList();
    return list;
  }

  double get _classAvg {
    if (_students.isEmpty) return 0;
    return _students.fold(0.0, (s, st) => s + (st['avg'] as int)) / _students.length;
  }

  int get _atRisk => _students.where((s) => (s['avg'] as int) < 65).length;
  int get _highPerf => _students.where((s) => (s['avg'] as int) >= 85).length;

  Color _perfColor(int avg) =>
      avg >= 85 ? AppColors.emerald : avg >= 65 ? AppColors.orange : AppColors.rose;

  String _initials(String name) =>
      name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase();

  void _showStudentDetail(Map<String, dynamic> student) {
    final avg = student['avg'] as int;
    final sub = student['submitted'] as int;
    final tot = student['total'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          // Avatar & name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: AppGradients.courseGradients[(student['gi'] as int) % 4],
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.35), blurRadius: 16)],
                ),
                child: Center(child: Text(_initials(student['name']),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22))),
              ),
              const SizedBox(height: 12),
              Text(student['name'] as String,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(student['email'] as String,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Last active: ${student['lastActive']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: _DetailStat(label: 'Average', value: '$avg%', color: _perfColor(avg))),
              Expanded(child: _DetailStat(label: 'Submitted', value: '$sub/$tot', color: AppColors.cyan)),
              Expanded(child: _DetailStat(label: 'Completion', value: '${((sub / tot) * 100).round()}%', color: AppColors.violet)),
            ]),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Average Score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('$avg / 100', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _perfColor(avg))),
              ]),
              const SizedBox(height: 8),
              GradientProgressBar(
                progress: avg / 100,
                gradient: LinearGradient(colors: [_perfColor(avg), _perfColor(avg).withOpacity(0.6)]),
                height: 10,
              ),
            ]),
          ),
          const Spacer(),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () { Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening chat...'))); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(gradient: AppGradients.violet, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.35), blurRadius: 10)]),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () { Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Viewing grades...'))); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(gradient: AppGradients.emerald, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.emerald.withOpacity(0.35), blurRadius: 10)]),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.grade_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Grades', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        GradientHeader(
          gradient: AppGradients.emerald,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppBackButton(),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Students', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(widget.course?.name ?? 'All Classes',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              // Stats bar
              Row(children: [
                Expanded(child: _HeaderStat(label: 'Total',     value: '${_students.length}')),
                const SizedBox(width: 8),
                Expanded(child: _HeaderStat(label: 'Avg Score', value: '${_classAvg.toStringAsFixed(0)}%')),
                const SizedBox(width: 8),
                Expanded(child: _HeaderStat(label: 'At Risk',   value: '$_atRisk')),
                const SizedBox(width: 8),
                Expanded(child: _HeaderStat(label: 'Excelling', value: '$_highPerf')),
              ]),
              const SizedBox(height: 14),
              // Search
              Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3))),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.green.shade200, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
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
            activeGradient: AppGradients.emerald,
          ),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Text('${filtered.length} student${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ]),
        ),

        // List
        Expanded(
          child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
              ? const EmptyState(icon: Icons.people_rounded, title: 'No students found',
                  subtitle: 'Try adjusting your search or filter', gradient: AppGradients.emerald)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final s = filtered[i];
                    final avg = s['avg'] as int;
                    final sub = s['submitted'] as int;
                    final tot = s['total'] as int;
                    final gi = (s['gi'] as int) % 4;
                    return GlassCard(
                      onTap: () => _showStudentDetail(s),
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        // Avatar
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            gradient: AppGradients.courseGradients[gi],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                                color: AppGradients.courseGradients[gi].colors.first.withOpacity(0.3),
                                blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Center(child: Text(_initials(s['name']),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Text(s['email'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            // Submission progress
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('Submitted', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                Text('$sub/$tot', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              ]),
                              const SizedBox(height: 3),
                              GradientProgressBar(
                                progress: sub / tot,
                                gradient: LinearGradient(colors: [AppColors.cyan, AppColors.cyan.withOpacity(0.6)]),
                                height: 4,
                              ),
                            ])),
                          ]),
                        ])),
                        const SizedBox(width: 12),
                        // Grade badge
                        Column(children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_perfColor(avg), _perfColor(avg).withOpacity(0.7)]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _perfColor(avg).withOpacity(0.35), blurRadius: 8)],
                            ),
                            child: Center(child: Text('$avg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                          ),
                          const SizedBox(height: 4),
                          Text(avg >= 85 ? 'Top' : avg < 65 ? 'Risk' : 'Good',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _perfColor(avg))),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label, value;
  const _HeaderStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
    ]),
  );
}

class _DetailStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DetailStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: color.withOpacity(0.75), fontSize: 11)),
    ]),
  );
}
