import 'dart:convert';

import 'package:bair_app/screens/login_page.dart';
import 'package:bair_app/services/api_client.dart';
import 'package:bair_app/services/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final identifier in ['tester', 'tester@gmail.com']) {
    testWidgets('login submits email or username: $identifier', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final requests = <http.Request>[];
      final store = AppStore(
        api: ApiClient(
          baseUrl: 'http://localhost:8000',
          client: SessionClient(
            MockClient((request) async {
              requests.add(request);
              return http.Response(
                jsonEncode({
                  'token': 'test-token',
                  'user': {
                    'id': 1,
                    'username': 'tester',
                    'email': 'tester@gmail.com',
                  },
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }),
          ),
        ),
      )..restoring = false;
      await tester.pumpWidget(
        AppScope(
          store: store,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, ' $identifier ');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(jsonDecode(requests.single.body), {
        'identifier': identifier,
        'password': 'password123',
      });
      expect(store.loggedIn, isTrue);
      expect(find.byType(LoginPage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.api.client.close();
      store.dispose();
    });
  }
}
