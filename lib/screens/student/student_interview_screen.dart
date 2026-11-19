import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/interview_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_text.dart';
import '../../utils/format_utils.dart';
import '../../utils/interview_format.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../widgets/interview_slot_picker.dart';
import '../../widgets/reason_dialog.dart';
import '../../services/auth_service.dart';
import '../../widgets/reschedule_request_card.dart';
import '../../utils/calendar_link.dart';

/// Shows the interview for one application: when and where, how to join, the
/// history of any changes with their reasons, and lets the student reschedule
/// or cancel (a reason is always required and the company sees it). There's no
/// embedded video calling here — HR books either an "online" interview (a
/// meeting link the student opens externally) or an "in_person" one (an
/// address).
///
/// Pops with `true` when the student changed the interview so the caller can
/// reload.
class StudentInterviewScreen extends StatefulWidget {
  final Map<String, dynamic> application;

  const StudentInterviewScreen({super.key, required this.application});

  @override
  State<StudentInterviewScreen> createState() => _StudentInterviewScreenState();
}

class _StudentInterviewScreenState extends State<StudentInterviewScreen> {
  bool _busy = false;
  InterviewInfo? _fresh;

  InterviewInfo? get _interview => _fresh ?? widget.application['interview'] as InterviewInfo?;

  @override
  void initState() {
    super.initState();
    _refreshInterview();
  }

  /// The copy handed to this screen may be old (for example the company has
  /// since declined a request), so load the current state.
  Future<void> _refreshInterview() async {
    final id = (widget.application['interview'] as InterviewInfo?)?.id;
    if (id == null) return;
    try {
      final latest = await InterviewService.instance.fetch(id);
      if (!mounted || latest == null) return;
      setState(() => _fresh = latest);
    } catch (_) {
      // Keep showing the copy we were given.
    }
  }

  Future<void> _reschedule() async {
    final iv = _interview!;
    final done = await showRescheduleSheet(
      context,
      otherParty: AppLocalizations.of(context)!.ivTheCompany,
      loadSlots: (from, to) => InterviewService.instance.freeSlots(iv.interviewerId!, from, to),
      onSubmit: (slot, reason) => InterviewService.instance.requestReschedule(interviewId: iv.id, newStart: slot.start, reason: reason),
    );
    if (done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.ivRequestSentCompany),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _answerRequest(RescheduleRequest request, {required bool accept}) async {
    String? note;
    if (!accept) {
      note = await showReasonDialog(
        context,
        title: AppLocalizations.of(context)!.ivDeclineNewTimeTitle,
        prompt: AppLocalizations.of(context)!.ivDeclinePromptToCompany,
        confirmLabel: AppLocalizations.of(context)!.ivDecline,
        hintText: AppLocalizations.of(context)!.ivDeclineHint,
        destructive: true,
      );
      if (note == null || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await InterviewService.instance.respondToReschedule(requestId: request.id, accept: accept, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? AppLocalizations.of(context)!.ivAcceptedMoved : AppLocalizations.of(context)!.ivDeclinedStays), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _withdrawRequest(RescheduleRequest request) async {
    setState(() => _busy = true);
    try {
      await InterviewService.instance.withdrawRescheduleRequest(request.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _cancel() async {
    final iv = _interview!;
    final reason = await showReasonDialog(
      context,
      title: AppLocalizations.of(context)!.ivCancelInterview,
      prompt: AppLocalizations.of(context)!.ivCancelPromptToCompany(formatInterviewDateTime(iv.start)),
      confirmLabel: AppLocalizations.of(context)!.ivCancelInterview,
      hintText: 'e.g. I have accepted another internship.',
      destructive: true,
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await InterviewService.instance.cancel(interviewId: iv.id, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.ivCancelledNotified), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.ivCouldNotCancel(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  Future<void> _addToCalendar(InterviewInfo iv, String title, String company) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await addInterviewToCalendar(
      title: l10n.calendarEventTitle(title),
      start: iv.start,
      end: iv.end,
      location: iv.location,
      details: l10n.calendarEventDetails(company),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.calendarCouldNotOpen), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final internship = widget.application['internships'] as Map;
    final companyName = internship['company_name'] as String;
    final iv = _interview;
    final isOnline = iv?.mode == 'online';
    final location = iv?.location;
    final cancelled = iv?.isCancelled ?? false;
    final changes = iv?.changes.where((c) => c.action != 'booked').toList() ?? const <InterviewChange>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.interview, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: nameColor(companyName).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(logoLetter(companyName),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: nameTextColor(companyName))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(internship['title'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(companyName, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (iv == null)
            EmptyState(icon: Icons.event_busy_outlined, title: l10n.noInterviewScheduled, description: l10n.interviewNotifiedOnceScheduled)
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: cancelled ? [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)] : AppColors.headerGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cancelled ? Icons.event_busy_outlined : (isOnline ? Icons.videocam_outlined : Icons.business_outlined), color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(cancelled ? 'Cancelled' : (isOnline ? l10n.onlineInterviewLabel : l10n.inPersonInterviewLabel),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(formatInterviewDay(iv.start), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: kOnBannerSoft)),
                  Text(formatInterviewTime(iv.start), style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('${iv.end.difference(iv.start).inMinutes} minutes', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: kOnBannerSoft)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!cancelled && location != null && location.isNotEmpty) ...[
              Text(isOnline ? l10n.hrMeetingLink : l10n.hrLocation, style: AppTextStyles.label),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Text(location, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 20),
            ],
            if (!cancelled && iv.isScheduled) ...[
              // A "join" button only makes sense for an online interview; an in-person one is explained
              // by the note below instead of a greyed-out button nobody can press.
              if (isOnline && location != null && location.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _join(context, location),
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    label: Text(l10n.joinInterview),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              if (!isOnline)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.inPersonNoJoinLinkNote,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addToCalendar(iv, internship['title'] as String, companyName),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: Text(l10n.addToCalendar),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(height: 12),
              if (iv.pendingRequest != null) ...[
                RescheduleRequestCard(
                  request: iv.pendingRequest!,
                  requestedByMe: iv.pendingRequest!.requestedBy == AuthService.instance.currentUserId,
                  otherParty: l10n.ivTheCompany,
                  currentStart: iv.start,
                  busy: _busy,
                  onAccept: () => _answerRequest(iv.pendingRequest!, accept: true),
                  onDecline: () => _answerRequest(iv.pendingRequest!, accept: false),
                  onWithdraw: () => _withdrawRequest(iv.pendingRequest!),
                ),
                const SizedBox(height: 12),
              ],
              if (iv.canBeChanged)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _cancel,
                        icon: Icon(Icons.event_busy_outlined, size: 16, color: AppColors.error),
                        label: Text(l10n.ivCancelButton, style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: AppColors.error)),
                      ),
                    ),
                    if (iv.pendingRequest == null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _reschedule,
                          icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                          label: Text(l10n.ivRescheduleButton),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ],
                )
              else
                Text(l10n.ivChangeWindowStudent, style: AppTextStyles.caption),
            ],
            if (cancelled)
              Text(l10n.ivCompanyWillArrange, style: AppTextStyles.bodySecondary),
            if (changes.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(l10n.ivChangesTitle, style: AppTextStyles.label),
              const SizedBox(height: 8),
              for (final c in changes.reversed) _ChangeTile(change: c),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, String link) async {
    final uri = Uri.tryParse(link.startsWith('http') ? link : 'https://$link');
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorCouldNotOpenMeetingLink), backgroundColor: AppColors.error));
    }
  }
}

class _ChangeTile extends StatelessWidget {
  final InterviewChange change;
  const _ChangeTile({required this.change});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actor = change.actorRole == 'student'
        ? l10n.ivTheStudent
        : (change.actorRole == null ? l10n.ivTheSystem : l10n.ivTheCompany);
    final String what;
    switch (change.action) {
      case 'rescheduled':
        what = change.oldStart != null && change.newStart != null
            ? l10n.ivChangeMovedFromTo(actor, formatInterviewDateTime(change.oldStart!), formatInterviewDateTime(change.newStart!))
            : l10n.ivChangeMoved(actor);
        break;
      case 'reschedule_requested':
        what = change.newStart != null
            ? l10n.ivChangeAskedTo(actor, formatInterviewDateTime(change.newStart!))
            : l10n.ivChangeAsked(actor);
        break;
      case 'reschedule_declined':
        what = change.newStart != null
            ? l10n.ivChangeDeclinedFor(actor, formatInterviewDateTime(change.newStart!))
            : l10n.ivChangeDeclined(actor);
        break;
      case 'auto_cancelled':
        what = l10n.ivAutoCancelled;
        break;
      default:
        what = l10n.ivChangeCancelled(actor);
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(what, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (change.reason != null && change.reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(l10n.ivReasonLine(change.reason!), style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 4),
          Text(formatInterviewDateTime(change.at), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
