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
  });
}
