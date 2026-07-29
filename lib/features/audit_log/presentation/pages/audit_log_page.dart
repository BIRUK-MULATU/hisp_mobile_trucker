import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/audit_log_store.dart';
import '../../../../core/data/ethiopian_period_service.dart';
import '../../../../core/data/server_audit_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Trail of edits to data values for one org unit. PRIMARY source is
/// DHIS2's OWN audit trail (`/api/audits/dataValue`, via
/// [ServerAuditService]) — authoritative, since it reflects every
/// client that has ever touched the value, not just this phone. When
/// the server can't be reached, falls back to this device's own
/// [AuditLogStore] so the screen still shows something offline; the
/// banner makes clear which source is on screen.
class AuditLogPage extends StatefulWidget {
  const AuditLogPage({
    required this.db,
    required this.orgUnitUid,
    required this.api,
    super.key,
  });

  final AppDatabase db;
  final String orgUnitUid;

  /// Server-root API client (see AppSession.api). Null when there has
  /// never been an online session — the page then never attempts a
  /// server call and goes straight to the local fallback.
  final ApiClient? api;

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

enum _AuditSource { server, local }

class _AuditLogPageState extends State<AuditLogPage> {
  late final AuditLogStore _localLog = AuditLogStore(widget.db);

  bool _isLoading = true;
  String? _error;
  _AuditSource _source = _AuditSource.server;
  List<_AuditRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = widget.api;
    if (api != null) {
      final serverAudits =
          await ServerAuditService(api).fetchForOrgUnit(widget.orgUnitUid);
      if (serverAudits != null) {
        final rows = await _rowsFromServer(serverAudits);
        if (!mounted) return;
        setState(() {
          _rows = rows;
          _source = _AuditSource.server;
          _isLoading = false;
        });
        return;
      }
    }

    // No API session, or the server call failed — local fallback.
    try {
      final entries = await _localLog.forOrgUnit(widget.orgUnitUid);
      final rows = await _rowsFromLocal(entries);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _source = _AuditSource.local;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<List<_AuditRow>> _rowsFromServer(
      List<ServerDataValueAudit> audits) async {
    final dataElementUids = {for (final a in audits) a.dataElementUid};
    final names = await _dataElementNames(dataElementUids);
    return [
      for (final a in audits)
        _AuditRow(
          title: names[a.dataElementUid] ?? a.dataElementUid,
          period: a.period,
          isCompleteness: false,
          changeText: _serverChangeText(a),
          modifiedBy: a.modifiedBy,
          modifiedAt: a.created,
        ),
    ];
  }

  Future<List<_AuditRow>> _rowsFromLocal(List<AuditEntry> entries) async {
    final dataElementUids = {
      for (final e in entries)
        if (e.dataElementUid != null) e.dataElementUid!,
    };
    final dataSetUids = {
      for (final e in entries)
        if (e.dataSetUid != null) e.dataSetUid!,
    };
    final names = await _dataElementNames(dataElementUids);
    final dataSetNames = await _dataSetNames(dataSetUids);
    return [
      for (final e in entries)
        _AuditRow(
          title: names[e.dataElementUid] ??
              dataSetNames[e.dataSetUid] ??
              e.dataElementUid ??
              e.dataSetUid ??
              '—',
          period: e.period,
          isCompleteness: e.entityType == AuditEntityType.completeness,
          changeText: _localChangeText(e),
          modifiedBy: e.modifiedBy,
          modifiedAt: e.modifiedAt,
        ),
    ];
  }

  Future<Map<String, String>> _dataElementNames(Set<String> uids) async {
    if (uids.isEmpty) return const {};
    final db = widget.db;
    final rows = await (db.select(db.dataElementsTable)
          ..where((t) => t.uid.isIn(uids)))
        .get();
    return {for (final r in rows) r.uid: r.displayName};
  }

  Future<Map<String, String>> _dataSetNames(Set<String> uids) async {
    if (uids.isEmpty) return const {};
    final db = widget.db;
    final rows =
        await (db.select(db.dataSetsTable)..where((t) => t.uid.isIn(uids)))
            .get();
    return {for (final r in rows) r.uid: r.displayName};
  }

  static String _serverChangeText(ServerDataValueAudit a) {
    final value = a.value ?? '(empty)';
    switch (a.auditType) {
      case 'DELETE':
        return 'Deleted (was "$value")';
      case 'CREATE':
        return 'Set to "$value"';
      default:
        return 'Changed to "$value"';
    }
  }

  static String _localChangeText(AuditEntry e) {
    if (e.entityType == AuditEntityType.completeness) {
      final isComplete = e.newValue == 'true';
      return isComplete ? 'Marked complete' : 'Marked incomplete';
    }
    final from = e.previousValue ?? '(empty)';
    final to = e.newValue ?? '(empty)';
    return e.previousValue == null ? 'Set to "$to"' : '"$from" → "$to"';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Audit Log', style: AppTextStyles.appBarTitle),
      ),
      body: Column(
        children: [
          if (!_isLoading && _error == null) _SourceBanner(source: _source),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Text(
            'Could not load the audit log.\n$_error',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded,
                  size: AppDimensions.iconHuge, color: AppColors.textHint),
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                _source == _AuditSource.server
                    ? 'No audited changes recorded on the server yet.'
                    : 'No changes recorded on this device yet.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space,
          vertical: AppDimensions.spaceMD,
        ),
        itemCount: _rows.length,
        itemBuilder: (context, index) => _AuditRowTile(row: _rows[index]),
      ),
    );
  }
}

class _SourceBanner extends StatelessWidget {
  const _SourceBanner({required this.source});

  final _AuditSource source;

  @override
  Widget build(BuildContext context) {
    final isServer = source == _AuditSource.server;
    return Container(
      width: double.infinity,
      color: isServer ? AppColors.infoLight : AppColors.warningLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          Icon(
            isServer ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: AppDimensions.iconSM,
            color: isServer ? AppColors.info : AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spaceXS),
          Expanded(
            child: Text(
              isServer
                  ? "DHIS2's server audit trail — every client, not just this device"
                  : 'Offline — showing this device\'s own edit history instead',
              style: AppTextStyles.labelSmall.copyWith(
                color: isServer ? AppColors.info : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditRow {
  const _AuditRow({
    required this.title,
    required this.period,
    required this.isCompleteness,
    required this.changeText,
    required this.modifiedBy,
    required this.modifiedAt,
  });

  final String title;
  final String period;
  final bool isCompleteness;
  final String changeText;
  final String? modifiedBy;
  final DateTime? modifiedAt;
}

class _AuditRowTile extends StatelessWidget {
  const _AuditRowTile({required this.row});

  final _AuditRow row;

  static final _timeFormat = DateFormat('d MMM y, HH:mm');

  @override
  Widget build(BuildContext context) {
    final icon =
        row.isCompleteness ? Icons.fact_check_rounded : Icons.edit_note_rounded;
    final color = row.isCompleteness ? AppColors.success : AppColors.primary;
    final period = EthiopianPeriodService.formatPeriodId(row.period);
    final when = row.modifiedAt == null
        ? 'Unknown time'
        : _timeFormat.format(row.modifiedAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconMD),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.title,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(period,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(row.changeText, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  '${row.modifiedBy ?? 'Unknown user'} · $when',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
