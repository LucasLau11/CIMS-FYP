import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/screens/hr/hr_applicants_screen.dart';
import 'package:fyp_cims/screens/hr/hr_availability_screen.dart';
import 'package:fyp_cims/screens/student/student_interview_screen.dart';
import 'package:fyp_cims/services/interview_service.dart';

import 'fixtures.dart';
import 'fixtures_staff.dart';
import 'layout_harness.dart';

/// Looks at the PICTURE of a screen, not at the colours in the code: for every piece of text it
/// compares the colour of the letters with the colour behind them, as drawn. This catches text that
/// "blends with the background" no matter how it came about (a theme colour never set, a colour
/// chosen for the dark theme showing up in the light one, ...). It is the check behind the
/// interview availability and reschedule screens that were unreadable in the light theme.

double _lum(int r, int g, int b) {
  double ch(int v) {
    final s = v / 255;
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b);
}

double _contrast(int c1, int c2) {
  final l1 = _lum((c1 >> 16) & 255, (c1 >> 8) & 255, c1 & 255);
  final l2 = _lum((c2 >> 16) & 255, (c2 >> 8) & 255, c2 & 255);
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

/// Every text on screen whose drawn letters have less than [min] contrast with what is behind them.
Future<List<String>> unreadableText(WidgetTester tester, {double min = 3.0}) async {
  final view = tester.binding.renderView;
  final layer = view.debugLayer as OffsetLayer;
  final size = view.size;
  final ui.Image image = (await tester.runAsync(() => layer.toImage(Offset.zero & size)))!;
  final ByteData data = (await tester.runAsync<ByteData?>(() => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
  final w = image.width;
  final h = image.height;

  int px(int x, int y) {
    final i = (y * w + x) * 4;
    return (data.getUint8(i) << 16) | (data.getUint8(i + 1) << 8) | data.getUint8(i + 2);
  }

  final problems = <String>[];
  for (final render in tester.allRenderObjects.whereType<RenderParagraph>()) {
    final text = render.text.toPlainText();
    if (text.trim().isEmpty || !render.attached || !render.hasSize) continue;
    final box = MatrixUtils.transformRect(render.getTransformTo(null), Offset.zero & render.size);
    final rect = box.intersect(Offset.zero & Size(w.toDouble(), h.toDouble()));
    if (rect.isEmpty || rect.width < 3 || rect.height < 3) continue;

    // Most common colour in the box = the background; the colour furthest from it = the letters.
    final counts = <int, int>{};
    for (var y = rect.top.floor(); y < rect.bottom.ceil() && y < h; y++) {
      for (var x = rect.left.floor(); x < rect.right.ceil() && x < w; x++) {
        counts.update(px(x, y), (v) => v + 1, ifAbsent: () => 1);
      }
    }
    if (counts.isEmpty) continue;
    final background = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    var best = background;
    var bestDistance = -1;
    for (final c in counts.keys) {
      final dr = ((c >> 16) & 255) - ((background >> 16) & 255);
      final dg = ((c >> 8) & 255) - ((background >> 8) & 255);
      final db = (c & 255) - (background & 255);
      final d = dr * dr + dg * dg + db * db;
      if (d > bestDistance) {
        bestDistance = d;
        best = c;
      }
    }
    final ratio = _contrast(best, background);
    if (ratio < min) {
      problems.add('"${text.replaceAll('\n', ' ')}" contrast ${ratio.toStringAsFixed(2)} '
          '(letters #${best.toRadixString(16).padLeft(6, '0')} on #${background.toRadixString(16).padLeft(6, '0')})');
    }
  }
  return problems;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) return;
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first, warnIfMissed: false);
  await _settle(tester);
}

String _slotTime(int day, int slot, int plusMinutes) {
  final d = DateTime.now().add(Duration(days: day));
  return DateTime.utc(d.year, d.month, d.day, 1 + slot ~/ 2, (slot % 2) * 30 + plusMinutes).toIso8601String();
}

Map<String, Object?> _tables(String role) => {
      ...staffTables(role),
      'rpc:interview_free_slots': [
        for (var day = 1; day <= 6; day++)
          for (var slot = 0; slot < 14; slot++)
            {'slot_start': _slotTime(day, slot, 0), 'slot_end': _slotTime(day, slot, 29), 'slot_minutes': 30},
      ],
    };

Map<String, dynamic> _hrApplicant(String status) {
  final a = application(status, withInterview: status == 'interview');
  return {
    ...a,
    'id': a['application_id'],
    'student_name': 'Lau Yik Hong',
    'programme': 'Diploma in IT',
    'student_reg_no': '24WMR12345',
    'internship_title': 'Prompt Engineer Intern',
    'company_name': 'Xilnex',
    'interview': a['interviews'] == null ? null : InterviewInfo.fromEmbed(a['interviews']),
  };
}

void main() {
  setUpAll(() async {
    await initFakeSupabase(tables: _tables('company_hr'));
  });

  final scenarios = <String, (String role, Widget Function() build, Future<void> Function(WidgetTester) act, String? expect)>{
    'HR availability screen': ('company_hr', () => const HrAvailabilityScreen(), (t) async {}, 'Monday'),
    'HR availability: add hours sheet': ('company_hr', () => const HrAvailabilityScreen(), (t) async => _tapText(t, 'Add hours'), 'Monday'),
    'HR: schedule interview sheet': (
      'company_hr',
      () => ApplicantDetailScreen(data: _hrApplicant('pending')),
      (t) async => _tapText(t, 'Schedule interview'),
      null
    ),
    'HR: reschedule interview sheet': (
      'company_hr',
      () => ApplicantDetailScreen(data: _hrApplicant('interview')),
      (t) async {
        await _tapText(t, 'Reschedule');
        if (find.byType(ChoiceChip).evaluate().isNotEmpty) {
          await t.tap(find.byType(ChoiceChip).first, warnIfMissed: false);
          await _settle(t);
        }
      },
      null
    ),
    'Student: reschedule interview sheet': (
      'student',
      () => StudentInterviewScreen(application: {
            ..._hrApplicant('interview'),
            'internships': {...posting(), 'id': postingId, 'company_name': 'Xilnex'},
          }),
      (t) async => _tapText(t, 'Reschedule'),
      null
    ),
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    scenarios.forEach((name, scenario) {
      testWidgets('$name is readable (${brightness.name})', (tester) async {
        final (role, build, act, expectText) = scenario;
        setFixtures(_tables(role));
        final found = <String>[];
        await checkLayout(
          tester,
          name,
          build,
          role: role,
          brightness: brightness,
          sizes: [deviceSizes[3]],
          scales: [1.0],
          expectText: expectText,
          interact: (t) async {
            await act(t);
            found.addAll(await unreadableText(t));
          },
        );
        expect(found, isEmpty, reason: '$name (${brightness.name}):\n${found.toSet().join('\n')}');
      });
    });
  }
}
