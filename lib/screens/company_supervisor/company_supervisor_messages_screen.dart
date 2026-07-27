import 'package:flutter/material.dart';
import '../student/student_messages_screen.dart';

/// Messaging is role-agnostic — reuses the same real screen students use.
class CompanySupervisorMessagesScreen extends StatelessWidget {
  const CompanySupervisorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) => const StudentMessagesScreen();
}
