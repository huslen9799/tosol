import 'dart:convert';

import 'package:bair_app/main.dart';
import 'package:bair_app/services/api_client.dart';
import 'package:bair_app/services/app_store.dart';
import 'package:bair_app/widgets/app_theme.dart';
import 'package:bair_app/widgets/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('theme switches across pages at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      appThemeMode.value = ThemeMode.light;
      addTearDown(() => appThemeMode.value = ThemeMode.system);
      final store = AppStore(
        api: ApiClient(
          baseUrl: 'http://localhost:8000',
          client: SessionClient(
            MockClient(
              (_) async => http.Response(
                jsonEncode({'count': 0, 'results': []}),
                200,
                headers: {'content-type': 'application/json'},
              ),
            ),
          ),
        ),
      )..restoring = false;
      await tester.pumpWidget(BairApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Бараан горим'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ThemeToggle));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).colorScheme.primary, AppColors.turquoise);
      expect(Theme.of(context).colorScheme.secondary, AppColors.blue);
      expect(Theme.of(context).colorScheme.tertiary, AppColors.lavender);
      final chipLabel = tester.element(find.text('Орон сууц').first);
      expect(
        DefaultTextStyle.of(chipLabel).style.color,
        const Color(0xFFF4F7FC),
      );
      await tester.tap(find.text('Профайл').first);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ThemeToggle))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.byTooltip('Гэгээлэг горим'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ThemeToggle))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.api.client.close();
      store.dispose();
    });
  }
}
