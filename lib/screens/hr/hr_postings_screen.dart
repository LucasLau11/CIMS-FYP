import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class HrPostingsScreen extends StatefulWidget {
  const HrPostingsScreen({super.key});

  @override
  State<HrPostingsScreen> createState() => _HrPostingsScreenState();
}

class _HrPostingsScreenState extends State<HrPostingsScreen> {
  final List<Map<String, dynamic>> _postings = [
    {
      'title': 'Software Engineering Intern',
      'location': 'Kuala Lumpur',
      'duration': '3 months',
      'allowance': 'RM 1,500/month',
      'applicants': 12,
      'status': 'Active',
      'postedDate': '15 May 2026',
    },
    {
      'title': 'Mobile App Development Intern',
      'location': 'Kuala Lumpur',
      'duration': '4 months',
      'allowance': 'RM 1,600/month',
      'applicants': 8,
      'status': 'Active',
      'postedDate': '1 Jun 2026',
    },
    {
      'title': 'QA Engineering Intern',
      'location': 'Cyberjaya',
      'duration': '3 months',
      'allowance': 'RM 1,400/month',
      'applicants': 5,
      'status': 'Active',
      'postedDate': '10 Jun 2026',
    },
    {
      'title': 'Data Analyst Intern',
      'location': 'Kuala Lumpur',
      'duration': '6 months',
      'allowance': 'RM 1,800/month',
      'applicants': 21,
      'status': 'Closed',
      'postedDate': '1 Mar 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Job postings',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const _AddEditPostingScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('${_postings.length} postings', style: AppTextStyles.caption),
                const Spacer(),
                Text(
                    '${_postings.where((p) => p['status'] == 'Active').length} active',
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _postings.length,
              itemBuilder: (_, i) => _PostingCard(
                data: _postings[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _AddEditPostingScreen(posting: _postings[i])),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const _AddEditPostingScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PostingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _PostingCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = data['status'] == 'Active';
    return AccentCard(
      onTap: onTap,
      accentColor: isActive ? AppColors.success : AppColors.textMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data['title'],
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              isActive
                  ? StatusBadge.active()
                  : const StatusBadge(label: 'Closed', backgroundColor: Color(0xFFF1EFE8), textColor: Color(0xFF5F5E5A)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(data['location'], style: AppTextStyles.caption),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(data['duration'], style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.attach_money, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 1),
              Text(data['allowance'], style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                child: Text('${data['applicants']} applicants',
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
              const Spacer(),
              Text('Posted ${data['postedDate']}', style: AppTextStyles.caption),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                onSelected: (_) {},
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'close', child: Text('Close posting')),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddEditPostingScreen extends StatefulWidget {
  final Map<String, dynamic>? posting;

  const _AddEditPostingScreen({this.posting});

  @override
  State<_AddEditPostingScreen> createState() => _AddEditPostingScreenState();
}

class _AddEditPostingScreenState extends State<_AddEditPostingScreen> {
  late bool isEdit;

  @override
  void initState() {
    super.initState();
    isEdit = widget.posting != null;
  }

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
        title: Text(isEdit ? 'Edit posting' : 'New posting',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Posting details', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.posting?['title'] ?? '',
              decoration: const InputDecoration(labelText: 'Job title', hintText: 'e.g. Software Engineering Intern'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'Job description', hintText: 'Describe the role and responsibilities'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'Requirements', hintText: 'Skills, qualifications, etc.'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text('Logistics', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.posting?['location'] ?? '',
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Duration'),
              value: widget.posting?['duration'],
              items: ['3 months', '4 months', '6 months']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.posting?['allowance'] ?? '',
              decoration: const InputDecoration(labelText: 'Monthly allowance', hintText: 'e.g. RM 1,500'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'Number of vacancies', hintText: 'e.g. 3'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text('Skills required', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Flutter', 'Dart', 'Firebase', 'Python', 'SQL', '+ Add']
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: s == '+ Add' ? AppColors.surface : AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: s == '+ Add' ? AppColors.border : AppColors.primaryLight),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: s == '+ Add' ? AppColors.textSecondary : AppColors.primary,
                                fontWeight: s == '+ Add' ? FontWeight.w400 : FontWeight.w600)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isEdit ? 'Save changes' : 'Publish posting'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete posting?', style: AppTextStyles.h3),
        content: const Text(
          'This will permanently remove this job posting. Existing applications will be retained for records.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
