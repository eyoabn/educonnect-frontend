import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

final _mockResults = [
  SearchResult(id: 1, type: 'file', title: 'Lecture 5 - Derivatives.pdf', course: 'Mathematics 101', match: 'Chapter on derivatives'),
  SearchResult(id: 2, type: 'message', title: 'Quiz reminder', course: 'Physics Advanced', match: "Tomorrow's quiz on Newton's laws"),
  SearchResult(id: 3, type: 'course', title: 'Computer Science', teacher: 'Dr. Emily Parker', match: 'Introduction to algorithms'),
  SearchResult(id: 4, type: 'file', title: 'Assignment 2 Solutions.pdf', course: 'Mathematics 101', match: 'Detailed solutions for assignment 2'),
  SearchResult(id: 5, type: 'announcement', title: 'Lab Session Update', course: 'Physics Advanced', match: 'Room change notification'),
];

const _recentSearches = ['calculus notes', 'assignment due dates', 'physics formulas', 'group study'];
const _trendingSearches = ['midterm review', 'project guidelines', 'office hours', 'final exam'];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  int _filterIndex = 0;
  List<SearchResult> _results = [];
  List<String> _recent = List.from(_recentSearches);
  bool _searching = false;

  final _filters = ['All', 'Files', 'Messages', 'Courses'];
  final _filterValues = ['all', 'files', 'messages', 'courses'];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    _doSearch(q);
  }

  Future<void> _doSearch(String q) async {
    setState(() => _searching = true);
    try {
      final data = await ApiService.search(q, filter: _filterValues[_filterIndex]);
      if (mounted) setState(() { _results = data; _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _results = _mockResults; _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _ctrl.text.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Sticky search bar
          Container(
            color: Colors.white.withOpacity(0.92),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Search input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _ctrl,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Search files, messages, courses...',
                          hintStyle: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.violet, size: 22),
                          suffixIcon: hasQuery
                              ? GestureDetector(
                                  onTap: () {
                                    _ctrl.clear();
                                    setState(() => _results = []);
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      color: AppColors.textSecondary))
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter bar
                    FilterBar(
                      labels: _filters,
                      selectedIndex: _filterIndex,
                      onSelected: (i) {
                        setState(() => _filterIndex = i);
                        if (hasQuery) _doSearch(_ctrl.text.trim());
                      },
                      activeGradient: AppGradients.violet,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : hasQuery
                    ? _ResultsList(results: _results)
                    : _DiscoveryView(
                        recent: _recent,
                        onSearchTap: (s) {
                          _ctrl.text = s;
                          _ctrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: s.length));
                        },
                        onClearRecent: () => setState(() => _recent = []),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<SearchResult> results;
  const _ResultsList({required this.results});

  IconData _icon(String type) {
    switch (type) {
      case 'file': return Icons.description_rounded;
      case 'message': return Icons.chat_bubble_rounded;
      case 'course': return Icons.menu_book_rounded;
      default: return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('${results.length} results found',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          );
        }
        final r = results[i - 1];
        final grad = AppGradients.cardGradients[(i - 1) % AppGradients.cardGradients.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GradientIconBox(gradient: grad, icon: _icon(r.type), size: 46, iconSize: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(r.course ?? r.teacher ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.violet)),
                      const SizedBox(height: 4),
                      Text(r.match,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiscoveryView extends StatelessWidget {
  final List<String> recent;
  final ValueChanged<String> onSearchTap;
  final VoidCallback onClearRecent;

  const _DiscoveryView({
    required this.recent,
    required this.onSearchTap,
    required this.onClearRecent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recent searches
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.history_rounded, color: AppColors.violet, size: 20),
                const SizedBox(width: 6),
                const Text('Recent Searches',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
              ]),
              GestureDetector(
                onTap: onClearRecent,
                child: const Text('Clear all',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.violet,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent
                .map((s) => GestureDetector(
                      onTap: () => onSearchTap(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8)
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary)),
                            const SizedBox(width: 6),
                            const Icon(Icons.close_rounded,
                                size: 13, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Trending
        Row(children: [
          const Icon(Icons.trending_up_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 6),
          const Text('Trending',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        ..._trendingSearches.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                onTap: () => onSearchTap(e.value),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppGradients.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(e.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
