import 'package:flutter/material.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../capture/domain/entities/org_unit_tree_node.dart';
import '../../../capture/presentation/pages/org_unit_filter_page.dart';
import '../../data/repositories/chart_repository_impl.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/chart_config.dart';
import '../widgets/chart_type_selector.dart';
import '../widgets/dhis2_chart.dart';
import '../widgets/item_picker_sheet.dart';
import '../widgets/period_selector.dart';

/// The Create New tab: pick a chart type, a data selection
/// (indicator / data element / dataset), one organisation unit and a
/// period, then Update runs analytics and previews the chart. Save
/// puts it on the Charts tab.
class ChartBuilderView extends StatefulWidget {
  /// Called after a successful save so the shell can switch to the
  /// Charts tab and refresh it.
  final VoidCallback onSaved;

  const ChartBuilderView({super.key, required this.onSaved});

  @override
  State<ChartBuilderView> createState() => _ChartBuilderViewState();
}

class _ChartBuilderViewState extends State<ChartBuilderView> {
  final _repository = ChartRepositoryImpl();
  final _nameController = TextEditingController();

  ChartType _chartType = ChartType.column;
  ChartDataType? _dataType;

  // Indicator selection.
  ChartItemRef? _indicatorGroup;
  List<ChartItemRef> _indicators = [];

  // Data element selection.
  ChartItemRef? _deGroup;
  List<DataElementWithCocs> _groupElements = [];
  List<DataElementWithCocs> _dataElements = [];
  Disaggregation _disaggregation = Disaggregation.totalsOnly;

  // Dataset selection.
  ChartItemRef? _dataSet;
  DataSetMetric? _metric;

  OrgUnitTreeNode? _orgUnit;
  PeriodOption? _period;

  bool _loadingPicker = false;
  bool _updating = false;
  bool _showErrors = false;

  AnalyticsData? _preview;
  ChartConfig? _previewConfig;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Pickers ────────────────────────────────────────────────────

  /// Every picker needs the server; fetch its options behind one
  /// shared spinner flag, with a readable failure snackbar.
  Future<T?> _fetch<T>(Future<T> Function() load) async {
    setState(() => _loadingPicker = true);
    try {
      await ConnectivityService.instance.checkNow();
      if (!(ConnectivityService.instance.online ?? false)) {
        _toast('You are offline. Connect to the server to build charts.');
        return null;
      }
      return await load();
    } catch (e) {
      _toast('Could not load options: '
          '${e.toString().replaceAll('Exception: ', '')}');
      return null;
    } finally {
      if (mounted) setState(() => _loadingPicker = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickIndicatorGroup() async {
    final groups = await _fetch(_repository.getIndicatorGroups);
    if (groups == null || !mounted) return;
    final picked = await showItemPicker(context,
        title: 'Select Indicator Group', items: groups);
    if (picked == null || picked.isEmpty) return;
    setState(() {
      _indicatorGroup = picked.first;
      _indicators = [];
    });
  }

  Future<void> _pickIndicators() async {
    final group = _indicatorGroup;
    if (group == null) return;
    final items =
        await _fetch(() => _repository.getIndicatorsInGroup(group.id));
    if (items == null || !mounted) return;
    final picked = await showItemPicker(context,
        title: 'Select Indicators',
        items: items,
        multi: true,
        initialSelected: _indicators);
    if (picked == null) return;
    setState(() => _indicators = picked);
  }

  Future<void> _pickDataElementGroup() async {
    final groups = await _fetch(_repository.getDataElementGroups);
    if (groups == null || !mounted) return;
    final picked = await showItemPicker(context,
        title: 'Select Data Element Group', items: groups);
    if (picked == null || picked.isEmpty) return;
    setState(() {
      _deGroup = picked.first;
      _groupElements = [];
      _dataElements = [];
    });
  }

  Future<void> _pickDataElements() async {
    final group = _deGroup;
    if (group == null) return;
    if (_groupElements.isEmpty) {
      final elements =
          await _fetch(() => _repository.getDataElementsInGroup(group.id));
      if (elements == null || !mounted) return;
      _groupElements = elements;
    }
    final picked = await showItemPicker(context,
        title: 'Select Data Elements',
        items: [for (final e in _groupElements) e.ref],
        multi: true,
        initialSelected: [for (final e in _dataElements) e.ref]);
    if (picked == null) return;
    final byId = {for (final e in _groupElements) e.ref.id: e};
    setState(() =>
        _dataElements = [for (final r in picked) byId[r.id]!]);
  }

  Future<void> _pickDataSet() async {
    final sets = await _fetch(_repository.getDataSets);
    if (sets == null || !mounted) return;
    final picked = await showItemPicker(context,
        title: 'Select Dataset', items: sets);
    if (picked == null || picked.isEmpty) return;
    setState(() => _dataSet = picked.first);
  }

  Future<void> _pickMetric() async {
    final picked = await showItemPicker(context,
        title: 'Select Metric Type',
        items: [
          for (final m in DataSetMetric.values)
            ChartItemRef(id: m.name, name: m.label),
        ]);
    if (picked == null || picked.isEmpty) return;
    setState(() =>
        _metric = DataSetMetric.values.asNameMap()[picked.first.id]);
  }

  Future<void> _pickOrgUnit() async {
    final node = await Navigator.push<OrgUnitTreeNode>(
      context,
      MaterialPageRoute(builder: (_) => const OrgUnitFilterPage()),
    );
    if (node != null && mounted) setState(() => _orgUnit = node);
  }

  // ── Building & running ─────────────────────────────────────────

  /// The dx item list for the current selection; data element details
  /// expand into `de.coc` operands here.
  List<ChartItemRef> _selectedItems() {
    switch (_dataType) {
      case ChartDataType.indicator:
        return _indicators;
      case ChartDataType.dataElement:
        if (_disaggregation == Disaggregation.totalsOnly) {
          return [for (final e in _dataElements) e.ref];
        }
        return [
          for (final e in _dataElements)
            if (e.cocs.isEmpty)
              e.ref
            else
              for (final coc in e.cocs)
                ChartItemRef(
                  id: '${e.ref.id}.${coc.id}',
                  name: coc.name == 'default'
                      ? e.ref.name
                      : '${e.ref.name} ${coc.name}',
                ),
        ];
      case ChartDataType.dataSet:
        return [if (_dataSet != null) _dataSet!];
      case null:
        return const [];
    }
  }

  String? get _dataError {
    switch (_dataType) {
      case null:
        return 'Select a data type';
      case ChartDataType.indicator:
        if (_indicatorGroup == null) return 'Select an indicator group';
        if (_indicators.isEmpty) return 'Select at least one indicator';
      case ChartDataType.dataElement:
        if (_deGroup == null) return 'Select a data element group';
        if (_dataElements.isEmpty) return 'Select at least one data element';
      case ChartDataType.dataSet:
        if (_dataSet == null) return 'Select a dataset';
        if (_metric == null) return 'Select a metric type';
    }
    return null;
  }

  String? get _orgUnitError =>
      _orgUnit == null ? 'Select an organisation unit' : null;

  String? get _periodError => _period == null ? 'Select a period' : null;

  String get _defaultName {
    final items = _selectedItems();
    final what = switch (_dataType) {
      ChartDataType.dataSet =>
        '${_dataSet?.name} — ${_metric?.label ?? ''}',
      _ => items.length == 1
          ? items.first.name
          : '${items.length} ${_dataType == ChartDataType.indicator ? 'indicators' : 'data elements'}',
    };
    return '$what · ${_period?.label ?? ''}';
  }

  Future<void> _update() async {
    setState(() => _showErrors = true);
    final firstError = _dataError ?? _orgUnitError ?? _periodError;
    if (firstError != null) {
      _toast(firstError);
      return;
    }

    setState(() {
      _updating = true;
      _preview = null;
      _previewConfig = null;
    });
    try {
      await ConnectivityService.instance.checkNow();
      if (!(ConnectivityService.instance.online ?? false)) {
        _toast('You are offline. Connect to the server to build charts.');
        return;
      }
      final name = _nameController.text.trim();
      final config = ChartConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isEmpty ? _defaultName : name,
        chartType: _chartType,
        dataType: _dataType!,
        groupName: switch (_dataType!) {
          ChartDataType.indicator => _indicatorGroup?.name,
          ChartDataType.dataElement => _deGroup?.name,
          ChartDataType.dataSet => null,
        },
        items: _selectedItems(),
        disaggregation:
            _dataType == ChartDataType.dataElement ? _disaggregation : null,
        metric: _dataType == ChartDataType.dataSet ? _metric : null,
        orgUnitId: _orgUnit!.id,
        orgUnitName: _orgUnit!.name,
        periodKind: _period!.kind,
        periodId: _period!.id,
        periodLabel: _period!.label,
        createdAt: DateTime.now(),
      );
      final data = await _repository.runChart(config);
      if (mounted) {
        setState(() {
          _preview = data;
          _previewConfig = config;
        });
      }
    } catch (e) {
      _toast('Could not load the chart: '
          '${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _save() async {
    final config = _previewConfig;
    if (config == null) return;
    await _repository.saveChart(config);
    if (!mounted) return;
    _toast('Chart saved.');
    widget.onSaved();
  }

  // ── UI ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space),
      children: [
        const Text('Chart Type', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.spaceSM),
        ChartTypeSelector(
          selected: _chartType,
          onChanged: (t) => setState(() => _chartType = t),
        ),
        const SizedBox(height: AppDimensions.space),
        _SectionCard(
          title: 'Data',
          error: _showErrors ? _dataError : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PickerField(
                label: 'Data Type',
                value: _dataType?.label,
                hint: 'Select data type',
                onTap: () async {
                  final picked = await showItemPicker(context,
                      title: 'Select Data Type',
                      items: [
                        for (final t in ChartDataType.values)
                          ChartItemRef(id: t.name, name: t.label),
                      ]);
                  if (picked == null || picked.isEmpty) return;
                  setState(() {
                    _dataType =
                        ChartDataType.values.asNameMap()[picked.first.id];
                  });
                },
              ),
              if (_dataType == ChartDataType.indicator) ...[
                _PickerField(
                  label: 'Indicator Group',
                  value: _indicatorGroup?.name,
                  hint: 'Select indicator group',
                  onTap: _pickIndicatorGroup,
                ),
                _PickerField(
                  label: 'Indicators',
                  value: _indicators.isEmpty
                      ? null
                      : _indicators.length == 1
                          ? _indicators.first.name
                          : '${_indicators.length} selected',
                  hint: 'Select indicators',
                  enabled: _indicatorGroup != null,
                  onTap: _pickIndicators,
                ),
              ],
              if (_dataType == ChartDataType.dataElement) ...[
                _PickerField(
                  label: 'Data Element Group',
                  value: _deGroup?.name,
                  hint: 'Select data element group',
                  onTap: _pickDataElementGroup,
                ),
                _PickerField(
                  label: 'Data Elements',
                  value: _dataElements.isEmpty
                      ? null
                      : _dataElements.length == 1
                          ? _dataElements.first.ref.name
                          : '${_dataElements.length} selected',
                  hint: 'Select data elements',
                  enabled: _deGroup != null,
                  onTap: _pickDataElements,
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                const Text('Disaggregation',
                    style: AppTextStyles.labelMedium),
                RadioGroup<Disaggregation>(
                  groupValue: _disaggregation,
                  onChanged: (v) =>
                      setState(() => _disaggregation = v ?? _disaggregation),
                  child: Column(
                    children: [
                      for (final d in Disaggregation.values)
                        RadioListTile<Disaggregation>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                          title:
                              Text(d.label, style: AppTextStyles.bodyMedium),
                          value: d,
                        ),
                    ],
                  ),
                ),
              ],
              if (_dataType == ChartDataType.dataSet) ...[
                _PickerField(
                  label: 'Dataset',
                  value: _dataSet?.name,
                  hint: 'Select dataset',
                  onTap: _pickDataSet,
                ),
                _PickerField(
                  label: 'Metric Type',
                  value: _metric?.label,
                  hint: 'Select metric type',
                  onTap: _pickMetric,
                ),
              ],
            ],
          ),
        ),
        _SectionCard(
          title: 'Organisation Unit',
          error: _showErrors ? _orgUnitError : null,
          child: _PickerField(
            label: 'Organisation Unit',
            value: _orgUnit?.name,
            hint: 'Select one organisation unit',
            onTap: _pickOrgUnit,
          ),
        ),
        _SectionCard(
          title: 'Period',
          error: _showErrors ? _periodError : null,
          child: PeriodSelector(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
        ),
        _SectionCard(
          title: 'Chart Name (optional)',
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Named after the data if left empty',
              isDense: true,
              filled: true,
              fillColor: AppColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSM),
        SizedBox(
          height: AppDimensions.buttonHeightLG,
          child: ElevatedButton.icon(
            onPressed: _updating || _loadingPicker ? null : _update,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.backgroundGrey,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            icon: _updating || _loadingPicker
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(_updating ? 'Loading...' : 'Update'),
          ),
        ),
        if (_preview != null) ...[
          const SizedBox(height: AppDimensions.space),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              side: const BorderSide(color: AppColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _previewConfig?.name ?? '',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Dhis2Chart(data: _preview!),
                  const SizedBox(height: AppDimensions.space),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightMD,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Chart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.spaceXXL),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? error;
  final Widget child;

  const _SectionCard({required this.title, this.error, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: BorderSide(
            color: error != null ? AppColors.error : AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.labelLarge),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.spaceXS),
                child: Text(
                  error!,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.error),
                ),
              ),
            const SizedBox(height: AppDimensions.spaceSM),
            child,
          ],
        ),
      ),
    );
  }
}

/// A tappable dropdown-style field: label above, current value or
/// hint inside, chevron on the right.
class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final bool enabled;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.hint,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelMedium),
          const SizedBox(height: AppDimensions.spaceXS),
          InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
                vertical: AppDimensions.spaceMD,
              ),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.backgroundGrey
                    : AppColors.backgroundGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? hint,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: value == null
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textDisabled,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
