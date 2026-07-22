import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white24,
                          child: Text('TK',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Tan Kai Ming',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Text('22CSB12345 · Bachelor of Computer Science',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Status card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Currently on internship',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            Text('Tencent Malaysia · Jun – Aug 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                      StatusBadge.active(),
                    ],
                  ),
                ),

                // Personal info
                const SectionHeader(title: 'Personal information'),
                _InfoSection(
                  items: const [
                    _InfoItem(icon: Icons.person_outline, label: 'Full name', value: 'Tan Kai Ming'),
                    _InfoItem(icon: Icons.badge_outlined, label: 'Student ID', value: '22CSB12345'),
                    _InfoItem(icon: Icons.phone_outlined, label: 'Phone', value: '+60 12-345 6789'),
                    _InfoItem(icon: Icons.email_outlined, label: 'Email', value: 'tankai@student.tarumt.edu.my'),
                    _InfoItem(icon: Icons.cake_outlined, label: 'Date of birth', value: '15 Mar 2002'),
                    _InfoItem(icon: Icons.location_on_outlined, label: 'Address', value: 'Kuala Lumpur, Malaysia'),
                  ],
                ),

                // Academic info
                const SectionHeader(title: 'Academic information'),
                _InfoSection(
                  items: const [
                    _InfoItem(icon: Icons.school_outlined, label: 'Programme', value: 'Bachelor of Computer Science (Hons)'),
                    _InfoItem(icon: Icons.calendar_today_outlined, label: 'Semester', value: 'Semester 6'),
                    _InfoItem(icon: Icons.class_outlined, label: 'Faculty', value: 'Faculty of Computing and Information Technology'),
                    _InfoItem(icon: Icons.grade_outlined, label: 'CGPA', value: '3.62'),
                    _InfoItem(icon: Icons.person_pin_outlined, label: 'Academic Supervisor', value: 'Dr. Lim Wei Shan'),
                  ],
                ),

                // Resume
                const SectionHeader(title: 'Resume'),
                AccentCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.picture_as_pdf_outlined,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('tankai_resume_2026.pdf',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('312 KB · Updated 30 May 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Replace'),
                      ),
                    ],
                  ),
                ),

                // Settings
                const SectionHeader(title: 'Account'),
                _SettingsTile(
                    icon: Icons.lock_outline,
                    label: 'Change password',
                    onTap: () {}),
                _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notification preferences',
                    onTap: () {}),
                _SettingsTile(
                    icon: Icons.language_outlined,
                    label: 'Language',
                    trailing: 'English',
                    onTap: () {}),
                _SettingsTile(
                    icon: Icons.logout,
                    label: 'Log out',
                    isDestructive: true,
                    onTap: () {}),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(item.value,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 44),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 20, color: isDestructive ? AppColors.error : AppColors.textSecondary),
        title: Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color)),
        trailing: trailing != null
            ? Text(trailing!,
                style: AppTextStyles.caption)
            : Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
