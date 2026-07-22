import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class SupervisorMessagesScreen extends StatefulWidget {
  const SupervisorMessagesScreen({super.key});

  @override
  State<SupervisorMessagesScreen> createState() => _SupervisorMessagesScreenState();
}

class _SupervisorMessagesScreenState extends State<SupervisorMessagesScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Tan Kai Ming',
      'role': 'Student · 22CSB12345',
      'lastMessage': 'Noted! I will have it ready by 28 June.',
      'time': '10:47 AM',
      'unread': 0,
      'initials': 'TK',
      'avatarColor': Color(0xFF0F7E8A),
      'online': true,
    },
    {
      'name': 'Priya Devi',
      'role': 'Student · 22CSB09988',
      'lastMessage': 'I am facing some delays with my report, can we discuss?',
      'time': '9:15 AM',
      'unread': 3,
      'initials': 'PD',
      'avatarColor': Color(0xFFD97706),
      'online': true,
    },
    {
      'name': 'Admin Office',
      'role': 'TARUMT',
      'lastMessage': 'Please complete pending evaluations by 10 Jul.',
      'time': 'Yesterday',
      'unread': 1,
      'initials': 'AD',
      'avatarColor': Color(0xFF8B0000),
      'online': false,
    },
    {
      'name': 'Ahmad Hafiz',
      'role': 'Student · 22CSB11223',
      'lastMessage': 'Thank you for the feedback on my last report!',
      'time': 'Mon',
      'unread': 0,
      'initials': 'AH',
      'avatarColor': Color(0xFF1A9E6E),
      'online': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'Messages'),
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
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (_, i) => _ConversationTile(data: _conversations[i]),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (data['avatarColor'] as Color).withOpacity(0.15),
            child: Text(data['initials'],
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: data['avatarColor'])),
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
                    fontFamily: 'Inter', fontSize: 14, fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500, color: AppColors.textPrimary)),
          ),
          Text(data['time'],
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: hasUnread ? AppColors.primary : AppColors.textMuted,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['role'], style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
          Row(
            children: [
              Expanded(
                child: Text(
                  data['lastMessage'],
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
                  child: Text('${data['unread']}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
