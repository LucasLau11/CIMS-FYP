import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class SupervisorEvaluateScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const SupervisorEvaluateScreen({super.key, required this.student});

  @override
  State<SupervisorEvaluateScreen> createState() => _SupervisorEvaluateScreenState();
}

class _SupervisorEvaluateScreenState extends State<SupervisorEvaluateScreen> {
  final Map<String, double> _scores = {
    'Technical competency': 3,
    'Communication skills': 3,
    'Professionalism & discipline': 3,
    'Problem-solving ability': 3,
    'Teamwork & collaboration': 3,
  };

  final _commentsController = TextEditingController();
  bool _submitted = false;

  double get _averageScore {
    final total = _scores.values.reduce((a, b) => a + b);
    return total / _scores.length;
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
        title: const Text('Evaluate student',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.infoBg,
                child: Text(widget.student['initials'],
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.student['name'],
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text('${widget.student['id']} · ${widget.student['company']}', style: AppTextStyles.bodySecondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    'Rate each criterion from 1 (poor) to 5 (excellent) based on internship performance.',
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
              gradient: const LinearGradient(colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Overall average score',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                Text(_averageScore.toStringAsFixed(1),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
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
              hintText: 'Provide qualitative feedback on the student\'s overall performance...',
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
                decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('Evaluation submitted', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Your evaluation for ${widget.student['name']} has been recorded.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to student'),
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
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              Text(value.toInt().toString(),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
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
