import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../utils/file_picker_utils.dart';
import '../../utils/format_utils.dart';
import '../../utils/profanity_filter.dart';
import '../../l10n/app_localizations.dart';
import '../document_preview_screen.dart';

const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

bool _isImage(String? fileName) {
  if (fileName == null) return false;
  final ext = fileName.split('.').last.toLowerCase();
  return _imageExtensions.contains(ext);
}

String _generateLocalMessageId() {
  final random = Random();
  const chars = '0123456789abcdef';
  String hex(int n) => List.generate(n, (_) => chars[random.nextInt(16)]).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-${chars[8 + random.nextInt(4)]}${hex(3)}-${hex(12)}';
}

class StudentMessagesScreen extends StatefulWidget {
  const StudentMessagesScreen({super.key});

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  static const _rolesAllowedToStartNewConversations = {'admin', 'academic_supervisor', 'company_hr', 'parent'};

  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await StudentDataService.instance.getConversations();
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _currentUserRole = profile?['role'] as String?;
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
    final l10n = AppLocalizations.of(context)!;
    final other = conversation['other_profile'] as Map<String, dynamic>?;
    final name = (other?['full_name'] as String?)?.isNotEmpty == true ? other!['full_name'] as String : l10n.chatConversationFallbackName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.chatDeleteConversationTitle),
        content: Text(l10n.chatDeleteConversationMessage(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
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
    final l10n = AppLocalizations.of(context)!;
    List<Map<String, dynamic>> directory;
    try {
      directory = await StudentDataService.instance.getDirectory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.chatCouldNotLoadContacts(e.toString())), backgroundColor: AppColors.error));
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
                child: Text(l10n.chatNewMessageTitle, style: AppTextStyles.h3),
              ),
            ),
            Expanded(
              child: directory.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(l10n.chatNoContactsToMessage, style: AppTextStyles.bodySecondary),
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
                          subtitle: Text(_roleLabel(l10n, person['role'] as String)),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.chatTabTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.white),
            tooltip: l10n.chatArchivedChatsTitle,
            onPressed: _openArchived,
          ),
          if (_rolesAllowedToStartNewConversations.contains(_currentUserRole))
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
                      children: [
                        EmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: l10n.chatNoConversationsYetTitle,
                          description: l10n.chatTapPencilToMessage,
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.chatArchivedChatsTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _conversations.isEmpty
              ? EmptyState(
                  icon: Icons.archive_outlined,
                  title: l10n.chatNoArchivedChatsTitle,
                  description: l10n.chatArchivedConversationsDescription,
                )
              : ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
                  itemBuilder: (_, i) {
                    final convo = _conversations[i];
                    final other = convo['other_profile'] as Map<String, dynamic>?;
                    final name =
                        (other?['full_name'] as String?)?.isNotEmpty == true ? other!['full_name'] as String : l10n.chatUnknownUser;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: nameColor(name).withOpacity(0.15),
                        child: Text(logoLetter(name),
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: nameColor(name))),
                      ),
                      title: Text(name),
                      trailing: TextButton(onPressed: () => _unarchive(convo), child: Text(l10n.chatUnarchiveAction)),
                    );
                  },
                ),
    );
  }
}

String _roleLabel(AppLocalizations l10n, String role) {
  switch (role) {
    case 'student':
      return l10n.chatRoleStudent;
    case 'academic_supervisor':
      return l10n.academicSupervisor;
    case 'company_hr':
      return l10n.hrPersonnelLabel;
    case 'company_supervisor':
      return l10n.companySupervisor;
    case 'parent':
      return l10n.parentGuardian;
    default:
      return role;
  }
}

String _previewText(AppLocalizations l10n, Map<String, dynamic>? lastMessage) {
  if (lastMessage == null) return '';
  final body = lastMessage['body'] as String?;
  if (body != null && body.isNotEmpty) return body;
  final attachmentName = lastMessage['attachment_file_name'] as String?;
  if (attachmentName != null) return _isImage(attachmentName) ? l10n.chatPhotoAttachmentPreview : '📎 $attachmentName';
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
    final l10n = AppLocalizations.of(context)!;
    final other = data['other_profile'] as Map<String, dynamic>?;
    final name = (other?['full_name'] as String?)?.isNotEmpty == true ? other!['full_name'] as String : l10n.chatUnknownUser;
    final role = other != null ? _roleLabel(l10n, other['role'] as String) : '';
    final lastMessage = data['last_message'] as Map<String, dynamic>?;
    final unreadCount = data['unread_count'] as int;
    final hasUnread = unreadCount > 0;
    final preview = _previewText(l10n, lastMessage);

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
            Text(timeAgo(context, DateTime.parse(lastMessage['created_at'] as String)),
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
              PopupMenuItem(value: 'archive', child: Text(l10n.chatArchiveAction)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete, style: TextStyle(color: AppColors.error))),
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
  final List<Map<String, dynamic>> _pendingMessages = [];
  bool _isSending = false;
  bool _isAttaching = false;

  List<Map<String, dynamic>> _visibleMessages(List<Map<String, dynamic>> rows) {
    return rows.where((m) => !((m['deleted_for'] as List?)?.contains(_myId) ?? false)).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
    StudentDataService.instance.messagesStream(widget.conversationId).listen((rows) {
      if (!mounted) return;
      final confirmedIds = rows.map((r) => r['id']).toSet();
      setState(() {
        _messages = _visibleMessages(rows);
        _pendingMessages.removeWhere((p) => confirmedIds.contains(p['id']));
      });
      _scrollToBottom();
      StudentDataService.instance.markConversationRead(widget.conversationId);
    });
  }

  Future<void> _load() async {
    try {
      final messages = await StudentDataService.instance.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = _visibleMessages(messages);
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

    final localId = _generateLocalMessageId();
    setState(() {
      _pendingMessages.add({
        'id': localId,
        'conversation_id': widget.conversationId,
        'sender_id': _myId,
        'body': text,
        'created_at': DateTime.now().toIso8601String(),
        'read_at': null,
        'attachment_path': null,
        'attachment_file_name': null,
      });
    });
    _scrollToBottom();

    try {
      await StudentDataService.instance.sendMessage(conversationId: widget.conversationId, body: text, clientMessageId: localId);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _pendingMessages.removeWhere((p) => p['id'] == localId));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.chatCouldNotSendMessage(e.toString())), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _attachFile() async {
    final l10n = AppLocalizations.of(context)!;
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
          .showSnackBar(SnackBar(content: Text(l10n.chatFileTooLarge), backgroundColor: AppColors.error));
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
          .showSnackBar(SnackBar(content: Text(l10n.chatCouldNotSendAttachment(e.toString())), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isAttaching = false);
    }
  }

  bool _isWithinEditWindow(Map<String, dynamic> message) {
    final createdAt = DateTime.parse(message['created_at'] as String);
    return DateTime.now().difference(createdAt) <= const Duration(minutes: 15);
  }

  Future<void> _showMessageActions(Map<String, dynamic> message) async {
    final l10n = AppLocalizations.of(context)!;
    final isMine = message['sender_id'] == _myId;
    final body = message['body'] as String?;
    final canEdit = isMine && body != null && body.isNotEmpty && _isWithinEditWindow(message);

    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.edit),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: Text(l10n.chatDeleteForMeAction),
              onTap: () => Navigator.pop(context, 'delete_for_me'),
            ),
            if (isMine)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(l10n.chatDeleteForEveryoneAction, style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(context, 'delete_for_everyone'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _editMessage(message);
    } else if (action == 'delete_for_me') {
      await _deleteMessageForMe(message);
    } else if (action == 'delete_for_everyone') {
      await _deleteMessage(message);
    }
  }

  Future<void> _deleteMessageForMe(Map<String, dynamic> message) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.chatDeleteForMeTitle),
        content: Text(l10n.chatDeleteForMeMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await StudentDataService.instance.deleteMessageForMe(message['id'] as String);
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m['id'] == message['id']));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.chatCouldNotDeleteMessage(e.toString())), backgroundColor: AppColors.error));
    }
  }

  Future<void> _editMessage(Map<String, dynamic> message) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: message['body'] as String);
    final newText = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.chatEditMessageTitle),
        content: TextField(controller: controller, autofocus: true, maxLines: 4, minLines: 1),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newText == null || newText.isEmpty || !mounted) return;
    try {
      await StudentDataService.instance.editMessage(message['id'] as String, newText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.chatCouldNotEditMessage(e.toString())), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.chatDeleteMessageTitle),
        content: Text(l10n.chatCannotBeUndone),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
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
          .showSnackBar(SnackBar(content: Text(l10n.chatCouldNotDeleteMessage(e.toString())), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = (widget.otherProfile['full_name'] as String?)?.isNotEmpty == true
        ? widget.otherProfile['full_name'] as String
        : l10n.chatUnknownUser;
    final roleValue = widget.otherProfile['role'] as String?;
    final role = roleValue != null ? _roleLabel(l10n, roleValue) : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: InkWell(
          onTap: () async {
            final deleted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => _ContactInfoScreen(conversationId: widget.conversationId, otherProfile: widget.otherProfile),
              ),
            );
            if (deleted == true && mounted) Navigator.pop(context);
          },
          child: Row(
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
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : (_messages.isEmpty && _pendingMessages.isEmpty)
                    ? Center(
                        child: Text(l10n.chatSayHello, style: TextStyle(fontFamily: 'Inter', color: AppColors.textMuted)),
                      )
                    : Builder(builder: (_) {
                        final allMessages = [..._messages, ..._pendingMessages];
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: allMessages.length,
                          itemBuilder: (_, i) {
                            final message = allMessages[i];
                            final isMine = message['sender_id'] == _myId;
                            final isPending = i >= _messages.length;
                            return _MessageBubble(
                              data: message,
                              isMine: isMine,
                              isPending: isPending,
                              onLongPress: !isPending ? () => _showMessageActions(message) : null,
                            );
                          },
                        );
                      }),
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
                    decoration: InputDecoration(
                      hintText: l10n.chatTypeMessageHint,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
  final bool isPending;
  final VoidCallback? onLongPress;

  const _MessageBubble({required this.data, required this.isMine, required this.isPending, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    Text(censorProfanity(body), style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isMine ? Colors.white : AppColors.textPrimary)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data['edited_at'] != null) ...[
                        Text(l10n.chatEditedLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: isMine ? Colors.white60 : AppColors.textMuted)),
                        const SizedBox(width: 4),
                      ],
                      Text(timeLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: isMine ? Colors.white60 : AppColors.textMuted)),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isPending ? Icons.done : Icons.done_all,
                          size: 12,
                          color: (!isPending && data['read_at'] != null) ? Colors.white : Colors.white60,
                        ),
                      ],
                    ],
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
        final l10n = AppLocalizations.of(context)!;
        if (!snapshot.hasData) {
          return const SizedBox(width: 120, height: 90, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final url = snapshot.data!;
        if (_isImage(fileName)) {
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName ?? l10n.chatAttachmentFallbackName),
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
            builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName ?? l10n.chatAttachmentFallbackName),
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
                  child: Text(fileName ?? l10n.chatAttachmentFallbackName,
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

class _ContactInfoScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherProfile;

  const _ContactInfoScreen({required this.conversationId, required this.otherProfile});

  @override
  State<_ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<_ContactInfoScreen> {
  bool _isLoading = true;
  String? _phone;
  List<Map<String, dynamic>> _sharedMedia = [];
  bool _muted = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final otherId = widget.otherProfile['id'] as String;
      final contactInfo = await StudentDataService.instance.getChatContactInfo(otherId);
      final media = await StudentDataService.instance.getSharedMedia(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _phone = contactInfo?['phone'] as String?;
        _sharedMedia = media;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMute(bool value) async {
    setState(() => _muted = value);
    try {
      await StudentDataService.instance.setConversationMuted(widget.conversationId, value);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _muted = !value);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.chatCouldNotUpdateMute(e.toString())), backgroundColor: AppColors.error));
    }
  }

  Future<void> _toggleBlock(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(value ? l10n.chatBlockContactTitle : l10n.chatUnblockContactTitle),
        content: Text(value ? l10n.chatBlockContactMessage : l10n.chatUnblockContactMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(value ? l10n.chatBlockAction : l10n.chatUnblockAction)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _blocked = value);
    try {
      await StudentDataService.instance.setConversationBlocked(widget.conversationId, value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _blocked = !value);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.chatCouldNotUpdateBlock(e.toString())), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteConversation() async {
    final l10n = AppLocalizations.of(context)!;
    final name = (widget.otherProfile['full_name'] as String?)?.isNotEmpty == true
        ? widget.otherProfile['full_name'] as String
        : l10n.chatConversationFallbackName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.chatDeleteConversationTitle),
        content: Text(l10n.chatDeleteConversationMessage(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete, style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await StudentDataService.instance.deleteConversation(widget.conversationId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.chatCouldNotDeleteConversation(e.toString())), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = (widget.otherProfile['full_name'] as String?)?.isNotEmpty == true
        ? widget.otherProfile['full_name'] as String
        : l10n.chatUnknownUser;
    final roleValue = widget.otherProfile['role'] as String?;
    final role = roleValue != null ? _roleLabel(l10n, roleValue) : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.chatContactInfoTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: nameColor(name).withOpacity(0.2),
                        child: Text(logoLetter(name), style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: nameColor(name))),
                      ),
                      const SizedBox(height: 10),
                      Text(name, style: AppTextStyles.h2),
                      Text(role, style: AppTextStyles.bodySecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.phone, style: AppTextStyles.label),
                const SizedBox(height: 8),
                Text(_phone?.isNotEmpty == true ? _phone! : l10n.chatPhoneNotAvailable, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Text(l10n.chatSharedMediaFiles, style: AppTextStyles.label),
                const SizedBox(height: 8),
                if (_sharedMedia.isEmpty)
                  Text(l10n.chatNoSharedMediaYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
                else
                  ..._sharedMedia.map((m) {
                    final fileName = (m['attachment_file_name'] as String?) ?? (m['attachment_path'] as String).split('/').last;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_isImage(fileName) ? Icons.image_outlined : Icons.insert_drive_file_outlined, color: AppColors.primary),
                      title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () async {
                        final url = await StudentDataService.instance.getChatAttachmentSignedUrl(m['attachment_path'] as String);
                        if (!mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName)));
                      },
                    );
                  }),
                const SizedBox(height: 24),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.chatMuteNotifications),
                  value: _muted,
                  onChanged: _toggleMute,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.chatBlockContactToggle),
                  value: _blocked,
                  onChanged: _toggleBlock,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleteConversation,
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    label: Text(l10n.chatDeleteConversationButton, style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
    );
  }
}
