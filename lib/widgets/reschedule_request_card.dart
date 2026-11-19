import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../services/interview_service.dart';
import '../theme/app_theme.dart';
import '../utils/interview_format.dart';

/// A reschedule request waiting for an answer. If the other side made it, the
/// person can accept (the interview moves) or decline (with a reason); if the
/// person made it themselves, they see that it is waiting and can withdraw it.
/// The interview keeps its current time until the request is accepted.
class RescheduleRequestCard extends StatelessWidget {
  const RescheduleRequestCard({
    super.key,
    required this.request,
    required this.requestedByMe,
    required this.otherParty,
    required this.currentStart,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onWithdraw,
  });

  final RescheduleRequest request;
  final bool requestedByMe;

  /// "The company" or the student's name, as the person would say it.
  final String otherParty;
  final DateTime currentStart;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = AppColors.info;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_calendar_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requestedByMe ? l10n.ivYouAskedToReschedule : l10n.ivAskedToReschedule(otherParty),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _line(l10n.ivLineNow, formatInterviewDateTime(currentStart)),
          const SizedBox(height: 4),
          _line(l10n.ivLineProposed, formatInterviewDateTime(request.proposedStart)),
          const SizedBox(height: 4),
          _line(l10n.ivLineReason, request.reason),
          const SizedBox(height: 10),
          Text(
            requestedByMe ? l10n.ivWaitingFor(otherParty) : l10n.ivMovesOnlyIfYouAccept,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.35, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          if (busy)
            const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
          else if (requestedByMe)
            OutlinedButton.icon(
              onPressed: onWithdraw,
              icon: const Icon(Icons.undo, size: 16),
              label: Text(l10n.ivWithdrawRequest),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error)),
                    child: Text(l10n.ivDecline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: onAccept, child: Text(l10n.ivAccept))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 74, child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted))),
        Expanded(child: Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ],
    );
  }
}
