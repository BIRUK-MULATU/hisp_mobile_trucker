import '../entities/analytics_data.dart';
import '../entities/chart_config.dart';
import '../entities/chart_load_result.dart';

export '../entities/chart_load_result.dart' show ChartLoadResult;

/// A data element together with its category option combos, so the
/// builder can expand a "Details Only" selection into `de.coc`
/// operand items without another round-trip.
class DataElementWithCocs {
  final ChartItemRef ref;
  final List<ChartItemRef> cocs;

  const DataElementWithCocs({required this.ref, required this.cocs});
}

/// Visualizations built and stored entirely on this device — never a
/// DHIS2 server-side Visualization object. A [ChartConfig] is the
/// saved configuration (data selection, org unit, period, chart
/// type); running it queries the DHIS2 Analytics API when online and
/// falls back to the last successful result when offline.
abstract class LocalVisualizationRepository {
  // ── Metadata for the builder (online-only: picking dimensions
  // needs the server) ──────────────────────────────────────────────

  Future<List<ChartItemRef>> getIndicatorGroups();

  Future<List<ChartItemRef>> getIndicatorsInGroup(String groupId);

  Future<List<ChartItemRef>> getDataElementGroups();

  /// Aggregatable data elements of one group, each with its COCs.
  Future<List<DataElementWithCocs>> getDataElementsInGroup(String groupId);

  Future<List<ChartItemRef>> getDataSets();

  // ── Saved visualizations (local device storage) ──────────────────

  /// Every saved visualization, newest first.
  Future<List<ChartConfig>> getSavedCharts();

  /// Creates a new saved visualization, or overwrites the existing one
  /// with the same id — this is how editing an existing chart is
  /// persisted (same id, new configuration).
  Future<void> saveChart(ChartConfig config);

  /// Permanently removes a saved visualization and its cached result.
  Future<void> deleteChart(String id);

  // ── Running / viewing ──────────────────────────────────────────

  /// Runs [config]'s analytics query live and caches the result.
  Future<AnalyticsData> runChart(ChartConfig config);

  /// Online-first, cache-fallback load for the chart VIEW screen: try
  /// a live query, fall back to the last cached result when offline
  /// or the request fails. [skipLiveAttempt] lets a caller that
  /// already knows it's offline skip straight to the cache.
  Future<ChartLoadResult> loadChart(
    ChartConfig config, {
    bool skipLiveAttempt = false,
  });
}
