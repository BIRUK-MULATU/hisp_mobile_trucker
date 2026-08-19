/// A visualization that already exists on the DHIS2 server — built in
/// the WebApp (or by any other client), never created or copied by
/// this app. The Dashboards tab only ever holds this lightweight
/// reference; the visualization's own definition is never written to
/// the local chart container. Its analytics RESULT is cached (see
/// ChartRepositoryImpl.loadServerVisualization) so it's still
/// viewable offline, same as this app's own saved charts — but that's
/// a read-only cache of the last live answer, not a local copy of the
/// visualization itself.
class RemoteVisualizationRef {
  final String id;
  final String name;
  final String type;

  const RemoteVisualizationRef({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type};

  factory RemoteVisualizationRef.fromJson(Map<String, dynamic> json) =>
      RemoteVisualizationRef(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        type: (json['type'] ?? '') as String,
      );
}
