import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'create_post_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  final Course course;
  const AnnouncementsScreen({super.key, required this.course});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> _all = [];
  List<Announcement> _filtered = [];
  bool _loading = true;
  int _filterIndex = 0;
  final _searchCtrl = TextEditingController();

  final _filters = ['All', 'Assignments', 'Grades', 'General'];
  final _filterValues = ['all', 'assignment', 'grade', 'general'];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAnnouncements(widget.course.id);
      if (mounted) {
        setState(() {
          _all = data.map<Announcement>((a) => Announcement.fromJson(a)).toList();
          _loading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _all = [];
          _applyFilter();
        });
      }
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    final fv = _filterValues[_filterIndex];
    setState(() {
      _filtered = _all.where((a) {
        final matchFilter = fv == 'all' || (a.category) == fv;
        final searchTerm = q.isEmpty ||
            (a.title).toLowerCase().contains(q) ||
            (a.content).toLowerCase().contains(q);
        return matchFilter && searchTerm;
      }).toList();
    });
  }

  void _toggleStar(Announcement a) async {
    setState(() => a.starred = !a.starred);
    try {
      await ApiService.starAnnouncement(
        courseId: widget.course.id,
        announcementId: a.id,
        starred: a.starred,
      );
    } catch (_) {}
  }

  Future<void> _deleteAnnouncement(Announcement a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to permanently delete this announcement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await ApiService.deleteAnnouncement(announcementId: a.id);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully'), backgroundColor: Colors.red),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to delete announcement')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editAnnouncement(Announcement a) async {
    final titleCtrl = TextEditingController(text: a.title);
    final contentCtrl = TextEditingController(text: a.content);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Edit Announcement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 18),
              TextFormField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Content',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Save Changes',
                gradient: AppGradients.orange,
                icon: Icons.check_rounded,
                onPressed: () async {
                  if (titleCtrl.text.trim().isNotEmpty && contentCtrl.text.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    try {
                      final res = await ApiService.updateAnnouncement(
                        announcementId: a.id,
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                      );
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Announcement updated!'), backgroundColor: Colors.green),
                        );
                        _load();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Failed to update announcement')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            gradient: AppGradients.orange,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Announcements',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.course.name,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13)),
                    const SizedBox(height: 14),
                    // Search
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search announcements...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.orange.shade200, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
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
                              onSelected: (i) {
                                setState(() => _filterIndex = i);
                                _applyFilter();
                              },
                              activeGradient: AppGradients.orange,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _AnnouncementCard(
                                  announcement: _filtered[i],
                                  index: i,
                                  onStar: () => _toggleStar(_filtered[i]),
                                  onEdit: () => _editAnnouncement(_filtered[i]),
                                  onDelete: () => _deleteAnnouncement(_filtered[i]),
                                ),
                              ),
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
      floatingActionButton: (context.watch<AuthProvider>().isTeacher || context.watch<AuthProvider>().isAdmin)
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
                if (created == true) {
                  _load();
                }
              },
              backgroundColor: AppColors.orange,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final int index;
  final VoidCallback onStar;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.index,
    required this.onStar,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final grad = index % 2 == 0 ? AppGradients.orange : AppGradients.violet;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GradientIconBox(
                      gradient: grad,
                      icon: Icons.person_rounded,
                      size: 46,
                      iconSize: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(announcement.author,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(announcement.timestamp,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onStar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: announcement.starred
                            ? Colors.yellow.shade100
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        announcement.starred
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: announcement.starred
                            ? Colors.amber
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  if (auth.isTeacher || auth.isAdmin) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        if (val == 'edit' && onEdit != null) onEdit!();
                        if (val == 'delete' && onDelete != null) onDelete!();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_rounded, size: 16, color: AppColors.textPrimary),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 13)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(announcement.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(announcement.content,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ],
          ),
        ),
        if (announcement.pinned)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: AppGradients.orange,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.orange, blurRadius: 8)],
              ),
              child: const Icon(Icons.push_pin_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }
}
