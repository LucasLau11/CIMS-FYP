import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/screens/confirm_email_screen.dart';
import 'package:fyp_cims/screens/forgot_password_screen.dart';
import 'package:fyp_cims/screens/login_screen.dart';
import 'package:fyp_cims/screens/privacy_policy_screen.dart';
import 'package:fyp_cims/screens/signup_screen.dart';

import 'layout_harness.dart';

void main() {
  setUpAll(() async {
    await initFakeSupabase();
  });

  final screens = <String, dynamic Function()>{
    'LoginScreen': () => const LoginScreen(),
    'SignUpScreen': () => const SignUpScreen(),
    'ForgotPasswordScreen': () => const ForgotPasswordScreen(),
    'ConfirmEmailScreen': () => const ConfirmEmailScreen(email: 'a.very.long.email.address.for.a.student@student.tarc.edu.my'),
    'PrivacyPolicyScreen': () => const PrivacyPolicyScreen(),
  };

  screens.forEach((name, build) {
    testWidgets('$name has no overflow at any size', (tester) async {
      addTearDown(tester.view.reset);
      final problems = await checkLayout(tester, name, () => build());
      expect(problems, isEmpty, reason: '\n${describeProblems(problems)}');
    });
  });
}
