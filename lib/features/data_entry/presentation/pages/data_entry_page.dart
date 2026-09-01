import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/data/ethiopian_period_service.dart';
import '../../../../core/data/period_access.dart';
import '../../../../core/data/validation_service.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../core/onboarding/tour_helper.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../data/repositories/data_entry_repository_impl.dart';
import '../../domain/entities/data_element_entity.dart';
import '../../domain/usecases/get_data_elements_usecase.dart';
import '../../domain/usecases/save_data_values_usecase.dart';
import '../bloc/data_entry_bloc.dart';
import '../utils/data_entry_excel.dart';
import '../utils/data_entry_pdf.dart';
import '../widgets/data_entry_table.dart';
import '../widgets/disease_entry_list.dart';

class DataEntryPage extends StatelessWidget {
  final String dataSetId;
  final String dataSetName;
  final String orgUnitId;
  final String orgUnitName;
  final String period;
  final String periodType;

  /// When set, the form covers a single dataset section.
  final String? sectionId;
  final String? sectionName;

  final DataEntryBloc? preloadedBloc;

  /// Tags this dataset as Disease Registration — themes the AppBar
  /// and save FAB with the disease accent.
  final bool isDiseaseRegistration;

  /// Scopes this form to one category-combo cell of the data set's
  /// OWN category combination (e.g. Department × Outcome). Null uses
  /// the data set's default combo — every Routine data set today.
  final String? attributeOptionComboUid;

  const DataEntryPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.period,
    required this.periodType,
    this.sectionId,
    this.sectionName,
    this.preloadedBloc,
    this.isDiseaseRegistration = false,
    this.attributeOptionComboUid,
  });

  @override
  Widget build(BuildContext context) {
    if (preloadedBloc != null) {
      return _DataEntryView(
        dataSetId: dataSetId,
        dataSetName: dataSetName,
        orgUnitId: orgUnitId,
        orgUnitName: orgUnitName,
        period: period,
        periodType: periodType,
        sectionId: sectionId,
        sectionName: sectionName,
        isDiseaseRegistration: isDiseaseRegistration,
        attributeOptionComboUid: attributeOptionComboUid,
      );
    }

    final repository = DataEntryRepositoryImpl();

    return BlocProvider(
      create: (_) => DataEntryBloc(
        getDataElementsUseCase: GetDataElementsUseCase(repository),
        saveDataValuesUseCase: SaveDataValuesUseCase(repository),
        repository: repository,
      )..add(DataEntryLoad(
          dataSetId: dataSetId,
          orgUnitId: orgUnitId,
          period: period,
          sectionId: sectionId,
          attributeOptionComboUid: attributeOptionComboUid,
        )),
      child: _DataEntryView(
        dataSetId: dataSetId,
        dataSetName: dataSetName,
        orgUnitId: orgUnitId,
        orgUnitName: orgUnitName,
        period: period,
        periodType: periodType,
        sectionId: sectionId,
        sectionName: sectionName,
        isDiseaseRegistration: isDiseaseRegistration,
        attributeOptionComboUid: attributeOptionComboUid,
      ),
    );
  }
}

class _DataEntryView extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String orgUnitId;
  final String orgUnitName;
  final String period;
  final String periodType;
  final String? sectionId;
  final String? sectionName;
  final bool isDiseaseRegistration;
  final String? attributeOptionComboUid;

  const _DataEntryView({
    required this.dataSetId,
    required this.dataSetName,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.period,
    required this.periodType,
    this.sectionId,
    this.sectionName,
    this.isDiseaseRegistration = false,
    this.attributeOptionComboUid,
  });

  @override
  State<_DataEntryView> createState() => _DataEntryViewState();
}

enum _DownloadFormat { pdf, excel }

class _DataEntryViewState extends State<_DataEntryView> {
  bool _isSaving = false;
  bool _isCompleting = false;

  /// Local completion status, loaded on form open — decides which
  /// bottom sheet the save flow shows (complete vs reopen).
  bool _isCompleted = false;

  /// True once this period's expiryDays deadline has passed — cells
  /// go read-only (view only) but stay fully visible. Checked on
  /// open so both a freshly-picked period and a reopened past report
  /// get the same gate; entry itself never re-checks it mid-session.
  bool _isPeriodClosed = false;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Live validation ──────────────────────────────────────────
  // Runs the data set's validation rules against whatever is
  // currently typed — debounced so every keystroke doesn't trigger a
  // rule pass — instead of only checking after Save → Complete.
  List<ValidationViolation> _liveViolations = const [];
  bool _violationsExpanded = false;
  Timer? _validationDebounce;

  void _scheduleLiveValidation(DataEntryLoaded state) {
    _validationDebounce?.cancel();
    _validationDebounce = Timer(const Duration(milliseconds: 500), () {
      _runLiveValidation(state);
    });
  }

  Future<void> _runLiveValidation(DataEntryLoaded state) async {
    // Informative only, same contract as the complete-time check — a
    // failure to validate must never interrupt data entry.
    try {
      final violations =
          await context.read<DataEntryBloc>().repository.validateLiveValues(
                dataSetId: widget.dataSetId,
                dataValues: state.dataValues.values.toList(),
              );
      if (mounted) setState(() => _liveViolations = violations);
    } catch (_) {}
  }

  Widget _buildValidationBanner() {
    final high = _liveViolations.any((v) => v.importance == 'HIGH');
    final color = high ? AppColors.error : AppColors.warning;
    return Column(
      children: [
        InkWell(
          onTap: () =>
              setState(() => _violationsExpanded = !_violationsExpanded),
          child: Container(
            width: double.infinity,
            color: color.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space,
              vertical: AppDimensions.spaceSM,
            ),
            child: Row(
              children: [
                Icon(Icons.rule_rounded,
                    color: color, size: AppDimensions.iconMD),
                const SizedBox(width: AppDimensions.spaceSM),
                Expanded(
                  child: Text(
                    '${_liveViolations.length} validation '
                    '${_liveViolations.length == 1 ? 'issue' : 'issues'} — '
                    'tap to ${_violationsExpanded ? 'hide' : 'review'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _violationsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: color,
                ),
              ],
            ),
          ),
        ),
        if (_violationsExpanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppDimensions.spaceSM),
              itemCount: _liveViolations.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spaceSM),
              itemBuilder: (_, i) =>
                  _ValidationViolationTile(violation: _liveViolations[i]),
            ),
          ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }

  // ── App tour targets ────────────────────────────────────────
  // Routine and Disease Registration share this page, but get their
  // OWN tour id — Disease Registration's extra "Select for new
  // disease" step has nothing to show a Routine user, and a user who
  // only ever opens one of the two should still see the other's tour
  // on their first visit to it.
  final _printShowcaseKey = GlobalKey();
  final _syncShowcaseKey = GlobalKey();
  final _saveFabShowcaseKey = GlobalKey();
  final _diseaseSearchShowcaseKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadCompletionStatus();
      // Awaited (not fire-and-forget) so _isPeriodClosed is settled
      // before the tour decides whether the Save FAB — hidden once
      // the period is closed — belongs in its target list.
      await _loadPeriodStatus();
      await _maybeStartTour();
    });
  }

  Future<void> _maybeStartTour({bool force = false}) async {
    if (!mounted) return;
    await maybeStartTour(
      context,
      tourId: widget.isDiseaseRegistration
          ? 'data_entry_disease'
          : 'data_entry_routine',
      keys: [
        _printShowcaseKey,
        _syncShowcaseKey,
        if (!_isPeriodClosed) _saveFabShowcaseKey,
        if (widget.isDiseaseRegistration && !_isPeriodClosed)
          _diseaseSearchShowcaseKey,
      ],
      force: force,
    );
  }

  Future<void> _loadPeriodStatus() async {
    if (!mounted) return;
    try {
      final db = AppSession.instance.service.db;
      final dataSet = await DataSetResource(db).getById(widget.dataSetId);
      if (dataSet == null) return;
      final status = await EthiopianPeriodService(db).statusForPeriod(
        dataSet: dataSet,
        periodId: widget.period,
      );
      if (mounted) {
        setState(() => _isPeriodClosed = status == PeriodStatus.expired);
      }
    } catch (_) {
      // Metadata not on the device yet — err open, same as the rest
      // of this page's best-effort loads.
    }
  }

  @override
  void dispose() {
    _validationDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletionStatus() async {
    if (!mounted) return;
    try {
      final completed =
          await context.read<DataEntryBloc>().repository.isCompleted(
                dataSetId: widget.dataSetId,
                orgUnitId: widget.orgUnitId,
                period: widget.period,
                attributeOptionComboUid: widget.attributeOptionComboUid,
              );
      if (mounted) setState(() => _isCompleted = completed);
    } catch (_) {
      // Metadata not on the device yet — the form itself will show
      // the real error; treat the status as not completed.
    }
  }

  // ── Sync tapped — reload values from the server ───────────
  // Fire-and-forget wrapper around [_reloadFromServer] for the app-bar
  // icon, which doesn't need to know when the reload finishes.
  void _onSyncTapped() => _reloadFromServer();

  /// Shared by the app-bar sync icon and pull-to-refresh: re-dispatches
  /// [DataEntryLoad], which already does a live server pull + push
  /// when connected (see DataEntryRepositoryImpl.getDataValues) before
  /// re-reading local values — so this is a genuine reload, not just a
  /// local re-render. Awaits the resulting state so a caller (the
  /// RefreshIndicator) knows when the real work is actually done,
  /// instead of just when the event was enqueued.
  Future<void> _reloadFromServer() async {
    final bloc = context.read<DataEntryBloc>();
    final state = bloc.state;
    // A reload replaces every cell — don't wipe unsaved edits.
    if (state is DataEntryLoaded && state.hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save your changes before reloading.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final done = bloc.stream
        .firstWhere((s) => s is DataEntryLoaded || s is DataEntryError);
    bloc.add(DataEntryLoad(
      dataSetId: widget.dataSetId,
      orgUnitId: widget.orgUnitId,
      period: widget.period,
      sectionId: widget.sectionId,
      attributeOptionComboUid: widget.attributeOptionComboUid,
    ));
    await done;
  }

  // Shared by Print and Download: the loaded form's state, or null
  // (after a warning snackbar) when the form isn't ready yet.
  DataEntryLoaded? _formLoadedOrWarn() {
    final state = context.read<DataEntryBloc>().state;
    if (state is! DataEntryLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form is still loading — try again in a moment.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
    return state;
  }

  // Asks whether the export should list every element in the form
  // (blanks included — e.g. to print and fill in by hand, or Disease
  // Registration's hundreds-of-diseases picker list) or only what's
  // actually been recorded. null = dismissed without choosing.
  Future<bool?> _askIncludeAllElements() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXL,
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What should the PDF include?',
              style: AppTextStyles.headingMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
            Text(
              'List every data element in the form — blank ones included '
              '— or only the ones you\'ve actually recorded.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppDimensions.spaceXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceMD),
                    ),
                    child: Text(
                      'Only recorded',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMD),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceMD),
                    ),
                    child: Text(
                      'All elements',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Resolves the user's include-all/only-recorded choice into the
  // actual element list to export, warning and returning null if
  // "only recorded" turns out to be empty.
  Future<List<DataElementEntity>?> _resolveExportElements(
      DataEntryLoaded state) async {
    final includeAll = await _askIncludeAllElements();
    if (includeAll == null || !mounted) return null;
    if (includeAll) return state.dataElements;

    final recorded = recordedDataElements(
      dataElements: state.dataElements,
      dataValues: state.dataValues,
    );
    if (recorded.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing recorded yet — enter some values first.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
    return recorded;
  }

  Future<Uint8List> _buildFormPdf(
      DataEntryLoaded state, List<DataElementEntity> elements) async {
    final printedBy = await SecureStorage().getUsername();
    return buildDataEntryPdf(
      title: widget.sectionName ?? widget.dataSetName,
      orgUnitName: widget.orgUnitName,
      periodLabel: EthiopianPeriodService.formatPeriodId(widget.period),
      isDiseaseRegistration: widget.isDiseaseRegistration,
      dataElements: elements,
      dataValues: state.dataValues,
      printedBy: printedBy,
    );
  }

  // ── Print tapped — export/print the form ──────────────────────
  Future<void> _onPrintTapped() async {
    final state = _formLoadedOrWarn();
    if (state == null) return;
    final elements = await _resolveExportElements(state);
    if (elements == null) return;
    final title = widget.sectionName ?? widget.dataSetName;
    await Printing.layoutPdf(
      name: '$title - ${widget.period}',
      onLayout: (_) => _buildFormPdf(state, elements),
    );
  }

  // ── Download tapped — same PDF, saved straight to the device
  // instead of going through the print/preview flow. Uses the
  // system share sheet (already how this app depends on `printing`)
  // so "Save to Files"/Drive works without a storage permission.
  Future<void> _onDownloadPdfTapped() async {
    final state = _formLoadedOrWarn();
    if (state == null) return;
    final elements = await _resolveExportElements(state);
    if (elements == null) return;
    final bytes = await _buildFormPdf(state, elements);
    final title = widget.sectionName ?? widget.dataSetName;
    final saved = await Printing.sharePdf(
      bytes: bytes,
      filename: '$title - ${widget.period}.pdf',
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF ready — choose where to save it.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Uint8List _buildFormExcel(
      DataEntryLoaded state, List<DataElementEntity> elements) {
    return buildDataEntryExcel(
      title: widget.sectionName ?? widget.dataSetName,
      orgUnitName: widget.orgUnitName,
      periodLabel: EthiopianPeriodService.formatPeriodId(widget.period),
      isDiseaseRegistration: widget.isDiseaseRegistration,
      dataElements: elements,
      dataValues: state.dataValues,
    );
  }

  // ── Download Excel tapped — same flow as PDF download (same
  // include-all/only-recorded choice, same system share sheet) but
  // producing an .xlsx workbook instead, since `printing` only knows
  // how to share PDFs.
  Future<void> _onDownloadExcelTapped() async {
    final state = _formLoadedOrWarn();
    if (state == null) return;
    final elements = await _resolveExportElements(state);
    if (elements == null) return;
    final bytes = _buildFormExcel(state, elements);
    final title = widget.sectionName ?? widget.dataSetName;
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/vnd.openxmlformats-officedocument'
                '.spreadsheetml.sheet',
            name: '$title - ${widget.period}.xlsx',
          ),
        ],
        fileNameOverrides: ['$title - ${widget.period}.xlsx'],
      ),
    );
    if (result.status == ShareResultStatus.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel file ready — choose where to save it.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── FAB tapped — save first ───────────────────────────────
  Future<void> _onSaveTapped() async {
    final bloc = context.read<DataEntryBloc>();

    // Value-type gate: invalid cells must never be queued. Only the
    // user's edits are checked — values that came from the server
    // stay the server's responsibility.
    final invalid = bloc.state is DataEntryLoaded
        ? invalidEditedValues(bloc.state as DataEntryLoaded)
        : const <String>[];
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invalid.length == 1
                ? 'One value is invalid: ${invalid.first}. '
                    'Fix the red cell before saving.'
                : '${invalid.length} values are invalid — fix the red '
                    'cells before saving. First problem: ${invalid.first}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save data values via use case directly
      final state = bloc.state;
      if (state is DataEntryLoaded) {
        // Only the loaded form's values — with a single section
        // open the map also holds the other sections' existing
        // values, which must not be re-posted.
        final formElementIds = state.dataElements.map((e) => e.id).toSet();
        await bloc.repository.saveDataValues(
          dataValues: state.dataValues.values
              .where((v) => formElementIds.contains(v.dataElementId))
              .toList(),
          dataSetId: widget.dataSetId,
          orgUnitId: widget.orgUnitId,
          period: widget.period,
          attributeOptionComboUid: widget.attributeOptionComboUid,
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      // Status-aware: a completed form offers reopening instead.
      if (_isCompleted) {
        await _showReopenDialog();
      } else {
        await _showCompleteDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Show complete bottom sheet ─────────────────────────────
  Future<void> _showCompleteDialog() async {
    if (!mounted) return;

    // Validation rule check on the saved local values. Informative
    // only — a failure to VALIDATE (missing metadata, bad rule) must
    // never stand between the user and completing.
    var violations = const <ValidationViolation>[];
    try {
      violations =
          await context.read<DataEntryBloc>().repository.validateDataSet(
                dataSetId: widget.dataSetId,
                orgUnitId: widget.orgUnitId,
                period: widget.period,
                attributeOptionComboUid: widget.attributeOptionComboUid,
              );
    } catch (_) {}
    if (!mounted) return;
    final hasViolations = violations.isNotEmpty;

    // Compulsory dataSetElement fields. Unlike validation rules above,
    // this DOES block completing (see missingMandatoryFields doc) — a
    // fetch failure is still treated as "nothing missing" so a single
    // bad query can't permanently strand the user, but it's logged so
    // real metadata corruption doesn't go unnoticed.
    var missing = const <String>[];
    try {
      missing = await context
          .read<DataEntryBloc>()
          .repository
          .missingMandatoryFields(
            dataSetId: widget.dataSetId,
            orgUnitId: widget.orgUnitId,
            period: widget.period,
            attributeOptionComboUid: widget.attributeOptionComboUid,
          );
    } catch (e) {
      log.e('missingMandatoryFields failed: $e');
    }
    if (!mounted) return;
    final hasMissingMandatory = missing.isNotEmpty;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePaddingH,
            AppDimensions.spaceXXL,
            AppDimensions.pagePaddingH,
            AppDimensions.spaceXXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──────────────────────────────
              Text(
                hasMissingMandatory
                    ? '${missing.length} required '
                        'field${missing.length == 1 ? '' : 's'} missing'
                    : hasViolations
                        ? '${violations.length} validation '
                            'issue${violations.length == 1 ? '' : 's'} found'
                        : 'Everything looks good',
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: (hasMissingMandatory || hasViolations)
                      ? AppColors.error
                      : null,
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // ── Message ────────────────────────────
              Text(
                hasMissingMandatory
                    ? 'Fill in the required fields marked with * before '
                        'completing. You can still save this as a draft '
                        'and finish later.'
                    : hasViolations
                        ? 'The values below conflict with this data set\'s '
                            'validation rules. Review them, or complete '
                            'anyway if the data is correct.'
                        : 'Complete the data set to send it to the server, '
                            'or keep it as a draft on this device to '
                            'finish later.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              if (hasMissingMandatory) ...[
                const SizedBox(height: AppDimensions.spaceMD),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: missing.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.spaceSM),
                    itemBuilder: (_, i) =>
                        _MandatoryFieldTile(fieldName: missing[i]),
                  ),
                ),
              ] else if (hasViolations) ...[
                const SizedBox(height: AppDimensions.spaceMD),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: violations.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.spaceSM),
                    itemBuilder: (_, i) =>
                        _ValidationViolationTile(violation: violations[i]),
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.spaceXL),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppDimensions.spaceXL),

              // ── Buttons ────────────────────────────
              // Missing mandatory fields is a HARD block — unlike
              // validation rules, there's no "complete anyway" escape:
              // only a single button back to the form.
              if (hasMissingMandatory)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceMD),
                    ),
                    child: Text(
                      'Review data',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    // With violations: back to the form. Clean: keep as
                    // a device-only draft.
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, hasViolations ? null : false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spaceMD),
                        ),
                        child: Text(
                          hasViolations ? 'Review data' : 'Incomplete',
                          style: AppTextStyles.buttonMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppDimensions.spaceMD),

                    // Complete
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasViolations
                              ? AppColors.error
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spaceMD),
                        ),
                        child: Text(
                          hasViolations ? 'Complete anyway' : 'Complete',
                          style: AppTextStyles.buttonMedium
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // User chose Complete
      setState(() => _isCompleting = true);
      try {
        await context.read<DataEntryBloc>().repository.completeDataSet(
              dataSetId: widget.dataSetId,
              orgUnitId: widget.orgUnitId,
              period: widget.period,
              attributeOptionComboUid: widget.attributeOptionComboUid,
            );
        if (mounted) {
          setState(() => _isCompleted = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data set completed successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, {
            'saved': true,
            'completed': true,
            'period': widget.period,
            'orgUnitName': widget.orgUnitName,
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isCompleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (result == false) {
      // User chose Incomplete — the values stay a device-only draft.
      // (null = dismissed / "Review data": stay on the form.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved as a draft on this device — complete '
                'the data set to send it to the server.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, {
          'saved': true,
          'completed': false,
          'period': widget.period,
          'orgUnitName': widget.orgUnitName,
        });
      }
    }
  }

  // ── Show reopen bottom sheet (form already completed) ──────
  Future<void> _showReopenDialog() async {
    if (!mounted) return;

    // null = dismissed (stay), true = keep completed, false = mark incomplete.
    final keepCompleted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXL,
          AppDimensions.pagePaddingH,
          AppDimensions.spaceXXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────
            Text(
              'This data set is completed',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // ── Message ────────────────────────────
            Text(
              'Keep it completed to send your saved changes with the '
              'report as it is, or mark it incomplete to reopen the report '
              'and continue editing on this device.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppDimensions.spaceXL),

            // ── Buttons ────────────────────────────
            Row(
              children: [
                // Incomplete — reopens the report (same term DHIS2's
                // own web app uses for undoing completion)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceMD),
                    ),
                    child: Text(
                      'Incomplete',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ),

                const SizedBox(width: AppDimensions.spaceMD),

                // Keep completed
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceMD),
                    ),
                    child: Text(
                      'Keep completed',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted || keepCompleted == null) return;

    setState(() => _isCompleting = true);
    try {
      final repository = context.read<DataEntryBloc>().repository;
      if (keepCompleted) {
        // Re-affirm: promotes the saved drafts and pushes them with
        // the (still standing) completion.
        await repository.completeDataSet(
          dataSetId: widget.dataSetId,
          orgUnitId: widget.orgUnitId,
          period: widget.period,
          attributeOptionComboUid: widget.attributeOptionComboUid,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Changes sent — the data set stays completed.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, {
            'saved': true,
            'completed': true,
            'period': widget.period,
            'orgUnitName': widget.orgUnitName,
          });
        }
      } else {
        await repository.uncompleteDataSet(
          dataSetId: widget.dataSetId,
          orgUnitId: widget.orgUnitId,
          period: widget.period,
          attributeOptionComboUid: widget.attributeOptionComboUid,
        );
        // Stay on the form — reopening means the user keeps working.
        if (mounted) {
          setState(() {
            _isCompleting = false;
            _isCompleted = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report reopened — your edits stay drafts on '
                  'this device until you complete it again.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to ${keepCompleted ? 'complete' : 'reopen'}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDiseaseRegistration
            ? AppColors.diseaseAccent
            : AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sectionName ?? widget.dataSetName,
              style: AppTextStyles.appBarTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.isDiseaseRegistration)
              Text(
                'Disease Registration',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
        actions: [
          const ConnectivityIndicator(),
          Showcase(
            key: _printShowcaseKey,
            title: 'Print / Export',
            description: "Print or export this form as a PDF — only "
                "what you've recorded is included.",
            child: IconButton(
              icon: const Icon(Icons.print_rounded, color: Colors.white),
              tooltip: 'Print / Export PDF',
              onPressed: _onPrintTapped,
            ),
          ),
          PopupMenuButton<_DownloadFormat>(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download',
            onSelected: (format) => switch (format) {
              _DownloadFormat.pdf => _onDownloadPdfTapped(),
              _DownloadFormat.excel => _onDownloadExcelTapped(),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _DownloadFormat.pdf,
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded,
                        color: AppColors.textSecondary),
                    SizedBox(width: AppDimensions.spaceMD),
                    Text('Download as PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _DownloadFormat.excel,
                child: Row(
                  children: [
                    Icon(Icons.grid_on_rounded,
                        color: AppColors.textSecondary),
                    SizedBox(width: AppDimensions.spaceMD),
                    Text('Download as Excel'),
                  ],
                ),
              ),
            ],
          ),
          Showcase(
            key: _syncShowcaseKey,
            title: 'Reload',
            description: 'Reload this form\'s values from the server.',
            child: IconButton(
              icon: const Icon(Icons.sync_rounded, color: Colors.white),
              tooltip: 'Reload values',
              onPressed: _onSyncTapped,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceXS),
        ],
      ),
      body: BlocListener<DataEntryBloc, DataEntryState>(
        listener: (context, state) {
          if (state is DataEntryLoaded) _scheduleLiveValidation(state);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sub header ────────────────────────────
            _SubHeader(
              period: widget.period,
              orgUnitName: widget.orgUnitName,
              completed: _isCompleted,
              periodClosed: _isPeriodClosed,
            ),
            const Divider(height: 1, color: AppColors.divider),

            // ── Live validation banner ─────────────────
            // Same rule engine the complete-time check uses, run
            // against whatever is currently typed — so a conflict
            // shows up while filling the form, not only after Save.
            if (_liveViolations.isNotEmpty) _buildValidationBanner(),

            // Disease Registration leads with "Select for new disease"
            // (see DiseaseEntryList) instead of a plain search bar —
            // there can be hundreds of diseases, so nothing is listed
            // until it's recorded or explicitly picked.
            if (!widget.isDiseaseRegistration) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space,
                  vertical: AppDimensions.spaceSM,
                ),
                child: SearchField(
                  controller: _searchController,
                  hint: 'Search...',
                  value: _searchQuery,
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
            ],

            // ── Table ─────────────────────────────────
            Expanded(
              child: BlocBuilder<DataEntryBloc, DataEntryState>(
                builder: (context, state) {
                  if (state is DataEntryLoading) {
                    return const AppLoader(message: 'Loading form...');
                  }
                  if (state is DataEntryError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<DataEntryBloc>().add(
                            DataEntryLoad(
                              dataSetId: widget.dataSetId,
                              orgUnitId: widget.orgUnitId,
                              period: widget.period,
                              sectionId: widget.sectionId,
                              attributeOptionComboUid:
                                  widget.attributeOptionComboUid,
                            ),
                          ),
                    );
                  }
                  if (state is DataEntryLoaded) {
                    // Guarded the same way as the app-bar sync icon —
                    // dragging down with unsaved edits shows the
                    // "save first" snackbar instead of silently
                    // discarding them.
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _reloadFromServer,
                      child: widget.isDiseaseRegistration
                          ? DiseaseEntryList(
                              dataElements: state.dataElements,
                              dataValues: state.dataValues,
                              orgUnitId: widget.orgUnitId,
                              period: widget.period,
                              readOnly: _isPeriodClosed,
                              searchShowcaseKey: _diseaseSearchShowcaseKey,
                            )
                          : DataEntryTable(
                              dataElements: state.dataElements,
                              dataValues: state.dataValues,
                              orgUnitId: widget.orgUnitId,
                              period: widget.period,
                              searchQuery: _searchQuery,
                              readOnly: _isPeriodClosed,
                            ),
                    );
                  }
                  // Initial state (load event not processed yet) —
                  // keep the spinner up instead of a blank page.
                  return const AppLoader(message: 'Loading form...');
                },
              ),
            ),
          ],
        ),
      ),

      // ── Save FAB — hidden once the period is closed: view only,
      // nothing left to save ─────────────────────────────
      floatingActionButton: _isPeriodClosed
          ? null
          : Showcase(
              key: _saveFabShowcaseKey,
              title: 'Save',
              description: "Save your entries — you'll then be asked to "
                  'complete the report or keep it as a draft.',
              targetShapeBorder: const CircleBorder(),
              child: FloatingActionButton(
                onPressed: (_isSaving || _isCompleting) ? null : _onSaveTapped,
                backgroundColor: widget.isDiseaseRegistration
                    ? AppColors.diseaseAccent
                    : AppColors.primary,
                elevation: 4,
                shape: const CircleBorder(),
                child: (_isSaving || _isCompleting)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: AppDimensions.iconXL,
                      ),
              ),
            ),
    );
  }
}

// ── Sub Header ─────────────────────────────────────────────────
class _SubHeader extends StatelessWidget {
  final String period;
  final String orgUnitName;
  final bool completed;
  final bool periodClosed;
  const _SubHeader({
    required this.period,
    required this.orgUnitName,
    this.completed = false,
    this.periodClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          Text(
            EthiopianPeriodService.formatPeriodId(period),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceXL),
          Expanded(
            child: Text(
              orgUnitName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (completed) ...[
            const SizedBox(width: AppDimensions.spaceSM),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceSM,
                vertical: AppDimensions.spaceXXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: AppDimensions.iconSM,
                  ),
                  const SizedBox(width: AppDimensions.spaceXXS),
                  Text(
                    'Completed',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (periodClosed) ...[
            const SizedBox(width: AppDimensions.spaceSM),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceSM,
                vertical: AppDimensions.spaceXXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.warning,
                    size: AppDimensions.iconSM,
                  ),
                  const SizedBox(width: AppDimensions.spaceXXS),
                  Text(
                    'Closed · View only',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Error View ─────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: AppDimensions.iconHuge, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceLG),
            const Text('Could not load form',
                style: AppTextStyles.headingSmall),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(message,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spaceXXL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Validation violation tile (complete bottom sheet) ────────────
// One compulsory field with no value yet — simpler than
// _ValidationViolationTile since there's no rule detail/instruction,
// just the element (and combo, when disaggregated) that's missing.
class _MandatoryFieldTile extends StatelessWidget {
  final String fieldName;

  const _MandatoryFieldTile({required this.fieldName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: AppDimensions.iconSM, color: AppColors.error),
          const SizedBox(width: AppDimensions.spaceSM),
          Expanded(
            child: Text(
              fieldName,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationViolationTile extends StatelessWidget {
  final ValidationViolation violation;

  const _ValidationViolationTile({required this.violation});

  @override
  Widget build(BuildContext context) {
    final high = violation.importance == 'HIGH';
    final color = high ? AppColors.error : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rule_rounded, size: AppDimensions.iconSM, color: color),
          const SizedBox(width: AppDimensions.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  violation.ruleName,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  violation.detail,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (violation.instruction != null &&
                    violation.instruction!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    violation.instruction!,
                    style: AppTextStyles.labelSmall.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
