import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

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
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final int index;
  final VoidCallback onStar;

  const _AnnouncementCard({
    required this.announcement,
    required this.index,
    required this.onStar,
  });

  @override
  Widget build(BuildContext context) {
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
