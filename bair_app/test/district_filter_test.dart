import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bair_app/models/property.dart';
import 'package:bair_app/widgets/desktop_browser.dart';
import 'package:bair_app/screens/filter_sheet.dart';

void main() {
  test(
    'districts toggle independently and all clears selection and complex',
    () {
      final query = {'complex': '12'};
      toggleDistrict(query, 'Хан-Уул');
      toggleDistrict(query, 'Баянзүрх');
      expect(selectedDistricts(query), {'Хан-Уул', 'Баянзүрх'});
      expect(query.containsKey('complex'), isFalse);
      toggleDistrict(query, 'Хан-Уул');
      expect(selectedDistricts(query), {'Баянзүрх'});
      toggleDistrict(query, 'Баянзүрх');
      expect(query.containsKey('district'), isFalse);
      toggleDistrict(query, 'Сүхбаатар');
      toggleDistrict(query, '');
      expect(selectedDistricts(query), isEmpty);
    },
  );

  testWidgets(
    'desktop can check two districts and uncheck one before applying',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final search = TextEditingController();
      Map<String, String>? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesktopBrowser(
              query: const {},
              search: search,
              items: const [],
              count: 0,
              loading: false,
              loadingMore: false,
              hasNext: false,
              onMap: () {},
              onFilters: () {},
              onMore: () {},
              onRetry: () {},
              onApply: (query) => applied = query,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Хан-Уул'));
      await tester.tap(find.text('Баянзүрх'));
      await tester.pump();
      expect(find.byIcon(Icons.check_box), findsNWidgets(2));
      await tester.tap(find.text('Хан-Уул'));
      await tester.pump();
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      await tester.ensureVisible(find.text('Үр дүн харах'));
      await tester.tap(find.text('Үр дүн харах'));
      expect(applied?['district'], 'Баянзүрх');
      await tester.pumpWidget(const SizedBox());
      search.dispose();
    },
  );

  testWidgets('mobile filter sheet keeps multiple district selections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FilterSheet(query: {'district': 'Хан-Уул,Баянзүрх'}),
        ),
      ),
    );
    bool checked(String name) => tester
        .widget<FilterChip>(find.widgetWithText(FilterChip, name))
        .selected;
    expect(checked('Хан-Уул'), isTrue);
    expect(checked('Баянзүрх'), isTrue);
    await tester.tap(find.text('Хан-Уул'));
    await tester.pump();
    expect(checked('Хан-Уул'), isFalse);
    expect(checked('Баянзүрх'), isTrue);
  });
}
