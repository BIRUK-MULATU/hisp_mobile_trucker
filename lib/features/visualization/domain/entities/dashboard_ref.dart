/// A dashboard on the DHIS2 server — the WebApp's Dashboard app
/// concept, a named group of visualization items. Browsable only:
/// the app never creates, edits, or owns a dashboard. The last
/// successful list IS cached locally (see
/// ChartRepositoryImpl.loadDashboards) purely so the Dashboards tab
/// still shows something while offline — that cache is a read-only
/// mirror, not a local copy the app can modify independently.
class DashboardRef {
  final String id;
  final String name;

  const DashboardRef({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory DashboardRef.fromJson(Map<String, dynamic> json) => DashboardRef(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
      );
}
