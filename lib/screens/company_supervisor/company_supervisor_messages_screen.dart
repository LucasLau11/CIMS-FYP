import 'package:flutter/material.dart';
import '../student/student_messages_screen.dart';

/// Messaging is role-agnostic — reuses the same real screen students use.
class CompanySupervisorMessagesScreen extends StatelessWidget {
  const CompanySupervisorMessagesScreen({super.key});

  // Not `const`: even though CompanySupervisorShell now passes a fresh
  // (non-const) instance on every rebuild (see company_supervisor_shell.dart),
  // if this build() kept returning a `const StudentMessagesScreen()`, Dart
  // would canonicalize it to the same singleton every call, and Flutter's
  // Element.updateChild would skip rebuilding it (identical widget = no
  // update), freezing it at whatever AppColors brightness was active on
  // first build.
  @override
  Widget build(BuildContext context) => StudentMessagesScreen();
}
