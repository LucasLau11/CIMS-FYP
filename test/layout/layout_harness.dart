import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/l10n/app_localizations.dart';
import 'package:fyp_cims/theme/app_theme.dart';
import 'package:fyp_cims/theme/role_theme.dart';
import 'package:fyp_cims/widgets/app_frame.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A phone / foldable / tablet the layout checks run at (logical pixels).
class DeviceSize {
  const DeviceSize(this.name, this.width, this.height);
  final String name;
  final double width;
  final double height;
}

/// Widths from a folded Galaxy Z Fold's cover screen up to a landscape tablet.
const List<DeviceSize> deviceSizes = [
  DeviceSize('fold-cover 280x653', 280, 653),
  DeviceSize('small phone 320x568', 320, 568),
  DeviceSize('phone 360x640', 360, 640),
  DeviceSize('phone 393x852', 393, 852),
  DeviceSize('large phone 430x932', 430, 932),
  DeviceSize('fold-open 673x841', 673, 841),
  DeviceSize('tablet 768x1024', 768, 1024),
  DeviceSize('tablet-landscape 1280x800', 1280, 800),
];

/// System font scales to try (the app clamps what it honours, see AppFrame).
const List<double> textScales = [1.0, 1.3, 2.0];

String _b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');

String fakeJwt(String userId) =>
    '${_b64({'alg': 'HS256', 'typ': 'JWT'})}.${_b64({
      'sub': userId,
      'role': 'authenticated',
      'aud': 'authenticated',
      'exp': DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000,
    })}.sig';

/// Canned responses for the REST API, by table (or `rpc:<function>`). Filters
/// and selects are ignored: a table returns every row it was given, already
/// shaped like the embeds the screen asks for.
class FakeBackend {
  FakeBackend({Map<String, Object?>? tables}) : tables = tables ?? {};
  final Map<String, Object?> tables;

  http.Response handle(http.Request req) {
    final path = req.url.path;
    if (path.startsWith('/auth/v1/token')) {
      return _json(_session);
    }
    if (path.startsWith('/auth/v1/user')) {
      return _json(_user);
    }
    if (path.startsWith('/rest/v1/')) {
      final name = path.substring('/rest/v1/'.length);
      final key = name.startsWith('rpc/') ? 'rpc:${name.substring(4)}' : name;
      final data = tables[key] ?? const <Object>[];
      if (req.method != 'GET' && req.method != 'POST' || (req.method == 'POST' && !name.startsWith('rpc/'))) {
        return http.Response('[]', 201, headers: {'content-type': 'application/json'});
      }
      final wantsObject = (req.headers['Accept'] ?? req.headers['accept'] ?? '').contains('vnd.pgrst.object');
      if (wantsObject) {
        final list = data is List ? data : [data];
        if (list.isEmpty) {
          return http.Response(jsonEncode({'code': 'PGRST116', 'message': 'no rows'}), 406, headers: {'content-type': 'application/json'});
        }
        return _json(list.first);
      }
      return _json(data);
    }
    if (path.startsWith('/storage/v1/')) {
      return http.Response('{"signedURL":"/object/sign/x?token=t","signedUrl":"https://fake.invalid/x"}', 200, headers: {'content-type': 'application/json'});
    }
    return http.Response('{}', 200, headers: {'content-type': 'application/json'});
  }

  http.Response _json(Object? body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  static const String userId = '00000000-0000-4000-8000-000000000001';

  Map<String, dynamic> get _user => {
        'id': userId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'student@example.com',
        'app_metadata': {},
        'user_metadata': {},
        'created_at': '2026-01-01T00:00:00Z',
      };

  Map<String, dynamic> get _session => {
        'access_token': fakeJwt(userId),
        'token_type': 'bearer',
        'expires_in': 31536000,
        'refresh_token': 'refresh',
        'user': _user,
      };
}

FakeBackend? _backend;

/// Initialises Supabase once per test file against [backend] and signs a fake
/// user in, so screens that read `currentUserId` behave as if logged in.
Future<FakeBackend> initFakeSupabase({Map<String, Object?>? tables}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadRealFonts();
  SharedPreferences.setMockInitialValues({});
  _backend = FakeBackend(tables: tables);
  await Supabase.initialize(
    url: 'https://fake.supabase.co',
    anonKey: 'fake-anon-key',
    httpClient: MockClient((req) async {
      final r = _backend!.handle(req);
      // PostgREST reads `response.request`, which a hand-built Response does not have.
      return http.Response(r.body, r.statusCode, headers: r.headers, request: req);
    }),
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    debug: false,
  );
  await Supabase.instance.client.auth.setSession('refresh');
  return _backend!;
}

void setFixtures(Map<String, Object?> tables) {
  _backend!.tables
    ..clear()
    ..addAll(tables);
}

/// Everything that went wrong while rendering one screen at one size.
class LayoutProblem {
  LayoutProblem(this.screen, this.size, this.scale, this.message);
  final String screen;
  final String size;
  final double scale;
  final String message;
  @override
  String toString() => '$screen @ $size x$scale: $message';
}

/// Renders [build] at every size and text scale and returns the layout
/// problems (RenderFlex overflows and other layout exceptions) it hit.
Future<List<LayoutProblem>> checkLayout(
  WidgetTester tester,
  String name,
  Widget Function() build, {
  String? role,
  Brightness brightness = Brightness.light,
  List<DeviceSize> sizes = deviceSizes,
  List<double> scales = textScales,
  Future<void> Function(WidgetTester tester)? interact,
  String? expectText,
}) async {
  final problems = <LayoutProblem>[];
  final seen = <String>{};

  for (final size in sizes) {
    for (final scale in scales) {
      tester.view.physicalSize = Size(size.width, size.height);
      tester.view.devicePixelRatio = 1.0;

      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;

      RoleController.instance.setRole(role);
      AppColors.setBrightness(brightness);

      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: Locale(const String.fromEnvironment('LAYOUT_LOCALE', defaultValue: 'en')),
        supportedLocales: const [Locale('en'), Locale('ms'), Locale('zh')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: AppFrame(child: child ?? const SizedBox.shrink()),
        ),
        home: build(),
      ));
      for (var i = 0; i < 16; i++) {
        // Large responses are decoded on a real isolate, which fake time never
        // advances; give real time a moment to pass so the data arrives.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 250));
        // Screens that load in several stages need a few rounds; stop as soon
        // as the expected data is on screen (or after four rounds if none is expected).
        final ready = expectText == null ? i >= 3 : find.textContaining(expectText).evaluate().isNotEmpty;
        if (ready) break;
      }
      if (expectText != null && find.textContaining(expectText).evaluate().isEmpty) {
        // The screen never showed the fixture data (shape mismatch or error state),
        // so a clean result at this size would prove nothing.
        problems.add(LayoutProblem(name, size.name, scale, 'DATA NOT RENDERED (looking for "$expectText")'));
      }
      if (interact != null) {
        await interact(tester);
      }

      FlutterError.onError = previous;
      for (final e in errors) {
        final text = e.exceptionAsString();
        final firstLine = text.split('\n').first;
        final isLayout = text.contains('overflowed') || text.contains('RenderFlex') || text.contains('BoxConstraints') || text.contains('RenderBox');
        if (!isLayout) continue;
        // Say WHICH widget overflowed (file:line), not just by how much.
        final deep = e.toDiagnosticsNode().toStringDeep();
        final loc = RegExp(r'lib/([\w/]+\.dart):(\d+)').firstMatch(deep);
        final label = loc == null ? firstLine : '${loc.group(1)}:${loc.group(2)}  (${firstLine.replaceAll(RegExp(r'by [\d.]+ pixels'), 'overflow')})';
        if (seen.add('${size.name}|$scale|$label')) {
          problems.add(LayoutProblem(name, size.name, scale, label));
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  RoleController.instance.setRole(null);
  AppColors.setBrightness(Brightness.light);
  // Machine-readable trail (tab separated) so a whole run can be summarised.
  final report = File('build/layout_report.tsv');
  report.parent.createSync(recursive: true);
  for (final p in problems) {
    report.writeAsStringSync('${p.screen}\t${p.size.split(' ').first}\t${p.scale}\t${p.message}\n', mode: FileMode.append);
  }
  return problems;
}

/// Summarises problems, grouping by message so a repeated overflow is one line.
String describeProblems(List<LayoutProblem> problems) {
  final byKey = <String, List<LayoutProblem>>{};
  for (final p in problems) {
    byKey.putIfAbsent('${p.screen}: ${p.message}', () => []).add(p);
  }
  final b = StringBuffer();
  byKey.forEach((key, list) {
    final where = list.map((p) => '${p.size.split(' ').first}x${p.scale}').toSet().join(', ');
    b.writeln('$key\n    at: $where');
  });
  return b.toString();
}

/// Taps every tab of the first TabBar so each tab's content is laid out.
Future<void> tapAllTabs(WidgetTester tester) async {
  final count = find.byType(Tab).evaluate().length;
  for (var i = 0; i < count; i++) {
    final tab = find.byType(Tab).at(i);
    await tester.ensureVisible(tab);
    await tester.tap(tab, warnIfMissed: false);
    for (var k = 0; k < 3; k++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
}

/// Pumps [home] once in the app shell and lets async loads finish (for debugging).
Future<void> checkLayoutOnce(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    supportedLocales: const [Locale('en')],
    home: home,
  ));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Tests draw every glyph as a full-width square ("Ahem") unless real fonts are
/// loaded, which makes text about twice as wide as on a phone and hides how
/// layouts really behave. The app does not bundle Inter or Poppins, so on a
/// device Android falls back to Roboto; load that same font here (from the
/// Flutter SDK) for the families the app asks for, plus the Material icons.
Future<void> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> bytes(String name) async => ByteData.sublistView(await File('$dir/$name').readAsBytes());

  for (final family in ['Roboto', 'Inter', 'Poppins']) {
    final loader = FontLoader(family)
      ..addFont(bytes('roboto-regular.ttf'))
      ..addFont(bytes('roboto-bold.ttf'))
      ..addFont(bytes('roboto-medium.ttf'));
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')..addFont(bytes('materialicons-regular.otf'));
  await icons.load();
}
