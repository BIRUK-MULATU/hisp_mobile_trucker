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
