import 'analytics_data.dart';

/// Result of an offline-aware chart/visualization load — shared by
/// [LocalVisualizationRepository.loadChart] (this app's own charts)
/// and the server Dashboard repository's loadServerVisualization
/// (WebApp-authored visualizations): both follow the same
/// online-first, cache-fallback shape.
class ChartLoadResult {
  final AnalyticsData data;

  /// True when [data] came from the local cache rather than a live
  /// query — the UI must say so, since it can be stale.
  final bool isFromCache;

  /// When [isFromCache], the moment that result was captured.
  final DateTime? cachedAt;

  const ChartLoadResult(
      {required this.data, required this.isFromCache, this.cachedAt});
}
