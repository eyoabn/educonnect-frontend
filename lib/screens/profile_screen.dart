import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;
  bool _loadingStats = true;
  int _courseCount = 0;
  int _completedAssignments = 0;
  
  // Teacher stats
  int _classesCount = 0;
  int _studentsCount = 0;
  int _pendingCount = 0;
  double _avgScore = 0.0;

  // Admin stats
  int _adminCoursesCount = 0;
  int _adminTeachersCount = 0;
  int _adminStudentsCount = 0;
  int _adminPendingApprovalsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    final auth = context.read<AuthProvider>();
    try {
      if (auth.isAdmin) {
        final results = await Future.wait([
          ApiService.adminGetCourses(),
          ApiService.adminGetUsersByRole('teacher'),
          ApiService.adminGetUsersByRole('student'),
        ]);
        
        final courses = results[0] as List;
        final teachers = results[1] as List;
        final students = results[2] as List;
        
        int pending = 0;
        pending += teachers.where((u) => u['approved'] == false).length;
        pending += students.where((u) => u['approved'] == false).length;

        if (mounted) {
          setState(() {
            _adminCoursesCount = courses.length;
            _adminTeachersCount = teachers.where((u) => u['approved'] == true).length;
            _adminStudentsCount = students.where((u) => u['approved'] == true).length;
            _adminPendingApprovalsCount = pending;
            _loadingStats = false;
          });
        }
      } else if (auth.isTeacher) {
        final courses = await ApiService.getCourses();
        int totalStudents = 0;
        int totalPending = 0;
        double sumAvgGrade = 0.0;
        int avgGradeCount = 0;

        for (final c in courses) {
          totalStudents += (c['students'] as num?)?.toInt() ?? 0;
          totalPending += (c['pending'] as num?)?.toInt() ?? 0;
          final avg = c['avgGrade'] as num?;
          if (avg != null && avg > 0) {
            sumAvgGrade += avg.toDouble();
            avgGradeCount++;
          }
        }

        if (mounted) {
          setState(() {
            _classesCount = courses.length;
            _studentsCount = totalStudents;
            _pendingCount = totalPending;
            _avgScore = avgGradeCount > 0 ? (sumAvgGrade / avgGradeCount) : 0.0;
            _loadingStats = false;
          });
        }
      } else {
        // Student
        final results = await Future.wait([
          ApiService.getCourses(),
          ApiService.getGrades(auth.id),
        ]);
        final courses = results[0] as List;
        final grades = results[1] as List;

        if (mounted) {
          setState(() {
            _courseCount = courses.length;
            _completedAssignments = grades.where((g) => g['status'] == 'graded').length;
            _loadingStats = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isTeacher = auth.isTeacher;
    final isAdmin = auth.isAdmin;
    final isStudent = !isTeacher && !isAdmin;

    final tabs = isStudent ? ['Stats', 'Badges', 'Activity'] : ['Stats', 'Activity'];
    if (_tabIndex >= tabs.length) {
      _tabIndex = 0;
    }

    final studentStats = [
      _StatData(icon: Icons.menu_book_rounded, label: 'Courses', value: _courseCount.toString(), gi: 0),
      _StatData(icon: Icons.emoji_events_rounded, label: 'Completed', value: _completedAssignments.toString(), gi: 1),
      _StatData(icon: Icons.track_changes_rounded, label: 'Goals', value: '8/10', gi: 2),
      _StatData(icon: Icons.military_tech_rounded, label: 'Rank', value: '#15', gi: 3),
    ];
    final teacherStats = [
      _StatData(icon: Icons.menu_book_rounded, label: 'Classes', value: _classesCount.toString(), gi: 0),
      _StatData(icon: Icons.people_rounded, label: 'Students', value: _studentsCount.toString(), gi: 1),
      _StatData(icon: Icons.assignment_turned_in_rounded, label: 'Pending', value: _pendingCount.toString(), gi: 2),
      _StatData(icon: Icons.military_tech_rounded, label: 'Avg Score', value: '${_avgScore.round()}%', gi: 3),
    ];
    final adminStats = [
      _StatData(icon: Icons.menu_book_rounded, label: 'Courses', value: _adminCoursesCount.toString(), gi: 0),
      _StatData(icon: Icons.school_rounded, label: 'Teachers', value: _adminTeachersCount.toString(), gi: 1),
      _StatData(icon: Icons.people_rounded, label: 'Students', value: _adminStudentsCount.toString(), gi: 2),
      _StatData(icon: Icons.hourglass_empty_rounded, label: 'Pending', value: _adminPendingApprovalsCount.toString(), gi: 3),
    ];

    final stats = isAdmin ? adminStats : (isTeacher ? teacherStats : studentStats);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        // ── Header ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: GradientHeader(
            gradient: AppGradients.primary,
            child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Manage your account', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ]),
            )),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // ── Profile card (overlaps header) ────────────────────────────
            Transform.translate(
              offset: const Offset(0, -20),
              child: GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  // Avatar
                  Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 74, height: 74,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary, borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: Text(
                        auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      )),
                    ),
                    Positioned(bottom: -3, right: -3,
                      child: GestureDetector(
                        onTap: () => _showEditProfile(context, auth),
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(gradient: AppGradients.emerald, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(auth.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.mail_outline_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(auth.email.isEmpty ? 'No email set' : auth.email,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 8),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: isAdmin 
                            ? AppGradients.darkBlue 
                            : (isTeacher ? AppGradients.emerald : AppGradients.cyan),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                            color: (isAdmin 
                                ? Colors.blue 
                                : (isTeacher ? AppColors.emerald : AppColors.cyan)).withOpacity(0.35),
                            blurRadius: 8)],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          isAdmin 
                              ? Icons.admin_panel_settings_rounded 
                              : (isTeacher ? Icons.school_rounded : Icons.person_rounded), 
                          color: Colors.white, 
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAdmin 
                              ? 'Admin' 
                              : (isTeacher ? 'Teacher' : 'Student'),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ),
                  ])),
                ]),
              ),
            ),

            // Adjust for overlap
            const SizedBox(height: 0),

            // ── Stat cards ────────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -8),
              child: Row(
                children: stats.map((s) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: StatCard(icon: s.icon, label: s.label, value: s.value,
                        gradient: AppGradients.courseGradients[s.gi % 4]),
                  ),
                )).toList(),
              ),
            ),

            // ── Tab switcher ──────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, 4),
              child: GlassCard(
                padding: const EdgeInsets.all(4),
                child: Row(children: List.generate(tabs.length, (i) {
                  final active = i == _tabIndex;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: active ? AppGradients.violet : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: active ? [BoxShadow(color: AppColors.violet.withOpacity(0.4), blurRadius: 10)] : [],
                      ),
                      child: Text(tabs[i], textAlign: TextAlign.center,
                          style: TextStyle(
                              color: active ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ));
                })),
              ),
            ),

            // ── Tab content ───────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _loadingStats
                    ? const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      ))
                    : tabs[_tabIndex] == 'Stats'
                        ? _StatsTab(
                            isTeacher: isTeacher,
                            isAdmin: isAdmin,
                            completedCount: _completedAssignments,
                            courseCount: _courseCount,
                            classesCount: _classesCount,
                            studentsCount: _studentsCount,
                            pendingCount: _pendingCount,
                            avgScore: _avgScore,
                            adminCoursesCount: _adminCoursesCount,
                            adminTeachersCount: _adminTeachersCount,
                            adminStudentsCount: _adminStudentsCount,
                            adminPendingCount: _adminPendingApprovalsCount,
                            key: const ValueKey('stats'),
                          )
                        : tabs[_tabIndex] == 'Badges'
                            ? const _BadgesTab(key: ValueKey('badges'))
                            : const _ActivityTab(key: ValueKey('activity')),
              ),
            ),

            // ── Quick settings ────────────────────────────────────────────
            const SectionHeader(title: 'Account'),
            const SizedBox(height: 12),
            _ActionRow(
              icon: Icons.person_outline_rounded, label: 'Edit Profile',
              gradient: AppGradients.cyan,
              onTap: () => _showEditProfile(context, auth),
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.lock_outline_rounded, label: 'Change Password',
              gradient: AppGradients.violet,
              onTap: () => _showChangePassword(context),
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.notifications_outlined, label: 'Notification Settings',
              gradient: AppGradients.orange,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings coming soon'))),
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.help_outline_rounded, label: 'Help & Support',
              gradient: AppGradients.emerald,
              onTap: () => _showHelpDialog(context),
            ),
            const SizedBox(height: 20),

            // ── Logout ────────────────────────────────────────────────────
            GestureDetector(
              onTap: () => _confirmLogout(context, auth),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200, width: 1.5),
                ),
                child: Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(gradient: AppGradients.red, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red.shade700))),
                  Icon(Icons.chevron_right_rounded, color: Colors.red.shade300),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // App version
            Center(child: Text('EduConnect v2.0.0', style: TextStyle(fontSize: 11, color: Colors.grey.shade400))),
            const SizedBox(height: 24),
          ])),
        ),
      ]),
    );
  }

  // ── Edit Profile Dialog ───────────────────────────────────────────────────────────────────
  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.displayName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        // Use the SHEET's context for viewInsets so keyboard push works
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 18),
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.violet, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Save Changes',
                gradient: AppGradients.violet,
                icon: Icons.check_rounded,
                onPressed: () async {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    await auth.updateName(nameCtrl.text.trim());
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green));
                    }
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

  // ── Change Password Dialog ─────────────────────────────────────────────────────────────────────
  void _showChangePassword(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 18),
              _PassField(controller: currentCtrl, label: 'Current Password'),
              const SizedBox(height: 12),
              _PassField(controller: newCtrl, label: 'New Password'),
              const SizedBox(height: 12),
              _PassField(controller: confirmCtrl, label: 'Confirm New Password'),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Update Password',
                gradient: AppGradients.violet,
                isLoading: loading,
                icon: Icons.lock_rounded,
                onPressed: () async {
                  if (currentCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your current password')));
                    return;
                  }
                  if (newCtrl.text != confirmCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                    return;
                  }
                  if (newCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                    return;
                  }
                  setS(() => loading = true);
                  final result = await ApiService.changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  setS(() => loading = false);
                  if (context.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Password updated!'), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Failed to update password'), backgroundColor: Colors.red));
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      )),
    );
  }

  // ── Help & Support Dialog ──────────────────────────────────────────────────
  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(gradient: AppGradients.emerald, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Text('Help & Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 20),
          _HelpItem(icon: Icons.school_rounded, title: 'How to join a course', desc: 'Ask your teacher or admin to enroll you. Once enrolled, the course appears on your dashboard.'),
          _HelpItem(icon: Icons.assignment_rounded, title: 'Submitting assignments', desc: 'Go to the Assignments tab, tap the assignment, then tap "Submit" to upload your file.'),
          _HelpItem(icon: Icons.chat_bubble_rounded, title: 'Messaging teachers', desc: 'Open the Messages tab. Only teachers assigned to your courses will appear as contacts.'),
          _HelpItem(icon: Icons.notifications_rounded, title: 'Notifications', desc: 'You receive notifications for new announcements, graded assignments, and messages.'),
          _HelpItem(icon: Icons.lock_rounded, title: 'Forgot your password?', desc: 'Go to Profile → Change Password and enter your current password to set a new one.'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppGradients.emerald,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Contact Admin: admin@educonnect.edu',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Logout Confirmation ────────────────────────────────────────────────────
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              widget.onLogout?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB CONTENT
// ════════════════════════════════════════════════════════════════════════════
class _StatsTab extends StatelessWidget {
  final bool isTeacher;
  final bool isAdmin;
  final int completedCount;
  final int courseCount;
  // Teacher-specific
  final int classesCount;
  final int studentsCount;
  final int pendingCount;
  final double avgScore;
  // Admin-specific
  final int adminCoursesCount;
  final int adminTeachersCount;
  final int adminStudentsCount;
  final int adminPendingCount;

  const _StatsTab({
    super.key,
    required this.isTeacher,
    required this.isAdmin,
    required this.completedCount,
    required this.courseCount,
    this.classesCount = 0,
    this.studentsCount = 0,
    this.pendingCount = 0,
    this.avgScore = 0.0,
    this.adminCoursesCount = 0,
    this.adminTeachersCount = 0,
    this.adminStudentsCount = 0,
    this.adminPendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      // Compute real approval rate from actual data
      final totalApproved = adminTeachersCount + adminStudentsCount;
      final totalAll = totalApproved + adminPendingCount;
      final approvalRate = totalAll > 0 ? (totalApproved / totalAll).clamp(0.0, 1.0) : 1.0;
      // Course fill rate: teachers assigned / total courses
      final teacherFill = adminCoursesCount > 0
          ? (adminTeachersCount.clamp(0, adminCoursesCount) / adminCoursesCount).clamp(0.0, 1.0)
          : 0.0;
      // Student/course ratio as engagement proxy (cap at 30 students per course = 100%)
      final maxEngagement = adminCoursesCount * 30;
      final engagementRate = maxEngagement > 0
          ? (adminStudentsCount / maxEngagement).clamp(0.0, 1.0)
          : 0.0;

      return Column(children: [
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Platform Overview'),
            const SizedBox(height: 16),
            _ProgressRow(label: 'User Approval Rate', percent: approvalRate, color: AppColors.emerald),
            const SizedBox(height: 12),
            _ProgressRow(label: 'Course Teacher Coverage', percent: teacherFill, color: AppColors.violet),
            const SizedBox(height: 12),
            _ProgressRow(label: 'Student Enrollment', percent: engagementRate, color: AppColors.cyan),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'System Summary'),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _WeekStat(label: 'Active Courses', value: adminCoursesCount.toString()),
              _WeekStat(label: 'Verified Users', value: totalApproved.toString()),
              _WeekStat(label: 'Pending', value: adminPendingCount.toString()),
            ]),
          ]),
        ),
      ]);
    }

    if (isTeacher) {
      // Use real data: pendingCount = ungraded submissions, avgScore = class average
      final gradingRate = studentsCount > 0
          ? ((studentsCount - pendingCount).clamp(0, studentsCount) / studentsCount).clamp(0.0, 1.0)
          : (pendingCount == 0 ? 1.0 : 0.5);
      final avgRate = avgScore > 0 ? (avgScore / 100.0).clamp(0.0, 1.0) : 0.0;
      final classLoad = classesCount > 0 ? (classesCount / 5.0).clamp(0.0, 1.0) : 0.0;

      return Column(children: [
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Class Analytics'),
            const SizedBox(height: 16),
            _ProgressRow(label: 'Grading Completion', percent: gradingRate, color: AppColors.violet),
            const SizedBox(height: 12),
            _ProgressRow(label: 'Average Student Score', percent: avgRate, color: AppColors.emerald),
            const SizedBox(height: 12),
            _ProgressRow(label: 'Teaching Load', percent: classLoad, color: AppColors.cyan),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Teaching Summary'),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _WeekStat(label: 'Classes', value: classesCount.toString()),
              _WeekStat(label: 'Students', value: studentsCount.toString()),
              _WeekStat(label: 'Pending', value: pendingCount.toString()),
            ]),
          ]),
        ),
      ]);
    }

    // Student
    double progress = courseCount > 0 ? (completedCount / (courseCount * 3).clamp(1, 100)) : 0.0;
    if (progress > 1.0) progress = 1.0;
    
    return Column(children: [
      GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeader(title: 'Learning Progress'),
          const SizedBox(height: 16),
          _ProgressRow(label: 'Syllabus Progress', percent: progress > 0 ? progress : 0.45, color: AppColors.violet),
          const SizedBox(height: 12),
          _ProgressRow(label: 'Assignment Completion', percent: completedCount > 0 ? 0.90 : 0.20, color: AppColors.emerald),
          const SizedBox(height: 12),
          const _ProgressRow(label: 'Attendance Rate', percent: 0.96, color: AppColors.cyan),
        ]),
      ),
      const SizedBox(height: 12),
      GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeader(title: 'This Week'),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _WeekStat(label: 'Tasks Done', value: completedCount.toString()),
            _WeekStat(label: 'Materials Read', value: (courseCount * 2).toString()),
            const _WeekStat(label: 'Messages', value: '12'),
          ]),
        ]),
      ),
    ]);
  }
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({super.key});
  final _achievements = const [
    {'title': 'Perfect Attendance', 'desc': 'Attended all classes this month', 'icon': Icons.calendar_month_rounded, 'unlocked': true, 'gi': 0},
    {'title': 'Quick Learner', 'desc': 'Completed 5 courses', 'icon': Icons.star_rounded, 'unlocked': true, 'gi': 1},
    {'title': 'Top Performer', 'desc': 'Scored 90+ in 3 subjects', 'icon': Icons.emoji_events_rounded, 'unlocked': false, 'gi': 2},
    {'title': 'Early Bird', 'desc': 'Submitted 10 assignments early', 'icon': Icons.access_time_rounded, 'unlocked': true, 'gi': 3},
    {'title': 'Collaborator', 'desc': 'Sent 100 messages', 'icon': Icons.chat_bubble_rounded, 'unlocked': false, 'gi': 0},
    {'title': 'Bookworm', 'desc': 'Downloaded 20 materials', 'icon': Icons.menu_book_rounded, 'unlocked': true, 'gi': 1},
  ];

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.05),
    itemCount: _achievements.length,
    itemBuilder: (_, i) {
      final a = _achievements[i];
      final unlocked = a['unlocked'] as bool;
      final gi = a['gi'] as int;
      return Opacity(
        opacity: unlocked ? 1.0 : 0.45,
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GradientIconBox(gradient: unlocked ? AppGradients.courseGradients[gi % 4] : const LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
                icon: a['icon'] as IconData, size: 44, iconSize: 20),
            const SizedBox(height: 10),
            Text(a['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(a['desc'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (unlocked) ...[
              const SizedBox(height: 6),
              Row(children: const [
                Icon(Icons.military_tech_rounded, color: Colors.amber, size: 13),
                SizedBox(width: 4),
                Text('Unlocked', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
              ]),
            ],
          ]),
        ),
      );
    },
  );
}

class _ActivityTab extends StatefulWidget {
  const _ActivityTab({super.key});
  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final List<Map<String, dynamic>> items = [];

      // Load announcements — real data for all roles
      final announcements = await ApiService.getAnnouncements();
      for (final ann in announcements.take(3)) {
        final courseName = ann['courseName']?.toString() ??
            ann['course']?.toString() ??
            'General';
        items.add({
          'action': ann['title']?.toString() ?? 'New Announcement',
          'course': courseName,
          'time': _fmt(ann['createdAt']?.toString()),
          'gi': items.length % 4,
          'icon': Icons.campaign_rounded,
        });
      }

      // Load student submissions — real assignment activity
      if (!auth.isTeacher && !auth.isAdmin) {
        final grades = await ApiService.getGrades(auth.id);
        for (final g in grades.take(4)) {
          final status = g['status']?.toString() ?? '';
          if (status == 'graded' || status == 'submitted') {
            items.add({
              'action': 'Submitted: ${g['assignmentName']?.toString() ?? 'Assignment'}',
              'course': g['course']?.toString() ?? 'Course',
              'time': _fmt(g['submittedDate']?.toString() ?? g['createdAt']?.toString()),
              'gi': items.length % 4,
              'icon': Icons.assignment_turned_in_rounded,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _items = items.take(5).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(String? s) {
    if (s == null) return 'Recently';
    try {
      final dt = DateTime.parse(s).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: CircularProgressIndicator(),
      ));
    }
    if (_items.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.history_rounded, size: 40, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('No recent activity', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ]),
      );
    }
    return Column(
      children: _items.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            GradientIconBox(
              gradient: AppGradients.courseGradients[(a['gi'] as int) % 4],
              icon: a['icon'] as IconData,
              size: 42,
              iconSize: 20,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['action'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(a['course'] as String,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Text(a['time'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      )).toList(),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
class _StatData {
  final IconData icon;
  final String label, value;
  final int gi;
  const _StatData({required this.icon, required this.label, required this.value, required this.gi});
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      GradientIconBox(gradient: gradient, icon: icon, size: 44, iconSize: 20),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary))),
      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
    ]),
  );
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  const _ProgressRow({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Text('${(percent * 100).round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
    ]),
    const SizedBox(height: 6),
    GradientProgressBar(progress: percent, gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), height: 8),
  ]);
}

class _WeekStat extends StatelessWidget {
  final String label, value;
  const _WeekStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _HelpItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    ),
  );
}


class _PassField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PassField({required this.controller, required this.label});

  @override
  State<_PassField> createState() => _PassFieldState();
}

class _PassFieldState extends State<_PassField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: !_visible,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _visible = !_visible),
        child: Icon(_visible ? Icons.visibility_off_rounded : Icons.visibility_rounded),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
