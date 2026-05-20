import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'announcements_screen.dart';
import 'materials_screen.dart';
import 'chat_screen.dart';
import 'assignments_screen.dart';
import 'grading_screen.dart';
import 'create_post_screen.dart';
import 'student_list_screen.dart';
import 'student_grades_screen.dart';
import 'schedule_management_screen.dart';
import 'qa_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final grad  = AppGradients.courseGradients[course.gradientIndex % 4];
    final isTeacher = auth.isTeacher;

    // Student tabs
    final studentTabs = [
      _Tab(icon: Icons.campaign_rounded,            label: 'Announcements',  gradient: AppGradients.orange,
           onTap: () => _push(context, AnnouncementsScreen(course: course))),
      _Tab(icon: Icons.folder_open_rounded,         label: 'Materials',      gradient: AppGradients.cyan,
           onTap: () => _push(context, MaterialsScreen(course: course))),
      _Tab(icon: Icons.assignment_rounded,          label: 'Assignments',    gradient: AppGradients.orange,
           onTap: () => _push(context, AssignmentsScreen(course: course))),
      _Tab(icon: Icons.grade_rounded,               label: 'My Grades',      gradient: AppGradients.purple,
           onTap: () => _push(context, StudentGradesScreen(course: course))),
      _Tab(icon: Icons.question_answer_rounded,     label: 'Q&A Forum',      gradient: AppGradients.red,
           onTap: () => _push(context, QAScreen(course: course))),
      _Tab(icon: Icons.forum_rounded,               label: 'Discussion',     gradient: AppGradients.violet,
           onTap: () => _push(context, const ChatScreen())),
    ];

    // Teacher tabs
    final teacherTabs = [
      _Tab(icon: Icons.campaign_rounded,            label: 'Announcements',  gradient: AppGradients.orange,
           onTap: () => _push(context, AnnouncementsScreen(course: course))),
      _Tab(icon: Icons.post_add_rounded,            label: 'Create Post',    gradient: AppGradients.emerald,
           onTap: () => _push(context, const CreatePostScreen())),
      _Tab(icon: Icons.folder_open_rounded,         label: 'Materials',      gradient: AppGradients.cyan,
           onTap: () => _push(context, MaterialsScreen(course: course))),
      _Tab(icon: Icons.assignment_turned_in_rounded,label: 'Grade Work',     gradient: AppGradients.fuchsia,
           onTap: () => _push(context, GradingScreen(course: course))),
      _Tab(icon: Icons.people_rounded,              label: 'Students',       gradient: AppGradients.emerald,
           onTap: () => _push(context, StudentListScreen(course: course))),
      _Tab(icon: Icons.calendar_month_rounded,      label: 'Schedule',       gradient: AppGradients.cyan,
           onTap: () => _push(context, ScheduleManagementScreen(course: course))),
      _Tab(icon: Icons.question_answer_rounded,     label: 'Q&A Forum',      gradient: AppGradients.red,
           onTap: () => _push(context, QAScreen(course: course))),
      _Tab(icon: Icons.forum_rounded,               label: 'Discussion',     gradient: AppGradients.violet,
           onTap: () => _push(context, const ChatScreen())),
    ];

    final tabs = isTeacher ? teacherTabs : studentTabs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        // ── Header ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: GradientHeader(
            gradient: grad,
            child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppBackButton(),
                const SizedBox(height: 16),
                Text(course.name,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(course.teacher,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                const SizedBox(height: 14),
                // Course stats
                Row(children: [
                  if (!isTeacher) ...[
                    _CoursePill(icon: Icons.trending_up_rounded, label: '${course.progress}% complete'),
                    const SizedBox(width: 10),
                    if (course.unread > 0)
                      _CoursePill(icon: Icons.notifications_rounded, label: '${course.unread} new'),
                  ] else ...[
                    if (course.students != null)
                      _CoursePill(icon: Icons.people_rounded, label: '${course.students} students'),
                    const SizedBox(width: 10),
                    if (course.pending != null && course.pending! > 0)
                      _CoursePill(icon: Icons.pending_rounded, label: '${course.pending} to grade'),
                  ],
                ]),
              ]),
            )),
          ),
        ),

        // ── Progress bar (student only) ──────────────────────────────────
        if (!isTeacher)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Course Progress',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    Text('${course.progress}%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: grad.colors.first)),
                  ]),
                  const SizedBox(height: 8),
                  GradientProgressBar(progress: course.progress / 100, gradient: grad, height: 10),
                ]),
              ),
            ),
          ),

        // ── Section label ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: SectionHeader(title: isTeacher ? 'Teaching Tools' : 'Course Content'),
          ),
        ),

        // ── Tabs grid ────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  onTap: tabs[i].onTap,
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    GradientIconBox(gradient: tabs[i].gradient, icon: tabs[i].icon, size: 52, iconSize: 24),
                    const SizedBox(width: 18),
                    Expanded(child: Text(tabs[i].label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary))),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.textSecondary),
                  ]),
                ),
              ),
              childCount: tabs.length,
            ),
          ),
        ),
      ]),
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _Tab {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _Tab({required this.icon, required this.label, required this.gradient, required this.onTap});
}

class _CoursePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CoursePill({required this.icon, required this.label});
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
