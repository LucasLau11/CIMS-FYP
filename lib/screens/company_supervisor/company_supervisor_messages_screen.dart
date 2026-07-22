import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class CompanySupervisorMessagesScreen extends StatefulWidget {
  const CompanySupervisorMessagesScreen({super.key});

  @override
  State<CompanySupervisorMessagesScreen> createState() =>
      _CompanySupervisorMessagesScreenState();
}

class _CompanySupervisorMessagesScreenState
    extends State<CompanySupervisorMessagesScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Tan Kai Ming',
      'role': 'Intern · Software Engineering',
      'lastMessage': 'I have completed the sprint tasks for this week.',
      'time': '10:15 AM',
      'unread': 2,
      'initials': 'TK',
      'avatarColor': Color(0xFF0F7E8A),
      'online': true,
    },
    {
      'name': 'Chong Wei Liang',
      'role': 'Intern · Software Engineering',
      'lastMessage': 'Sorry, I will be late tomorrow morning.',
      'time': '9:02 AM',
      'unread': 1,
      'initials': 'CW',
      'avatarColor': Color(0xFFD97706),
      'online': false,
    },
    {
      'name': 'Dr. Lim Wei Shan',
      'role': 'Academic Supervisor · TARUMT',
      'lastMessage': 'Please send me Tan Kai\'s latest progress report.',
      'time': 'Yesterday',
      'unread': 0,
      'initials': 'LW',
      'avatarColor': Color(0xFF1A9E6E),
      'online': false,
    },
    {
      'name': 'Sarah Tan (HR)',
      'role': 'HR · Tencent Malaysia',
      'lastMessage': 'New intern Rajesh starts Monday. Please brief him.',
      'time': 'Yesterday',
      'unread': 0,
      'initials': 'ST',
      'avatarColor': Color(0xFF00A3FF),
      'online': true,
    },
    {
      'name': 'Nur Sabrina',
      'role': 'Intern · QA Engineering',
      'lastMessage': 'Thank you for the feedback on my report!',
      'time': 'Mon',
      'unread': 0,
      'initials': 'NS',
      'avatarColor': Color(0xFF14B8C8),
      'online': false,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchController.text.isEmpty) return _conversations;
    final q = _searchController.text.toLowerCase();
    return _conversations
        .where((c) =>
            c['name'].toLowerCase().contains(q) ||
            c['role'].toLowerCase().contains(q))
        .toList();
  }

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
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon:
                    Icon(Icons.search, size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No conversations found',
                    description: 'Try a different search term.',
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72, endIndent: 16),
                    itemBuilder: (_, i) =>
                        _ConversationTile(data: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ConversationTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasUnread = (data['unread'] as int) > 0;

    return ListTile(
      onTap: () {},
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                (data['avatarColor'] as Color).withOpacity(0.15),
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
                  color:
                      hasUnread ? AppColors.primary : AppColors.textMuted,
                  fontWeight: hasUnread
                      ? FontWeight.w600
                      : FontWeight.w400)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['role'],
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
          Row(
            children: [
              Expanded(
                child: Text(data['lastMessage'],
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
                    overflow: TextOverflow.ellipsis),
              ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle),
                  child: Text('${data['unread']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
