import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/hr_data_service.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';
import '../document_preview_screen.dart';
import '../student/student_messages_screen.dart' show ChatScreen;

class RecommendedCandidatesScreen extends StatefulWidget {
  final String postingTitle;
  final List<String> requiredSkills;

  const RecommendedCandidatesScreen({super.key, required this.postingTitle, required this.requiredSkills});

  @override
  State<RecommendedCandidatesScreen> createState() => _RecommendedCandidatesScreenState();
}

class _RecommendedCandidatesScreenState extends State<RecommendedCandidatesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _candidates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final candidates = await HrDataService.instance.getRecommendedCandidates(widget.requiredSkills);
      if (!mounted) return;
      setState(() {
        _candidates = candidates;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('Recommended candidates', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _candidates.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        const EmptyState(
                          icon: Icons.person_search_outlined,
                          title: 'No matching candidates',
                          description: 'No student has listed skills that overlap with this posting\'s requirements yet.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _candidates.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text('For "${widget.postingTitle}" · ${_candidates.length} match${_candidates.length == 1 ? '' : 'es'}', style: AppTextStyles.caption),
                          );
                        }
                        final candidate = _candidates[i - 1];
                        return _CandidateCard(
                          data: candidate,
                          onViewProfile: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => _CandidateProfileScreen(data: candidate)));
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onViewProfile;

  const _CandidateCard({required this.data, required this.onViewProfile});

  @override
  Widget build(BuildContext context) {
    final name = (data['full_name'] as String?)?.isNotEmpty == true ? data['full_name'] as String : 'Unnamed student';
    final matched = List<String>.from(data['matched_skills'] as List? ?? []);
    final programme = data['programme'] as String?;

    return AccentCard(
      accentColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(logoLetter(name), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(programme?.isNotEmpty == true ? programme! : 'Programme not set', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                child: Text('${matched.length} skill${matched.length == 1 ? '' : 's'}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: matched
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(s, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.primary)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewProfile,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 9)),
              child: const Text('View profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateProfileScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const _CandidateProfileScreen({required this.data});

  @override
  State<_CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<_CandidateProfileScreen> {
  bool _isMessaging = false;
  Map<String, String>? _resume;
  bool _isLoadingResume = true;

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  Future<void> _loadResume() async {
    try {
      final resume = await HrDataService.instance.getCandidateResume(widget.data['id'] as String);
      if (!mounted) return;
      setState(() {
        _resume = resume;
        _isLoadingResume = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingResume = false);
    }
  }

  Future<void> _message() async {
    setState(() => _isMessaging = true);
    try {
      final conversation = await StudentDataService.instance.getOrCreateConversation(widget.data['id'] as String);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation['id'] as String, otherProfile: widget.data)),
      );
      if (!mounted) return;
      setState(() => _isMessaging = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMessaging = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open chat: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final name = (data['full_name'] as String?)?.isNotEmpty == true ? data['full_name'] as String : 'Unnamed student';
    final skills = List<String>.from(data['skills'] as List? ?? []);
    final matched = List<String>.from(data['matched_skills'] as List? ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Candidate profile', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.infoBg,
                  child: Text(logoLetter(name), style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(height: 10),
                Text(name, style: AppTextStyles.h2),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Skills', style: AppTextStyles.label),
          const SizedBox(height: 8),
          if (skills.isEmpty)
            Text('No skills listed.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: matched.contains(s) ? AppColors.successBg : AppColors.infoBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                fontFamily: 'Inter', fontSize: 12, color: matched.contains(s) ? AppColors.success : AppColors.primary)),
                      ))
                  .toList(),
            ),
          if (!_isLoadingResume) ...[
            const SizedBox(height: 24),
            Text('Resume', style: AppTextStyles.label),
            const SizedBox(height: 8),
            if (_resume == null)
              Text('No resume uploaded.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
            else
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: _resume!['url']!, fileName: _resume!['filename']!)),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_resume!['filename']!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isMessaging ? null : _message,
              icon: _isMessaging
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
