import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/features/data_entry/domain/entities/data_element_entity.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/repositories/data_entry_repository.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/usecases/save_data_values_usecase.dart';
import 'package:hisp_mobile_trucker/features/data_entry/presentation/widgets/data_entry_table.dart';
import 'package:hisp_mobile_trucker/features/capture/domain/entities/dataset_entity.dart';
import 'package:hisp_mobile_trucker/features/capture/presentation/widgets/dataset_card.dart';
import 'package:hisp_mobile_trucker/core/data/validation_service.dart';
import 'package:hisp_mobile_trucker/core/network/connectivity_service.dart';
import 'package:hisp_mobile_trucker/features/home/presentation/widgets/home_app_bar.dart';

class _FakeDataEntryRepository implements DataEntryRepository {
  List<DataValueEntity>? savedValues;

  @override
  Future<void> saveDataValues({
    required List<DataValueEntity> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  }) async {
    savedValues = dataValues;
  }

  @override
  Future<List<DataElementEntity>> getDataElements(
          {required String dataSetId, String? sectionId}) =>
      throw UnimplementedError();

  @override
  Future<List<DataValueEntity>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<ValidationViolation>> validateDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  }) async =>
      const [];

  @override
  Future<bool> isCompleted({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> uncompleteDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('SaveDataValuesUseCase', () {
    DataValueEntity value(String id, {required bool modified}) =>
        DataValueEntity(
          dataElementId: id,
          categoryOptionComboId: 'combo',
          orgUnitId: 'ou1',
          period: '202601',
          value: '5',
          isModified: modified,
        );

    test('saves only the modified values', () async {
      final repository = _FakeDataEntryRepository();
      final useCase = SaveDataValuesUseCase(repository);

      await useCase.call(
        dataValues: [
          value('de1', modified: true),
          value('de2', modified: false),
        ],
        dataSetId: 'ds1',
        orgUnitId: 'ou1',
        period: '202601',
      );

      expect(repository.savedValues, hasLength(1));
      expect(repository.savedValues!.first.dataElementId, 'de1');
    });

    test('does not call the repository when nothing changed', () async {
      final repository = _FakeDataEntryRepository();
      final useCase = SaveDataValuesUseCase(repository);

      await useCase.call(
        dataValues: [value('de1', modified: false)],
        dataSetId: 'ds1',
        orgUnitId: 'ou1',
        period: '202601',
      );

      expect(repository.savedValues, isNull);
    });
  });

  group('DataSetCard', () {
    testWidgets(
        'fits a long two-line title inside a narrow grid tile '
        'without overflowing', (tester) async {
      // Mirrors the dataset grid: fixed 128px tile, narrow width.
      // The test framework fails on any RenderFlex overflow.
      const dataSet = DataSetEntity(
        id: 'ds1',
        name: '05.2 - Nutrition | Hospital, Health center, '
            'Comprehensive HP, Clinic | Monthly',
        periodType: 'Monthly',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 128,
                child: DataSetCard(dataSet: dataSet),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the dataset name and both sync chips',
        (tester) async {
      const dataSet = DataSetEntity(
        id: 'ds1',
        name: 'Malaria Monthly Report',
        periodType: 'Monthly',
        syncStatus: SyncStatus.synced,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DataSetCard(dataSet: dataSet)),
        ),
      );

      expect(find.text('Malaria Monthly Report'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('unsync'), findsOneWidget);
    });
  });

  group('DataEntryTable', () {
    testWidgets(
        'first element starts expanded; tapping headers toggles their combos',
        (tester) async {
      const disaggregated = DataElementEntity(
        id: 'de1',
        name: 'Malaria cases',
        categoryComboId: 'ccAgeSex',
        categoryOptionCombos: [
          CategoryOptionCombo(id: 'c1', name: 'Under 5'),
          CategoryOptionCombo(id: 'c2', name: '5 and above'),
        ],
      );
      const plain = DataElementEntity(
        id: 'de2',
        name: 'Stock-outs',
        categoryComboId: 'ccDefault',
        categoryOptionCombos: [
          CategoryOptionCombo(id: 'c3', name: 'Value'),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataEntryTable(
              dataElements: [disaggregated, plain],
              dataValues: {},
              orgUnitId: 'ou1',
              period: '202607',
            ),
          ),
        ),
      );

      // Both element headers are always listed.
      expect(find.text('Malaria cases'), findsOneWidget);
      expect(find.text('Stock-outs'), findsOneWidget);

      // Routine never gets the Total row — that's opt-in
      // (showElementTotal), Disease Registration only.
      expect(find.text('Total'), findsNothing);

      // The first element starts expanded: its combos are visible.
      expect(find.text('Under 5'), findsOneWidget);
      expect(find.text('5 and above'), findsOneWidget);

      // The rest start collapsed: their combos are hidden.
      expect(find.text('Value'), findsNothing);

      // Tapping a collapsed header reveals its combo rows AND
      // auto-closes whatever else was open (accordion, not
      // multi-expand) — shared by both Routine and Disease forms.
      await tester.tap(find.text('Stock-outs'));
      await tester.pump();
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Under 5'), findsNothing);
      expect(find.text('5 and above'), findsNothing);

      // Tapping another header swaps which one is open.
      await tester.tap(find.text('Malaria cases'));
      await tester.pump();
      expect(find.text('Under 5'), findsOneWidget);
      expect(find.text('5 and above'), findsOneWidget);
      expect(find.text('Value'), findsNothing);

      // Tapping the currently-open header just collapses it.
      await tester.tap(find.text('Malaria cases'));
      await tester.pump();
      expect(find.text('Under 5'), findsNothing);
      expect(find.text('5 and above'), findsNothing);
    });

    testWidgets(
        'showElementTotal sums the combos entered so far, live, at the '
        'end of the section', (tester) async {
      const element = DataElementEntity(
        id: 'de1',
        name: 'Malaria cases',
        categoryOptionCombos: [
          CategoryOptionCombo(id: 'c1', name: 'Male'),
          CategoryOptionCombo(id: 'c2', name: 'Female'),
        ],
      );

      Widget buildWith(Map<String, DataValueEntity> dataValues) => MaterialApp(
            home: Scaffold(
              body: DataEntryTable(
                dataElements: const [element],
                dataValues: dataValues,
                orgUnitId: 'ou1',
                period: '202607',
                showElementTotal: true,
              ),
            ),
          );

      await tester.pumpWidget(buildWith({
        'de1_c1': DataValueEntity(
          dataElementId: 'de1',
          categoryOptionComboId: 'c1',
          orgUnitId: 'ou1',
          period: '202607',
          value: '5',
        ),
      }));

      // Only Male entered so far — the Total row exists. (Its value
      // is also "5" here, same digit as the Male field itself, so
      // that particular number isn't asserted until it's unambiguous
      // below.)
      expect(find.text('Total'), findsOneWidget);

      // The parent (BlocBuilder in the real app) rebuilds with fresh
      // dataValues on every edit — simulate that here and confirm
      // Total recomputes from whatever is now entered.
      await tester.pumpWidget(buildWith({
        'de1_c1': DataValueEntity(
          dataElementId: 'de1',
          categoryOptionComboId: 'c1',
          orgUnitId: 'ou1',
          period: '202607',
          value: '5',
        ),
        'de1_c2': DataValueEntity(
          dataElementId: 'de1',
          categoryOptionComboId: 'c2',
          orgUnitId: 'ou1',
          period: '202607',
          value: '3',
        ),
      }));
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('readOnly makes every combo cell view-only, not editable',
        (tester) async {
      const element = DataElementEntity(
        id: 'de1',
        name: 'Malaria cases',
        categoryOptionCombos: [
          CategoryOptionCombo(id: 'c1', name: 'Cases'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataEntryTable(
              dataElements: const [element],
              dataValues: {
                'de1_c1': DataValueEntity(
                  dataElementId: 'de1',
                  categoryOptionComboId: 'c1',
                  orgUnitId: 'ou1',
                  period: '202607',
                  value: '5',
                ),
              },
              orgUnitId: 'ou1',
              period: '202607',
              readOnly: true,
            ),
          ),
        ),
      );

      // The value is still fully visible...
      expect(find.text('5'), findsOneWidget);
      // ...but the field itself refuses edits.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
    });
  });

  group('HomeAppBar', () {
    testWidgets('shows the filter button only when showFilterButton is set',
        (tester) async {
      for (final visible in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: HomeAppBar(showFilterButton: visible),
            ),
          ),
        );
        expect(
          find.byIcon(Icons.format_list_bulleted_rounded),
          visible ? findsOneWidget : findsNothing,
          reason: 'showFilterButton: $visible',
        );
      }
      // The embedded ConnectivityIndicator lazily created the
      // ConnectivityService singleton; flush its in-flight probe and
      // cancel the periodic timer so none are pending at teardown.
      await tester.pump(const Duration(seconds: 6));
      ConnectivityService.instance.dispose();
    });
  });
}
