import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/features/data_entry/domain/entities/data_element_entity.dart';
import 'package:hisp_mobile_trucker/features/data_entry/presentation/utils/data_entry_pdf.dart';

void main() {
  // buildDataEntryPdf loads the bundled Ethiopic fallback font via
  // rootBundle, which needs a live binding — same as any test that
  // touches platform channels/assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  const recordedElement = DataElementEntity(
    id: 'de1',
    name: 'ANC 1st visit',
    categoryOptionCombos: [
      CategoryOptionCombo(id: 'coc1', name: 'default'),
    ],
  );
  const blankElement = DataElementEntity(
    id: 'de2',
    name: 'Never entered',
    categoryOptionCombos: [
      CategoryOptionCombo(id: 'coc1', name: 'default'),
    ],
  );

  final dataValues = {
    'de1_coc1': DataValueEntity(
      dataElementId: 'de1',
      categoryOptionComboId: 'coc1',
      orgUnitId: 'ou1',
      period: '201811',
      value: '25',
    ),
    'de2_coc1': DataValueEntity(
      dataElementId: 'de2',
      categoryOptionComboId: 'coc1',
      orgUnitId: 'ou1',
      period: '201811',
      value: '', // never filled in
    ),
  };

  group('recordedDataElements', () {
    test('keeps only elements with at least one non-empty value', () {
      final result = recordedDataElements(
        dataElements: [recordedElement, blankElement],
        dataValues: dataValues,
      );
      expect(result, [recordedElement]);
    });

    test('empty when nothing has been entered', () {
      final result = recordedDataElements(
        dataElements: [blankElement],
        dataValues: dataValues,
      );
      expect(result, isEmpty);
    });
  });

  group('buildDataEntryPdf', () {
    test('produces a non-empty PDF for a recorded form', () async {
      final bytes = await buildDataEntryPdf(
        title: 'ANC Monthly',
        orgUnitName: 'Test Health Center',
        periodLabel: 'Hamle 2018',
        isDiseaseRegistration: false,
        dataElements: [recordedElement, blankElement],
        dataValues: dataValues,
        printedBy: 'shussein',
      );
      expect(bytes, isNotEmpty);
      // PDF files start with the "%PDF" magic bytes.
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('still produces a valid PDF when nothing is recorded', () async {
      final bytes = await buildDataEntryPdf(
        title: 'ANC Monthly',
        orgUnitName: 'Test Health Center',
        periodLabel: 'Hamle 2018',
        isDiseaseRegistration: true,
        dataElements: [blankElement],
        dataValues: const {},
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('renders Amharic text (Ethiopian period labels, element names) '
        'without crashing', () async {
      const amharicElement = DataElementEntity(
        id: 'de3',
        name: 'ክትባት', // "Vaccine"
        categoryOptionCombos: [
          CategoryOptionCombo(id: 'coc1', name: 'default'),
        ],
      );
      final bytes = await buildDataEntryPdf(
        title: amharicElement.name,
        orgUnitName: 'ጤና ጣቢያ', // "Health post"
        periodLabel: 'ሐምሌ 2018', // Amharic month name, like
        // EthiopianCalendar.monthNamesAmharic actually produces.
        isDiseaseRegistration: false,
        dataElements: [amharicElement],
        dataValues: {
          'de3_coc1': DataValueEntity(
            dataElementId: 'de3',
            categoryOptionComboId: 'coc1',
            orgUnitId: 'ou1',
            period: '201811',
            value: '5',
          ),
        },
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });
}
