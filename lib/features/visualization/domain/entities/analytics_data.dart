/// The analytics result for one visualization, already reshaped for
/// charting: series (the visualization's COLUMNS dimension) crossed
/// with categories (its ROWS dimension), names resolved from the
/// analytics metaData so Ethiopian period labels come straight from
/// the server.
class AnalyticsData {
  final String visualizationId;
  final String title;

  /// DHIS2 visualization type driving which chart is drawn.
  final String type;

  /// Category labels, in server order (x-axis / pie slices).
  final List<String> categories;

  /// One series per COLUMNS item: name + a value per category
  /// (null = no data for that cell).
  final List<AnalyticsSeries> series;

  const AnalyticsData({
    required this.visualizationId,
    required this.title,
    required this.type,
    required this.categories,
    required this.series,
  });

  bool get isEmpty =>
      series.isEmpty ||
      series.every((s) => s.values.every((v) => v == null));

  /// SINGLE_VALUE visualizations: the one number.
  double? get singleValue {
    for (final s in series) {
      for (final v in s.values) {
        if (v != null) return v;
      }
    }
    return null;
  }

  /// For the offline cache (see ChartRepositoryImpl) — round-trips
  /// through JSON exactly, so a cached chart renders identically to
  /// the live query that produced it.
  Map<String, dynamic> toJson() => {
        'visualizationId': visualizationId,
        'title': title,
        'type': type,
        'categories': categories,
        'series': [for (final s in series) s.toJson()],
      };

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => AnalyticsData(
        visualizationId: (json['visualizationId'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        type: (json['type'] ?? '') as String,
        categories:
            (json['categories'] as List? ?? const []).cast<String>(),
        series: [
          for (final s in (json['series'] as List? ?? const []))
            AnalyticsSeries.fromJson((s as Map).cast<String, dynamic>()),
        ],
      );
}

class AnalyticsSeries {
  final String name;
  final List<double?> values;

  const AnalyticsSeries({required this.name, required this.values});

  Map<String, dynamic> toJson() => {'name': name, 'values': values};

  factory AnalyticsSeries.fromJson(Map<String, dynamic> json) =>
      AnalyticsSeries(
        name: (json['name'] ?? '') as String,
        values: [
          for (final v in (json['values'] as List? ?? const []))
            v == null ? null : (v as num).toDouble(),
        ],
      );
}
