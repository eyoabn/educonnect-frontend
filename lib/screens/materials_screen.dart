import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

final _mockMaterials = [
  StudyMaterial(id: 1, name: 'Lecture 1 - Introduction.pdf', type: 'PDF', size: '2.3 MB', date: 'Apr 20, 2026', category: 'lecture'),
  StudyMaterial(id: 2, name: 'Assignment 3 - Calculus.docx', type: 'DOC', size: '156 KB', date: 'Apr 24, 2026', category: 'assignment', downloaded: true),
  StudyMaterial(id: 3, name: 'Chapter 5 Notes.pdf', type: 'PDF', size: '4.1 MB', date: 'Apr 18, 2026', category: 'note'),
  StudyMaterial(id: 4, name: 'Practice Problems.xlsx', type: 'XLS', size: '89 KB', date: 'Apr 15, 2026', category: 'exercise', downloaded: true),
  StudyMaterial(id: 5, name: 'Midterm Review.pdf', type: 'PDF', size: '1.8 MB', date: 'Apr 22, 2026', category: 'exam'),
  StudyMaterial(id: 6, name: 'Lab Report Template.docx', type: 'DOC', size: '234 KB', date: 'Apr 10, 2026', category: 'template'),
];

class MaterialsScreen extends StatefulWidget {
  final Course course;
  const MaterialsScreen({super.key, required this.course});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<StudyMaterial> _all = [];
  List<StudyMaterial> _filtered = [];
  bool _loading = true;
  int _filterIndex = 0;
  final _searchCtrl = TextEditingController();

  final _filters = ['All', 'Lectures', 'Assignments', 'Notes', 'Exams'];
  final _filterValues = ['all', 'lecture', 'assignment', 'note', 'exam'];

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
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMaterials(widget.course.id);
      if (mounted) setState(() {
        _all = data.map((m) => StudyMaterial(
          id: (m['id'] as num?)?.toInt() ?? 0,
          name: m['name'] as String? ?? 'Material',
          type: m['type'] as String? ?? 'FILE',
          size: m['size'] as String? ?? 'Unknown',
          date: m['date'] as String? ?? '',
          category: m['category'] as String? ?? 'general',
          downloaded: m['downloaded'] as bool? ?? false,
          version: m['version'] as int? ?? 1,
        )).toList();
        _loading = false;
        _applyFilter();
      });
    } catch (_) {
      if (mounted) setState(() { _all = List.from(_mockMaterials); _loading = false; _applyFilter(); });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    final fv = _filterValues[_filterIndex];
    setState(() {
      _filtered = _all.where((m) {
        final matchCat = fv == 'all' || m.category == fv;
        final matchQ   = q.isEmpty || m.name.toLowerCase().contains(q);
        return matchCat && matchQ;
      }).toList();
    });
  }

  Future<void> _download(StudyMaterial material) async {
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('Downloading ${material.name}...'),
        ]),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.violet,
      ),
    );
    try {
      final response = await ApiService.getMaterialDownloadUrl(widget.course.id, material.id);
      final url = response['url'] as String? ?? '';
      if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        setState(() => material.downloaded = true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started!'), backgroundColor: Colors.green));
      }
    } catch (_) {
      // Demo fallback
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => material.downloaded = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: ${material.name}'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _deleteMaterial(StudyMaterial material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteMaterial(widget.course.id, material.id);
      } catch (_) {}
      setState(() {
        _all.removeWhere((m) => m.id == material.id);
        _applyFilter();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material deleted'), backgroundColor: Colors.red));
    }
  }

  void _showUpdateVersionDialog(StudyMaterial material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadSheet(
        isUpdate: true,
        onUpload: (name, category) async {
          await ApiService.updateMaterialVersion(
            materialId: material.id.toString(),
            fileUrl: 'https://example.com/updated_file',
          );
          _load();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${material.name} updated to v${material.version + 1}!'), backgroundColor: Colors.green));
        },
      ),
    );
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadSheet(
        onUpload: (name, category) async {
          try {
            final res = await ApiService.uploadMaterial(
              courseId: widget.course.id,
              title: name,
              url: 'https://example.com/demo_material.pdf', // Placeholder for demo upload
              category: category,
            );
            if (res['success'] == true) {
              _load(); // Reload materials from backend
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Material uploaded successfully!'), backgroundColor: Colors.green));
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Upload failed: ${res['message'] ?? 'Unknown error'}'), backgroundColor: Colors.red));
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red));
            }
          }
        },
      ),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // Stats
  int get _totalCount => _all.length;
  int get _downloadedCount => _all.where((m) => m.downloaded).length;
  int get _newCount => 3; // Would come from API

  @override
  Widget build(BuildContext context) {
    final isTeacher = context.watch<AuthProvider>().isTeacher;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ───────────────────────────────────────────────────────
        GradientHeader(
          gradient: AppGradients.cyan,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppBackButton(),
                const Spacer(),
                if (isTeacher)
                  GestureDetector(
                    onTap: _showUploadDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3))),
                      child: const Row(children: [
                        Icon(Icons.upload_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              const Text('Materials', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.course.name, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              const SizedBox(height: 14),
              // Search
              _GlassSearch(controller: _searchCtrl, hint: 'Search materials...', accentColor: Colors.cyan.shade200),
              const SizedBox(height: 14),
              // Stats row
              Row(children: [
                Expanded(child: _StatBox(label: 'Total', value: '$_totalCount')),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(label: 'Downloaded', value: '$_downloadedCount')),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(label: 'New', value: '$_newCount')),
              ]),
            ]),
          )),
        ),

        // ── Filters ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: FilterBar(
            labels: _filters,
            selectedIndex: _filterIndex,
            onSelected: (i) { setState(() => _filterIndex = i); _applyFilter(); },
            activeGradient: AppGradients.cyan,
          ),
        ),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_open_rounded,
                      title: 'No materials found',
                      subtitle: isTeacher ? 'Upload your first material' : 'Materials will appear here',
                      gradient: AppGradients.cyan,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _MaterialCard(
                          material: _filtered[i],
                          index: i,
                          isTeacher: isTeacher,
                          onDownload: () => _download(_filtered[i]),
                          onDelete: isTeacher ? () => _deleteMaterial(_filtered[i]) : null,
                          onUpdate: isTeacher ? () => _showUpdateVersionDialog(_filtered[i]) : null,
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ── Material Card ─────────────────────────────────────────────────────────────
class _MaterialCard extends StatelessWidget {
  final StudyMaterial material;
  final int index;
  final bool isTeacher;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdate;

  const _MaterialCard({
    required this.material, required this.index,
    required this.isTeacher, required this.onDownload, this.onDelete, this.onUpdate,
  });

  Color get _typeColor {
    switch (material.type) {
      case 'PDF': return Colors.red;
      case 'DOC': return Colors.blue;
      case 'XLS': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color get _categoryColor {
    switch (material.category) {
      case 'lecture': return AppColors.cyan;
      case 'assignment': return AppColors.orange;
      case 'note': return AppColors.violet;
      case 'exam': return AppColors.rose;
      default: return AppColors.emerald;
    }
  }

  IconData get _fileIcon {
    switch (material.type) {
      case 'PDF': return Icons.picture_as_pdf_rounded;
      case 'DOC': return Icons.description_rounded;
      case 'XLS': return Icons.table_chart_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grad = AppGradients.cardGradients[index % AppGradients.cardGradients.length];
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        // File icon
        GradientIconBox(gradient: grad, icon: _fileIcon, size: 52, iconSize: 24),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(material.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis, maxLines: 2),
          const SizedBox(height: 5),
          Row(children: [
            Text(material.size, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(material.date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('v${material.version}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            InfoChip(label: material.category, color: _categoryColor),
            const SizedBox(width: 6),
            InfoChip(label: material.type, color: _typeColor),
            if (material.downloaded) ...[
              const SizedBox(width: 6),
              InfoChip(label: 'Downloaded', color: Colors.green),
            ],
          ]),
        ])),
        const SizedBox(width: 8),
        // Actions
        Column(children: [
          // Download button
          GestureDetector(
            onTap: onDownload,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(gradient: AppGradients.violet, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]),
              child: Icon(material.downloaded ? Icons.download_done_rounded : Icons.download_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          if (isTeacher && onUpdate != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onUpdate,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.update_rounded, color: Colors.blue, size: 18),
              ),
            ),
          ],
          if (isTeacher && onDelete != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ── Upload Bottom Sheet ────────────────────────────────────────────────────────
class _UploadSheet extends StatefulWidget {
  final Function(String name, String category) onUpload;
  final bool isUpdate;
  const _UploadSheet({required this.onUpload, this.isUpdate = false});

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedCat = 'lecture';
  bool _uploading = false;

  final _cats = ['lecture', 'assignment', 'note', 'exam', 'exercise', 'template'];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _upload() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a file name')));
      return;
    }
    setState(() => _uploading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate upload
    if (mounted) {
      Navigator.pop(context);
      widget.onUpload(_nameCtrl.text.trim(), _selectedCat);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(widget.isUpdate ? 'Update Material Version' : 'Upload Material', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 18),
        // File name
        TextFormField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'File name',
            hintText: 'e.g. Lecture 7 - Calculus.pdf',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            prefixIcon: const Icon(Icons.insert_drive_file_rounded),
          ),
        ),
        const SizedBox(height: 16),
        // Category
        const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _cats.map((c) {
            final selected = c == _selectedCat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCat = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected ? AppGradients.cyan : null,
                  color: selected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected ? [BoxShadow(color: AppColors.cyan.withOpacity(0.4), blurRadius: 8)] : [],
                ),
                child: Text(c, style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13,
                    color: selected ? Colors.white : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: widget.isUpdate ? 'Upload New Version' : 'Upload Material',
          gradient: AppGradients.cyan,
          isLoading: _uploading,
          icon: widget.isUpdate ? Icons.system_update_alt_rounded : Icons.cloud_upload_rounded,
          onPressed: _upload,
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// ── Helpers ────────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
    ]),
  );
}

class _GlassSearch extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accentColor;
  const _GlassSearch({required this.controller, required this.hint, required this.accentColor});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(Icons.search_rounded, color: accentColor, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}
