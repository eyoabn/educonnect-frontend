import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

final _mockNotifications = [
  AppNotification(id: 1, type: 'file', title: 'New file uploaded', description: 'Assignment 3 - Calculus.docx in Mathematics 101', time: '2 hours ago', read: false),
  AppNotification(id: 2, type: 'message', title: 'New message', description: 'Dr. Sarah Johnson replied in Mathematics 101 discussion', time: '5 hours ago', read: false),
  AppNotification(id: 3, type: 'announcement', title: 'Course announcement', description: 'Lab session moved to Room 204 - Physics Advanced', time: '1 day ago', read: true),
  AppNotification(id: 4, type: 'file', title: 'New file uploaded', description: 'Chapter 8 Notes.pdf in Computer Science', time: '2 days ago', read: true),
  AppNotification(id: 5, type: 'grade', title: 'Grade posted', description: 'Your assignment has been graded - Mathematics 101', time: '3 days ago', read: false),
  AppNotification(id: 6, type: 'reminder', title: 'Deadline reminder', description: 'Physics Lab Report due tomorrow', time: '4 hours ago', read: false),
];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _all = [];
  int _filterIndex = 0;
  bool _loading = true;

  final _filters = ['All', 'Unread', 'Read'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getNotifications();
      if (mounted) setState(() { 
        _all = data.map((n) => AppNotification(
          id: (n['id'] as num?)?.toInt() ?? 0,
          type: n['type'] as String? ?? 'info',
          title: n['title'] as String? ?? 'Notification',
          description: n['description'] as String? ?? '',
          time: n['time'] as String? ?? '',
          read: n['read'] as bool? ?? false,
        )).toList(); 
        _loading = false; 
      }); 
    } catch (_) {
      if (mounted) setState(() { _all = _mockNotifications; _loading = false; });
    }
  }

  List<AppNotification> get _filtered {
    switch (_filterIndex) {
      case 1: return _all.where((n) => !n.read).toList();
      case 2: return _all.where((n) => n.read).toList();
      default: return _all;
    }
  }

  int get _unreadCount => _all.where((n) => !n.read).length;

  Future<void> _markRead(AppNotification n) async {
    setState(() => n.read = true);
    try { await ApiService.markNotificationRead(n.id.toString()); } catch (_) {}
  }

  Future<void> _markAllRead() async {
    setState(() { for (final n in _all) n.read = true; });
    try { await ApiService.markAllNotificationsRead(); } catch (_) {}
  }

  Future<void> _delete(AppNotification n) async {
    setState(() => _all.remove(n));
    try { await ApiService.deleteNotification(n.id.toString()); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFFD946EF), Color(0xFFF97316)],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Notifications',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                _unreadCount > 0
                                    ? '$_unreadCount unread notifications'
                                    : "All caught up!",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (_unreadCount > 0)
                          GestureDetector(
                            onTap: _markAllRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.done_all_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Mark all read',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                            child: FilterBar(
                              labels: _filters,
                              selectedIndex: _filterIndex,
                              onSelected: (i) => setState(() => _filterIndex = i),
                              activeGradient: AppGradients.violet,
                            ),
                          ),
                        ),
                        if (_filtered.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.violet,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: const Icon(
                                        Icons.notifications_off_rounded,
                                        color: Colors.white,
                                        size: 40),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No notifications here',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  const Text("You're all caught up!",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  final n = _filtered[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _NotificationCard(
                                      notification: n,
                                      index: i,
                                      onMarkRead: () => _markRead(n),
                                      onDelete: () => _delete(n),
                                    ),
                                  );
                                },
                                childCount: _filtered.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final int index;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.index,
    required this.onMarkRead,
    required this.onDelete,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'file': return Icons.description_rounded;
      case 'message': return Icons.chat_bubble_rounded;
      case 'announcement': return Icons.campaign_rounded;
      case 'grade': return Icons.check_circle_rounded;
      case 'reminder': return Icons.alarm_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grad = AppGradients.cardGradients[index % AppGradients.cardGradients.length];
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBox(gradient: grad, icon: _icon, size: 46, iconSize: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notification.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                    ),
                    if (!notification.read)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          gradient: AppGradients.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.description,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(notification.time,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        if (!notification.read)
                          _ActionBtn(
                            icon: Icons.done_rounded,
                            color: Colors.green,
                            onTap: onMarkRead,
                          ),
                        const SizedBox(width: 6),
                        _ActionBtn(
                          icon: Icons.archive_rounded,
                          color: AppColors.violet,
                          onTap: () {},
                        ),
                        const SizedBox(width: 6),
                        _ActionBtn(
                          icon: Icons.delete_rounded,
                          color: Colors.red,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
