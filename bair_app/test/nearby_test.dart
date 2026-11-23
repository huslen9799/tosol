import 'package:bair_app/screens/property_detail_page.dart';
import 'package:bair_app/services/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'widget_test.dart' as fixtures;

void main() {
  testWidgets('detail shows nearby amenities for a located property', (
    tester,
  ) async {
    await fixtures.mobileSize(tester);
    final requests = <http.Request>[];
    final located = {
      ...fixtures.sample,
      'latitude': 47.9185,
      'longitude': 106.9177,
    };
    final store = fixtures.testStore(
      requests,
      handler: (request) async {
        if (request.url.path == '/api/properties/1/') {
          return fixtures.jsonResponse(located);
        }
        if (request.url.path == '/api/properties/1/nearby/') {
          return fixtures.jsonResponse({
            'available': true,
            'categories': [
              {
                'key': 'school',
                'label': 'Сургууль',
                'places': [
                  {
                    'name': 'Төв сургууль',
                    'distance': 450,
                    'latitude': 47.92,
                    'longitude': 106.92,
                  },
                ],
              },
              {
                'key': 'bus_stop',
                'label': 'Автобусны буудал',
                'places': [],
              },
            ],
          });
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
    expect(find.text('Ойр байрлах газрууд'), findsOneWidget);
    expect(find.text('Төв сургууль'), findsOneWidget);
    expect(find.text('450 м'), findsWidgets);
    expect(
      requests.any((r) => r.url.path == '/api/properties/1/nearby/'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    store.api.client.close();
  });

  testWidgets('detail hides nearby section when property has no coordinates', (
    tester,
  ) async {
    await fixtures.mobileSize(tester);
    final requests = <http.Request>[];
    final store = fixtures.testStore(
      requests,
      handler: (request) async {
        if (request.url.path == '/api/properties/1/') {
          return fixtures.jsonResponse(fixtures.sample);
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
    expect(find.text('Ойр байрлах газрууд'), findsNothing);
    expect(
      requests.any((r) => r.url.path == '/api/properties/1/nearby/'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    store.api.client.close();
  });
}