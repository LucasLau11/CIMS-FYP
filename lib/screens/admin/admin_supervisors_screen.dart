import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class AdminSupervisorsScreen extends StatefulWidget {
  const AdminSupervisorsScreen({super.key});

  @override
  State<AdminSupervisorsScreen> createState() => _AdminSupervisorsScreenState();
}

class _AdminSupervisorsScreenState extends State<AdminSupervisorsScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _supervisors = [
    {
      'name': 'Dr. Lim Wei Shan',
      'staffId': 'STF0012',
      'faculty': 'Faculty of Computing and IT',
      'studentCount': 12,
      'initials': 'LW',
      'email': 'limws@tarumt.edu.my',
    },
    {
      'name': 'Dr. Wong Chee Keong',
      'staffId': 'STF0034',
      'faculty': 'Faculty of Computing and IT',
      'studentCount': 9,
      'initials': 'WC',
      'email': 'wongck@tarumt.edu.my',
    },
    {
      'name': 'Dr. Tan Soo Beng',
      'staffId': 'STF0056',
      'faculty': 'Faculty of Engineering',
      'studentCount': 15,
      'initials': 'TS',
      'email': 'tansb@tarumt.edu.my',
    },
    {
      'name': 'Dr. Nurul Aisyah',
      'staffId': 'STF0078',
      'faculty': 'Faculty of Computing and IT',
      'studentCount': 7,
      'initials': 'NA',
      'email': 'nurula@tarumt.edu.my',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Supervisors',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _AddEditSupervisorScreen())),
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
                hintText: 'Search supervisors...',
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_supervisors.length} academic supervisors', style: AppTextStyles.caption),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 6, bottom: 80),
              itemCount: _supervisors.length,
              itemBuilder: (_, i) => _SupervisorCard(data: _supervisors[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const _AddEditSupervisorScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SupervisorCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SupervisorCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _SupervisorDetailScreen(data: data))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.infoBg,
            child: Text(data['initials'],
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
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
                Text(data['staffId'], style: AppTextStyles.caption),
                Text(data['faculty'],
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${data['studentCount']} students',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupervisorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SupervisorDetailScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    final assignedStudents = [
      {'name': 'Tan Kai Ming', 'id': '22CSB12345', 'initials': 'TK'},
      {'name': 'Priya Devi', 'id': '22CSB09988', 'initials': 'PD'},
      {'name': 'Ahmad Hafiz', 'id': '22CSB11223', 'initials': 'AH'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Supervisor details',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => _AddEditSupervisorScreen(supervisor: data))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.infoBg,
                  child: Text(data['initials'],
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
                const SizedBox(height: 10),
                Text(data['name'], style: AppTextStyles.h2),
                const SizedBox(height: 2),
                Text(data['faculty'], style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _DetailLine(icon: Icons.badge_outlined, label: 'Staff ID', value: data['staffId']),
                const Divider(height: 1, indent: 44),
                _DetailLine(icon: Icons.email_outlined, label: 'Email', value: data['email']),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Assigned students', style: AppTextStyles.h3),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Assign'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...assignedStudents.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Text(s['initials']!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name']!,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(s['id']!, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              label: const Text('Remove supervisor', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({required this.icon, required this.label, required this.value});

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
                      fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddEditSupervisorScreen extends StatefulWidget {
  final Map<String, dynamic>? supervisor;

  const _AddEditSupervisorScreen({this.supervisor});

  @override
  State<_AddEditSupervisorScreen> createState() => _AddEditSupervisorScreenState();
}

class _AddEditSupervisorScreenState extends State<_AddEditSupervisorScreen> {
  late bool isEdit;

  @override
  void initState() {
    super.initState();
    isEdit = widget.supervisor != null;
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
        title: Text(isEdit ? 'Edit Supervisor' : 'Add Supervisor',
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
            const Text('Supervisor information', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.supervisor?['name'] ?? '',
              decoration: const InputDecoration(labelText: 'Full name', hintText: 'e.g. Dr. Lim Wei Shan'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.supervisor?['staffId'] ?? '',
              decoration: const InputDecoration(labelText: 'Staff ID'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.supervisor?['email'] ?? '',
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Faculty'),
              value: widget.supervisor?['faculty'],
              items: [
                'Faculty of Computing and IT',
                'Faculty of Engineering',
                'Faculty of Business',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isEdit ? 'Save changes' : 'Add supervisor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
