import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class ScheduleManagementScreen extends StatefulWidget {
  final Course course;
  const ScheduleManagementScreen({super.key, required this.course});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _loading = true;

  final _timeCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  String _type = 'Lecture';
  String _day  = 'Monday';
  int    _duration = 60;

  static const _types = ['Lecture', 'Lab', 'Tutorial', 'Exam', 'Consultation'];
  static const _days  = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static const _durations = [30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getSchedule(courseId: widget.course.id);
      if (mounted) setState(() {
        _schedules = data.map((s) => {
          'id': (s['_id'] ?? s['id'] ?? 'unknown').toString(),
          'time': s['time'] as String? ?? '09:00 AM',
          'day': s['day'] as String? ?? '',
          'room': s['room'] as String? ?? '',
          'type': s['type'] as String? ?? 'Lecture',
          'duration': (s['duration'] as num?)?.toInt() ?? 60
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _schedules = [
          {'id': '1', 'time': '09:00 AM', 'day': 'Monday',    'room': 'Room 101', 'type': 'Lecture',     'duration': 60},
          {'id': '2', 'time': '11:00 AM', 'day': 'Tuesday',   'room': 'Lab A',    'type': 'Lab',         'duration': 90},
          {'id': '3', 'time': '02:00 PM', 'day': 'Wednesday', 'room': 'Room 205', 'type': 'Tutorial',    'duration': 45},
          {'id': '4', 'time': '10:00 AM', 'day': 'Thursday',  'room': 'Lab A',    'type': 'Lecture',     'duration': 60},
        ];
        _loading = false;
      });
    }
  }

  void _showAddSheet() {
    _timeCtrl.clear(); _roomCtrl.clear();
    _type = 'Lecture'; _day = 'Monday'; _duration = 60;

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
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              GradientIconBox(gradient: AppGradients.cyan, icon: Icons.event_rounded, size: 42, iconSize: 20),
              const SizedBox(width: 12),
              const Text('Add Schedule Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 22),

            // Day
            const _Label('Day of Week'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _days.map((d) {
                final sel = d == _day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setS(() => _day = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? AppGradients.cyan : null,
                        color: sel ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: sel ? [BoxShadow(color: AppColors.cyan.withOpacity(0.35), blurRadius: 8)] : [],
                      ),
                      child: Text(d.substring(0, 3),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                              color: sel ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 16),

            // Time picker
            const _Label('Time'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: AppColors.cyan)),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setS(() => _timeCtrl.text = picked.format(context));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.cyan, size: 20),
                  const SizedBox(width: 10),
                  Text(_timeCtrl.text.isEmpty ? 'Tap to select time' : _timeCtrl.text,
                      style: TextStyle(
                          color: _timeCtrl.text.isEmpty ? Colors.grey.shade400 : AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Room
            const _Label('Room / Location'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _roomCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Room 101, Lab A',
                prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.cyan, size: 20),
                filled: true, fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cyan, width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            // Type
            const _Label('Class Type'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6,
              children: _types.map((t) {
                final sel = t == _type;
                return GestureDetector(
                  onTap: () => setS(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: sel ? _typeGradient(t) : null,
                      color: sel ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: sel ? [BoxShadow(color: _typeGradient(t).colors.first.withOpacity(0.35), blurRadius: 8)] : [],
                    ),
                    child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                        color: sel ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Duration
            const _Label('Duration (minutes)'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _durations.map((d) {
                final sel = d == _duration;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setS(() => _duration = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? AppGradients.violet : null,
                        color: sel ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${d}m', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                          color: sel ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 24),

            GradientButton(
              label: 'Add to Schedule',
              gradient: AppGradients.cyan,
              icon: Icons.add_rounded,
              onPressed: () async {
                if (_timeCtrl.text.isEmpty || _roomCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in time and room')));
                  return;
                }
                try {
                  await ApiService.createScheduleItem(widget.course.id, {
                    'time': _timeCtrl.text, 'day': _day,
                    'room': _roomCtrl.text, 'type': _type, 'duration': _duration,
                  });
                } catch (_) {}
                setState(() {
                  _schedules.add({
                    'id': '${DateTime.now().millisecondsSinceEpoch}',
                    'time': _timeCtrl.text, 'day': _day,
                    'room': _roomCtrl.text, 'type': _type, 'duration': _duration,
                  });
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Schedule added!'), backgroundColor: Colors.green));
                }
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Schedule'),
        content: const Text('Remove this class from the schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try { await ApiService.deleteScheduleItem(widget.course.id, int.parse(id)); } catch (_) {}
    setState(() => _schedules.removeWhere((s) => s['id'] == id));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule item removed'), backgroundColor: Colors.red));
  }

  LinearGradient _typeGradient(String type) {
    switch (type) {
      case 'Lab':          return AppGradients.emerald;
      case 'Tutorial':     return AppGradients.orange;
      case 'Exam':         return AppGradients.red;
      case 'Consultation': return AppGradients.purple;
      default:             return AppGradients.cyan;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Lab':          return Icons.science_rounded;
      case 'Tutorial':     return Icons.groups_rounded;
      case 'Exam':         return Icons.quiz_rounded;
      case 'Consultation': return Icons.support_agent_rounded;
      default:             return Icons.school_rounded;
    }
  }

  // Group by day for display
  Map<String, List<Map<String, dynamic>>> get _byDay {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final d in _days) {
      final items = _schedules.where((s) => s['day'] == d).toList();
      if (items.isNotEmpty) result[d] = items;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _byDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ─────────────────────────────────────────────────────
        GradientHeader(
          gradient: AppGradients.cyan,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppBackButton(),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Schedule', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(widget.course.name, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ])),
                GestureDetector(
                  onTap: _showAddSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _StatPill(label: '${_schedules.length} classes'),
                const SizedBox(width: 10),
                _StatPill(label: '${_byDay.length} days/week'),
              ]),
            ]),
          )),
        ),

        // ── List ───────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _schedules.isEmpty
                  ? EmptyState(
                      icon: Icons.calendar_month_rounded,
                      title: 'No schedule yet',
                      subtitle: 'Tap "Add" to create your first class slot',
                      gradient: AppGradients.cyan,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: grouped.length,
                        itemBuilder: (_, i) {
                          final day   = grouped.keys.elementAt(i);
                          final items = grouped[day]!;
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Day header
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10, top: 4),
                              child: Row(children: [
                                Container(width: 4, height: 18,
                                    decoration: BoxDecoration(gradient: AppGradients.cyan, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 8),
                                Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text('${items.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyan)),
                                ),
                              ]),
                            ),
                            ...items.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ScheduleCard(schedule: s, onDelete: () => _delete(s['id']),
                                  gradient: _typeGradient(s['type']), icon: _typeIcon(s['type'])),
                            )),
                            const SizedBox(height: 8),
                          ]);
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onDelete;
  final LinearGradient gradient;
  final IconData icon;
  const _ScheduleCard({required this.schedule, required this.onDelete, required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      GradientIconBox(gradient: gradient, icon: icon, size: 48, iconSize: 22),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(schedule['time'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(width: 10),
          InfoChip(label: schedule['type'] as String, color: gradient.colors.first),
        ]),
        const SizedBox(height: 5),
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(schedule['room'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('${schedule['duration']}min', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
      ])),
      GestureDetector(
        onTap: onDelete,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
        ),
      ),
    ]),
  );
}

class _StatPill extends StatelessWidget {
  final String label;
  const _StatPill({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
}
