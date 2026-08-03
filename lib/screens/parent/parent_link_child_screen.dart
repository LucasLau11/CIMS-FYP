import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/parent_data_service.dart';
import '../../utils/format_utils.dart';

/// Lets a parent search for their child by exact registered email, pick a
/// relationship, and send a link request. The student must approve it
/// (via their notifications) before the parent can see any of their data.
/// Also shows the parent's own past/pending requests for status visibility.
class ParentLinkChildScreen extends StatefulWidget {
  const ParentLinkChildScreen({super.key});

  @override
  State<ParentLinkChildScreen> createState() => _ParentLinkChildScreenState();
}

const String _studentEmailDomain = '@student.tarc.edu.my';

class _ParentLinkChildScreenState extends State<ParentLinkChildScreen> {
  final _emailController = TextEditingController();
  String _relationship = 'father';

  bool _isSearching = false;
  bool _isSending = false;
  String? _searchError;
  Map<String, dynamic>? _foundStudent;

  bool _isLoadingRequests = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final requests = await ParentDataService.instance.getMyLinkRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoadingRequests = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _search() async {
    final typed = _emailController.text.trim();
    if (typed.isEmpty) return;
    // Accept either just the username or a pasted full address.
    final localPart = typed.contains('@') ? typed.substring(0, typed.indexOf('@')) : typed;
    final email = '$localPart$_studentEmailDomain';
    setState(() {
      _isSearching = true;
      _searchError = null;
      _foundStudent = null;
    });
    try {
      final student = await ParentDataService.instance.searchStudentByEmail(email);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isSearching = false;
        _foundStudent = student;
        _searchError = student == null ? l10n.parentNoStudentFoundError : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = AppLocalizations.of(context)!.parentSearchError(e.toString());
      });
    }
  }

  Future<void> _sendRequest() async {
    final student = _foundStudent;
    if (student == null) return;
    setState(() => _isSending = true);
    try {
      await ParentDataService.instance.requestParentLink(studentId: student['id'] as String, relationship: _relationship);
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _foundStudent = null;
        _emailController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.parentRequestSentMessage), backgroundColor: AppColors.primary),
      );
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.parentSendRequestError(e.toString())), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await ParentDataService.instance.cancelLinkRequest(requestId);
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.parentCancelRequestError(e.toString())), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.parentLinkChildButton, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.parentStudentEmailLabel, style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: l10n.parentStudentEmailHint, suffixText: _studentEmailDomain),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 14),
          Text(l10n.parentRelationshipLabel, style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            items: [
              DropdownMenuItem(value: 'father', child: Text(l10n.parentRelationshipFather)),
              DropdownMenuItem(value: 'mother', child: Text(l10n.parentRelationshipMother)),
              DropdownMenuItem(value: 'guardian', child: Text(l10n.parentRelationshipGuardian)),
            ],
            onChanged: (v) => setState(() => _relationship = v!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSearching ? null : _search,
              child: _isSearching
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.search),
            ),
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 10),
            Text(_searchError!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          ],
          if (_foundStudent != null) ...[
            const SizedBox(height: 16),
            AccentCard(
              accentColor: AppColors.primary,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.infoBg,
                    child: Text(logoLetter(_foundStudent!['full_name'] as String? ?? '?'),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_foundStudent!['full_name'] as String? ?? l10n.parentUnnamedStudent,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text((_foundStudent!['programme'] as String?) ?? l10n.programmeNotSet, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendRequest,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
                    child: _isSending
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.parentSendRequestButton, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(l10n.parentYourRequestsTitle, style: AppTextStyles.h3),
          const SizedBox(height: 10),
          if (_isLoadingRequests)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_requests.isEmpty)
            Text(l10n.parentNoRequestsYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
          else
            ..._requests.map((r) => _RequestRow(request: r, onCancel: () => _cancelRequest(r['id'] as String))),
        ],
      ),
    );
  }
}

String _relationshipLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'father':
      return l10n.parentRelationshipFather;
    case 'mother':
      return l10n.parentRelationshipMother;
    default:
      return l10n.parentRelationshipGuardian;
  }
}

class _RequestRow extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onCancel;

  const _RequestRow({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = request['status'] as String;
    final studentName = (request['profiles'] as Map?)?['full_name'] as String? ?? l10n.parentUnknownStudent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(l10n.parentAsRelationship(_relationshipLabel(l10n, request['relationship'] as String)), style: AppTextStyles.caption),
              ],
            ),
          ),
          switch (status) {
            'approved' => StatusBadge.approved(context),
            'rejected' => StatusBadge.rejected(context),
            _ => StatusBadge.pending(context),
          },
          if (status == 'pending') ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
              tooltip: l10n.withdraw,
              onPressed: onCancel,
            ),
          ],
        ],
      ),
    );
  }
}
