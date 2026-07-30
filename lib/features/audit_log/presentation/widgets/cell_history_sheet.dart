import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/data/audit_log_store.dart';
import '../../../../core/data/ethiopian_period_service.dart';
import '../../../../core/data/server_audit_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/metadata/category_option_combo.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// Opens the history of one data-entry cell — same place DHIS2's own
/// entry apps put it: inside the data element, on that specific
/// category option combo. A modal bottom sheet rather than a page push
/// keeps it reachable with one tap and cheap to dismiss on a phone.
Future<void> showCellHistorySheet(
  BuildContext context, {
  required String dataElementId,
  required String dataElementName,
  required String comboId,
  required String comboName,
  required String orgUnitId,
  required String period,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusXXL),
      ),
    ),
    builder: (_) => _CellHistorySheet(
      dataElementId: dataElementId,
      dataElementName: dataElementName,
      comboId: comboId,
      comboName: comboName,
      orgUnitId: orgUnitId,
      period: period,
    ),
  );
}

enum _Source { server, local }

class _HistoryRow {
  const _HistoryRow({
    required this.changeText,
    required this.modifiedBy,
    required this.modifiedAt,
  });

  final String changeText;
  final String? modifiedBy;
  final DateTime? modifiedAt;

  factory _HistoryRow.fromServer(ServerDataValueAudit a) {
    final value = a.value ?? '(empty)';
    final text = switch (a.auditType) {
      'DELETE' => 'Deleted (was "$value")',
      'CREATE' => 'Set to "$value"',
      _ => 'Changed to "$value"',
    };
    return _HistoryRow(
        changeText: text, modifiedBy: a.modifiedBy, modifiedAt: a.created);
  }

  factory _HistoryRow.fromLocal(AuditEntry e) {
    final from = e.previousValue ?? '(empty)';
    final to = e.newValue ?? '(empty)';
    final text = e.previousValue == null ? 'Set to "$to"' : '"$from" → "$to"';
    return _HistoryRow(
        changeText: text, modifiedBy: e.modifiedBy, modifiedAt: e.modifiedAt);
  }
}

class _CellHistorySheet extends StatefulWidget {
  const _CellHistorySheet({
    required this.dataElementId,
    required this.dataElementName,
    required this.comboId,
    required this.comboName,
    required this.orgUnitId,
    required this.period,
  });

  final String dataElementId;
  final String dataElementName;
  final String comboId;
  final String comboName;
  final String orgUnitId;
  final String period;

  @override
  State<_CellHistorySheet> createState() => _CellHistorySheetState();
}

class _CellHistorySheetState extends State<_CellHistorySheet> {
  bool _isLoading = true;
  String? _error;
  _Source _source = _Source.server;
  List<_HistoryRow> _rows = const [];

  AppDatabase get _db => AppSession.instance.service.db;

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

    final api = AppSession.instance.api;
    if (api != null) {
      final comboParams = await resolveCcCpParams(_db, widget.comboId);
      final audits = await ServerAuditService(api).fetchForCell(
        dataElementUid: widget.dataElementId,
        period: widget.period,
        orgUnitUid: widget.orgUnitId,
        comboParams: comboParams,
      );
      if (audits != null) {
        // The default combo has no cc/cp to filter by server-side —
        // the query then returns every combo of the element, so this
        // cell's own rows must be picked out client-side.
        final scoped = comboParams.isEmpty
            ? audits
                .where((a) => a.categoryOptionComboUid == widget.comboId)
                .toList()
            : audits;
        if (!mounted) return;
        setState(() {
          _rows = [for (final a in scoped) _HistoryRow.fromServer(a)];
          _source = _Source.server;
          _isLoading = false;
        });
        return;
      }
    }

    // No session, or the server call failed — local fallback.
    try {
      final entries = await AuditLogStore(_db).forCell(
        dataElementUid: widget.dataElementId,
        period: widget.period,
        orgUnitUid: widget.orgUnitId,
        categoryOptionComboUid: widget.comboId,
      );
      if (!mounted) return;
      setState(() {
        _rows = [for (final e in entries) _HistoryRow.fromLocal(e)];
        _source = _Source.local;
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

  @override
  Widget build(BuildContext context) {
    // Fraction of the screen height rather than a fixed size — what
    // fits comfortably differs a lot between phones and tablets.
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDimensions.spaceSM),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            _buildHeader(),
            if (!_isLoading && _error == null) _buildSourceBanner(),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space,
        AppDimensions.spaceMD,
        AppDimensions.spaceSM,
        AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.dataElementName,
                    style: AppTextStyles.headingSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${widget.comboName} · '
                  '${EthiopianPeriodService.formatPeriodId(widget.period)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBanner() {
    final isServer = _source == _Source.server;
    return Container(
      width: double.infinity,
      color: isServer ? AppColors.infoLight : AppColors.warningLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceXS,
      ),
      child: Row(
        children: [
          Icon(
            isServer ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: AppDimensions.iconXS,
            color: isServer ? AppColors.info : AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spaceXS),
          Expanded(
            child: Text(
              isServer
                  ? 'From the DHIS2 server'
                  : "Offline — this device's own history",
              style: AppTextStyles.labelSmall.copyWith(
                color: isServer ? AppColors.info : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.spaceXXL),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Text(
          'Could not load history.\n$_error',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    if (_rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: AppDimensions.iconXXL, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(
              'No changes recorded for this cell yet.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      itemCount: _rows.length,
      separatorBuilder: (_, __) =>
          const Divider(height: AppDimensions.space, color: AppColors.divider),
      itemBuilder: (context, index) => _buildRow(_rows[index]),
    );
  }

  static final _timeFormat = DateFormat('d MMM y, HH:mm');

  Widget _buildRow(_HistoryRow row) {
    final when =
        row.modifiedAt == null ? 'Unknown time' : _timeFormat.format(row.modifiedAt!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_note_rounded,
              size: AppDimensions.iconMD, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.changeText, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
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
