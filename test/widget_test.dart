import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/features/data_entry/domain/entities/data_element_entity.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/repositories/data_entry_repository.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/usecases/get_data_elements_usecase.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/usecases/save_data_values_usecase.dart';
import 'package:hisp_mobile_trucker/features/data_entry/presentation/bloc/data_entry_bloc.dart';
import 'package:hisp_mobile_trucker/features/data_entry/presentation/widgets/data_entry_table.dart';
import 'package:hisp_mobile_trucker/features/capture/domain/entities/dataset_entity.dart';
import 'package:hisp_mobile_trucker/features/capture/presentation/widgets/dataset_card.dart';
import 'package:hisp_mobile_trucker/core/data/indicator_display_service.dart';
import 'package:hisp_mobile_trucker/core/data/validation_service.dart';
import 'package:hisp_mobile_trucker/core/network/connectivity_service.dart';
import 'package:hisp_mobile_trucker/features/home/presentation/widgets/home_app_bar.dart';

class _FakeDataEntryRepository implements DataEntryRepository {
  _FakeDataEntryRepository({
    this.elementsToLoad = const [],
    this.valuesToLoad = const [],
  });

  List<DataValueEntity>? savedValues;

  /// What [getDataElements]/[getDataValues] hand back on a
  /// DataEntryLoad — only set by tests that actually load a form
  /// (e.g. to drive a real DataEntryBloc behind DataEntryTable).
  final List<DataElementEntity> elementsToLoad;
  final List<DataValueEntity> valuesToLoad;

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
          {required String dataSetId, String? sectionId}) async =>
      elementsToLoad;

  @override
  Future<List<DataValueEntity>> getDataValues({
    required String dataSetId,
    required String orgUnitId,
    required String period,
    String? attributeOptionComboUid,
  }) async =>
      valuesToLoad;

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
  Future<List<ValidationViolation>> validateLiveValues({
    required String dataSetId,
    required List<DataValueEntity> dataValues,
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

    testWidgets('shows the dataset name and both sync chips', (tester) async {
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
        'an element on the real "default" combo shows its field beside '
        'the name, not behind an accordion labeled "default"', (tester) async {
      const element = DataElementEntity(
        id: 'de3',
        name: 'Stock-outs',
        categoryComboId: 'ccDefault',
        categoryOptionCombos: [
          CategoryOptionCombo(id: 'default', name: 'default'),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataEntryTable(
              dataElements: [element],
              dataValues: {},
              orgUnitId: 'ou1',
              period: '202607',
            ),
          ),
        ),
      );

      // No "default" text anywhere, and no chevron to tap — the
      // field sits right on the header row from the start.
      expect(find.text('default'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
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
      // "8" now appears twice by design: the always-visible header
      // badge (so a disaggregated element's total reads without
      // expanding it) and the expanded section's own Total row.
      expect(find.text('8'), findsNWidgets(2));
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

  group('DataEntryTable — controller data elements', () {
    const controller = DataElementEntity(
      id: 'controllerDe1',
      name: 'Delivery services provided',
      valueType: 'BOOLEAN',
      categoryOptionCombos: [
        CategoryOptionCombo(id: 'ctlCombo001', name: 'default')
      ],
      controlledElementIds: ['gatedDe00001'],
    );
    const gated = DataElementEntity(
      id: 'gatedDe00001',
      name: 'Normal deliveries',
      categoryOptionCombos: [
        CategoryOptionCombo(id: 'gtdCombo001', name: 'default')
      ],
    );

    // Mirrors how DataEntryPage really wires DataEntryTable to the
    // Bloc: the table only ever displays state.dataValues/dataElements
    // and dispatches DataEntryValueChanged — a real Bloc + BlocBuilder
    // is what proves the confirm/clear round-trip actually lands.
    Widget harness({required List<DataValueEntity> initialValues}) {
      final repo = _FakeDataEntryRepository(
        elementsToLoad: const [controller, gated],
        valuesToLoad: initialValues,
      );
      final bloc = DataEntryBloc(
        getDataElementsUseCase: GetDataElementsUseCase(repo),
        saveDataValuesUseCase: SaveDataValuesUseCase(repo),
        repository: repo,
      )..add(const DataEntryLoad(
          dataSetId: 'ds1', orgUnitId: 'ou1', period: '202607'));
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: BlocBuilder<DataEntryBloc, DataEntryState>(
              builder: (context, state) {
                if (state is! DataEntryLoaded) return const SizedBox();
                return DataEntryTable(
                  dataElements: state.dataElements,
                  dataValues: state.dataValues,
                  orgUnitId: 'ou1',
                  period: '202607',
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets(
        'a closed controller hides what it controls; answering Yes '
        'reveals them', (tester) async {
      await tester.pumpWidget(harness(initialValues: const []));
      await tester.pumpAndSettle();

      expect(find.text('Delivery services provided'), findsOneWidget);
      expect(find.text('Normal deliveries'), findsNothing);

      await tester.tap(find.text('—')); // unanswered -> Yes
      await tester.pumpAndSettle();

      expect(find.text('Normal deliveries'), findsOneWidget);
    });

    testWidgets(
        'closing an open controller that has entered data asks first — '
        'cancelling leaves the data and the section alone', (tester) async {
      await tester.pumpWidget(harness(initialValues: [
        DataValueEntity(
          dataElementId: controller.id,
          categoryOptionComboId: 'ctlCombo001',
          orgUnitId: 'ou1',
          period: '202607',
          value: 'true',
        ),
        DataValueEntity(
          dataElementId: gated.id,
          categoryOptionComboId: 'gtdCombo001',
          orgUnitId: 'ou1',
          period: '202607',
          value: '12',
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Normal deliveries'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      await tester.tap(find.text('Yes')); // true -> false
      await tester.pumpAndSettle();
      expect(find.text('Clear entered data?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Nothing moved: still open, still "Yes", data untouched.
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Normal deliveries'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets(
        'confirming the close clears the controlled values and hides '
        'the section again', (tester) async {
      await tester.pumpWidget(harness(initialValues: [
        DataValueEntity(
          dataElementId: controller.id,
          categoryOptionComboId: 'ctlCombo001',
          orgUnitId: 'ou1',
          period: '202607',
          value: 'true',
        ),
        DataValueEntity(
          dataElementId: gated.id,
          categoryOptionComboId: 'gtdCombo001',
          orgUnitId: 'ou1',
          period: '202607',
          value: '12',
        ),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes')); // true -> false
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear and close'));
      await tester.pumpAndSettle();

      // The controller itself now reads No, and the section it used
      // to show is gone entirely.
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Normal deliveries'), findsNothing);

      // Reopening confirms the data was actually cleared, not just
      // hidden: no confirmation this time (nothing left to lose) and
      // the field comes back empty.
      await tester.tap(find.text('No')); // false -> unanswered
      await tester.pumpAndSettle();
      await tester.tap(find.text('—')); // unanswered -> true
      await tester.pumpAndSettle();

      expect(find.text('Clear entered data?'), findsNothing);
      expect(find.text('Normal deliveries'), findsOneWidget);
      expect(find.text('12'), findsNothing);
    });
  });

  group('DataEntryTable — labeled data elements', () {
    const prlafpLabel =
        'Premature Removal of Long term family planning methods (PRLAFP)';

    testWidgets(
        'a labeled element gets its resolved label as a heading above it',
        (tester) async {
      const labeled = DataElementEntity(
        id: 'de1',
        name: 'MAT_LAFP Removal within 6 Months of Insertion',
        label: prlafpLabel,
        categoryOptionCombos: [CategoryOptionCombo(id: 'c1', name: 'default')],
      );
      const plain = DataElementEntity(
        id: 'de2',
        name: 'Stock-outs',
        categoryOptionCombos: [CategoryOptionCombo(id: 'c2', name: 'default')],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataEntryTable(
              dataElements: [labeled, plain],
              dataValues: {},
              orgUnitId: 'ou1',
              period: '202607',
            ),
          ),
        ),
      );

      expect(find.text(prlafpLabel), findsOneWidget);
      expect(find.text('MAT_LAFP Removal within 6 Months of Insertion'),
          findsOneWidget);
      // The unlabeled element gets no heading of its own.
      expect(find.text('Stock-outs'), findsOneWidget);
    });

    testWidgets('elements sharing one label are grouped under a SINGLE heading',
        (tester) async {
      const a = DataElementEntity(
        id: 'de1',
        name: 'Patient Neutral response',
        label: 'Satisfaction survey',
        categoryOptionCombos: [CategoryOptionCombo(id: 'c1', name: 'default')],
      );
      const b = DataElementEntity(
        id: 'de2',
        name: 'Staff Neutral response',
        label: 'Satisfaction survey',
        categoryOptionCombos: [CategoryOptionCombo(id: 'c2', name: 'default')],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataEntryTable(
              dataElements: [a, b],
              dataValues: {},
              orgUnitId: 'ou1',
              period: '202607',
            ),
          ),
        ),
      );

      // One heading, both elements listed underneath it.
      expect(find.text('Satisfaction survey'), findsOneWidget);
      expect(find.text('Patient Neutral response'), findsOneWidget);
      expect(find.text('Staff Neutral response'), findsOneWidget);
    });
  });

  group('DataEntryTable — displayable indicators', () {
    const carAgeIndicator = DisplayIndicator(
      name: 'MAT_New and Repeat Contraceptive Acceptors by Age',
      numerator: '#{newAccept01} + #{repeatAcc01}',
      denominator: '1',
      factor: 1,
    );
    const newAcceptors = DataElementEntity(
      id: 'newAccept01',
      name: 'MAT_Contraceptive New Acceptors By Age',
      displayIndicators: [carAgeIndicator],
      categoryOptionCombos: [CategoryOptionCombo(id: 'c1', name: 'default')],
    );
    const repeatAcceptors = DataElementEntity(
      id: 'repeatAcc01',
      name: 'MAT_Contraceptive Repeat Acceptors By Age',
      categoryOptionCombos: [CategoryOptionCombo(id: 'c2', name: 'default')],
    );

    testWidgets(
        'renders the calculated value above its anchor element, and it '
        'updates live as the referenced values change', (tester) async {
      Widget buildWith(Map<String, DataValueEntity> dataValues) => MaterialApp(
            home: Scaffold(
              body: DataEntryTable(
                dataElements: const [newAcceptors, repeatAcceptors],
                dataValues: dataValues,
                orgUnitId: 'ou1',
                period: '202607',
              ),
            ),
          );

      await tester.pumpWidget(buildWith({
        'newAccept01_c1': DataValueEntity(
          dataElementId: 'newAccept01',
          categoryOptionComboId: 'c1',
          orgUnitId: 'ou1',
          period: '202607',
          value: '30',
        ),
        'repeatAcc01_c2': DataValueEntity(
          dataElementId: 'repeatAcc01',
          categoryOptionComboId: 'c2',
          orgUnitId: 'ou1',
          period: '202607',
          value: '15',
        ),
      }));

      expect(find.text('MAT_New and Repeat Contraceptive Acceptors by Age'),
          findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      // Not an input — no field carries this indicator's own value.
      expect(find.widgetWithText(TextField, '45'), findsNothing);

      // The parent rebuilds with fresh dataValues on every edit, same
      // as the real Bloc-driven form — the indicator must follow.
      await tester.pumpWidget(buildWith({
        'newAccept01_c1': DataValueEntity(
          dataElementId: 'newAccept01',
          categoryOptionComboId: 'c1',
          orgUnitId: 'ou1',
          period: '202607',
          value: '30',
        ),
        'repeatAcc01_c2': DataValueEntity(
          dataElementId: 'repeatAcc01',
          categoryOptionComboId: 'c2',
          orgUnitId: 'ou1',
          period: '202607',
          value: '25',
        ),
      }));

      expect(find.text('55'), findsOneWidget);
      expect(find.text('45'), findsNothing);
    });

    testWidgets(
        'an indicator referencing another indicator (N{...}, '
        'unsupported offline) renders nothing rather than a wrong value',
        (tester) async {
      const unsupported = DisplayIndicator(
        name: 'Depends on another indicator',
        numerator: 'N{someIndicat}',
        denominator: '1',
        factor: 1,
      );
      const element = DataElementEntity(
        id: 'de1',
        name: 'Plain element',
        displayIndicators: [unsupported],
        categoryOptionCombos: [CategoryOptionCombo(id: 'c1', name: 'default')],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataEntryTable(
              dataElements: [element],
              dataValues: {},
              orgUnitId: 'ou1',
              period: '202607',
            ),
          ),
        ),
      );

      expect(find.text('Depends on another indicator'), findsNothing);
      expect(find.text('Plain element'), findsOneWidget);
    });
  });

  group('DataEntryTable — greyed fields', () {
    testWidgets(
        'a greyed combo renders disabled with no editable field, and is '
        'excluded from the filled/total count', (tester) async {
      const element = DataElementEntity(
        id: 'de1',
        name: 'Disease diagnosis',
        categoryOptionCombos: [
          CategoryOptionCombo(id: 'c1', name: 'Male'),
          CategoryOptionCombo(id: 'c2', name: 'Female', isGreyed: true),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataEntryTable(
              dataElements: [element],
              dataValues: {},
              orgUnitId: 'ou1',
              period: '202607',
            ),
          ),
        ),
      );

      // Only the non-greyed combo gets a real, editable field.
      expect(find.byType(TextField), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isFalse);

      // "—" appears twice: the header's disaggregation-total badge
      // (nothing entered yet) and the greyed combo's own placeholder.
      expect(find.text('—'), findsNWidgets(2));

      // "0/1", not "0/2" — the greyed cell was never enterable to
      // begin with.
      expect(find.text('0/1'), findsOneWidget);
    });

    testWidgets('a greyed cell ignores taps — it never becomes editable',
        (tester) async {
      const boolElement = DataElementEntity(
        id: 'de1',
        name: 'Some Boolean KPI',
        valueType: 'BOOLEAN',
        categoryOptionCombos: [
          CategoryOptionCombo(id: 'c1', name: 'default', isGreyed: true),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataEntryTable(
              dataElements: [boolElement],
              dataValues: {},
              orgUnitId: 'ou1',
              period: '202607',
            ),
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      // Never renders the Yes/No boolean cell, tap or not.
      await tester.tap(find.text('—'));
      await tester.pump();
      expect(find.text('Yes'), findsNothing);
      expect(find.text('—'), findsOneWidget);
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
