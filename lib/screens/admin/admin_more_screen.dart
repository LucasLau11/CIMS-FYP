import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import 'admin_monitor_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'More'),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          // Admin profile summary
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Administrator',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('admin@tarumt.edu.my',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              ],
            ),
          ),

          const SectionHeader(title: 'Oversight'),
          _MenuTile(
            icon: Icons.monitor_heart_outlined,
            label: 'Monitor',
            subtitle: 'Student progress, reports & documents',
            color: AppColors.primary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminMonitorScreen())),
          ),
          _MenuTile(
            icon: Icons.upload_file_outlined,
            label: 'Upload Forms Template',
            subtitle: 'Manage official document templates',
            color: AppColors.primaryLight,
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.assessment_outlined,
            label: 'Evaluate Student',
            subtitle: 'Assess overall student performance',
            color: AppColors.success,
            onTap: () {},
          ),

          const SectionHeader(title: 'Communication'),
          _MenuTile(
            icon: Icons.send_outlined,
            label: 'Send Messages',
            subtitle: 'Message students, supervisors, or companies',
            color: AppColors.primary,
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            subtitle: 'View system alerts and updates',
            color: AppColors.warning,
            badge: '5',
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.campaign_outlined,
            label: 'Broadcast Announcement',
            subtitle: 'Send announcement to all users',
            color: AppColors.primaryLight,
            onTap: () {},
          ),

          const SectionHeader(title: 'System'),
          _MenuTile(
            icon: Icons.bar_chart_outlined,
            label: 'Reports & Analytics',
            subtitle: 'System usage and performance reports',
            color: AppColors.primary,
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: 'System Settings',
            subtitle: 'Configure application preferences',
            color: AppColors.textSecondary,
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.logout,
            label: 'Log out',
            subtitle: null,
            color: AppColors.error,
            isDestructive: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final String? badge;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    this.badge,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        title: Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? AppColors.error : AppColors.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AppTextStyles.caption)
            : null,
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                child: Text(badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              )
            : const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
