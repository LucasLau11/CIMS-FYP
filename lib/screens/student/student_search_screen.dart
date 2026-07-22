import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import 'student_apply_screen.dart';

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All', 'Software', 'Data', 'Design', 'Network', 'Business'
  ];

  final List<Map<String, dynamic>> _internships = [
    {
      'company': 'Tencent Malaysia',
      'role': 'Software Engineering Intern',
      'location': 'Kuala Lumpur',
      'duration': '3 months',
      'allowance': 'RM 1,500/month',
      'tags': ['Flutter', 'Dart', 'Firebase'],
      'logo': 'T',
      'logoColor': Color(0xFF00A3FF),
      'matched': 94,
      'posted': '2 days ago',
    },
    {
      'company': 'Grab',
      'role': 'Data Science Intern',
      'location': 'Petaling Jaya',
      'duration': '6 months',
      'allowance': 'RM 2,000/month',
      'tags': ['Python', 'SQL', 'ML'],
      'logo': 'G',
      'logoColor': Color(0xFF00B14F),
      'matched': 88,
      'posted': '1 week ago',
    },
    {
      'company': 'Maxis Berhad',
      'role': 'Network Engineering Intern',
      'location': 'Kuala Lumpur',
      'duration': '4 months',
      'allowance': 'RM 1,200/month',
      'tags': ['Networking', 'Cisco', 'Linux'],
      'logo': 'M',
      'logoColor': Color(0xFFE30613),
      'matched': 76,
      'posted': '3 days ago',
    },
    {
      'company': 'Shopee',
      'role': 'UI/UX Design Intern',
      'location': 'Shah Alam',
      'duration': '3 months',
      'allowance': 'RM 1,800/month',
      'tags': ['Figma', 'UI Design', 'Research'],
      'logo': 'S',
      'logoColor': Color(0xFFEE4D2D),
      'matched': 71,
      'posted': '5 days ago',
    },
    {
      'company': 'CIMB Bank',
      'role': 'IT Business Analyst Intern',
      'location': 'Kuala Lumpur',
      'duration': '4 months',
      'allowance': 'RM 1,000/month',
      'tags': ['Analysis', 'SQL', 'Excel'],
      'logo': 'C',
      'logoColor': Color(0xFF8B0000),
      'matched': 65,
      'posted': '1 week ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Search internships',
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by role, company, or skill...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _selectedCategory == _categories[i];
                return FilterChip(
                  label: Text(_categories[i]),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = _categories[i]),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accent,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_internships.length} opportunities found',
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                // AI match badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('AI matched',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Listing
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _internships.length,
              itemBuilder: (_, i) => _InternshipCard(
                data: _internships[i],
                onApply: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentApplyScreen(internship: _internships[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _InternshipCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onApply;

  const _InternshipCard({required this.data, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final matchPct = data['matched'] as int;
    final matchColor = matchPct >= 90
        ? AppColors.success
        : matchPct >= 75
            ? AppColors.primary
            : AppColors.warning;

    return AccentCard(
      onTap: onApply,
      accentColor: matchColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Company logo circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (data['logoColor'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    data['logo'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: data['logoColor'] as Color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['role'],
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(data['company'],
                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              // Match score
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: matchColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$matchPct%',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: matchColor)),
                  ),
                  const SizedBox(height: 2),
                  Text('match',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: matchColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Details row
          Row(
            children: [
              _InfoChip(icon: Icons.location_on_outlined, label: data['location']),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.schedule, label: data['duration']),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.attach_money, label: data['allowance']),
            ],
          ),
          const SizedBox(height: 10),
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (data['tags'] as List<String>).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(tag,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(data['posted'],
                  style: AppTextStyles.caption),
              const Spacer(),
              ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Apply', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Filters', style: AppTextStyles.h3),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Reset', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Location', style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(),
            value: 'All',
            items: ['All', 'Kuala Lumpur', 'Petaling Jaya', 'Shah Alam', 'Cyberjaya']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          const Text('Allowance range', style: AppTextStyles.label),
          const SizedBox(height: 8),
          RangeSlider(
            values: const RangeValues(800, 2500),
            min: 0,
            max: 5000,
            divisions: 50,
            labels: const RangeLabels('RM 800', 'RM 2,500'),
            activeColor: AppColors.primary,
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          const Text('Duration', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['3 months', '4 months', '6 months']
                .map((d) => FilterChip(label: Text(d), onSelected: (_) {}))
                .toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply filters'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
