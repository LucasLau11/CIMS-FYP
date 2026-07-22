import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class ParentAcknowledgementScreen extends StatefulWidget {
  const ParentAcknowledgementScreen({super.key});

  @override
  State<ParentAcknowledgementScreen> createState() =>
      _ParentAcknowledgementScreenState();
}

class _ParentAcknowledgementScreenState
    extends State<ParentAcknowledgementScreen> {
  bool _agreedToTerms = false;
  bool _confirmedAccuracy = false;
  bool _submitted = false;
  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _relationshipController = TextEditingController();

  bool get _canSubmit =>
      _agreedToTerms &&
      _confirmedAccuracy &&
      _nameController.text.isNotEmpty &&
      _icController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Acknowledgement Form',
            style: TextStyle(
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
            // Form header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description_outlined,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Parent/Guardian Acknowledgement Form',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TARUMT Industrial Training Programme',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This form acknowledges that you are aware of and consent to your child\'s participation in the industrial training programme.',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Student info (read-only)
            const Text('Student information', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  _ReadOnlyRow(label: 'Student name', value: 'Tan Kai Ming'),
                  Divider(height: 1, indent: 44),
                  _ReadOnlyRow(label: 'Student ID', value: '22CSB12345'),
                  Divider(height: 1, indent: 44),
                  _ReadOnlyRow(label: 'Programme', value: 'B.Sc Computer Science (Hons)'),
                  Divider(height: 1, indent: 44),
                  _ReadOnlyRow(label: 'Company', value: 'Tencent Malaysia Sdn. Bhd.'),
                  Divider(height: 1, indent: 44),
                  _ReadOnlyRow(label: 'Duration', value: '1 Jun 2026 – 31 Aug 2026'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Parent details
            const Text('Parent/Guardian information', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: 'Full name (as per IC)',
                  hintText: 'e.g. Tan Ah Kow'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _icController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'IC number',
                  hintText: 'e.g. 700101-01-1234'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Relationship to student'),
              items: ['Father', 'Mother', 'Guardian']
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) {
                _relationshipController.text = v ?? '';
                setState(() {});
              },
            ),

            const SizedBox(height: 20),

            // Declaration text box
            const Text('Declaration', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'I, as the parent/guardian of the above-named student, hereby acknowledge and consent to my child\'s participation in the TARUMT Industrial Training Programme. I understand that:\n\n'
                '1. My child will be working at the company stated above for the duration specified.\n\n'
                '2. The university and company will not be held liable for any personal loss or injury not arising from negligence.\n\n'
                '3. My child is required to adhere to the company\'s rules, regulations, and code of conduct.\n\n'
                '4. I may be contacted by the university if my child faces any difficulties during the internship.',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.6),
              ),
            ),

            const SizedBox(height: 16),

            // Checkboxes
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
                onPressed: _canSubmit
                    ? () => setState(() => _submitted = true)
                    : null,
                icon: const Icon(Icons.draw_outlined, size: 18),
                label: const Text('Sign & Submit'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Your digital signature will be recorded with a timestamp.',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('Form submitted successfully',
                  style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text(
                'Your acknowledgement has been recorded. The university will be notified.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Signed on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to home'),
                ),
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
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  const _CheckItem({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4)),
            ),
          ),
        ),
      ],
    );
  }
}
