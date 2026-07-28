import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/features/data_entry/domain/entities/data_element_entity.dart';
import 'package:hisp_mobile_trucker/features/data_entry/presentation/widgets/data_entry_table.dart';
import 'package:hisp_mobile_trucker/features/data_entry/presentation/widgets/disease_entry_list.dart';

const _malaria = DataElementEntity(
  id: 'de-malaria',
  name: 'Malaria',
  categoryOptionCombos: [
    CategoryOptionCombo(id: 'coc-malaria', name: 'Cases'),
  ],
);

const _tb = DataElementEntity(
  id: 'de-tb',
  name: 'TB',
  categoryOptionCombos: [
    CategoryOptionCombo(id: 'coc-tb', name: 'Cases'),
  ],
);

const _cholera = DataElementEntity(
  id: 'de-cholera',
  name: 'Cholera',
  categoryOptionCombos: [
    CategoryOptionCombo(id: 'coc-cholera', name: 'Cases'),
  ],
);

Future<void> pumpList(
  WidgetTester tester,
  Map<String, DataValueEntity> values, {
  bool readOnly = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DiseaseEntryList(
          dataElements: const [_malaria, _tb, _cholera],
          dataValues: values,
          orgUnitId: 'ou1',
          period: '202607',
          readOnly: readOnly,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('only recorded diseases show by default — nothing is listed '
      'up front', (tester) async {
    await pumpList(tester, {
      'de-malaria_coc-malaria': DataValueEntity(
        dataElementId: 'de-malaria',
        categoryOptionComboId: 'coc-malaria',
        orgUnitId: 'ou1',
        period: '202607',
        value: '12',
      ),
    });
    await tester.pump();

    expect(find.text('Malaria'), findsOneWidget);
    expect(find.text('TB'), findsNothing);
    expect(find.text('Cholera'), findsNothing);
  });

  testWidgets('with nothing recorded, prompts to use "Select for new '
      'disease"', (tester) async {
    await pumpList(tester, {});
    await tester.pump();

    expect(find.textContaining('Select for new disease'), findsWidgets);
    expect(find.byType(DataEntryTable), findsNothing);
  });

  testWidgets('tapping the search field browses every not-yet-recorded '
      'disease', (tester) async {
    await pumpList(tester, {});
    await tester.pump();

    await tester.tap(find.widgetWithText(TextField, 'Select for new disease'));
    await tester.pump();

    expect(find.text('Malaria'), findsOneWidget);
    expect(find.text('TB'), findsOneWidget);
    expect(find.text('Cholera'), findsOneWidget);
  });

  testWidgets('typing narrows the dropdown to matching diseases',
      (tester) async {
    await pumpList(tester, {});
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextField, 'Select for new disease'), 'tb');
    await tester.pump();

    expect(find.text('TB'), findsOneWidget);
    expect(find.text('Malaria'), findsNothing);
    expect(find.text('Cholera'), findsNothing);
  });

  testWidgets(
      'leaving the search field without picking anything closes the '
      'dropdown', (tester) async {
    await pumpList(tester, {});
    await tester.pump();

    await tester.tap(find.widgetWithText(TextField, 'Select for new disease'));
    await tester.pump();
    expect(find.text('TB'), findsOneWidget,
        reason: 'dropdown open, browsing every disease');

    // Tap elsewhere (the list area below) without picking anything.
    await tester.tap(find.textContaining('No diseases yet'));
    await tester.pump();

    expect(find.text('TB'), findsNothing);
    expect(find.text('Malaria'), findsNothing);
    expect(find.text('Cholera'), findsNothing);
  });

  testWidgets('the collapse chevron closes the dropdown, and reopens it',
      (tester) async {
    await pumpList(tester, {});
    await tester.pump();

    await tester.tap(find.widgetWithText(TextField, 'Select for new disease'));
    await tester.pump();
    expect(find.text('TB'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pump();
    expect(find.text('TB'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    // Tapping it again (now pointing down) reopens the dropdown.
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pump();
    expect(find.text('TB'), findsOneWidget);
  });

  testWidgets(
      'picking a new disease opens it above anything already recorded',
      (tester) async {
    await pumpList(tester, {
      'de-malaria_coc-malaria': DataValueEntity(
        dataElementId: 'de-malaria',
        categoryOptionComboId: 'coc-malaria',
        orgUnitId: 'ou1',
        period: '202607',
        value: '12',
      ),
    });
    await tester.pump();

    await tester.tap(find.widgetWithText(TextField, 'Select for new disease'));
    await tester.pump();
    await tester.tap(find.text('TB'));
    await tester.pump();

    // Both now show; TB (just picked) renders first, above Malaria.
    final tbCenter = tester.getCenter(find.text('TB'));
    final malariaCenter = tester.getCenter(find.text('Malaria'));
    expect(tbCenter.dy, lessThan(malariaCenter.dy));

    // The newly picked disease (TB) opens expanded — its combo row
    // shows immediately without an extra tap. Malaria, already
    // recorded, starts collapsed again after the reorder.
    expect(find.text('Cases'), findsOneWidget);
  });

  testWidgets(
      'readOnly hides "Select for new disease" and makes recorded values '
      'view-only', (tester) async {
    await pumpList(
      tester,
      {
        'de-malaria_coc-malaria': DataValueEntity(
          dataElementId: 'de-malaria',
          categoryOptionComboId: 'coc-malaria',
          orgUnitId: 'ou1',
          period: '202607',
          value: '12',
        ),
      },
      readOnly: true,
    );
    await tester.pump();

    // The recorded disease is still visible...
    expect(find.text('Malaria'), findsOneWidget);
    // ...there's nothing to add a new one with...
    expect(find.widgetWithText(TextField, 'Select for new disease'),
        findsNothing);
    // ...and the underlying cell refuses edits.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.readOnly, isTrue);
  });
}
