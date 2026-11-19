import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/theme/app_theme.dart';
import 'package:fyp_cims/theme/role_theme.dart';

import 'contrast_audit_test.dart' show contrast;

/// Filter / choice / input chips (the day and time pickers in the HR availability screen and the
/// reschedule sheet) take their label colour from the theme. A label colour that was never set
/// there came out almost the same as the chip's own colour in the light theme.
void main() {
  for (final role in <String?>['student', 'academic_supervisor', 'company_hr', 'company_supervisor', 'admin']) {
    for (final dark in [false, true]) {
      testWidgets('chip labels are readable: role=$role dark=$dark', (tester) async {
        RoleController.instance.setRole(role);
        AppColors.setBrightness(dark ? Brightness.dark : Brightness.light);
        final theme = AppTheme.theme;
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Column(
              children: [
                FilterChip(label: const Text('Mon'), selected: true, onSelected: (_) {}),
                FilterChip(label: const Text('Tue'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('30 min'), selected: true, onSelected: (_) {}),
                ChoiceChip(label: const Text('45 min'), selected: false, onSelected: (_) {}),
                InputChip(label: const Text('09:00 – 12:00'), onDeleted: () {}),
              ],
            ),
          ),
        ));

        for (final entry in {
          'Mon': AppColors.accent,
          'Tue': AppColors.surfaceVariant,
          '30 min': AppColors.accent,
          '45 min': AppColors.surfaceVariant,
          '09:00 – 12:00': AppColors.surfaceVariant,
        }.entries) {
          final paragraph = tester.renderObject<RenderParagraph>(find.text(entry.key));
          final color = paragraph.text.style?.color;
          expect(color, isNotNull, reason: '"${entry.key}" has no label colour');
          expect(contrast(color!, entry.value), greaterThanOrEqualTo(4.5),
              reason: '"${entry.key}" label $color on ${entry.value} (role $role, dark $dark)');
        }
      });
    }
  }
}
