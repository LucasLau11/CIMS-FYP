import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/interview_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_text.dart';
import '../../utils/interview_format.dart';
import '../../widgets/common/shared_widgets.dart';

/// Where an HR person sets when they can interview: weekly hours (several per
/// day, each with its own slot length) and days off. Interview times offered to
/// everyone are generated from this, minus anything already booked.
class HrAvailabilityScreen extends StatefulWidget {
  const HrAvailabilityScreen({super.key});

  @override
  State<HrAvailabilityScreen> createState() => _HrAvailabilityScreenState();
}

class _HrAvailabilityScreenState extends State<HrAvailabilityScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _windows = [];
  List<Map<String, dynamic>> _daysOff = [];

  String get _hrId => AuthService.instance.currentUserId!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final windows = await InterviewService.instance.getAvailability(_hrId);
      final daysOff = await InterviewService.instance.getBlockedDates(_hrId);
      if (!mounted) return;
      setState(() {
        _windows = windows;
        _daysOff = daysOff;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.error : AppColors.success),
    );
  }

  String _hhmm(String dbTime) => dbTime.length >= 5 ? dbTime.substring(0, 5) : dbTime;

  Future<void> _addHours() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddHoursSheet(hrId: _hrId),
    );
    if (added == true) {
      _snack(AppLocalizations.of(context)!.avHoursSaved);
      _load();
    }
  }

  Future<void> _deleteWindow(Map<String, dynamic> w) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.avRemoveTitle),
        content: Text(AppLocalizations.of(context)!.avRemoveBody(
            interviewWeekdayName(w['weekday'] as int), _hhmm(w['start_time'] as String), _hhmm(w['end_time'] as String))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.avKeep)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.avRemove, style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await InterviewService.instance.deleteAvailability(w['availability_id'] as String);
      _load();
    } catch (e) {
      if (mounted) _snack(friendlyError(e), error: true);
    }
  }

  Future<void> _addDayOff() async {
    final picked = await showDatePicker(
      context: context,
      helpText: AppLocalizations.of(context)!.avDayOffHelp,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    try {
      await InterviewService.instance.addBlockedDate(hrId: _hrId, date: picked);
      _load();
    } catch (e) {
      if (mounted) _snack(friendlyError(e), error: true);
    }
  }

  Future<void> _removeDayOff(Map<String, dynamic> d) async {
    try {
      await InterviewService.instance.removeBlockedDate(hrId: _hrId, blockedOn: d['blocked_on'] as String);
      _load();
    } catch (e) {
      if (mounted) _snack(friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: AppLocalizations.of(context)!.avTitle),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addHours,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.avAddHours, style: const TextStyle(color: Colors.white)),
            ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)!.ivTryAgain)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          AppLocalizations.of(context)!.avIntro,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.info),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.avWeeklyHours, style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      if (_windows.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
                          child: Text(AppLocalizations.of(context)!.avNoHoursYet,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.warning)),
                        ),
                      for (var day = 1; day <= 7; day++) _daySection(day),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Text(AppLocalizations.of(context)!.avDaysOff, style: AppTextStyles.h3)),
                          TextButton.icon(onPressed: _addDayOff, icon: const Icon(Icons.event_busy_outlined, size: 18), label: Text(AppLocalizations.of(context)!.avAddDayOff)),
                        ],
                      ),
                      if (_daysOff.isEmpty)
                        Text(AppLocalizations.of(context)!.avNoDaysOff,
                            style: AppTextStyles.bodySecondary),
                      for (final d in _daysOff)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                          child: Row(
                            children: [
                              Icon(Icons.event_busy_outlined, size: 18, color: AppColors.textMuted),
                              const SizedBox(width: 10),
                              Expanded(child: Text(formatInterviewDay(DateTime.parse(d['blocked_on'] as String)), style: const TextStyle(fontFamily: 'Inter', fontSize: 13))),
                              IconButton(icon: const Icon(Icons.close, size: 18), tooltip: AppLocalizations.of(context)!.avRemove, onPressed: () => _removeDayOff(d)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _daySection(int day) {
    final windows = _windows.where((w) => w['weekday'] == day).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(interviewWeekdayName(day),
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: windows.isEmpty ? AppColors.textMuted : AppColors.textPrimary)),
          ),
          Expanded(
            child: windows.isEmpty
                ? Text(AppLocalizations.of(context)!.avNotAvailable, style: AppTextStyles.caption)
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final w in windows)
                        InputChip(
                          label: Text('${_hhmm(w['start_time'] as String)} – ${_hhmm(w['end_time'] as String)} · ${AppLocalizations.of(context)!.avMinutesShort(w['slot_minutes'] as int)}'),
                          onDeleted: () => _deleteWindow(w),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddHoursSheet extends StatefulWidget {
  const _AddHoursSheet({required this.hrId});
  final String hrId;

  @override
  State<_AddHoursSheet> createState() => _AddHoursSheetState();
}

class _AddHoursSheetState extends State<_AddHoursSheet> {
  final Set<int> _days = {1, 2, 3, 4, 5};
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 12, minute: 0);
  int _slot = 30;
  bool _busy = false;
  String? _serverError;

  static const _slotChoices = [15, 20, 30, 45, 60, 90, 120];

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Live rule check, shown under the pickers as the values change.
  String? get _problem {
    final l10n = AppLocalizations.of(context)!;
    if (_days.isEmpty) return l10n.avPickOneDay;
    if (_minutes(_end) <= _minutes(_start)) return l10n.avEndAfterStart;
    if (_minutes(_end) - _minutes(_start) < _slot) return l10n.avShorterThanSlot(_slot);
    return null;
  }

  int get _slotCount => (_minutes(_end) - _minutes(_start)) ~/ _slot;

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pick(bool start) async {
    final picked = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _serverError = null;
    });
  }

  Future<void> _save() async {
    if (_problem != null) return;
    setState(() {
      _busy = true;
      _serverError = null;
    });
    try {
      await InterviewService.instance.addAvailability(
        hrId: widget.hrId,
        weekdays: _days.toList()..sort(),
        startTime: _fmt(_start),
        endTime: _fmt(_end),
        slotMinutes: _slot,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final text = friendlyError(e);
      setState(() {
        _busy = false;
        // Overlap with hours already set is the usual cause of a server refusal here.
        _serverError = isVagueDatabaseError(e)
            ? AppLocalizations.of(context)!.avOverlap
            : text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppLocalizations.of(context)!.avAddAvailableHours, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: _busy ? null : () => Navigator.pop(context, false)),
            ],
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.avDays, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(interviewWeekdayNameShort(d)),
                  selected: _days.contains(d),
                  onSelected: (on) => setState(() {
                    on ? _days.add(d) : _days.remove(d);
                    _serverError = null;
                  }),
                ),
            ],
          ),
          Row(
            children: [
              TextButton(onPressed: () => setState(() => _days..clear()..addAll([1, 2, 3, 4, 5])), child: Text(AppLocalizations.of(context)!.avMonFri)),
              TextButton(onPressed: () => setState(() => _days..clear()..addAll([1, 2, 3, 4, 5, 6, 7])), child: Text(AppLocalizations.of(context)!.avEveryDay)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(true),
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(AppLocalizations.of(context)!.avFromTime(_start.format(context))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(false),
                  icon: const Icon(Icons.access_time_filled, size: 18),
                  label: Text(AppLocalizations.of(context)!.avToTime(_end.format(context))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(AppLocalizations.of(context)!.avLengthOfInterview, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in _slotChoices)
                ChoiceChip(
                  label: Text(AppLocalizations.of(context)!.avMinutesShort(m)),
                  selected: _slot == m,
                  onSelected: (_) => setState(() {
                    _slot = m;
                    _serverError = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (problem != null)
            Text(problem, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error))
          else
            Text(AppLocalizations.of(context)!.avSlotsSummary(_slotCount, _slot),
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
          if (_serverError != null) ...[
            const SizedBox(height: 6),
            Text(_serverError!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (problem != null || _busy) ? null : _save,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context)!.avSaveHours),
            ),
          ),
        ],
      ),
    );
  }
}
