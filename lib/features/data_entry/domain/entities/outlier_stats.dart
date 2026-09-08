import 'dart:math' as math;

/// Which statistical test decides whether a typed value is an outlier.
/// Names/behaviour mirror DHIS2's own Outlier Detection app.
enum OutlierAlgorithm {
  /// Distance from the mean in standard deviations.
  zScore,

  /// Distance from the median in (scaled) median-absolute-deviations —
  /// robust to the very outliers it is looking for, so this is the
  /// default. DHIS2 calls it MODIFIED_Z_SCORE.
  modifiedZScore,

  /// Outside the historical [min, max] range, widened by a guard band
  /// of `threshold` standard deviations so a single past spike doesn't
  /// permanently stretch the acceptable range.
  minMax,
}

extension OutlierAlgorithmLabel on OutlierAlgorithm {
  String get label => switch (this) {
        OutlierAlgorithm.zScore => 'Z-score',
        OutlierAlgorithm.modifiedZScore => 'Modified Z-score',
        OutlierAlgorithm.minMax => 'Min–Max',
      };

  String get shortDescription => switch (this) {
        OutlierAlgorithm.zScore =>
          'Flags values more than the threshold number of standard '
              'deviations from the recent average.',
        OutlierAlgorithm.modifiedZScore =>
          'Like Z-score but measured from the median, so a few past '
              'spikes don\'t hide new ones. Recommended.',
        OutlierAlgorithm.minMax =>
          'Flags values outside the recent minimum–maximum range '
              '(plus a small guard band).',
      };
}

/// The user-chosen detection settings — one global default, persisted
/// via [OutlierConfigStore].
class OutlierConfig {
  const OutlierConfig({
    this.algorithm = OutlierAlgorithm.modifiedZScore,
    this.threshold = 3.0,
  });

  final OutlierAlgorithm algorithm;
  final double threshold;

  static const defaults = OutlierConfig();

  OutlierConfig copyWith({OutlierAlgorithm? algorithm, double? threshold}) =>
      OutlierConfig(
        algorithm: algorithm ?? this.algorithm,
        threshold: threshold ?? this.threshold,
      );
}

/// The recent history of ONE `(dataElement, categoryOptionCombo)` cell
/// at one org unit, reduced to the summary statistics every algorithm
/// needs. Built by [OutlierDetectionService.fetchHistory].
class OutlierStats {
  const OutlierStats({
    required this.n,
    required this.mean,
    required this.stdDev,
    required this.median,
    required this.mad,
    required this.min,
    required this.max,
  });

  /// Number of historical data points behind these figures.
  final int n;
  final double mean;
  final double stdDev;
  final double median;

  /// Median absolute deviation.
  final double mad;
  final double min;
  final double max;

  /// Derive the stats from a raw list of historical values. Returns
  /// null when there is nothing numeric to summarise.
  static OutlierStats? fromValues(Iterable<double> raw) {
    final values = raw.where((v) => v.isFinite).toList()..sort();
    if (values.isEmpty) return null;

    final n = values.length;
    final mean = values.reduce((a, b) => a + b) / n;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / n;
    final stdDev = math.sqrt(variance);

    double medianOf(List<double> sorted) {
      final m = sorted.length ~/ 2;
      return sorted.length.isOdd
          ? sorted[m]
          : (sorted[m - 1] + sorted[m]) / 2;
    }

    final median = medianOf(values);
    final deviations = (values.map((v) => (v - median).abs()).toList())..sort();
    final mad = medianOf(deviations);

    return OutlierStats(
      n: n,
      mean: mean,
      stdDev: stdDev,
      median: median,
      mad: mad,
      min: values.first,
      max: values.last,
    );
  }

  Map<String, dynamic> toJson() => {
        'n': n,
        'mean': mean,
        'stdDev': stdDev,
        'median': median,
        'mad': mad,
        'min': min,
        'max': max,
      };

  factory OutlierStats.fromJson(Map<String, dynamic> j) => OutlierStats(
        n: (j['n'] as num).toInt(),
        mean: (j['mean'] as num).toDouble(),
        stdDev: (j['stdDev'] as num).toDouble(),
        median: (j['median'] as num).toDouble(),
        mad: (j['mad'] as num).toDouble(),
        min: (j['min'] as num).toDouble(),
        max: (j['max'] as num).toDouble(),
      );
}

/// The result of judging one typed value against its [OutlierStats].
class OutlierVerdict {
  const OutlierVerdict({
    required this.value,
    required this.lowerBound,
    required this.upperBound,
    required this.score,
    required this.typical,
    required this.historicalMin,
    required this.historicalMax,
    required this.n,
  });

  final double value;
  final double lowerBound;
  final double upperBound;

  /// The algorithm's own score (z-score / modified z-score), or the
  /// number of guard-band widths past min/max for [OutlierAlgorithm.minMax].
  final double score;

  /// A representative "normal" value to show the user (the median).
  final double typical;
  final double historicalMin;
  final double historicalMax;
  final int n;
}
