import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class CompanySupervisorEvaluateScreen extends StatefulWidget {
  final Map<String, dynamic> intern;

  const CompanySupervisorEvaluateScreen({super.key, required this.intern});

  @override
  State<CompanySupervisorEvaluateScreen> createState() =>
      _CompanySupervisorEvaluateScreenState();
}

class _CompanySupervisorEvaluateScreenState
    extends State<CompanySupervisorEvaluateScreen> {
  // Workplace-lens criteria (different from Academic Supervisor's academic rubric)
  final Map<String, double> _scores = {
    'Work quality & output': 3,
    'Punctuality & attendance': 3,
    'Initiative & proactiveness': 3,
    'Adaptability to workplace': 3,
    'Teamwork & communication': 3,
  };

  final _commentsController = TextEditingController();
  bool _submitted = false;

  double get _average => _scores.values.reduce((a, b) => a + b) / _scores.length;

  String get _grade {
    if (_average >= 4.5) return 'Excellent';
    if (_average >= 3.5) return 'Good';
    if (_average >= 2.5) return 'Satisfactory';
    return 'Needs improvement';
  }

  Color get _gradeColor {
    if (_average >= 4.5) return AppColors.success;
    if (_average >= 3.5) return AppColors.primary;
    if (_average >= 2.5) return AppColors.warning;
    return AppColors.error;
  }

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
        title: const Text('Evaluate intern',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.infoBg,
                child: Text(widget.intern['initials'],
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.intern['name'],
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text('${widget.intern['id']} · ${widget.intern['role']}',
                      style: AppTextStyles.bodySecondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rate each criterion from 1 (poor) to 5 (excellent) based on workplace performance.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._scores.keys.map((criterion) => _RatingRow(
                label: criterion,
                value: _scores[criterion]!,
                onChanged: (v) => setState(() => _scores[criterion] = v),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Average score',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.white70)),
                      Text(_grade,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _gradeColor == AppColors.success
                                  ? const Color(0xFFA8EDEA)
                                  : Colors.white)),
                    ],
                  ),
                ),
                Text(_average.toStringAsFixed(1),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Additional comments', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _commentsController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe the intern\'s overall performance, attitude, and growth during the internship period...',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _submitted = true),
              child: const Text('Submit evaluation'),
            ),
          ),
        ],
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
              const Text('Evaluation submitted', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Your workplace evaluation for ${widget.intern['name']} has been recorded and shared with the university.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to intern'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _RatingRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Text(value.toInt().toString(),
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              final starValue = i + 1;
              return GestureDetector(
                onTap: () => onChanged(starValue.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    starValue <= value ? Icons.star : Icons.star_border,
                    color: starValue <= value ? AppColors.primaryLight : AppColors.textMuted,
                    size: 26,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
