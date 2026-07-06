import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/features/data_entry/domain/entities/data_element_entity.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/repositories/data_entry_repository.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/usecases/save_data_values_usecase.dart';
import 'package:hisp_mobile_trucker/features/data_entry/presentation/widgets/data_entry_table.dart';
import 'package:hisp_mobile_trucker/features/home/domain/entities/dataset_entity.dart';
import 'package:hisp_mobile_trucker/features/home/presentation/widgets/dataset_card.dart';

class _FakeDataEntryRepository implements DataEntryRepository {
  List<DataValueEntity>? savedValues;

  @override
  Future<void> saveDataValues({
    required List<DataValueEntity> dataValues,
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) async {
    savedValues = dataValues;
  }

  @override
  Future<List<DataElementEntity>> getDataElements(
          {required String dataSetId}) =>
      throw UnimplementedError();

  @override
  Future<List<DataValueEntity>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> completeDataSet({
    required String dataSetId,
    required String orgUnitId,
    required String period,
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
        'shows every category combo group with its own headers',
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
      // Different combo than the first element — before the grouping
      // fix its columns were never shown as headers.
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

      expect(find.text('Under 5'), findsOneWidget);
      expect(find.text('5 and above'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Malaria cases'), findsOneWidget);
      expect(find.text('Stock-outs'), findsOneWidget);
    });
  });
}
