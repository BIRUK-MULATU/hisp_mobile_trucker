import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/entities/outlier_stats.dart';
import 'package:hisp_mobile_trucker/features/data_entry/presentation/widgets/outlier_warning_dialog.dart';

/// Builds the verdict the service produces for a cell that read
/// 34, 38, 40 and has just been told 100.
OutlierVerdict spikeVerdict({double entered = 100}) => OutlierVerdict(
      value: entered,
      lowerBound: 29.1,
      upperBound: 46.9,
      score: 20.9,
      typical: 38,
      historicalMin: 34,
      historicalMax: 40,
      n: 3,
      recent: const [
        HistoryEntry(value: 40, periodId: '20260301'),
        HistoryEntry(value: 38, periodId: '20260201'),
        HistoryEntry(value: 34, periodId: '20260101'),
      ],
    );

/// Opens the dialog over a fresh [MaterialApp] and settles it.
Future<void> pump(WidgetTester tester, List<OutlierWarning> warnings) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => showOutlierWarning(context, warnings: warnings),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('outlier warning dialog', () {
    testWidgets('states the comparison in the order the user thinks in',
        (tester) async {
      await pump(tester, [
        OutlierWarning(label: 'Malaria cases', verdict: spikeVerdict()),
      ]);

      expect(find.text('Are you sure?'), findsOneWidget);
      expect(
        find.textContaining('The values for the previous 3 months were '
            '34, 38, and 40, but you entered 100 for this month. This value '
            'appears to be significantly higher than the previous 3 months.'),
        findsOneWidget,
      );
    });

    testWidgets('says "lower" for a value below the previous three',
        (tester) async {
      await pump(tester, [
        OutlierWarning(label: 'Malaria cases', verdict: spikeVerdict(entered: 2)),
      ]);
      expect(
        find.textContaining(
            'significantly lower than the previous 3 months'),
        findsOneWidget,
      );
    });

    testWidgets('offers both a save and a go-back action', (tester) async {
      await pump(tester, [
        OutlierWarning(label: 'Malaria cases', verdict: spikeVerdict()),
      ]);
      expect(find.text('Go back and correct'), findsOneWidget);
      expect(find.text('Save value'), findsOneWidget);
    });

    testWidgets('"Save value" saves, "Go back and correct" does not',
        (tester) async {
      bool? kept;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              kept = await showOutlierWarning(context, warnings: [
                OutlierWarning(label: 'Malaria cases', verdict: spikeVerdict()),
              ]);
            },
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save value'));
      await tester.pumpAndSettle();
      expect(kept, isTrue);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go back and correct'));
      await tester.pumpAndSettle();
      expect(kept, isFalse);
    });

    testWidgets('a second flagged value is listed rather than hidden',
        (tester) async {
      await pump(tester, [
        OutlierWarning(label: 'Malaria cases', verdict: spikeVerdict()),
        OutlierWarning(
          label: 'Deaths · Under 5',
          verdict: spikeVerdict(entered: 500),
        ),
      ]);
      expect(find.textContaining('2 values look very different'), findsOneWidget);
      expect(find.text('Malaria cases'), findsOneWidget);
      expect(find.text('Deaths · Under 5'), findsOneWidget);
      expect(find.text('Save anyway'), findsOneWidget);
    });

    testWidgets('a long list of flagged values scrolls instead of overflowing',
        (tester) async {
      await pump(tester, [
        for (var i = 0; i < 12; i++)
          OutlierWarning(label: 'Field $i', verdict: spikeVerdict()),
      ]);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('Field 11'), findsOneWidget);
    });
  });
}
