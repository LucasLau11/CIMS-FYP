import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/theme/role_theme.dart';

void main() {
  testWidgets('RoleHeaderBackground in a Column is as tall as its child and full width', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          RoleHeaderBackground(child: SizedBox(height: 90, child: Text('title'))),
          Expanded(child: Text('body')),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(RoleHeaderBackground));
    expect(size.height, 90);
    expect(size.width, tester.view.physicalSize.width / tester.view.devicePixelRatio);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('RoleHeaderBackground in an app bar fills the bar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(flexibleSpace: const RoleHeaderBackground(child: SizedBox.expand())),
        body: const SizedBox(),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(RoleHeaderBackground)).height, kToolbarHeight);
  });
}
