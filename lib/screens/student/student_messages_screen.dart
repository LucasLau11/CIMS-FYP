import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../utils/file_picker_utils.dart';
import '../../utils/format_utils.dart';
import '../document_preview_screen.dart';

const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

bool _isImage(String? fileName) {
  if (fileName == null) return false;
  final ext = fileName.split('.').last.toLowerCase();
  return _imageExtensions.contains(ext);
}

class StudentMessagesScreen extends StatefulWidget {
  const StudentMessagesScreen({super.key});

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await StudentDataService.instance.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openConversation(Map<String, dynamic> conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation['id'] as String,
          otherProfile: conversation['other_profile'] as Map<String, dynamic>,
        ),
      ),
    );
    _load();
  }

  Future<void> _archive(Map<String, dynamic> conversation) async {
    await StudentDataService.instance.setConversationArchived(conversation['id'] as String, true);
    _load();
  }

  Future<void> _delete(Map<String, dynamic> conversation) async {
    final other = conversation['other_profile'] as Map<String, dynamic>?;
    final name = (other?['full_name'] as String?)?.isNotEmpty == true ? other!['full_name'] as String : 'this conversation';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text('This deletes the whole conversation with $name for both of you. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StudentDataService.instance.deleteConversation(conversation['id'] as String);
    _load();
  }

  Future<void> _openArchived() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const _ArchivedConversationsScreen()));
    _load();
  }

  Future<void> _startNewConversation() async {
    List<Map<String, dynamic>> directory;
    try {
      directory = await StudentDataService.instance.getDirectory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not load contacts: $e'), backgroundColor: AppColors.error));
      return;
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('New message', style: AppTextStyles.h3),
              ),
            ),
            Expanded(
              child: directory.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No other accounts to message yet.', style: AppTextStyles.bodySecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: directory.length,
                      itemBuilder: (_, i) {
                        final person = directory[i];
                        final name = (person['full_name'] as String?)?.isNotEmpty == true
                            ? person['full_name'] as String
                            : person['role'] as String;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: nameColor(name).withOpacity(0.15),
                            child: Text(logoLetter(name),
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: nameColor(name))),
                          ),
                          title: Text(name),
                          subtitle: Text(_roleLabel(person['role'] as String)),
                          onTap: () => Navigator.pop(context, person),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    if (selected == null) return;
    if (!mounted) return;
    final conversation = await StudentDataService.instance.getOrCreateConversation(selected['id'] as String);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation['id'] as String, otherProfile: selected)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Messages',
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.white),
            tooltip: 'Archived chats',
            onPressed: _openArchived,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: _startNewConversation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _conversations.isEmpty
                  ? ListView(
                      children: const [
                        EmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'No conversations yet',
                          description: 'Tap the pencil icon to message someone.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
                      itemBuilder: (_, i) => _ConversationTile(
                        data: _conversations[i],
                        onTap: () => _openConversation(_conversations[i]),
                        onArchive: () => _archive(_conversations[i]),
                        onDelete: () => _delete(_conversations[i]),
                      ),
                    ),
            ),
    );
  }
}

class _ArchivedConversationsScreen extends StatefulWidget {
  const _ArchivedConversationsScreen();

  @override
  State<_ArchivedConversationsScreen> createState() => _ArchivedConversationsScreenState();
}

class _ArchivedConversationsScreenState extends State<_ArchivedConversationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await StudentDataService.instance.getConversations(archived: true);
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unarchive(Map<String, dynamic> conversation) async {
    await StudentDataService.instance.setConversationArchived(conversation['id'] as String, false);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'Archived chats'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _conversations.isEmpty
              ? const EmptyState(
                  icon: Icons.archive_outlined,
                  title: 'No archived chats',
                  description: 'Conversations you archive show up here.',
                )
              : ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
                  itemBuilder: (_, i) {
                    final convo = _conversations[i];
                    final other = convo['other_profile'] as Map<String, dynamic>?;
                    final name =
                        (other?['full_name'] as String?)?.isNotEmpty == true ? other!['full_name'] as String : 'Unknown user';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: nameColor(name).withOpacity(0.15),
                        child: Text(logoLetter(name),
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: nameColor(name))),
                      ),
                      title: Text(name),
                      trailing: TextButton(onPressed: () => _unarchive(convo), child: const Text('Unarchive')),
                    );
                  },
                ),
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'student':
      return 'Student';
    case 'academic_supervisor':
      return 'Academic Supervisor';
    case 'company_hr':
      return 'HR Personnel';
    case 'company_supervisor':
      return 'Company Supervisor';
    case 'parent':
      return 'Parent/Guardian';
    default:
      return role;
  }
}

String _previewText(Map<String, dynamic>? lastMessage) {
  if (lastMessage == null) return '';
  final body = lastMessage['body'] as String?;
  if (body != null && body.isNotEmpty) return body;
  final attachmentName = lastMessage['attachment_file_name'] as String?;
  if (attachmentName != null) return _isImage(attachmentName) ? '📷 Photo' : '📎 $attachmentName';
  return '';
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ConversationTile({required this.data, required this.onTap, required this.onArchive, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final other = data['other_profile'] as Map<String, dynamic>?;
    final name = (other?['full_name'] as String?)?.isNotEmpty == true ? other!['full_name'] as String : 'Unknown user';
    final role = other != null ? _roleLabel(other['role'] as String) : '';
    final lastMessage = data['last_message'] as Map<String, dynamic>?;
    final unreadCount = data['unread_count'] as int;
    final hasUnread = unreadCount > 0;
    final preview = _previewText(lastMessage);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: nameColor(name).withOpacity(0.15),
        child: Text(logoLetter(name),
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: nameColor(name))),
      ),
      title: Text(name,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary)),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              preview.isNotEmpty ? preview : role,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: hasUnread ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Text('$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lastMessage != null)
            Text(timeAgo(DateTime.parse(lastMessage['created_at'] as String)),
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: hasUnread ? AppColors.primary : AppColors.textMuted,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400)),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
            onSelected: (value) {
              if (value == 'archive') onArchive();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherProfile;

  const ChatScreen({super.key, required this.conversationId, required this.otherProfile});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _myId = AuthService.instance.currentUserId;

  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  bool _isAttaching = false;

  @override
  void initState() {
    super.initState();
    _load();
    StudentDataService.instance.messagesStream(widget.conversationId).listen((rows) {
      if (!mounted) return;
      setState(() => _messages = rows);
      _scrollToBottom();
      StudentDataService.instance.markConversationRead(widget.conversationId);
    });
  }

  Future<void> _load() async {
    try {
      final messages = await StudentDataService.instance.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
      StudentDataService.instance.markConversationRead(widget.conversationId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _messageController.clear();
    try {
      await StudentDataService.instance.sendMessage(conversationId: widget.conversationId, body: text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send message: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _attachFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;

    if (picked.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: const Text('File is too large. Maximum size is 10MB.'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isAttaching = true);
    try {
      final file = await resolvePickedFile(picked);
      final path = await StudentDataService.instance.uploadChatAttachment(
        conversationId: widget.conversationId,
        file: file,
        fileName: picked.name,
      );
      await StudentDataService.instance.sendMessage(
        conversationId: widget.conversationId,
        attachmentPath: path,
        attachmentFileName: picked.name,
        attachmentSizeBytes: picked.size,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send attachment: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isAttaching = false);
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await StudentDataService.instance.deleteMessage(
        message['id'] as String,
        attachmentPath: message['attachment_path'] as String?,
      );
      // Don't wait on the realtime round-trip to reflect this locally —
      // Supabase Realtime truncates DELETE payloads to primary-key-only
      // under RLS and has known gaps in delivering them at all, so the
      // deleter's own view needs to update from the successful call
      // itself rather than depend on the stream echoing it back.
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m['id'] == message['id']));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not delete message: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.otherProfile['full_name'] as String?)?.isNotEmpty == true
        ? widget.otherProfile['full_name'] as String
        : 'Unknown user';
    final role = _roleLabel(widget.otherProfile['role'] as String);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: nameColor(name).withOpacity(0.2),
              child: Text(logoLetter(name), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nameColor(name))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(role,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Text('Say hello 👋', style: TextStyle(fontFamily: 'Inter', color: AppColors.textMuted)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final message = _messages[i];
                          final isMine = message['sender_id'] == _myId;
                          return _MessageBubble(
                            data: message,
                            isMine: isMine,
                            onLongPress: isMine ? () => _deleteMessage(message) : null,
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  icon: _isAttaching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.attach_file, color: AppColors.textMuted, size: 22),
                  onPressed: _isAttaching ? null : _attachFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMine;
  final VoidCallback? onLongPress;

  const _MessageBubble({required this.data, required this.isMine, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.parse(data['created_at'] as String);
    final timeLabel = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final body = data['body'] as String?;
    final attachmentPath = data['attachment_path'] as String?;
    final attachmentFileName = data['attachment_file_name'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: isMine ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (attachmentPath != null) _AttachmentContent(path: attachmentPath, fileName: attachmentFileName, isMine: isMine),
                  if (body != null && body.isNotEmpty) ...[
                    if (attachmentPath != null) const SizedBox(height: 6),
                    Text(body, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isMine ? Colors.white : AppColors.textPrimary)),
                  ],
                  const SizedBox(height: 4),
                  Text(timeLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: isMine ? Colors.white60 : AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentContent extends StatelessWidget {
  final String path;
  final String? fileName;
  final bool isMine;

  const _AttachmentContent({required this.path, required this.fileName, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: StudentDataService.instance.getChatAttachmentSignedUrl(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(width: 120, height: 90, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final url = snapshot.data!;
        if (_isImage(fileName)) {
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName ?? 'Attachment'),
            )),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(url, width: 180, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SizedBox(
                        width: 120,
                        height: 90,
                        child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted)),
                      )),
            ),
          );
        }
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName ?? 'Attachment'),
          )),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isMine ? Colors.white.withOpacity(0.15) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file_outlined, size: 16, color: isMine ? Colors.white : AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(fileName ?? 'Attachment',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isMine ? Colors.white : AppColors.textPrimary,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
