import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class QAScreen extends StatefulWidget {
  final Course course;
  const QAScreen({super.key, required this.course});

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  List<Question> _questions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final questions = await ApiService.getQuestions(widget.course.id);
    if (mounted) {
      setState(() {
        _questions = questions;
        _loading = false;
      });
    }
  }

  void _showAskDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ask a Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'Short summary of your question'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Details', hintText: 'Explain your question in detail'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await ApiService.createQuestion(
                  courseId: widget.course.id,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                );
                _load();
              }
            },
            child: const Text('Ask'),
          ),
        ],
      ),
    );
  }

  void _openQuestion(Question q) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _QuestionDetailScreen(question: q, onAnswerPosted: _load)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            gradient: AppGradients.cyan,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppBackButton(),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showAskDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Ask', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Q&A Forum', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.course.name, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? const EmptyState(
                        icon: Icons.forum_rounded,
                        title: 'No questions yet',
                        subtitle: 'Be the first to ask a question!',
                        gradient: AppGradients.cyan,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final q = _questions[i];
                            return GestureDetector(
                              onTap: () => _openQuestion(q),
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(q.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text(q.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('By ${q.authorName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        Row(
                                          children: [
                                            const Icon(Icons.comment_rounded, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text('${q.answers.length} answers', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _QuestionDetailScreen extends StatefulWidget {
  final Question question;
  final VoidCallback onAnswerPosted;

  const _QuestionDetailScreen({required this.question, required this.onAnswerPosted});

  @override
  State<_QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<_QuestionDetailScreen> {
  final _replyCtrl = TextEditingController();

  Future<void> _postReply() async {
    if (_replyCtrl.text.isEmpty) return;
    await ApiService.postAnswer(questionId: widget.question.id, content: _replyCtrl.text);
    _replyCtrl.clear();
    widget.onAnswerPosted();
    if (mounted) Navigator.pop(context); // Pop detail screen to refresh data in parent
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Q&A Thread')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(widget.question.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Asked by ${widget.question.authorName}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Text(widget.question.content, style: const TextStyle(fontSize: 16)),
                const Divider(height: 32),
                const Text('Answers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...widget.question.answers.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(a.content),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type an answer...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.blue),
                  onPressed: _postReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
