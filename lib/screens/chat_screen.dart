import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ── Mock data ──────────────────────────────────────────────────────────────
final _mockContacts = [
  ChatContact(id: 1, name: 'Dr. Sarah Johnson', role: 'Mathematics Teacher', avatar: 'SJ', online: true, unread: 2, lastMessage: 'See you tomorrow!', gradientIndex: 0),
  ChatContact(id: 2, name: 'Prof. Michael Chen', role: 'Physics Teacher', avatar: 'MC', online: true, unread: 0, lastMessage: 'Great work on the lab report', gradientIndex: 1),
  ChatContact(id: 3, name: 'Dr. Emily Parker', role: 'CS Teacher', avatar: 'EP', online: false, unread: 1, lastMessage: 'Assignment deadline extended', gradientIndex: 2),
  ChatContact(id: 4, name: 'Ms. Rachel Adams', role: 'English Teacher', avatar: 'RA', online: true, unread: 0, lastMessage: 'Thanks for your essay', gradientIndex: 3),
  ChatContact(id: 5, name: 'Study Group A', role: '5 members', avatar: 'SG', online: true, unread: 5, lastMessage: 'Anyone free for study session?', gradientIndex: 2),
];

final _mockMessages = <int, List<ChatMessage>>{
  1: [
    ChatMessage(id: 1, sender: 'Dr. Sarah Johnson', content: "Good morning! Don't forget about tomorrow's quiz.", time: '09:30 AM', isSelf: false),
    ChatMessage(id: 2, sender: 'You', content: 'Will the quiz cover chapter 5?', time: '09:35 AM', isSelf: true),
    ChatMessage(id: 3, sender: 'Dr. Sarah Johnson', content: 'Yes, chapters 4 and 5 will be included. Focus on integration formulas.', time: '09:40 AM', isSelf: false),
    ChatMessage(id: 4, sender: 'You', content: 'Thank you for clarifying!', time: '09:42 AM', isSelf: true),
  ],
  2: [
    ChatMessage(id: 1, sender: 'Prof. Michael Chen', content: 'Great work on the lab report!', time: '10:15 AM', isSelf: false),
    ChatMessage(id: 2, sender: 'You', content: 'Thank you professor! I really enjoyed the experiment.', time: '10:20 AM', isSelf: true),
  ],
  3: [
    ChatMessage(id: 1, sender: 'Dr. Emily Parker', content: 'Assignment deadline has been extended to next Friday.', time: 'Yesterday', isSelf: false),
    ChatMessage(id: 2, sender: 'You', content: "That's great news, thank you!", time: 'Yesterday', isSelf: true),
  ],
  4: [
    ChatMessage(id: 1, sender: 'Ms. Rachel Adams', content: 'Thanks for your essay on Shakespeare. Very insightful!', time: '2 days ago', isSelf: false),
  ],
  5: [
    ChatMessage(id: 1, sender: 'John', content: 'Anyone free for a study session this weekend?', time: '11:00 AM', isSelf: false),
    ChatMessage(id: 2, sender: 'You', content: "I'm available Saturday afternoon", time: '11:05 AM', isSelf: true),
    ChatMessage(id: 3, sender: 'Sarah', content: "Me too! Let's meet at the library", time: '11:10 AM', isSelf: false),
  ],
};

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatContact> _contacts = [];
  List<ChatContact> _filtered = [];
  bool _loading = true;
  ChatContact? _selected;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadContacts() async {
    try {
      final data = await ApiService.getContacts();
      if (mounted) setState(() { 
        _contacts = data.map((c) => ChatContact(
          id: (c['id'] as num?)?.toInt() ?? 0,
          name: c['name'] as String? ?? 'Unknown',
          role: c['role'] as String? ?? '',
          avatar: c['avatar'] as String? ?? '?',
          online: c['online'] as bool? ?? false,
          unread: (c['unread'] as num?)?.toInt() ?? 0,
          lastMessage: c['lastMessage'] as String? ?? '',
          gradientIndex: (c['gradientIndex'] as num?)?.toInt() ?? 0,
        )).toList(); 
        _filtered = _contacts; 
        _loading = false; 
      }); 
    } catch (_) {
      if (mounted) setState(() { _contacts = _mockContacts; _filtered = _mockContacts; _loading = false; });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() => _filtered = q.isEmpty ? _contacts
        : _contacts.where((c) => c.name.toLowerCase().contains(q) || c.role.toLowerCase().contains(q)).toList());
  }

  void _openConversation(ChatContact contact) {
    // Clear unread badge
    setState(() { contact.unread = 0; });
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ConversationScreen(contact: contact)));
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _ConversationScreen(contact: _selected!);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        GradientHeader(
          gradient: AppGradients.violet,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('Messages', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
                // New message button
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New conversation coming soon'))),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.3))),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _SearchBar(controller: _searchCtrl, hint: 'Search conversations...', accentColor: Colors.purple.shade200),
            ]),
          )),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'No conversations', subtitle: 'Start a new conversation')
                  : RefreshIndicator(
                      onRefresh: _loadContacts,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ContactTile(
                          contact: _filtered[i],
                          onTap: () => _openConversation(_filtered[i]),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ── Contact Tile ─────────────────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final ChatContact contact;
  final VoidCallback onTap;
  const _ContactTile({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grad = AppGradients.courseGradients[contact.gradientIndex % 4];
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: grad.colors.first.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Center(child: Text(contact.avatar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
          ),
          if (contact.online)
            Positioned(bottom: -2, right: -2,
              child: Container(width: 14, height: 14,
                decoration: BoxDecoration(color: Colors.green.shade400, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(contact.role, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(contact.lastMessage, style: TextStyle(
              fontSize: 13, color: contact.unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: contact.unread > 0 ? FontWeight.w600 : FontWeight.normal),
              overflow: TextOverflow.ellipsis),
        ])),
        if (contact.unread > 0) GradientBadge(text: '${contact.unread}', gradient: AppGradients.orange),
      ]),
    );
  }
}

// ── Conversation Screen ───────────────────────────────────────────────────────
class _ConversationScreen extends StatefulWidget {
  final ChatContact contact;
  const _ConversationScreen({required this.contact});
  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService.getMessages(widget.contact.id.toString());
      if (mounted) setState(() { _messages = msgs.map((m) => ChatMessage(
        id: (m['id'] as num?)?.toInt() ?? 0,
        sender: m['sender'] as String? ?? 'Unknown',
        content: m['content'] as String? ?? '',
        time: m['time'] as String? ?? '',
        isSelf: m['isSelf'] as bool? ?? false,
      )).toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _messages = List.from(_mockMessages[widget.contact.id] ?? []); _loading = false; });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _nowTime() => DateFormat('hh:mm a').format(DateTime.now());

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();

    // Optimistic update
    final msg = ChatMessage(
      id: _messages.length + 1, sender: 'You', content: text,
      time: _nowTime(), isSelf: true, status: MessageStatus.sending,
    );
    setState(() { _messages.add(msg); _sending = true; });
    _scrollToBottom();

    try {
      await ApiService.sendMessage(
        receiverId: widget.contact.id,
        text: text,
      );
      // Mark as sent
      if (mounted) setState(() {
        final idx = _messages.indexOf(msg);
        if (idx >= 0) _messages[idx] = ChatMessage(id: msg.id, sender: msg.sender, content: msg.content, time: msg.time, isSelf: true, status: MessageStatus.sent);
        _sending = false;
        widget.contact.lastMessage = text;
      });
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    final grad = AppGradients.courseGradients[contact.gradientIndex % 4];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ──
        GradientHeader(
          gradient: AppGradients.violet,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.3))),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 10),
              Stack(clipBehavior: Clip.none, children: [
                Container(width: 42, height: 42,
                  decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(contact.avatar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))),
                if (contact.online)
                  Positioned(bottom: -1, right: -1,
                    child: Container(width: 11, height: 11,
                      decoration: BoxDecoration(color: Colors.green.shade400, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(contact.online ? '● Online' : '● Offline',
                    style: TextStyle(color: contact.online ? Colors.green.shade300 : Colors.white.withOpacity(0.6), fontSize: 11)),
              ])),
              Row(children: [
                _HeaderBtn(icon: Icons.call_rounded),
                const SizedBox(width: 6),
                _HeaderBtn(icon: Icons.videocam_rounded),
                const SizedBox(width: 6),
                _HeaderBtn(icon: Icons.more_vert_rounded),
              ]),
            ]),
          )),
        ),

        // ── Messages ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'No messages yet', subtitle: 'Say hello!')
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
                    ),
        ),

        // ── Input bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: SafeArea(top: false, child: Row(children: [
            _InputBtn(icon: Icons.image_rounded, onTap: () {}),
            const SizedBox(width: 6),
            _InputBtn(icon: Icons.attach_file_rounded, onTap: () {}),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background, borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.06), blurRadius: 6)],
                ),
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: 4, minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...', border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(gradient: AppGradients.violet, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ])),
        ),
      ]),
    );
  }
}

// ── Message Bubble ─────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) => Align(
    alignment: msg.isSelf ? Alignment.centerRight : Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: msg.isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!msg.isSelf) Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 3),
          child: Text(msg.sender, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.violet)),
        ),
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            gradient: msg.isSelf ? AppGradients.violet : null,
            color: msg.isSelf ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(msg.isSelf ? 20 : 4),
              bottomRight: Radius.circular(msg.isSelf ? 4 : 20),
            ),
            boxShadow: [BoxShadow(
              color: msg.isSelf ? AppColors.violet.withOpacity(0.3) : Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
            border: msg.isSelf ? null : Border.all(color: AppColors.border),
          ),
          child: Text(msg.content, style: TextStyle(color: msg.isSelf ? Colors.white : AppColors.textPrimary, fontSize: 14, height: 1.4)),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10, left: msg.isSelf ? 0 : 8, right: msg.isSelf ? 8 : 0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(msg.time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            if (msg.isSelf) ...[
              const SizedBox(width: 4),
              Icon(
                msg.status == MessageStatus.sending ? Icons.access_time_rounded
                    : msg.status == MessageStatus.read ? Icons.done_all_rounded : Icons.done_rounded,
                size: 12,
                color: msg.status == MessageStatus.read ? AppColors.violet : AppColors.textSecondary,
              ),
            ],
          ]),
        ),
      ],
    ),
  );
}

// ── Small helpers ─────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accentColor;
  const _SearchBar({required this.controller, required this.hint, required this.accentColor});

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

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  const _HeaderBtn({required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Icon(icon, color: Colors.white, size: 18),
  );
}

class _InputBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _InputBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.violet.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: AppColors.violet, size: 20),
    ),
  );
}
