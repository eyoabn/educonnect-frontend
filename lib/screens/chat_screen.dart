import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';



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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _startPolling();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollContacts());
  }

  Future<void> _loadContacts() async {
    try {
      final data = await ApiService.getContacts();
      if (mounted) setState(() { 
        _contacts = data.map((c) => ChatContact(
          id: c['id']?.toString() ?? '',
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
      if (mounted) setState(() { _contacts = []; _filtered = []; _loading = false; });
    }
  }

  Future<void> _pollContacts() async {
    try {
      final data = await ApiService.getContacts();
      final newContacts = data.map((c) => ChatContact(
        id: c['id']?.toString() ?? '',
        name: c['name'] as String? ?? 'Unknown',
        role: c['role'] as String? ?? '',
        avatar: c['avatar'] as String? ?? '?',
        online: c['online'] as bool? ?? false,
        unread: (c['unread'] as num?)?.toInt() ?? 0,
        lastMessage: c['lastMessage'] as String? ?? '',
        gradientIndex: (c['gradientIndex'] as num?)?.toInt() ?? 0,
      )).toList();

      if (mounted && !_areContactsEqual(_contacts, newContacts)) {
        setState(() {
          _contacts = newContacts;
          _filter();
        });
      }
    } catch (_) {}
  }

  bool _areContactsEqual(List<ChatContact> list1, List<ChatContact> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].lastMessage != list2[i].lastMessage ||
          list1[i].unread != list2[i].unread ||
          list1[i].online != list2[i].online) {
        return false;
      }
    }
    return true;
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() => _filtered = q.isEmpty ? _contacts
        : _contacts.where((c) => c.name.toLowerCase().contains(q) || c.role.toLowerCase().contains(q)).toList());
  }

  void _openConversation(ChatContact contact) {
    // Clear unread badge
    setState(() { contact.unread = 0; });
    ApiService.markChatAsRead(contact.id);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationScreen(contact: contact))).then((_) {
      _loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return ConversationScreen(contact: _selected!);

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
class ConversationScreen extends StatefulWidget {
  final ChatContact contact;
  const ConversationScreen({required this.contact});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollMessages());
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService.getMessages(widget.contact.id);
      if (mounted) setState(() { _messages = msgs.map((m) => ChatMessage(
        id: (m['id'] as num?)?.toInt() ?? 0,
        sender: m['sender'] as String? ?? 'Unknown',
        content: m['content'] as String? ?? '',
        time: m['time'] as String? ?? '',
        isSelf: m['isSelf'] as bool? ?? false,
      )).toList(); _loading = false; });
      _scrollToBottom();
      ApiService.markChatAsRead(widget.contact.id);
    } catch (_) {
      if (mounted) setState(() { _messages = []; _loading = false; });
    }
  }

  Future<void> _pollMessages() async {
    if (_sending) return;
    try {
      final msgs = await ApiService.getMessages(widget.contact.id);
      final newMessages = msgs.map((m) => ChatMessage(
        id: (m['id'] as num?)?.toInt() ?? 0,
        sender: m['sender'] as String? ?? 'Unknown',
        content: m['content'] as String? ?? '',
        time: m['time'] as String? ?? '',
        isSelf: m['isSelf'] as bool? ?? false,
      )).toList();

      if (mounted && !_areMessagesEqual(_messages, newMessages)) {
        setState(() {
          _messages = newMessages;
        });
        _scrollToBottom();
        ApiService.markChatAsRead(widget.contact.id);
      }
    } catch (_) {}
  }

  bool _areMessagesEqual(List<ChatMessage> list1, List<ChatMessage> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].content != list2[i].content ||
          list1[i].time != list2[i].time) {
        return false;
      }
    }
    return true;
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
      _pollMessages();
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
