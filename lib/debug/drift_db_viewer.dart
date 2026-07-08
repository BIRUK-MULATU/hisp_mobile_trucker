// TEMPORARY debug screen. Point MaterialApp's home here while testing.
//
//   - sync buttons (full / delta) + in-app DB browser
//   - a DRILL-DOWN explorer: tap a dataset -> see its sections; tap a
//     section -> see its elements/indicators/cells. One level per tap,
//     mirroring the real screen flow. "Back" pops a level.

import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/material.dart';

import '../core/database/app_database.dart';
import '../core/metadata/attribute.dart';
import '../core/metadata/category_combo.dart';
import '../core/metadata/data_element.dart';
import '../core/metadata/data_set.dart';
import '../core/metadata/indicator.dart';
import '../core/metadata/metadata_sync_service.dart';
import '../core/metadata/section.dart';
import '../core/network/api_client.dart';
import '../core/utils/app_logger.dart';

const _baseUrl = '';
const _username = '';
const _password = '';

/// One tappable row: a label, optional detail lines, and (if descendable)
/// an onTap returning the NEXT level.
class _Node {
  _Node({required this.label, this.detail = const [], this.descend});
  final String label;
  final List<String> detail;
  final Future<_Level> Function()? descend;
}

class _Level {
  _Level(this.title, this.nodes);
  final String title;
  final List<_Node> nodes;
}

class DebugSyncScreen extends StatefulWidget {
  const DebugSyncScreen({super.key});

  @override
  State<DebugSyncScreen> createState() => _DebugSyncScreenState();
}

class _DebugSyncScreenState extends State<DebugSyncScreen> {
  late final AppDatabase _db = AppDatabase.forUser(_username);
  late final ApiClient _api = ApiClient.withBasicAuth(
      baseUrl: _baseUrl, username: _username, password: _password);

  late final _dataSets = DataSetResource(_db);
  late final _sections = SectionResource(_db);
  late final _elements = DataElementResource(_db);
  late final _indicators = IndicatorResource(_db);
  late final _combos = CategoryComboResource(_db);

  final List<_Level> _stack = [];
  String _status = 'Ready. Full-sync first, then Explore.';
  bool _busy = false;

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _guard(String label, Future<void> Function() body) async {
    log.i('BUTTON: $label');
    setState(() {
      _busy = true;
      _status = '$label ...';
    });
    try {
      await body();
      setState(() => _status = '$label OK');
    } catch (e, st) {
      log.e('$label failed', error: e, stackTrace: st);
      setState(() => _status = '$label FAILED: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<_Level> _datasetLevel() async {
    final all = await _dataSets.getAll();
    return _Level('Datasets (${all.length})', [
      for (final ds in all)
        _Node(
          label: '${ds.displayName}  [${ds.periodType}]',
          detail: [ds.uid],
          descend: () => _sectionLevel(ds),
        ),
    ]);
  }

  Future<_Level> _sectionLevel(DataSet ds) async {
    final avs = await _db.attributeValuesOf('dataSet', ds.uid);
    final sections = await _sections.getByDataSet(ds.uid);
    final effective = await _dataSets.effectiveComboByElement(ds.uid);

    return _Level('${ds.displayName} — sections (${sections.length})', [
      if (avs.isNotEmpty)
        _Node(
          label: 'attributes',
          detail: [for (final e in avs.entries) '${e.key} = ${e.value}'],
        ),
      for (final s in sections)
        _Node(
          label: s.displayName,
          detail: [s.uid],
          descend: () => _sectionContents(s, effective),
        ),
      if (sections.isEmpty) _Node(label: '(no sections)'),
    ]);
  }

  Future<_Level> _sectionContents(
      Section s, Map<String, String> effective) async {
    final deUids = await _sections.dataElementUids(s.uid);
    final elements = await _elements.getByIds(deUids);
    final grey = await _sections.greyFieldsOf(s.uid);
    final greyed = {
      for (final g in grey) '${g.dataElementUid}:${g.categoryOptionComboUid}'
    };

    final nodes = <_Node>[];
    for (final de in elements) {
      final comboUid = effective[de.uid];
      final cells = comboUid == null
          ? const []
          : await _combos.orderedOptionCombos(comboUid);
      nodes.add(_Node(
        label: '${de.formName}  [${de.valueType}]',
        detail: [
          for (final c in cells)
            greyed.contains('${de.uid}:${c.uid}')
                ? '· ${c.name}  (greyed)'
                : '· ${c.name}',
          if (cells.isEmpty) '(no cells — combo ${comboUid ?? "missing"})',
        ],
      ));
    }

    final indUids = await _sections.indicatorUids(s.uid);
    for (final ind in await _indicators.getByIds(indUids)) {
      nodes.add(_Node(label: '= ${ind.displayName}  (indicator)'));
    }
    if (nodes.isEmpty) nodes.add(_Node(label: '(empty section)'));

    return _Level('${s.displayName} — contents', nodes);
  }

  Future<void> _enterExplorer() =>
      _guard('Explore', () async => _push(await _datasetLevel()));

  void _push(_Level level) => setState(() => _stack.add(level));

  Future<void> _tap(_Node node) async {
    if (node.descend == null) return;
    await _guard(
        'Open ${node.label}', () async => _push(await node.descend!()));
  }

  void _back() => setState(() => _stack.removeLast());

  @override
  Widget build(BuildContext context) {
    final sync = MetadataSyncService(_db, _api);
    final level = _stack.isEmpty ? null : _stack.last;

    return Scaffold(
      appBar: AppBar(
        title: Text(level?.title ?? 'DB debug'),
        leading: _stack.isNotEmpty
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _guard(
                          'Full sync', () async => await sync.syncMetadata()),
                  child: const Text('Full sync'),
                ),
                FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () => _guard('Delta sync',
                          () async => await sync.syncMetadataDelta()),
                  child: const Text('Delta sync'),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => DriftDbViewer(_db),
                          )),
                  child: const Text('Browse DB'),
                ),
                FilledButton(
                  onPressed: _busy ? null : _enterExplorer,
                  child: const Text('Explore'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(fontSize: 12)),
            const Divider(),
            Expanded(
              child: level == null
                  ? const Center(child: Text('Tap Explore to start'))
                  : ListView.separated(
                      itemCount: level.nodes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final node = level.nodes[i];
                        final canDescend = node.descend != null;
                        return ListTile(
                          dense: true,
                          title: Text(node.label,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 13)),
                          subtitle: node.detail.isEmpty
                              ? null
                              : Text(node.detail.join('\n'),
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: Colors.black54)),
                          trailing:
                              canDescend ? const Icon(Icons.chevron_right) : null,
                          onTap: canDescend ? () => _tap(node) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
