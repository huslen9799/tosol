import 'dart:convert';

import 'package:bair_app/screens/property_detail_page.dart';
import 'package:bair_app/services/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'widget_test.dart' as fixtures;

Map<String, dynamic> comment(int id, {int likeCount = 0, bool isLiked = false}) =>
    {
      'id': id,
      'username': 'Бат',
      'user_id': 1,
      'text': 'Сайхан байр',
      'created_at': '2026-11-23T10:30:00Z',
      'like_count': likeCount,
      'is_liked': isLiked,
    };

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<({AppStore store, List<http.Request> requests})> open(
  WidgetTester tester, {
  required bool authenticated,
  required Future<http.Response> Function(http.Request) comments,
}) async {
  await fixtures.mobileSize(tester);
  final requests = <http.Request>[];
  final store = fixtures.testStore(
    requests,
    authenticated: authenticated,
    handler: (request) async {
      if (request.url.path == '/api/properties/1/') {
        return fixtures.jsonResponse({...fixtures.sample, 'is_owner': false});
      }
      if (request.url.path == '/api/properties/1/comments/') {
        return comments(request);
      }
      if (request.url.path.endsWith('/like/')) {
        return fixtures.jsonResponse({'like_count': 1, 'is_liked': true});
      }
      if (request.method == 'DELETE' &&
          request.url.path.startsWith('/api/properties/1/comments/')) {
        return http.Response('', 204);
      }
      return http.Response('', 418);
    },
  );
  await tester.pumpWidget(
    AppScope(
      store: store,
      child: MaterialApp(home: PropertyDetailPage(id: 1)),
    ),
  );
  await tester.pumpAndSettle();
  return (store: store, requests: requests);
}

void main() {
  testWidgets('guest sees comments without write or delete controls', (
    tester,
  ) async {
    final fixture = await open(
      tester,
      authenticated: false,
      comments: (request) async => fixtures.jsonResponse({
        'count': 1,
        'next': null,
        'results': [comment(1)],
      }),
    );
    expect(find.text('Сайхан байр'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Сэтгэгдэл бичих'), findsNothing);
    expect(find.text('Нэвтрэх'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Устгах'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    fixture.store.dispose();
    fixture.store.api.client.close();
  });

  testWidgets('logged-in user posts, likes and deletes own comment', (
    tester,
  ) async {
    final fixture = await open(
      tester,
      authenticated: true,
      comments: (request) async {
        if (request.method == 'POST') {
          return fixtures.jsonResponse({
            'id': 2,
            'username': 'Бат',
            'user_id': 1,
            'text': 'Сайхан байр',
            'created_at': '2026-11-23T10:30:00Z',
            'like_count': 0,
            'is_liked': false,
          }, 201);
        }
        return fixtures.jsonResponse({
          'count': 1,
          'next': null,
          'results': [comment(1)],
        });
      },
    );

    final field = find.widgetWithText(TextField, 'Сэтгэгдэл бичих');
    await scrollTo(tester, field);
    await tester.enterText(field, '  Сайхан байр  ');
    tester.testTextInput.hide();
    await scrollTo(tester, find.text('Нийтлэх'));
    await tester.tap(find.text('Нийтлэх'));
    await tester.pumpAndSettle();
    final write = fixture.requests.singleWhere(
      (r) => r.method == 'POST' && r.url.path == '/api/properties/1/comments/',
    );
    expect(jsonDecode(write.body)['text'], 'Сайхан байр');

    await scrollTo(tester, find.byIcon(Icons.thumb_up_outlined));
    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(
      fixture.requests.any((r) => r.url.path.endsWith('/comments/1/like/')),
      isTrue,
    );

    await scrollTo(tester, find.widgetWithText(TextButton, 'Устгах'));
    await tester.tap(find.widgetWithText(TextButton, 'Устгах'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Устгах'));
    await tester.pumpAndSettle();
    expect(
      fixture.requests.any(
        (r) => r.method == 'DELETE' && r.url.path == '/api/properties/1/comments/1/',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    fixture.store.dispose();
    fixture.store.api.client.close();
  });
}