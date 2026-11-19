import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/validators.dart';
import 'package:fyp_cims/widgets/common/validated_field.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));

void main() {
  group('ValidatedField live validation', () {
    testWidgets('stays quiet while typing, then shows the rule after a pause', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_host(ValidatedField(controller: controller, fieldValidator: Validators.email)));

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('must contain "@"'), findsNothing); // too soon

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('must contain "@"'), findsOneWidget);
    });

    testWidgets('error clears as soon as the text becomes valid, and a tick appears', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_host(ValidatedField(controller: controller, fieldValidator: Validators.email)));

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('must contain "@"'), findsOneWidget);

      // Fixing it re-checks immediately (no extra wait needed).
      await tester.enterText(find.byType(TextField), 'abc@gmail.com');
      await tester.pump();
      expect(find.textContaining('must contain "@"'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('leaving the field validates immediately', (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      await tester.pumpWidget(_host(Column(children: [
        ValidatedField(controller: controller, fieldValidator: Validators.email, focusNode: focus),
        const TextField(key: Key('other')),
      ])));

      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'nope');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('other'))); // move focus away
      await tester.pump();
      expect(find.textContaining('must contain "@"'), findsOneWidget);
    });

    testWidgets('Form.validate() shows every field error at once (submit button path)', (tester) async {
      final formKey = GlobalKey<FormState>();
      final email = TextEditingController();
      final name = TextEditingController();
      await tester.pumpWidget(_host(Form(
        key: formKey,
        child: Column(children: [
          ValidatedField(controller: email, fieldValidator: Validators.email),
          ValidatedField(controller: name, fieldValidator: (v) => Validators.fullName(v)),
        ]),
      )));

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Full name is required.'), findsOneWidget);

      email.text = 'a@gmail.com';
      name.text = 'Lau Yik Hong';
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('a server message shows under the field and can be cleared', (tester) async {
      final controller = TextEditingController(text: 'whatever');
      String? server = 'Incorrect email or password.';
      late StateSetter setHost;
      await tester.pumpWidget(_host(StatefulBuilder(builder: (context, setState) {
        setHost = setState;
        return ValidatedField(
          controller: controller,
          fieldValidator: (v) => null,
          externalError: server,
        );
      })));

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      setHost(() => server = null);
      await tester.pump();
      expect(find.text('Incorrect email or password.'), findsNothing);
    });

    testWidgets('does not show a success tick when showSuccess is false', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_host(ValidatedField(
        controller: controller,
        fieldValidator: (v) => null,
        showSuccess: false,
      )));
      await tester.enterText(find.byType(TextField), 'fine');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });

  group('PasswordChecklist', () {
    testWidgets('rules turn green as the password is typed', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_host(PasswordChecklist(controller: controller)));

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));

      controller.text = 'abc';
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // lowercase only

      controller.text = r'Str0ng!pass';
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
    });
  });
}
