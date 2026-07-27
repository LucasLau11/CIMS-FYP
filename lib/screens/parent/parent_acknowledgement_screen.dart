import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/parent_data_service.dart';

class ParentAcknowledgementScreen extends StatefulWidget {
  final Map<String, dynamic> child;
  final Map<String, dynamic>? application;

  const ParentAcknowledgementScreen({super.key, required this.child, required this.application});

  @override
  State<ParentAcknowledgementScreen> createState() => _ParentAcknowledgementScreenState();
}

class _ParentAcknowledgementScreenState extends State<ParentAcknowledgementScreen> {
  bool _agreedToTerms = false;
  bool _confirmedAccuracy = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _existing;
  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  String? _relationship;

  bool get _canSubmit => _agreedToTerms && _confirmedAccuracy && _nameController.text.trim().isNotEmpty && _icController.text.trim().isNotEmpty && _relationship != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final existing = await ParentDataService.instance.getExistingAcknowledgement(
        childId: widget.child['id'] as String,
        applicationId: widget.application?['id'] as String?,
      );
      if (!mounted) return;
      setState(() {
        _existing = existing;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await ParentDataService.instance.submitAcknowledgement(
        childId: widget.child['id'] as String,
        applicationId: widget.application?['id'] as String?,
        parentFullName: _nameController.text,
        parentIc: _icController.text,
        relationship: _relationship!,
      );
      if (!mounted) return;
      final saved = await ParentDataService.instance.getExistingAcknowledgement(
        childId: widget.child['id'] as String,
        applicationId: widget.application?['id'] as String?,
      );
      setState(() {
        _existing = saved;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit form: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_existing != null) return _buildSuccessScreen();

    final internship = widget.application?['internships'] as Map?;
    final name = (widget.child['full_name'] as String?)?.isNotEmpty == true ? widget.child['full_name'] as String : 'Unnamed student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Acknowledgement Form', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryLight.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Parent/Guardian Acknowledgement Form', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('TARUMT Industrial Training Programme',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    'This form acknowledges that you are aware of and consent to your child\'s participation in the industrial training programme.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Student information', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  _ReadOnlyRow(label: 'Student name', value: name),
                  const Divider(height: 1, indent: 44),
                  _ReadOnlyRow(label: 'Programme', value: (widget.child['programme'] as String?) ?? 'Not set'),
                  const Divider(height: 1, indent: 44),
                  _ReadOnlyRow(label: 'Company', value: (internship?['company_name'] as String?) ?? 'No active internship'),
                  if (internship?['title'] != null) ...[
                    const Divider(height: 1, indent: 44),
                    _ReadOnlyRow(label: 'Role', value: internship!['title'] as String),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Parent/Guardian information', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Full name (as per IC)', hintText: 'e.g. Tan Ah Kow'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _icController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'IC number', hintText: 'e.g. 700101-01-1234'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Relationship to student'),
              value: _relationship,
              items: ['Father', 'Mother', 'Guardian'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _relationship = v),
            ),
            const SizedBox(height: 20),
            Text('Declaration', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Text(
                'I, as the parent/guardian of the above-named student, hereby acknowledge and consent to my child\'s participation in the TARUMT Industrial Training Programme. I understand that:\n\n'
                '1. My child will be working at the company stated above for the duration specified.\n\n'
                '2. The university and company will not be held liable for any personal loss or injury not arising from negligence.\n\n'
                '3. My child is required to adhere to the company\'s rules, regulations, and code of conduct.\n\n'
                '4. I may be contacted by the university if my child faces any difficulties during the internship.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            _CheckItem(
              value: _agreedToTerms,
              label: 'I have read and understood the declaration above and agree to its terms.',
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            ),
            const SizedBox(height: 8),
            _CheckItem(
              value: _confirmedAccuracy,
              label: 'I confirm that the information I have provided is accurate and complete.',
              onChanged: (v) => setState(() => _confirmedAccuracy = v ?? false),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                icon: _isSubmitting ? const SizedBox.shrink() : const Icon(Icons.draw_outlined, size: 18),
                label: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign & Submit'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Your digital signature will be recorded with a timestamp.', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final signedAt = DateTime.tryParse(_existing?['signed_at'] as String? ?? '') ?? DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Acknowledgement Form', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_outline, color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 24),
              Text('Form submitted successfully', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('Your acknowledgement has been recorded.', style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Signed on ${signedAt.day}/${signedAt.month}/${signedAt.year}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  const _CheckItem({required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: value, onChanged: onChanged, activeColor: AppColors.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
            ),
          ),
        ),
      ],
    );
  }
}
