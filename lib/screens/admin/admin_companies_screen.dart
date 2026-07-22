import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _companies = [
    {
      'name': 'Tencent Malaysia Sdn. Bhd.',
      'industry': 'Technology',
      'location': 'Kuala Lumpur',
      'activeInterns': 8,
      'totalPostings': 3,
      'status': 'Verified',
      'logo': 'T',
      'logoColor': Color(0xFF00A3FF),
    },
    {
      'name': 'Grab Holdings',
      'industry': 'Technology',
      'location': 'Petaling Jaya',
      'activeInterns': 12,
      'totalPostings': 5,
      'status': 'Verified',
      'logo': 'G',
      'logoColor': Color(0xFF00B14F),
    },
    {
      'name': 'ByteDance Malaysia',
      'industry': 'Technology',
      'location': 'Kuala Lumpur',
      'activeInterns': 0,
      'totalPostings': 1,
      'status': 'Pending',
      'logo': 'B',
      'logoColor': Color(0xFF000000),
    },
    {
      'name': 'Maxis Berhad',
      'industry': 'Telecommunications',
      'location': 'Kuala Lumpur',
      'activeInterns': 4,
      'totalPostings': 2,
      'status': 'Verified',
      'logo': 'M',
      'logoColor': Color(0xFFE30613),
    },
    {
      'name': 'CIMB Bank',
      'industry': 'Banking & Finance',
      'location': 'Kuala Lumpur',
      'activeInterns': 6,
      'totalPostings': 4,
      'status': 'Verified',
      'logo': 'C',
      'logoColor': Color(0xFF8B0000),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Companies',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _AddEditCompanyScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text('${_companies.length} registered companies', style: AppTextStyles.caption),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('1 pending verification',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _companies.length,
              itemBuilder: (_, i) => _CompanyCard(
                data: _companies[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _CompanyDetailScreen(data: _companies[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const _AddEditCompanyScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _CompanyCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPending = data['status'] == 'Pending';
    return AccentCard(
      onTap: onTap,
      accentColor: isPending ? AppColors.warning : AppColors.success,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (data['logoColor'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(data['logo'],
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: data['logoColor'])),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'],
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text('${data['industry']} · ${data['location']}',
                    style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text('${data['activeInterns']} interns',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 10),
                    Icon(Icons.work_outline, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text('${data['totalPostings']} postings',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          isPending
              ? const StatusBadge(
                  label: 'Pending', backgroundColor: Color(0xFFFEF3C7), textColor: Color(0xFFD97706))
              : const StatusBadge(
                  label: 'Verified', backgroundColor: Color(0xFFE2F6EF), textColor: Color(0xFF1A9E6E)),
        ],
      ),
    );
  }
}

class _CompanyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CompanyDetailScreen({required this.data});

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
        title: const Text('Company details',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => _AddEditCompanyScreen(company: data))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (data['logoColor'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(data['logo'],
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: data['logoColor'])),
                  ),
                ),
                const SizedBox(height: 10),
                Text(data['name'], style: AppTextStyles.h2, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(data['industry'], style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Active interns',
                  value: '${data['activeInterns']}',
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  label: 'Job postings',
                  value: '${data['totalPostings']}',
                  icon: Icons.work_outline,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Company information', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: data['location']),
                const Divider(height: 1, indent: 44),
                const _DetailRow(icon: Icons.email_outlined, label: 'HR Contact', value: 'hr@company.com'),
                const Divider(height: 1, indent: 44),
                const _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: '+60 3-1234 5678'),
                const Divider(height: 1, indent: 44),
                _DetailRow(
                  icon: Icons.verified_outlined,
                  label: 'Status',
                  value: data['status'],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (data['status'] == 'Pending')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Verify company'),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              label: const Text('Remove company', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddEditCompanyScreen extends StatefulWidget {
  final Map<String, dynamic>? company;

  const _AddEditCompanyScreen({this.company});

  @override
  State<_AddEditCompanyScreen> createState() => _AddEditCompanyScreenState();
}

class _AddEditCompanyScreenState extends State<_AddEditCompanyScreen> {
  late bool isEdit;

  @override
  void initState() {
    super.initState();
    isEdit = widget.company != null;
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
        title: Text(isEdit ? 'Edit Company' : 'Add Company',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Company information', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.company?['name'] ?? '',
              decoration: const InputDecoration(labelText: 'Company name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Industry'),
              value: widget.company?['industry'],
              items: [
                'Technology',
                'Banking & Finance',
                'Telecommunications',
                'Manufacturing',
                'Retail & E-commerce',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.company?['location'] ?? '',
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'Company address', hintText: 'Full registered address'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            const Text('HR contact', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(labelText: 'HR contact name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'HR email'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'HR phone number'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isEdit ? 'Save changes' : 'Add company'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
