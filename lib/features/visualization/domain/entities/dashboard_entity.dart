/// A DHIS2 dashboard: a named collection of items (charts, tables,
/// maps, text...). Only visualization items are renderable here —
/// the rest are counted so the UI can say "2 items not supported".
class DashboardEntity {
  final String id;
  final String name;
  final List<DashboardVisualizationRef> visualizations;

  /// Dashboard items of types this app cannot render yet
  /// (MAP, TEXT, EVENT_CHART, ...).
  final int unsupportedItems;

  const DashboardEntity({
    required this.id,
    required this.name,
    required this.visualizations,
    this.unsupportedItems = 0,
  });
}

/// Reference to one visualization on a dashboard — enough to list it
/// and fetch its full definition on demand.
class DashboardVisualizationRef {
  final String id;
  final String name;

  /// DHIS2 visualization type (COLUMN, LINE, PIE, PIVOT_TABLE...).
  final String type;

  const DashboardVisualizationRef({
    required this.id,
    required this.name,
    required this.type,
  });
}
