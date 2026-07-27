/// A user-built chart: everything needed to (re)run its analytics
/// query and render it. Persisted as JSON in the per-user database's
/// syncInfo store, so saved charts survive restarts without a schema
/// migration.
library;

/// The chart types the builder offers, mapped to the DHIS2
/// visualization type ids the renderer already understands.
enum ChartType {
  column('COLUMN', 'Column Chart'),
  bar('BAR', 'Bar Chart'),
  line('LINE', 'Line Chart'),
  pie('PIE', 'Pie Chart'),
  singleValue('SINGLE_VALUE', 'Single Value'),
  gauge('GAUGE', 'Gauge');

  const ChartType(this.dhis2Type, this.label);
  final String dhis2Type;
  final String label;

  static ChartType fromDhis2(String type) => ChartType.values.firstWhere(
        (t) => t.dhis2Type == type,
        orElse: () => ChartType.column,
      );
}

enum ChartDataType {
  indicator('Indicator'),
  dataElement('Data Element'),
  dataSet('Dataset');

  const ChartDataType(this.label);
  final String label;
}

enum Disaggregation {
  totalsOnly('Totals Only'),
  detailsOnly('Details Only');

  const Disaggregation(this.label);
  final String label;
}

/// Data set reporting metrics — the `ds.METRIC` dx item suffixes the
/// analytics API accepts.
enum DataSetMetric {
  reportingRate('REPORTING_RATE', 'Reporting Rate'),
  reportingRateOnTime('REPORTING_RATE_ON_TIME', 'Reporting Rate on Time'),
  actualReports('ACTUAL_REPORTS', 'Actual Reports'),
  actualReportsOnTime('ACTUAL_REPORTS_ON_TIME', 'Actual Reports on Time'),
  expectedReports('EXPECTED_REPORTS', 'Expected Reports');

  const DataSetMetric(this.apiName, this.label);
  final String apiName;
  final String label;
}

enum PeriodKind { relative, fixed }

/// One selectable metadata item (indicator, data element, operand,
/// data set, org unit…): the uid that goes on the wire plus the name
/// shown to the user.
class ChartItemRef {
  final String id;
  final String name;

  const ChartItemRef({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ChartItemRef.fromJson(Map<String, dynamic> json) => ChartItemRef(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
      );
}

class ChartConfig {
  final String id;
  final String name;
  final ChartType chartType;
  final ChartDataType dataType;

  /// The indicator/data element group the items came from — only for
  /// showing where the selection lives; not part of the query.
  final String? groupName;

  /// The dx selection, ready for analytics: indicator uids, data
  /// element uids (totals) or `de.coc` operand uids (details), or the
  /// single data set uid (the metric suffix is appended at query time).
  final List<ChartItemRef> items;

  final Disaggregation? disaggregation;
  final DataSetMetric? metric;

  final String orgUnitId;
  final String orgUnitName;

  final PeriodKind periodKind;

  /// Relative id (THIS_YEAR…) or a fixed Ethiopian period id (201811).
  final String periodId;
  final String periodLabel;

  final DateTime createdAt;

  const ChartConfig({
    required this.id,
    required this.name,
    required this.chartType,
    required this.dataType,
    this.groupName,
    required this.items,
    this.disaggregation,
    this.metric,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.periodKind,
    required this.periodId,
    required this.periodLabel,
    required this.createdAt,
  });

  /// The analytics dx dimension items for this chart.
  List<String> get dxItems => [
        for (final item in items)
          dataType == ChartDataType.dataSet
              ? '${item.id}.${(metric ?? DataSetMetric.reportingRate).apiName}'
              : item.id,
      ];

  String get summary => '${dataType.label} · $orgUnitName · $periodLabel';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'chartType': chartType.dhis2Type,
        'dataType': dataType.name,
        if (groupName != null) 'groupName': groupName,
        'items': [for (final i in items) i.toJson()],
        if (disaggregation != null) 'disaggregation': disaggregation!.name,
        if (metric != null) 'metric': metric!.name,
        'orgUnitId': orgUnitId,
        'orgUnitName': orgUnitName,
        'periodKind': periodKind.name,
        'periodId': periodId,
        'periodLabel': periodLabel,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChartConfig.fromJson(Map<String, dynamic> json) => ChartConfig(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        chartType: ChartType.fromDhis2((json['chartType'] ?? '') as String),
        dataType: ChartDataType.values.asNameMap()[json['dataType']] ??
            ChartDataType.indicator,
        groupName: json['groupName'] as String?,
        items: [
          for (final i in (json['items'] as List? ?? const []))
            ChartItemRef.fromJson((i as Map).cast<String, dynamic>()),
        ],
        disaggregation:
            Disaggregation.values.asNameMap()[json['disaggregation']],
        metric: DataSetMetric.values.asNameMap()[json['metric']],
        orgUnitId: (json['orgUnitId'] ?? '') as String,
        orgUnitName: (json['orgUnitName'] ?? '') as String,
        periodKind: PeriodKind.values.asNameMap()[json['periodKind']] ??
            PeriodKind.relative,
        periodId: (json['periodId'] ?? '') as String,
        periodLabel: (json['periodLabel'] ?? '') as String,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String) ??
            DateTime.now(),
      );
}
