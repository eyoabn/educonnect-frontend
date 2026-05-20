import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  String _category   = 'general';
  bool   _isPinned   = false;
  bool   _isLoading  = false;
  bool   _loadingCourses = true;
  String? _loadError;
  
  List<Map<String, dynamic>> _courses = [];
  Map<String, dynamic>? _selectedCourse;

  static const _categories = [
    {'value': 'general',    'label': 'General',    'icon': Icons.info_outline_rounded},
    {'value': 'assignment', 'label': 'Assignment',  'icon': Icons.assignment_rounded},
    {'value': 'grade',      'label': 'Grade',       'icon': Icons.grade_rounded},
    {'value': 'resource',   'label': 'Resource',    'icon': Icons.folder_rounded},
    {'value': 'important',  'label': 'Important',   'icon': Icons.priority_high_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await ApiService.getCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _loadingCourses = false;
          if (courses.isNotEmpty) {
            _selectedCourse = courses[0];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCourses = false;
          _loadError = 'Failed to load courses: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    // Manual validation (no Form in tree currently)
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content is required'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.createAnnouncement(
        course: _selectedCourse!['id']?.toString() ?? '',
        title: title,
        content: content,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to publish post'), backgroundColor: Colors.red),
        );
      }
    } catch (e, st) {
      // Log and surface network/timeout/errors
      // ignore: avoid_print
      print('Publish error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing post: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final auth = context.watch<AuthProvider>();
      
      if (_loadingCourses) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Create Post'), leading: const AppBackButton()),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      if (_courses.isEmpty) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Create Post'), leading: const AppBackButton()),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No courses available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_loadError ?? 'Contact your administrator to create courses', 
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadingCourses = true;
                          _loadError = null;
                        });
                        _loadCourses();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Create Post'),
          leading: const AppBackButton(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _isLoading ? null : _publish,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: AppGradients.emerald, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_selectedCourse?['name'] ?? 'Select Course', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('By ${auth.displayName}', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ]),
            ),
            const SizedBox(height: 12),
            const _FieldLabel(text: 'Select Course'),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedCourse,
              items: _courses.map((course) {
                return DropdownMenuItem(value: course, child: Text(course['name'] ?? 'Course'));
              }).toList(),
              onChanged: (course) => setState(() => _selectedCourse = course),
              decoration: _inputDec(hint: 'Choose a course', icon: Icons.menu_book_rounded, color: AppColors.emerald),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(text: 'Post Title'),
            const SizedBox(height: 8),
            TextFormField(controller: _titleCtrl, decoration: _inputDec(hint: 'e.g. Assignment 3 Posted', icon: Icons.title_rounded, color: AppColors.emerald)),
            const SizedBox(height: 16),
            const _FieldLabel(text: 'Content'),
            const SizedBox(height: 8),
            TextFormField(controller: _contentCtrl, maxLines: 8, decoration: _inputDec(hint: 'Write your post here...', icon: Icons.notes_rounded, color: AppColors.emerald)),
            const SizedBox(height: 16),
            GradientButton(label: 'Publish Post', gradient: AppGradients.emerald, isLoading: _isLoading, icon: Icons.send_rounded, onPressed: _publish),
            const SizedBox(height: 24),
          ]),
        ),
      );
    } catch (e, st) {
      // Show error scaffold instead of blank white page
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Create Post'), leading: const AppBackButton()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('An error occurred', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loadingCourses = true;
                    _loadError = null;
                  });
                  _loadCourses();
                },
                child: const Text('Retry'),
              ),
            ]),
          ),
        ),
      );
    }
  }

  InputDecoration _inputDec({required String hint, required IconData icon, required Color color}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
}
