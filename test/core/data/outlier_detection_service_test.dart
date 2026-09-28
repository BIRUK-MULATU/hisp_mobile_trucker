import 'package:flutter_test/flutter_test.dart';
import 'package:hisp_mobile_trucker/core/data/outlier_detection_service.dart';
import 'package:hisp_mobile_trucker/features/data_entry/domain/entities/outlier_stats.dart';

void main() {
  group('OutlierStats.fromValues', () {
    test('computes mean, median, min, max', () {
      final s = OutlierStats.fromValues([10, 20, 30, 40, 50])!;
      expect(s.n, 5);
      expect(s.mean, closeTo(30, 1e-9));
      expect(s.median, 30);
      expect(s.min, 10);
      expect(s.max, 50);
    });

    test('median of an even-length series is the midpoint average', () {
      final s = OutlierStats.fromValues([1, 2, 3, 4])!;
      expect(s.median, closeTo(2.5, 1e-9));
    });

    test('returns null when there is nothing numeric', () {
      expect(OutlierStats.fromValues(const []), isNull);
    });

    test('round-trips through JSON', () {
      final s = OutlierStats.fromValues([4, 8, 15, 16, 23, 42])!;
      final back = OutlierStats.fromJson(s.toJson());
      expect(back.n, s.n);
      expect(back.mean, s.mean);
      expect(back.median, s.median);
      expect(back.mad, s.mad);
    });
  });

  group('OutlierStats.fromHistory', () {
    HistoryEntry e(String period, double value) =>
        HistoryEntry(value: value, periodId: period);

    test('keeps the newest entries, newest-first', () {
      final stats = OutlierStats.fromHistory([
        e('20260501', 1),
        e('20260505', 5),
        e('20260503', 3),
        e('20260504', 4),
        e('20260502', 2),
      ])!;
      expect(stats.recent.map((h) => h.value), [5, 4, 3, 2, 1]);
      expect(stats.n, 5);
    });

    test('caps recent at recentCount', () {
      final entries = [
        for (var i = 1; i <= 20; i++)
          e('2026${i.toString().padLeft(4, '0')}', i.toDouble()),
      ];
      final stats = OutlierStats.fromHistory(entries)!;
      expect(stats.n, 20);
      expect(stats.recent.length, OutlierStats.recentCount);
      expect(stats.recent.first.value, 20);
    });

    test('stats use the whole history, not just recent', () {
      final stats = OutlierStats.fromHistory([
        e('20260101', 50),
        e('20260102', 50),
        e('20260103', 50),
        e('20260104', 5000),
      ])!;
      expect(stats.n, 4);
      expect(stats.mean, closeTo(1287.5, 0.01));
      expect(stats.recent.first.value, 5000);
    });

    test('recent round-trips through JSON', () {
      final s = OutlierStats.fromHistory([
        e('20260102', 14),
        e('20260101', 12),
        e('20260103', 13),
      ])!;
      final back = OutlierStats.fromJson(s.toJson());
      expect(back.recent.map((h) => h.value), [13, 14, 12]);
      expect(back.recent.first.periodId, '20260103');
    });

    test('old cached JSON without recent parses to an empty list', () {
      final back = OutlierStats.fromJson({
        'n': 3,
        'mean': 10.0,
        'stdDev': 1.0,
        'median': 10.0,
        'mad': 1.0,
        'min': 9.0,
        'max': 11.0,
      });
      expect(back.recent, isEmpty);
    });
  });

  group('OutlierDetectionService.cacheKey', () {
    test('names the window so a snapshot from another window is never read',
        () {
      final key = OutlierDetectionService.cacheKey(
        dataSetUid: 'ds1',
        orgUnitUid: 'ou1',
        attributeOptionComboUid: 'aoc1',
      );
      expect(
        key,
        contains('v${OutlierDetectionService.historyWindowPeriods}'),
        reason: 'a cached snapshot cannot be re-narrowed on read, so the '
            'window it was built with has to be part of its identity',
      );
      expect(key, isNot(contains('outlierHistory_ds1_ou1_aoc1')));
    });
  });

  group('OutlierDetectionService.lastPeriods', () {
    HistoryEntry e(String period, double value) =>
        HistoryEntry(value: value, periodId: period);

    test('keeps only the three newest periods', () {
      final windowed = OutlierDetectionService.lastPeriods([
        e('20260101', 34),
        e('20260201', 38),
        e('20260301', 40),
        e('20260401', 999),
        e('20260501', 888),
      ]);
      expect(windowed.length, OutlierDetectionService.historyWindowPeriods);
      expect(
        windowed.map((h) => h.value),
        [888, 999, 40],
        reason: 'newest periods first, regardless of fetch order',
      );
    });

    test('leaves a short history in place, but ordered newest-first', () {
      final two = [e('20260101', 34), e('20260201', 38)];
      expect(OutlierDetectionService.lastPeriods(two).map((h) => h.value),
          [38, 34]);
    });

    test('ignores the order the server sent the values in', () {
      final windowed = OutlierDetectionService.lastPeriods([
        e('20260501', 40),
        e('20260301', 34),
        e('20260401', 38),
      ]);
      expect(windowed.map((h) => h.value), [40, 38, 34]);
    });

    test('does not window a cell whose periods cannot be ordered', () {
      final entries = [
        e('', 34),
        e('', 38),
        e('', 40),
        e('', 100),
        e('', 900),
      ];
      expect(
        OutlierDetectionService.lastPeriods(entries).length,
        5,
        reason: 'blank period ids have no timeline to take the newest from',
      );
    });
  });

  group('three-period rule', () {
    // The case the feature exists for: a cell that has read 34, 38, 40
    // and is about to be told 100.
    final three = OutlierStats.fromHistory([
      const HistoryEntry(value: 34, periodId: '20260101'),
      const HistoryEntry(value: 38, periodId: '20260201'),
      const HistoryEntry(value: 40, periodId: '20260301'),
    ])!;

    test('flags a spike on the previous three months', () {
      final v = OutlierDetectionService.judge('100', three, OutlierConfig.defaults);
      expect(v, isNotNull);
      expect(v!.value, 100);
      expect(v.upperBound, lessThan(100));
      expect(v.previousValues, [34, 38, 40]);
    });

    test('quotes the previous values oldest-first', () {
      final v = OutlierDetectionService.judge('100', three, OutlierConfig.defaults)!;
      expect(
        v.recent.map((e) => e.value),
        [40, 38, 34],
        reason: 'recent is newest-first; the dialog reads oldest-first',
      );
      expect(v.previousValues, [34, 38, 40]);
    });

    test('lets an in-trend value through', () {
      expect(
        OutlierDetectionService.judge('41', three, OutlierConfig.defaults),
        isNull,
      );
    });

    test('an old spike no longer hides a new one', () {
      // A long history of 100s used to drag the statistics up far
      // enough that entering 100 looked normal. The cell has since
      // settled back to 34, 38, 40 over the three newest months.
      List<HistoryEntry> history() => [
            for (var i = 1; i <= 20; i++)
              HistoryEntry(
                value: 100,
                periodId: '2026${i.toString().padLeft(2, '0')}01',
              ),
            const HistoryEntry(value: 34, periodId: '20262101'),
            const HistoryEntry(value: 38, periodId: '20262201'),
            const HistoryEntry(value: 40, periodId: '20262301'),
          ];

      final longHistory = OutlierStats.fromHistory(history())!;
      final windowed =
          OutlierStats.fromHistory(OutlierDetectionService.lastPeriods(history()))!;

      expect(
        OutlierDetectionService.judge('100', longHistory, OutlierConfig.defaults),
        isNull,
        reason: 'the un-windowed history is what used to swallow the spike',
      );
      expect(
        OutlierDetectionService.judge('100', windowed, OutlierConfig.defaults),
        isNotNull,
        reason: 'the three-period window sees through it',
      );
    });

    test('skips a cell with fewer than three previous periods', () {
      final two = OutlierStats.fromHistory([
        const HistoryEntry(value: 34, periodId: '20260101'),
        const HistoryEntry(value: 38, periodId: '20260201'),
      ])!;
      expect(
        OutlierDetectionService.judge('100', two, OutlierConfig.defaults),
        isNull,
      );
    });
  });

  group('OutlierDetectionService.judge', () {
    // A steady facility: ~50/month with small wobble.
    final steady = OutlierStats.fromValues([48, 52, 49, 51, 50, 47, 53, 50])!;

    test('a normal value is not flagged (Z-score)', () {
      final v = OutlierDetectionService.judge(
          '51', steady, const OutlierConfig(algorithm: OutlierAlgorithm.zScore));
      expect(v, isNull);
    });

    test('a wildly high value is flagged (Z-score)', () {
      final v = OutlierDetectionService.judge('900', steady,
          const OutlierConfig(algorithm: OutlierAlgorithm.zScore));
      expect(v, isNotNull);
      expect(v!.value, 900);
      expect(v.upperBound, lessThan(900));
      expect(v.score, greaterThan(3));
    });

    test('modified Z-score flags a spike even when history has one already',
        () {
      final skewed =
          OutlierStats.fromValues([50, 48, 52, 49, 51, 50, 400])!;
      final v = OutlierDetectionService.judge('380', skewed,
          const OutlierConfig(algorithm: OutlierAlgorithm.modifiedZScore));
      expect(v, isNotNull);
      expect(v!.typical, closeTo(50, 2));
    });

    test('min-max uses the historical range plus a guard band', () {
      final v = OutlierDetectionService.judge('50', steady,
          const OutlierConfig(algorithm: OutlierAlgorithm.minMax));
      expect(v, isNull); // within 47..53
      final out = OutlierDetectionService.judge('120', steady,
          const OutlierConfig(algorithm: OutlierAlgorithm.minMax));
      expect(out, isNotNull);
    });

    test('lower threshold flags more values', () {
      final loose = OutlierDetectionService.judge('54', steady,
          const OutlierConfig(algorithm: OutlierAlgorithm.zScore));
      final tight = OutlierDetectionService.judge(
          '54',
          steady,
          const OutlierConfig(
              algorithm: OutlierAlgorithm.zScore, threshold: 1.0));
      expect(loose, isNull);
      expect(tight, isNotNull);
    });

    test('skips when there are fewer than 3 data points', () {
      final thin = OutlierStats.fromValues([10, 5000])!;
      expect(
        OutlierDetectionService.judge('9999', thin, const OutlierConfig()),
        isNull,
      );
    });

    test('skips a non-numeric value', () {
      expect(
        OutlierDetectionService.judge('abc', steady, const OutlierConfig()),
        isNull,
      );
    });

    test('skips when the history has no spread', () {
      final flat = OutlierStats.fromValues([50, 50, 50, 50])!;
      expect(
        OutlierDetectionService.judge('999', flat,
            const OutlierConfig(algorithm: OutlierAlgorithm.zScore)),
        isNull,
      );
    });

    test('verdict carries the newest actual values for the dialog', () {
      final history = OutlierStats.fromHistory([
        for (var i = 1; i <= 10; i++)
          HistoryEntry(
              value: i.toDouble(), periodId: '2026${i.toString().padLeft(4, '0')}'),
      ])!;
      final v = OutlierDetectionService.judge(
        '900',
        history,
        const OutlierConfig(),
      );
      expect(v, isNotNull);
      expect(v!.recent.length, OutlierDetectionService.recentEntryCount);
      // Newest three, newest first.
      expect(v.recent.map((e) => e.value), [10, 9, 8]);
    });
  });
}
