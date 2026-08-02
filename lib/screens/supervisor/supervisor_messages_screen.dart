import 'package:flutter/material.dart';
import '../student/student_messages_screen.dart' show StudentMessagesScreen;

/// Conversations/messages are role-agnostic (keyed by the current user's
/// id via StudentDataService, not their role) — the student messages
/// screen has no student-specific logic in it at all, so it's reused
/// directly here rather than duplicating the same list/chat/archive UI.
class SupervisorMessagesScreen extends StatelessWidget {
  const SupervisorMessagesScreen({super.key});

  // Not `const`: even though SupervisorShell now passes a fresh (non-const)
  // instance on every rebuild (see supervisor_shell.dart), if this build()
  // kept returning a `const StudentMessagesScreen()`, Dart would
  // canonicalize it to the same singleton every call, and Flutter's
  // Element.updateChild would skip rebuilding it (identical widget = no
  // update), freezing it at whatever AppColors brightness was active on
  // first build.
  @override
  Widget build(BuildContext context) => StudentMessagesScreen();
}
