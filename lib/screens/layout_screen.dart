import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';          // ← NEW
import 'dashboard_screen.dart';
import 'chat_screen.dart';
import 'grading_screen.dart';
import 'search_screen.dart';
import 'student_list_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class LayoutScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const LayoutScreen({super.key, this.onLogout});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> {
  int _currentIndex = 0;

  // ── Admin gets a single-tab layout: just the admin panel + profile ────────
  List<Widget> get _adminScreens => [
    const AdminScreen(),
    ProfileScreen(onLogout: widget.onLogout),
  ];

  static const _adminItems = [
    _NavItem(icon: Icons.admin_panel_settings_rounded, label: 'Admin'),
    _NavItem(icon: Icons.person_rounded,               label: 'Profile'),
  ];

  // ── Student screens ───────────────────────────────────────────────────────
  List<Widget> get _studentScreens => [
    const DashboardScreen(),
    const ChatScreen(),
    const SearchScreen(),
    const NotificationsScreen(),
    ProfileScreen(onLogout: widget.onLogout),
  ];

  static const _studentItems = [
    _NavItem(icon: Icons.home_rounded,          label: 'Home'),
    _NavItem(icon: Icons.chat_bubble_rounded,   label: 'Chat'),
    _NavItem(icon: Icons.search_rounded,        label: 'Search'),
    _NavItem(icon: Icons.notifications_rounded, label: 'Alerts'),
    _NavItem(icon: Icons.person_rounded,        label: 'Profile'),
  ];

  // ── Teacher screens ───────────────────────────────────────────────────────
  List<Widget> get _teacherScreens => [
    const DashboardScreen(),
    const StudentListScreen(),
    const GradingScreen(),
    const NotificationsScreen(),
    ProfileScreen(onLogout: widget.onLogout),
  ];

  static const _teacherItems = [
    _NavItem(icon: Icons.home_rounded,                 label: 'Home'),
    _NavItem(icon: Icons.people_rounded,               label: 'Students'),
    _NavItem(icon: Icons.assignment_turned_in_rounded, label: 'Grade'),
    _NavItem(icon: Icons.notifications_rounded,        label: 'Alerts'),
    _NavItem(icon: Icons.person_rounded,               label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Pick the right screens + nav items based on role
    final List<Widget>   screens;
    final List<_NavItem> items;

    if (auth.isAdmin) {
      screens = _adminScreens;
      items   = _adminItems;
    } else if (auth.isTeacher) {
      screens = _teacherScreens;
      items   = _teacherItems;
    } else {
      screens = _studentScreens;
      items   = _studentItems;
    }

    // Guard: if the stored index exceeds the new list length, reset to 0.
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: _BottomNav(
        items: items,
        currentIndex: safeIndex,
        isAdmin: auth.isAdmin,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final bool isAdmin;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.isAdmin,
    required this.onTap,
  });

  // Admin uses a distinct gradient to make it visually clear
  LinearGradient get _activeGradient =>
      isAdmin ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E40AF), Color(0xFF1E1B4B)]) : AppGradients.violet;

  Color get _activeTextColor =>
      isAdmin ? AppColors.blue : AppColors.violet;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: AppColors.violet.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ],
      border: Border(top: BorderSide(color: AppColors.border, width: 1)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 64,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Active top indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3, width: active ? 32 : 0,
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      gradient: _activeGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: active ? _activeGradient : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: active
                          ? [BoxShadow(
                              color: _activeGradient.colors.first.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )]
                          : [],
                    ),
                    child: Icon(items[i].icon, size: 22,
                        color: active ? Colors.white : Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Text(items[i].label,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: active ? _activeTextColor : Colors.grey.shade400,
                      )),
                ]),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
