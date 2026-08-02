import 'package:flutter/material.dart';
import '../student/student_messages_screen.dart';

/// Messaging is role-agnostic (conversations/messages are keyed by user id,
/// not role), so this just reuses the same real screen students use rather
/// than duplicating the mock UI that was here before.
class HrMessagesScreen extends StatelessWidget {
  const HrMessagesScreen({super.key});

  // Not `const`: even though HrShell now passes a fresh (non-const)
  // HrMessagesScreen instance on every rebuild (see hr_shell.dart), if this
  // build() kept returning a `const StudentMessagesScreen()`, Dart would
  // canonicalize it to the same singleton every call, and Flutter's
  // Element.updateChild would skip rebuilding it (identical widget = no
  // update), freezing it at whatever AppColors brightness was active on
  // first build.
  @override
  Widget build(BuildContext context) => StudentMessagesScreen();
}
