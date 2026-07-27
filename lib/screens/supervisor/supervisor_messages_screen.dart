import 'package:flutter/material.dart';
import '../student/student_messages_screen.dart' show StudentMessagesScreen;

/// Conversations/messages are role-agnostic (keyed by the current user's
/// id via StudentDataService, not their role) — the student messages
/// screen has no student-specific logic in it at all, so it's reused
/// directly here rather than duplicating the same list/chat/archive UI.
class SupervisorMessagesScreen extends StatelessWidget {
  const SupervisorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) => const StudentMessagesScreen();
}
