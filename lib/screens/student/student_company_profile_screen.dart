import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';

/// A company's public profile: details, job posting history, past-intern
/// count (no names, to protect other students' privacy), and an anonymous
/// ratings/reviews section. Reviewing is gated to students who have
/// actually applied to this company (StudentDataService.canReviewCompany,
/// mirrored by the company_reviews_insert_own RLS policy).
class StudentCompanyProfileScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const StudentCompanyProfileScreen({super.key, required this.companyId, required this.companyName});

  @override
  State<StudentCompanyProfileScreen> createState() => _StudentCompanyProfileScreenState();
}

class _StudentCompanyProfileScreenState extends State<StudentCompanyProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _company;
  List<Map<String, dynamic>> _postings = [];
  int _internCount = 0;
  List<Map<String, dynamic>> _reviews = [];
  bool _canReview = false;
  Map<String, dynamic>? _myReview;

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (s, r) => s + (r['rating'] as int));
    return sum / _reviews.length;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final company = await StudentDataService.instance.getCompanyDetails(widget.companyId);
      final postings = await StudentDataService.instance.getCompanyPostings(widget.companyId);
      final internCount = await StudentDataService.instance.getCompanyInternCount(widget.companyId);
      final reviews = await StudentDataService.instance.getCompanyReviews(widget.companyId);
      final canReview = await StudentDataService.instance.canReviewCompany(widget.companyId);
      final myReview = canReview ? await StudentDataService.instance.getMyCompanyReview(widget.companyId) : null;
      if (!mounted) return;
      setState(() {
        _company = company;
        _postings = postings;
        _internCount = internCount;
        _reviews = reviews;
        _canReview = canReview;
        _myReview = myReview;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openReviewSheet() async {
    int rating = (_myReview?['rating'] as int?) ?? 5;
    final reviewController = TextEditingController(text: _myReview?['review'] as String? ?? '');
    bool isSubmitting = false;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_myReview != null ? l10n.companyProfileEditReview : l10n.companyProfileWriteReview,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Text(l10n.companyProfileRatingLabel, style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  _StarRating(
                    rating: rating,
                    size: 32,
                    onChanged: (v) => setSheetState(() => rating = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(hintText: l10n.companyProfileReviewHint),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              try {
                                await StudentDataService.instance.submitCompanyReview(
                                  companyId: widget.companyId,
                                  rating: rating,
                                  review: reviewController.text,
                                );
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext, true);
                              } catch (e) {
                                setSheetState(() => isSubmitting = false);
                                if (!sheetContext.mounted) return;
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text(l10n.companyProfileReviewError(e.toString())), backgroundColor: AppColors.error),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (submitted == true) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.companyProfileReviewSubmitted), backgroundColor: AppColors.primary));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyName = (_company?['name'] as String?) ?? widget.companyName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.companyProfileTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: nameColor(companyName).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                        child: Center(
                          child: Text(logoLetter(companyName),
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: nameColor(companyName))),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(companyName, style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            if (_company?['industry'] != null) Text(_company!['industry'] as String, style: AppTextStyles.bodySecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        if (_company?['location'] != null) ...[
                          _DetailRow(icon: Icons.location_on_outlined, label: l10n.address, value: _company!['location'] as String),
                          const Divider(height: 20),
                        ],
                        if (_company?['hr_contact_name'] != null) ...[
                          _DetailRow(icon: Icons.person_outline, label: l10n.hrContact, value: _company!['hr_contact_name'] as String),
                          const Divider(height: 20),
                        ],
                        if (_company?['hr_contact_email'] != null)
                          _DetailRow(icon: Icons.email_outlined, label: l10n.contactEmail, value: _company!['hr_contact_email'] as String),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.companyProfileJobPostings, style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  if (_postings.isEmpty)
                    Text(l10n.companyProfileNoPostings, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
                  else
                    ..._postings.map((p) => _PostingRow(posting: p)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l10n.companyProfileInternCount(_internCount),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.companyProfileReviews, style: AppTextStyles.h3),
                      if (_canReview)
                        TextButton.icon(
                          onPressed: _openReviewSheet,
                          icon: Icon(_myReview != null ? Icons.edit_outlined : Icons.add, size: 16),
                          label: Text(_myReview != null ? l10n.companyProfileEditReview : l10n.companyProfileWriteReview, style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StarRating(rating: _averageRating.round(), size: 18),
                      const SizedBox(width: 8),
                      Text(_reviews.isEmpty ? '—' : _averageRating.toStringAsFixed(1),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(width: 6),
                      Text('· ${l10n.companyProfileReviewCount(_reviews.length)}', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.companyProfileNoReviewsYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                    )
                  else
                    ..._reviews.map((r) => _ReviewCard(review: r)),
                  if (!_canReview) ...[
                    const SizedBox(height: 12),
                    Text(l10n.companyProfileMustApplyNote, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const _StarRating({required this.rating, this.size = 18, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        final filled = starValue <= rating;
        final star = Icon(filled ? Icons.star : Icons.star_border, size: size, color: AppColors.primaryLight);
        if (onChanged == null) return star;
        return GestureDetector(onTap: () => onChanged!(starValue), child: Padding(padding: const EdgeInsets.only(right: 4), child: star));
      }),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostingRow extends StatelessWidget {
  final Map<String, dynamic> posting;

  const _PostingRow({required this.posting});

  @override
  Widget build(BuildContext context) {
    final status = posting['status'] as String?;
    final postedAt = DateTime.tryParse(posting['posted_at'] as String? ?? '');
    return AccentCard(
      accentColor: status == 'open' ? AppColors.success : AppColors.textMuted,
      child: Row(
        children: [
          Icon(Icons.work_outline, size: 18, color: status == 'open' ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(posting['title'] as String? ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (postedAt != null) Text(timeAgo(context, postedAt), style: AppTextStyles.caption),
              ],
            ),
          ),
          if (status == 'open') StatusBadge.active(context) else StatusBadge(label: status ?? '', backgroundColor: AppColors.surfaceVariant, textColor: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(review['created_at'] as String? ?? '');
    final text = review['review'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StarRating(rating: review['rating'] as int, size: 15),
              const Spacer(),
              if (createdAt != null) Text(timeAgo(context, createdAt), style: AppTextStyles.caption),
            ],
          ),
          if (text != null && text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
