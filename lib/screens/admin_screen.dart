import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ── Simple data models used only inside the admin panel ──────────────────────

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool approved;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.approved,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: (j['_id'] ?? j['id']).toString(),
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        role: j['role'] ?? 'student',
        approved: j.containsKey('approved') ? j['approved'] == true : true,
      );

  String get initials => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

class AdminCourse {
  final String id;
  final String name;
  String? teacherId;
  String? teacherName;
  final List<String> studentIds;

  AdminCourse({
    required this.id,
    required this.name,
    this.teacherId,
    this.teacherName,
    List<String>? studentIds,
  }) : studentIds = studentIds ?? [];

  factory AdminCourse.fromJson(Map<String, dynamic> j) => AdminCourse(
        id: (j['_id'] ?? j['id']).toString(),
        name: j['name'] ?? '',
        teacherId: j['teacherId']?.toString(),
        teacherName: j['teacherName'],
        studentIds: (j['studentIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ── Mock fallback data ────────────────────────────────────────────────────────

final _mockTeachers = [
  AdminUser(id: 't1', name: 'Dr. Sarah Johnson',  email: 'sarah.j@school.edu',   role: 'teacher', approved: true),
  AdminUser(id: 't2', name: 'Prof. Michael Chen', email: 'michael.c@school.edu', role: 'teacher', approved: true),
  AdminUser(id: 't3', name: 'Dr. Emily Parker',   email: 'emily.p@school.edu',   role: 'teacher', approved: true),
  AdminUser(id: 't4', name: 'Ms. Rachel Adams',   email: 'rachel.a@school.edu',  role: 'teacher', approved: true),
];

final _mockStudents = [
  AdminUser(id: 's1', name: 'Alice Johnson',  email: 'alice.j@school.edu',  role: 'student', approved: true),
  AdminUser(id: 's2', name: 'Bob Smith',      email: 'bob.s@school.edu',    role: 'student', approved: true),
  AdminUser(id: 's3', name: 'Carol White',    email: 'carol.w@school.edu',  role: 'student', approved: true),
  AdminUser(id: 's4', name: 'David Brown',    email: 'david.b@school.edu',  role: 'student', approved: true),
  AdminUser(id: 's5', name: 'Emma Wilson',    email: 'emma.w@school.edu',   role: 'student', approved: true),
  AdminUser(id: 's6', name: 'Frank Davis',    email: 'frank.d@school.edu',  role: 'student', approved: true),
  AdminUser(id: 's7', name: 'Grace Lee',      email: 'grace.l@school.edu',  role: 'student', approved: true),
  AdminUser(id: 's8', name: 'Henry Martin',   email: 'henry.m@school.edu',  role: 'student', approved: true),
];

final _mockCourses = [
  AdminCourse(id: 'c1', name: 'Mathematics 101',  teacherId: 't1', teacherName: 'Dr. Sarah Johnson',  studentIds: ['s1', 's2', 's3']),
  AdminCourse(id: 'c2', name: 'Physics Advanced',  teacherId: 't2', teacherName: 'Prof. Michael Chen', studentIds: ['s2', 's4', 's5']),
  AdminCourse(id: 'c3', name: 'Computer Science',  teacherId: 't3', teacherName: 'Dr. Emily Parker',   studentIds: ['s1', 's6', 's7']),
  AdminCourse(id: 'c4', name: 'English Literature', teacherId: null, teacherName: null,                 studentIds: []),
];

// ── AdminScreen ───────────────────────────────────────────────────────────────

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<AdminCourse> _courses  = [];
  List<AdminUser>   _teachers = [];
  List<AdminUser>   _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.adminGetCourses(),
        ApiService.adminGetUsersByRole('teacher'),
        ApiService.adminGetUsersByRole('student'),
      ]);

      if (mounted) {
        setState(() {
          _courses  = (results[0] as List).map((e) => AdminCourse.fromJson(e as Map<String, dynamic>)).toList();
          _teachers = (results[1] as List).map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
          _students = (results[2] as List).map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
          _loading  = false;
        });
      }
    } catch (_) {
      // Fallback to mock data so the UI is always functional during development
      if (mounted) {
        setState(() {
          _courses  = List.from(_mockCourses);
          _teachers = List.from(_mockTeachers);
          _students = List.from(_mockStudents);
          _loading  = false;
        });
      }
    }
  }

  // ── Assign teacher to a course ──────────────────────────────────────────

  void _showAssignTeacher(AdminCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignTeacherSheet(
        course: course,
        teachers: _teachers,
        onAssign: (teacher) async {
          try {
            await ApiService.adminAssignTeacher(course.id, teacher.id);
          } catch (_) {
            // API not yet live — update locally anyway
          }
          setState(() {
            course.teacherId   = teacher.id;
            course.teacherName = teacher.name;
          });
          if (mounted) {
            _showSnack('${teacher.name} assigned to ${course.name}', Colors.green);
          }
        },
      ),
    );
  }

  // ── Assign students to a course ──────────────────────────────────────────

  void _showAssignStudents(AdminCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignStudentsSheet(
        course: course,
        students: _students,
        onSave: (selected) async {
          final added   = selected.where((id) => !course.studentIds.contains(id)).toList();
          final removed = course.studentIds.where((id) => !selected.contains(id)).toList();
          try {
            await ApiService.adminAssignStudents(course.id, selected);
          } catch (_) {
            // API not yet live — update locally anyway
          }
          setState(() {
            course.studentIds
              ..clear()
              ..addAll(selected);
          });
          if (mounted) {
            final delta = added.length - removed.length;
            final msg = delta == 0
                ? 'Enrolment updated for ${course.name}'
                : delta > 0
                    ? '$delta student(s) added to ${course.name}'
                    : '${-delta} student(s) removed from ${course.name}';
            _showSnack(msg, Colors.green);
          }
        },
      ),
    );
  }

  Future<void> _approveUser(AdminUser user) async {
    try {
      final result = await ApiService.adminApproveUser(user.id);
      if (result['success'] == true) {
        setState(() {
          final index = _teachers.indexWhere((u) => u.id == user.id);
          if (index >= 0) _teachers[index] = AdminUser(
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            approved: true,
          );
          final studentIndex = _students.indexWhere((u) => u.id == user.id);
          if (studentIndex >= 0) _students[studentIndex] = AdminUser(
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            approved: true,
          );
        });
        _showSnack('${user.name} approved successfully', Colors.green);
      } else {
        _showSnack(result['message']?.toString() ?? 'Approval failed', Colors.red);
      }
    } catch (_) {
      _showSnack('Approval failed. Try again.', Colors.red);
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Remove Account'),
        ]),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
            children: [
              const TextSpan(text: 'Are you sure you want to permanently remove '),
              TextSpan(text: user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ApiService.adminDeleteUser(user.id);
      if (result['success'] == true) {
        setState(() {
          _teachers.removeWhere((u) => u.id == user.id);
          _students.removeWhere((u) => u.id == user.id);
        });
        _showSnack('${user.name} removed successfully', Colors.red);
      } else {
        _showSnack(result['message']?.toString() ?? 'Failed to remove user', Colors.red);
      }
    } catch (_) {
      _showSnack('Could not remove user. Try again.', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        GradientHeader(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E40AF), Color(0xFF1E1B4B)]),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Admin Panel',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Signed in as ${auth.name.isNotEmpty ? auth.name : auth.email}',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                ])),
                // Refresh button
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              // Summary stats
              if (!_loading) _StatRow(
                courses:  _courses.length,
                teachers: _teachers.length,
                students: _students.length,
                unassigned: _courses.where((c) => c.teacherId == null).length,
              ),
            ]),
          )),
        ),

        // ── Tab bar ──────────────────────────────────────────────────────
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
              Tab(text: 'Courses (${_courses.length})'),
              Tab(child: _TabLabel(
                text: 'Teachers',
                count: _teachers.length,
                pending: _teachers.where((u) => !u.approved).length,
              )),
              Tab(child: _TabLabel(
                text: 'Students',
                count: _students.length,
                pending: _students.where((u) => !u.approved).length,
              )),
            ],
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : TabBarView(controller: _tabCtrl, children: [
                      _CourseTab(
                        courses: _courses,
                        students: _students,
                        onAssignTeacher:  _showAssignTeacher,
                        onAssignStudents: _showAssignStudents,
                      ),
                      _UserTab(users: _teachers, role: 'teacher', onApprove: _approveUser, onDelete: _deleteUser),
                      _UserTab(users: _students, role: 'student', onApprove: _approveUser, onDelete: _deleteUser),
                    ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COURSE TAB
// ════════════════════════════════════════════════════════════════════════════

class _CourseTab extends StatelessWidget {
  final List<AdminCourse> courses;
  final List<AdminUser>   students;
  final void Function(AdminCourse) onAssignTeacher;
  final void Function(AdminCourse) onAssignStudents;

  const _CourseTab({
    required this.courses,
    required this.students,
    required this.onAssignTeacher,
    required this.onAssignStudents,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const _Empty(icon: Icons.menu_book_rounded, label: 'No courses found');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CourseCard(
        course:   courses[i],
        students: students,
        onAssignTeacher:  onAssignTeacher,
        onAssignStudents: onAssignStudents,
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final AdminCourse course;
  final List<AdminUser> students;
  final void Function(AdminCourse) onAssignTeacher;
  final void Function(AdminCourse) onAssignStudents;

  const _CourseCard({
    required this.course,
    required this.students,
    required this.onAssignTeacher,
    required this.onAssignStudents,
  });

  static const _grads = [
    AppGradients.cyan,
    AppGradients.emerald,
    AppGradients.purple,
    AppGradients.orange,
  ];

  // Enrolled student avatars (up to 3 shown)
  List<AdminUser> _enrolled(List<AdminUser> all) =>
      all.where((s) => course.studentIds.contains(s.id)).toList();

  @override
  Widget build(BuildContext context) {
    final enrolled = _enrolled(students);
    final grad     = _grads[course.id.hashCode.abs() % _grads.length];
    final hasTeacher = course.teacherId != null;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Course name row
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: grad.colors.first.withOpacity(0.3), blurRadius: 8)]),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text('${course.studentIds.length} student${course.studentIds.length == 1 ? '' : 's'} enrolled',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),

        // Teacher row
        Row(children: [
          const Icon(Icons.school_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: hasTeacher
              ? Text(course.teacherName!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))
              : Text('No teacher assigned',
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontStyle: FontStyle.italic))),
          _ActionChip(
            label: hasTeacher ? 'Change' : 'Assign',
            icon: Icons.person_add_rounded,
            color: hasTeacher ? AppColors.violet : AppColors.orange,
            onTap: () => onAssignTeacher(course),
          ),
        ]),
        const SizedBox(height: 10),

        // Students row
        Row(children: [
          const Icon(Icons.people_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          // Stacked avatars
          if (enrolled.isEmpty)
            Expanded(child: Text('No students enrolled',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic)))
          else
            Expanded(child: Row(children: [
              // Show up to 3 mini-avatars
              ...enrolled.take(3).map((s) => Container(
                width: 26, height: 26, margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  gradient: _grads[s.id.hashCode.abs() % _grads.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(child: Text(s.initials,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              )),
              if (enrolled.length > 3)
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: AppColors.border, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5)),
                  child: Center(child: Text('+${enrolled.length - 3}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                ),
            ])),
          _ActionChip(
            label: enrolled.isEmpty ? 'Enrol' : 'Manage',
            icon: Icons.group_add_rounded,
            color: AppColors.cyan,
            onTap: () => onAssignStudents(course),
          ),
        ]),
      ]),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final int count;
  final int pending;
  const _TabLabel({required this.text, required this.count, required this.pending});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$text ($count)'),
      if (pending > 0) ...[
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// USER TAB (shared for teachers and students)
// ═══════════════════════════════════════════════════════════════════════════

class _UserTab extends StatefulWidget {
  final List<AdminUser> users;
  final String role;
  final void Function(AdminUser)? onApprove;
  final void Function(AdminUser)? onDelete;
  const _UserTab({required this.users, required this.role, this.onApprove, this.onDelete});

  @override
  State<_UserTab> createState() => _UserTabState();
}

class _UserTabState extends State<_UserTab> {
  final _search = TextEditingController();
  String _query = '';
  bool _showOnlyPending = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text));
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  List<AdminUser> get _pending => widget.users.where((u) => !u.approved).toList();

  List<AdminUser> get _filtered {
    final base = _showOnlyPending ? _pending : widget.users;
    if (_query.isEmpty) return base;
    return base.where((u) =>
        u.name.toLowerCase().contains(_query.toLowerCase()) ||
        u.email.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  static const _grads = [
    AppGradients.violet, AppGradients.cyan, AppGradients.emerald, AppGradients.orange,
  ];

  @override
  Widget build(BuildContext context) {
    final filtered   = _filtered;
    final pendingCount = _pending.length;
    final isTeacher  = widget.role == 'teacher';
    final emptyLabel = _showOnlyPending
        ? 'No pending approvals'
        : (isTeacher ? 'No teachers found' : 'No students found');

    return Column(children: [
      // ── Pending Banner (shown when there are pending accounts) ──────────────
      if (pendingCount > 0)
        GestureDetector(
          onTap: () => setState(() => _showOnlyPending = !_showOnlyPending),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _showOnlyPending ? AppColors.orange : AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.orange.withOpacity(0.4)),
            ),
            child: Row(children: [
              Icon(Icons.hourglass_empty_rounded,
                  color: _showOnlyPending ? Colors.white : AppColors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$pendingCount ${isTeacher ? 'teacher' : 'student'}${pendingCount == 1 ? '' : 's'} waiting for approval',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13,
                    color: _showOnlyPending ? Colors.white : AppColors.orange,
                  ),
                ),
              ),
              Text(
                _showOnlyPending ? 'Show all' : 'Review',
                style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12,
                  color: _showOnlyPending ? Colors.white : AppColors.orange,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: _showOnlyPending ? Colors.white : AppColors.orange),
            ]),
          ),
        ),

      // ── Search bar ──────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search ${isTeacher ? 'teachers' : 'students'}...',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.violet, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () { _search.clear(); setState(() => _query = ''); },
                      child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18))
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),

      // ── User list ──────────────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? _Empty(icon: isTeacher ? Icons.school_rounded : Icons.person_rounded, label: emptyLabel)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final u    = filtered[i];
                  final grad = _grads[u.id.hashCode.abs() % _grads.length];
                  final isPending = !u.approved;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isPending
                          ? Border.all(color: AppColors.orange.withOpacity(0.5), width: 1.5)
                          : null,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        // Avatar
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: isPending
                                ? const LinearGradient(colors: [Color(0xFFFC913A), Color(0xFFF97316)])
                                : grad,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(
                              color: (isPending ? AppColors.orange : grad.colors.first).withOpacity(0.3),
                              blurRadius: 8,
                            )],
                          ),
                          child: Center(child: Text(u.initials,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                        ),
                        const SizedBox(width: 14),
                        // Name + email
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Text(u.email,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ])),
                        const SizedBox(width: 8),
                        // Status / action
                        if (!isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isTeacher ? AppColors.emerald : AppColors.violet).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isTeacher ? 'Teacher' : 'Student',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold,
                                color: isTeacher ? AppColors.emerald : AppColors.violet,
                              ),
                            ),
                          )
                        else
                          // Big prominent Approve button for pending users
                          GestureDetector(
                            onTap: widget.onApprove != null ? () => widget.onApprove!(u) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.orange,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(
                                  color: AppColors.orange.withOpacity(0.4),
                                  blurRadius: 8, offset: const Offset(0, 3),
                                )],
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Approve', style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,
                                )),
                              ]),
                            ),
                          ),
                        // Delete button — always shown
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: widget.onDelete != null ? () => widget.onDelete!(u) : null,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);

  }
}

// ════════════════════════════════════════════════════════════════════════════
// ASSIGN TEACHER BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════════

class _AssignTeacherSheet extends StatefulWidget {
  final AdminCourse course;
  final List<AdminUser> teachers;
  final void Function(AdminUser) onAssign;

  const _AssignTeacherSheet({
    required this.course,
    required this.teachers,
    required this.onAssign,
  });

  @override
  State<_AssignTeacherSheet> createState() => _AssignTeacherSheetState();
}

class _AssignTeacherSheetState extends State<_AssignTeacherSheet> {
  String? _selectedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.course.teacherId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            const GradientIconBox(gradient: AppGradients.violet, icon: Icons.person_add_rounded, size: 42, iconSize: 20),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Assign Teacher', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(widget.course.name, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Teacher list
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: widget.teachers.length,
            itemBuilder: (_, i) {
              final t = widget.teachers[i];
              final selected = t.id == _selectedId;
              return ListTile(
                onTap: () => setState(() => _selectedId = t.id),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: selected ? AppGradients.violet : const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(t.initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                ),
                title: Text(t.name,
                    style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.violet : AppColors.textPrimary)),
                subtitle: Text(t.email, style: const TextStyle(fontSize: 12)),
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.violet)
                    : const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.border),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              );
            },
          ),
        ),
        // Confirm button
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: GradientButton(
            label: _saving ? 'Saving...' : 'Confirm Assignment',
            gradient: AppGradients.violet,
            isLoading: _saving,
            onPressed: () async {
              if (_selectedId == null) return;
              final teacher = widget.teachers.firstWhere((t) => t.id == _selectedId);
              setState(() => _saving = true);
              await Future.delayed(const Duration(milliseconds: 300));
              widget.onAssign(teacher);
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ASSIGN STUDENTS BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════════

class _AssignStudentsSheet extends StatefulWidget {
  final AdminCourse course;
  final List<AdminUser> students;
  final void Function(List<String>) onSave;

  const _AssignStudentsSheet({
    required this.course,
    required this.students,
    required this.onSave,
  });

  @override
  State<_AssignStudentsSheet> createState() => _AssignStudentsSheetState();
}

class _AssignStudentsSheetState extends State<_AssignStudentsSheet> {
  late Set<String> _selected;
  final _search = TextEditingController();
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.course.studentIds);
    _search.addListener(() => setState(() => _query = _search.text));
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  List<AdminUser> get _filtered => _query.isEmpty
      ? widget.students
      : widget.students.where((s) =>
          s.name.toLowerCase().contains(_query.toLowerCase()) ||
          s.email.toLowerCase().contains(_query.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(children: [
            const GradientIconBox(gradient: AppGradients.cyan, icon: Icons.group_add_rounded, size: 42, iconSize: 20),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Manage Enrolment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(widget.course.name, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
            // Selection counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(gradient: AppGradients.cyan, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.3), blurRadius: 8)]),
              child: Text('${_selected.length} selected',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border)),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.violet, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // Select all row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${filtered.length} students', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            GestureDetector(
              onTap: () {
                final allIds = filtered.map((s) => s.id).toSet();
                final allSelected = allIds.every(_selected.contains);
                setState(() {
                  if (allSelected) {
                    _selected.removeAll(allIds);
                  } else {
                    _selected.addAll(allIds);
                  }
                });
              },
              child: Text(
                filtered.every((s) => _selected.contains(s.id)) ? 'Deselect all' : 'Select all',
                style: const TextStyle(fontSize: 12, color: AppColors.violet, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Student list
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final s = filtered[i];
              final sel = _selected.contains(s.id);
              return ListTile(
                onTap: () => setState(() => sel ? _selected.remove(s.id) : _selected.add(s.id)),
                leading: Stack(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: sel ? AppGradients.cyan : const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(s.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  ),
                  if (sel)
                    Positioned(bottom: -2, right: -2,
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5)),
                        child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                ]),
                title: Text(s.name,
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: sel ? AppColors.cyan : AppColors.textPrimary)),
                subtitle: Text(s.email, style: const TextStyle(fontSize: 12)),
                trailing: sel
                    ? const Icon(Icons.check_box_rounded, color: AppColors.cyan)
                    : const Icon(Icons.check_box_outline_blank_rounded, color: AppColors.border),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              );
            },
          ),
        ),
        // Save button
        Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: GradientButton(
            label: _saving ? 'Saving...' : 'Save Enrolment (${_selected.length})',
            gradient: AppGradients.cyan,
            isLoading: _saving,
            onPressed: () async {
              setState(() => _saving = true);
              await Future.delayed(const Duration(milliseconds: 300));
              widget.onSave(_selected.toList());
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SMALL SHARED WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _StatRow extends StatelessWidget {
  final int courses, teachers, students, unassigned;
  const _StatRow({
    required this.courses, required this.teachers,
    required this.students, required this.unassigned,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    _StatBox(value: '$courses',    label: 'Courses'),
    const SizedBox(width: 8),
    _StatBox(value: '$teachers',   label: 'Teachers'),
    const SizedBox(width: 8),
    _StatBox(value: '$students',   label: 'Students'),
    const SizedBox(width: 8),
    _StatBox(value: '$unassigned', label: 'No Teacher', warn: unassigned > 0),
  ]);
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final bool warn;
  const _StatBox({required this.value, required this.label, this.warn = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: warn && value != '0'
            ? Colors.orange.withOpacity(0.25)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(
            color: warn && value != '0' ? Colors.orange.shade200 : Colors.white,
            fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
      ]),
    ),
  );
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
    ),
  );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Empty({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
        decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E40AF), Color(0xFF1E1B4B)]), borderRadius: BorderRadius.circular(24)),
        child: Icon(icon, color: Colors.white, size: 34)),
    const SizedBox(height: 14),
    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
  ]));
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textSecondary),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ]),
  ));
}
