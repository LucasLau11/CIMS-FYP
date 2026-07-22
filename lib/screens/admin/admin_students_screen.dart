import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'All';

  final List<Map<String, dynamic>> _students = [
    {
      'name': 'Tan Kai Ming',
      'id': '22CSB12345',
      'programme': 'B.Sc Computer Science',
      'status': 'Active',
      'supervisor': 'Dr. Lim Wei Shan',
      'initials': 'TK',
    },
    {
      'name': 'Lee Mei Ling',
      'id': '23CSB00112',
      'programme': 'B.Sc Information Technology',
      'status': 'Unassigned',
      'supervisor': null,
      'initials': 'LM',
    },
    {
      'name': 'Muhammad Aiman',
      'id': '22CSB10876',
      'programme': 'B.Sc Computer Science',
      'status': 'Active',
      'supervisor': 'Dr. Wong Chee Keong',
      'initials': 'MA',
    },
    {
      'name': 'Priya Devi',
      'id': '22CSB09988',
      'programme': 'B.Sc Software Engineering',
      'status': 'Pending',
      'supervisor': 'Dr. Lim Wei Shan',
      'initials': 'PD',
    },
    {
      'name': 'Wong Jia Hui',
      'id': '21CSB05544',
      'programme': 'B.Sc Computer Science',
      'status': 'Completed',
      'supervisor': 'Dr. Tan Soo Beng',
      'initials': 'WJ',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    var list = _students;
    if (_filterStatus != 'All') {
      list = list.where((s) => s['status'] == _filterStatus).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      list = list
          .where((s) =>
              s['name'].toLowerCase().contains(q) ||
              s['id'].toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Students',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _AddEditStudentScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by name or student ID...',
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Active', 'Unassigned', 'Pending', 'Completed']
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s),
                          selected: _filterStatus == s,
                          onSelected: (_) => setState(() => _filterStatus = s),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: _filterStatus == s
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: _filterStatus == s
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          selectedColor: AppColors.accent,
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text('${_filtered.length} students', style: AppTextStyles.caption),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.school_outlined,
                    title: 'No students found',
                    description: 'Try adjusting your search or filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _StudentCard(data: _filtered[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const _AddEditStudentScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StudentCard({required this.data});

  Color get _statusColor {
    switch (data['status']) {
      case 'Active': return AppColors.success;
      case 'Unassigned': return AppColors.error;
      case 'Pending': return AppColors.warning;
      case 'Completed': return AppColors.textMuted;
      default: return AppColors.primary;
    }
  }

  StatusBadge get _badge {
    switch (data['status']) {
      case 'Active': return StatusBadge.active();
      case 'Unassigned': return const StatusBadge(
          label: 'Unassigned', backgroundColor: Color(0xFFFDEEEE), textColor: Color(0xFFD94F4F));
      case 'Pending': return StatusBadge.pending();
      case 'Completed': return const StatusBadge(
          label: 'Completed', backgroundColor: Color(0xFFF1EFE8), textColor: Color(0xFF5F5E5A));
      default: return StatusBadge.active();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _statusColor,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _AddEditStudentScreen(student: data))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(data['initials'],
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
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
                Text('${data['id']} · ${data['programme']}',
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis),
                if (data['supervisor'] != null)
                  Text('Supervisor: ${data['supervisor']}',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.primary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _badge,
              const SizedBox(height: 6),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                onSelected: (_) {},
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'assign', child: Text('Assign Supervisor')),
                  PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddEditStudentScreen extends StatefulWidget {
  final Map<String, dynamic>? student;

  const _AddEditStudentScreen({this.student});

  @override
  State<_AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<_AddEditStudentScreen> {
  late bool isEdit;

  @override
  void initState() {
    super.initState();
    isEdit = widget.student != null;
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
        title: Text(isEdit ? 'Edit Student' : 'Add Student',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
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
            const Text('Personal information', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.student?['name'] ?? '',
              decoration: const InputDecoration(labelText: 'Full name', hintText: 'e.g. Tan Kai Ming'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.student?['id'] ?? '',
              decoration: const InputDecoration(labelText: 'Student ID', hintText: 'e.g. 22CSB12345'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'Email', hintText: 'student@student.tarumt.edu.my'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(labelText: 'Phone number', hintText: '+60 12-345 6789'),
            ),
            const SizedBox(height: 20),
            const Text('Academic information', style: AppTextStyles.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Programme'),
              value: widget.student?['programme'],
              items: [
                'B.Sc Computer Science',
                'B.Sc Information Technology',
                'B.Sc Software Engineering',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Semester'),
              items: List.generate(8, (i) => 'Semester ${i + 1}')
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Academic Supervisor'),
              value: widget.student?['supervisor'],
              items: [
                'Dr. Lim Wei Shan',
                'Dr. Wong Chee Keong',
                'Dr. Tan Soo Beng',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: widget.student?['status'] ?? 'Pending',
              items: ['Active', 'Unassigned', 'Pending', 'Completed']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isEdit ? 'Save changes' : 'Add student'),
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
        title: const Text('Remove student?', style: AppTextStyles.h3),
        content: const Text(
          'This will permanently remove this student record from the system. This action cannot be undone.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
