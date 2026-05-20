import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'course_detail_screen.dart';
import 'notifications_screen.dart';
import 'create_post_screen.dart';
import 'grading_screen.dart';
import 'schedule_management_screen.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'assignments_screen.dart';
import 'student_grades_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Course> _courses = [];
  List<Announcement> _recentAnnouncements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final courses = await ApiService.getCourses();
      
      // Load announcements from all courses
      List<Announcement> allAnnouncements = [];
      for (var course in courses) {
        final courseAnnouncements = await ApiService.getAnnouncements(
          course['id']?.toString(),
        );
        for (var ann in courseAnnouncements) {
          // Extract author name from populated authorId object
          String authorName = 'Unknown';
          if (ann is Map && ann['authorId'] is Map) {
            authorName = ann['authorId']['name'] ?? 'Unknown';
          } else if (ann is Map && ann['author'] is String) {
            authorName = ann['author'];
          }

          allAnnouncements.add(Announcement(
            id: 0,
            author: authorName,
            title: ann['title'] as String? ?? '',
            content: ann['content'] as String? ?? '',
            timestamp: ann['createdAt']?.toString() ?? DateTime.now().toString(),
            category: ann['category'] as String? ?? 'general',
            pinned: ann['pinned'] as bool? ?? false,
            date: ann['createdAt']?.toString() ?? '',
          ));
        }
      }

      if (mounted) {
        setState(() { 
          _courses = courses.map((c) => Course(
            id: c['id']?.toString() ?? '',
            name: c['name'] as String? ?? 'Course',
            teacher: c['teacher'] as String? ?? 'Unknown',
            gradientIndex: (c['gradientIndex'] as num?)?.toInt() ?? 0,
            unread: (c['unread'] as num?)?.toInt() ?? 0,
            progress: (c['progress'] as num?)?.toInt() ?? 0,
            students: (c['students'] as num?)?.toInt(),
            pending: (c['pending'] as num?)?.toInt(),
            avgGrade: (c['avgGrade'] as num?)?.toInt(),
          )).toList();
          
          // Sort by pinned first, then by most recent
          allAnnouncements.sort((a, b) {
            if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
            return b.timestamp.compareTo(a.timestamp);
          });
          _recentAnnouncements = allAnnouncements.take(5).toList();
          _loading = false; 
        }); 
      }
    } catch (e) {
      // ignore: avoid_print
      print('Dashboard load error: $e');
      if (mounted) setState(() {
        _loading = false;
        _recentAnnouncements = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isTeacher
        ? _TeacherDashboard(courses: _courses, announcements: _recentAnnouncements, loading: _loading, onRefresh: _load)
        : _StudentDashboard(courses: _courses, announcements: _recentAnnouncements, loading: _loading, onRefresh: _load);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STUDENT DASHBOARD
// ══════════════════════════════════════════════════════════════════════════════
class _StudentDashboard extends StatefulWidget {
  final List<Course> courses;
  final List<Announcement> announcements;
  final bool loading;
  final Future<void> Function() onRefresh;
  const _StudentDashboard({required this.courses, required this.announcements, required this.loading, required this.onRefresh});

  @override
  State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: CustomScrollView(slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GradientHeader(
              gradient: AppGradients.primary,
              child: SafeArea(bottom: false, child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$greeting, $name 👋',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Ready to learn today?',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ])),
                    _NotifBell(count: widget.courses.fold(0, (s, c) => s + c.unread)),
                  ]),
                  const SizedBox(height: 18),
                  // ── Progress summary ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.25))),
                    child: Row(children: [
                      Expanded(child: _MiniStat(label: 'Courses', value: '${widget.courses.length}')),
                      _Divider(),
                      Expanded(child: _MiniStat(label: 'Avg Progress',
                          value: widget.courses.isEmpty ? '0%'
                              : '${(widget.courses.fold(0, (s, c) => s + c.progress) / widget.courses.length).round()}%')),
                      _Divider(),
                      Expanded(child: _MiniStat(label: 'Announcements',
                          value: '${widget.announcements.length}')),
                    ]),
                  ),
                ]),
              )),
            ),
          ),

          SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Quick Actions ──────────────────────────────────────────
              SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              _StudentQuickActions(),
              const SizedBox(height: 24),

              // ── Recent Announcements ───────────────────────────────
              SectionHeader(
                title: 'Recent Announcements',
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('See all', style: TextStyle(color: AppColors.violet, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.announcements.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No announcements yet 📢',
                      style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ...widget.announcements.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnnouncementCard(announcement: a),
                )),
              const SizedBox(height: 24),

              // ── My Courses ─────────────────────────────────────────────
              SectionHeader(title: 'My Courses',
                trailing: widget.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null),
              const SizedBox(height: 12),
              if (widget.loading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (widget.courses.isEmpty)
                const EmptyState(icon: Icons.menu_book_rounded, title: 'No courses yet', subtitle: 'Courses you enrol in will appear here')
              else
                ...widget.courses.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StudentCourseCard(course: c),
                )),
              const SizedBox(height: 24),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TEACHER DASHBOARD
// ══════════════════════════════════════════════════════════════════════════════
class _TeacherDashboard extends StatelessWidget {
  final List<Course> courses;
  final List<Announcement> announcements;
  final bool loading;
  final Future<void> Function() onRefresh;
  const _TeacherDashboard({required this.courses, required this.announcements, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName;
    final totalStudents  = courses.fold(0, (s, c) => s + (c.students ?? 0));
    final totalPending   = courses.fold(0, (s, c) => s + (c.pending ?? 0));
    final avgGrade       = courses.isEmpty ? 0 : (courses.fold(0, (s, c) => s + (c.avgGrade ?? 0)) / courses.length).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GradientHeader(
              gradient: AppGradients.primary,
              child: SafeArea(bottom: false, child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome, $name 👨‍🏫',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Teaching Dashboard',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ])),
                    _NotifBell(count: totalPending),
                  ]),
                  const SizedBox(height: 18),
                  // ── Stats row ──
                  Row(children: [
                    Expanded(child: _TeacherStatBox(icon: Icons.people_rounded, label: 'Students', value: '$totalStudents')),
                    const SizedBox(width: 10),
                    Expanded(child: _TeacherStatBox(icon: Icons.pending_actions_rounded, label: 'To Grade', value: '$totalPending')),
                    const SizedBox(width: 10),
                    Expanded(child: _TeacherStatBox(icon: Icons.trending_up_rounded, label: 'Avg Grade', value: '$avgGrade%')),
                  ]),
                ]),
              )),
            ),
          ),

          SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Quick Actions ──────────────────────────────────────────
              SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              _TeacherQuickActions(courses: courses, onPostCreated: onRefresh),
              const SizedBox(height: 24),

              // ── My Classes with real data ──────────────────────────
              SectionHeader(title: 'My Classes',
                trailing: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null),
              const SizedBox(height: 12),
              if (loading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (courses.isEmpty)
                const EmptyState(icon: Icons.menu_book_rounded, title: 'No classes yet', subtitle: 'Your courses will appear here')
              else
                ...courses.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TeacherCourseCard(course: c),
                )),
              const SizedBox(height: 24),

              // ── Recent Announcements Posted ────────────────────────────
              SectionHeader(title: 'Posts You\'ve Made'),
              const SizedBox(height: 12),
              if (announcements.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No posts yet. Create one to get started! 📝',
                      style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ...announcements.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnnouncementCard(announcement: a),
                )),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED SUBWIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _NotifBell extends StatelessWidget {
  final int count;
  const _NotifBell({required this.count});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
    child: Stack(clipBehavior: Clip.none, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.3))),
        child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
      ),
      if (count > 0)
        Positioned(top: -4, right: -4,
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(gradient: AppGradients.orange, shape: BoxShape.circle),
            child: Center(child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          )),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
  ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.25));
}

class _TeacherStatBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _TeacherStatBox({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.25))),
    child: Column(children: [
      Icon(icon, color: Colors.white, size: 22),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
    ]),
  );
}

class _StudentQuickActions extends StatelessWidget {
  const _StudentQuickActions();
  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.search_rounded,   'label': 'Search',      'gi': 0, 'route': const SearchScreen()},
      {'icon': Icons.assignment_rounded,'label': 'Assignments', 'gi': 1, 'route': const AssignmentsScreen()},
      {'icon': Icons.chat_bubble_rounded,'label': 'Chat',       'gi': 2, 'route': const ChatScreen()},
      {'icon': Icons.grade_rounded,     'label': 'My Grades',   'gi': 3, 'route': const StudentGradesScreen()},
    ];
    return Row(children: actions.map((a) {
      final gi = a['gi'] as int;
      final route = a['route'] as Widget?;
      return Expanded(child: GestureDetector(
        onTap: () {
          if (route != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => route));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${a['label']} coming soon'), duration: const Duration(seconds: 1)));
          }
        },
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(children: [
            GradientIconBox(gradient: AppGradients.courseGradients[gi], icon: a['icon'] as IconData, size: 46, iconSize: 21),
            const SizedBox(height: 8),
            Text(a['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
          ]),
        ),
      ));
    }).toList());
  }
}

class _TeacherQuickActions extends StatelessWidget {
  final List<Course> courses;
  final Future<void> Function()? onPostCreated;
  const _TeacherQuickActions({required this.courses, this.onPostCreated});

  Course? get _firstCourse => courses.isEmpty ? null : courses.first;

  void _nav(BuildContext context, Widget Function(Course) builder) {
    final c = _firstCourse;
    if (c == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No courses available')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder(c)));
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.post_add_rounded, 'label': 'Create Post', 'gi': 3, 'type': 'post'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Schedule', 'gi': 0, 'type': 'schedule'},
      {'icon': Icons.assignment_turned_in_rounded, 'label': 'Grade Work', 'gi': 1, 'type': 'grade'},
      {'icon': Icons.analytics_rounded, 'label': 'Analytics', 'gi': 2, 'type': 'analytics'},
    ];
    return Row(children: actions.map((a) {
      final gi = a['gi'] as int;
      return Expanded(child: GestureDetector(
        onTap: () {
          switch (a['type']) {
            case 'post':
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()))
                .then((res) {
                  if (res == true) {
                    if (onPostCreated != null) onPostCreated!();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dashboard updated')));
                  }
                });
              break;
            case 'schedule': _nav(context, (c) => ScheduleManagementScreen(course: c)); break;
            case 'grade': _nav(context, (c) => GradingScreen(course: c)); break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analytics coming soon')));
          }
        },
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(children: [
            GradientIconBox(gradient: AppGradients.courseGradients[gi], icon: a['icon'] as IconData, size: 46, iconSize: 21),
            const SizedBox(height: 8),
            Text(a['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
          ]),
        ),
      ));
    }).toList());
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  Color get _categoryColor {
    switch (announcement.category) {
      case 'assignment':
        return AppColors.emerald;
      case 'grade':
        return AppColors.orange;
      case 'resource':
        return AppColors.violet;
      default:
        return AppColors.blue;
    }
  }

  String get _categoryLabel {
    switch (announcement.category) {
      case 'assignment':
        return 'Assignment';
      case 'grade':
        return 'Grade';
      case 'resource':
        return 'Resource';
      default:
        return 'General';
    }
  }

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (announcement.pinned) ...[
        Row(children: [
          Icon(Icons.push_pin_rounded, size: 14, color: AppColors.orange),
          const SizedBox(width: 4),
          Text('Pinned', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.orange)),
        ]),
        const SizedBox(height: 6),
      ],
      Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(announcement.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Text(announcement.author, style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _categoryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Text(_categoryLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _categoryColor)),
        ),
      ]),
    ]),
  );
}

class _StudentCourseCard extends StatelessWidget {
  final Course course;
  const _StudentCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final grad = AppGradients.courseGradients[course.gradientIndex % 4];
    return GlassCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course))),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        GradientIconBox(gradient: grad, icon: Icons.menu_book_rounded, size: 56, iconSize: 26),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(course.teacher, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Progress', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('${course.progress}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: grad.colors.first)),
          ]),
          const SizedBox(height: 4),
          GradientProgressBar(progress: course.progress / 100, gradient: grad),
        ])),
        if (course.unread > 0) ...[
          const SizedBox(width: 10),
          GradientBadge(text: '${course.unread}', gradient: AppGradients.orange),
        ],
      ]),
    );
  }
}

class _TeacherCourseCard extends StatelessWidget {
  final Course course;
  const _TeacherCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final grad = AppGradients.courseGradients[course.gradientIndex % 4];
    return GlassCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course))),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        GradientIconBox(gradient: grad, icon: Icons.menu_book_rounded, size: 58, iconSize: 28),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.people_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${course.students ?? 0} students', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            const Icon(Icons.trending_up_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('Avg: ${course.avgGrade ?? 0}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          if ((course.pending ?? 0) > 0) ...[
            const SizedBox(height: 6),
            InfoChip(label: '${course.pending} pending grades', color: AppColors.orange),
          ],
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      ]),
    );
  }
}
