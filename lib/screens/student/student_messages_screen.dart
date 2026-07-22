import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class StudentMessagesScreen extends StatefulWidget {
  const StudentMessagesScreen({super.key});

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Dr. Lim Wei Shan',
      'role': 'Academic Supervisor',
      'lastMessage': 'Please submit your June report by end of month.',
      'time': '10:45 AM',
      'unread': 2,
      'initials': 'LW',
      'avatarColor': Color(0xFF0F7E8A),
      'online': true,
    },
    {
      'name': 'Sarah Tan (HR)',
      'role': 'Tencent Malaysia',
      'lastMessage': 'Your onboarding documents have been approved.',
      'time': 'Yesterday',
      'unread': 0,
      'initials': 'ST',
      'avatarColor': Color(0xFF00A3FF),
      'online': false,
    },
    {
      'name': 'Ahmad Faris',
      'role': 'Company Supervisor',
      'lastMessage': 'Good work on the sprint. See you tomorrow.',
      'time': 'Yesterday',
      'unread': 0,
      'initials': 'AF',
      'avatarColor': Color(0xFF1A9E6E),
      'online': true,
    },
    {
      'name': 'Admin Office',
      'role': 'TARUMT',
      'lastMessage': 'Reminder: LI01 form must be submitted by 10 Jul.',
      'time': 'Mon',
      'unread': 1,
      'initials': 'AD',
      'avatarColor': Color(0xFF8B0000),
      'online': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Messages',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _conversations.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
              ),
              itemBuilder: (_, i) => _ConversationTile(
                data: _conversations[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _ChatScreen(contact: _conversations[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ConversationTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = (data['unread'] as int) > 0;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (data['avatarColor'] as Color).withOpacity(0.15),
            child: Text(data['initials'],
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: data['avatarColor'])),
          ),
          if (data['online'] == true)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(data['name'],
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight:
                        hasUnread ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
          Text(data['time'],
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: hasUnread
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontWeight: hasUnread
                      ? FontWeight.w600
                      : FontWeight.w400)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              data['lastMessage'],
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: hasUnread
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontWeight: hasUnread
                      ? FontWeight.w500
                      : FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${data['unread']}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const _ChatScreen({required this.contact});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hi Tan Kai, how is your internship going?',
      'isMine': false,
      'time': '10:30 AM',
    },
    {
      'text': 'It\'s going well! I have been learning a lot about mobile development.',
      'isMine': true,
      'time': '10:32 AM',
    },
    {
      'text': 'Great to hear. Don\'t forget your monthly report is due end of this month.',
      'isMine': false,
      'time': '10:40 AM',
    },
    {
      'text': 'Please submit your June report by end of month.',
      'isMine': false,
      'time': '10:45 AM',
    },
    {
      'text': 'Noted! I will have it ready by 28 June.',
      'isMine': true,
      'time': '10:47 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  (widget.contact['avatarColor'] as Color).withOpacity(0.2),
              child: Text(widget.contact['initials'],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.contact['avatarColor'])),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contact['name'],
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text(widget.contact['role'],
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _MessageBubble(data: _messages[i]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file,
                      color: AppColors.textMuted, size: 22),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
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

  const _MessageBubble({required this.data});

  @override
  Widget build(BuildContext context) {
    final isMine = data['isMine'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
              border:
                  isMine ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(data['text'],
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: isMine ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(data['time'],
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: isMine
                            ? Colors.white60
                            : AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
