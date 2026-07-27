import 'package:flutter/material.dart';
import '../student/student_messages_screen.dart';

/// Messaging is role-agnostic (conversations/messages are keyed by user id,
/// not role), so this just reuses the same real screen students use rather
/// than duplicating the mock UI that was here before.
class HrMessagesScreen extends StatelessWidget {
  const HrMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) => const StudentMessagesScreen();
}
