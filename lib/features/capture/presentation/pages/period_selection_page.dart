import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../../data_entry/data/repositories/data_entry_repository_impl.dart';
import '../../../data_entry/domain/usecases/get_data_elements_usecase.dart';
import '../../../data_entry/domain/usecases/save_data_values_usecase.dart';
import '../../../data_entry/presentation/bloc/data_entry_bloc.dart';
import '../../../data_entry/presentation/pages/data_entry_page.dart';
import '../widgets/period_selector_field.dart';

/// Last step before the form: pick the report period. The form
/// metadata is prefetched in the background while the user picks,
/// so opening the form is instant.
class PeriodSelectionPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType;
  final String orgUnitId;
  final String orgUnitName;
  final String? sectionId;
  final String? sectionName;

  /// Tags this dataset as Disease Registration — themes this page
  /// and the form after it with the disease accent.
  final bool isDiseaseRegistration;

  const PeriodSelectionPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    required this.periodType,
    required this.orgUnitId,
    required this.orgUnitName,
    this.sectionId,
    this.sectionName,
    this.isDiseaseRegistration = false,
  });

  @override
  State<PeriodSelectionPage> createState() => _PeriodSelectionPageState();
}

class _PeriodSelectionPageState extends State<PeriodSelectionPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPeriodId;

  late final DataEntryRepositoryImpl _repository;
  late final GetDataElementsUseCase _getDataElementsUseCase;
  late final DataEntryBloc _dataEntryBloc;

  bool _isPrefetching = false;
  bool _isPrefetchDone = false;

  /// The data set's OWN category combination (e.g. Department ×
  /// Outcome) — empty for the common "default combo" case, which
  /// needs no selection.
  List<CategoryDimension> _dimensions = const [];
  final Map<String, String> _dimensionSelections = {};

  @override
  void initState() {
    super.initState();
    _repository = DataEntryRepositoryImpl();
    _getDataElementsUseCase = GetDataElementsUseCase(_repository);
    _dataEntryBloc = DataEntryBloc(
      getDataElementsUseCase: _getDataElementsUseCase,
      saveDataValuesUseCase: SaveDataValuesUseCase(_repository),
      repository: _repository,
    );
    _prefetchDataElements();
    _loadDimensions();
  }

  Future<void> _loadDimensions() async {
    try {
      final db = AppSession.instance.service.db;
      final dimensions =
          await DataSetResource(db).categoryDimensions(widget.dataSetId);
      if (mounted) setState(() => _dimensions = dimensions);
    } catch (_) {
      // Metadata not synced yet — treated the same as "no combo to
      // pick"; the form still opens under the default combo.
    }
  }

  @override
  void dispose() {
    _dataEntryBloc.close();
    super.dispose();
  }

  // ── Prefetch form metadata while the user picks ────────────
  Future<void> _prefetchDataElements() async {
    setState(() => _isPrefetching = true);
    try {
      await _getDataElementsUseCase.call(
        dataSetId: widget.dataSetId,
        sectionId: widget.sectionId,
      );
      if (mounted) {
        setState(() {
          _isPrefetching = false;
          _isPrefetchDone = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPrefetching = false;
          _isPrefetchDone = false;
        });
      }
    }
  }

  Future<void> _openForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    String? attributeOptionComboUid;
    if (_dimensions.isNotEmpty) {
      final db = AppSession.instance.service.db;
      attributeOptionComboUid = await DataSetResource(db)
          .resolveCategoryOptionCombo(widget.dataSetId, _dimensionSelections);
      if (attributeOptionComboUid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not resolve the selected combination — '
                  'try again once metadata has synced.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    _dataEntryBloc.add(DataEntryLoad(
      dataSetId: widget.dataSetId,
      orgUnitId: widget.orgUnitId,
      period: _selectedPeriodId!,
      sectionId: widget.sectionId,
      attributeOptionComboUid: attributeOptionComboUid,
    ));

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _dataEntryBloc,
          child: DataEntryPage(
            dataSetId: widget.dataSetId,
            dataSetName: widget.dataSetName,
            orgUnitId: widget.orgUnitId,
            orgUnitName: widget.orgUnitName,
            period: _selectedPeriodId!,
            periodType: widget.periodType,
            sectionId: widget.sectionId,
            sectionName: widget.sectionName,
            preloadedBloc: _dataEntryBloc,
            isDiseaseRegistration: widget.isDiseaseRegistration,
            attributeOptionComboUid: attributeOptionComboUid,
          ),
        ),
      ),
    );

    // The form popped after a save — return to the section list so
    // the user can continue with the next section.
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionName = widget.sectionName;
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
              sectionName ?? widget.dataSetName,
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
          if (_isPrefetching)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (_isPrefetchDone)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Icon(
                  Icons.cloud_done_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: ResponsiveContent(
          maxWidth: AppBreakpoints.formMaxWidth,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spaceLG),

                // ── Context summary ────────────────────
                _SummaryField(label: 'Org unit', value: widget.orgUnitName),
                const SizedBox(height: AppDimensions.spaceXL),
                _SummaryField(label: 'Dataset', value: widget.dataSetName),
                if (sectionName != null) ...[
                  const SizedBox(height: AppDimensions.spaceXL),
                  _SummaryField(label: 'Section', value: sectionName),
                ],

                const SizedBox(height: AppDimensions.spaceXXL),

                PeriodSelectorField(
                  selectedPeriod: _selectedPeriodId,
                  periodType: widget.periodType,
                  dataSetId: widget.dataSetId,
                  onChanged: (value) {
                    setState(() => _selectedPeriodId = value);
                  },
                ),

                // Department/Outcome only make sense once a period is
                // picked — they stay hidden until then instead of
                // dumping every field on the user at once.
                if (_selectedPeriodId != null)
                  for (final dimension in _dimensions) ...[
                    const SizedBox(height: AppDimensions.spaceXL),
                    _DimensionField(
                      dimension: dimension,
                      selected: _dimensionSelections[dimension.uid],
                      onChanged: (value) => setState(() {
                        if (value == null) {
                          _dimensionSelections.remove(dimension.uid);
                        } else {
                          _dimensionSelections[dimension.uid] = value;
                        }
                      }),
                    ),
                  ],

                const SizedBox(height: AppDimensions.spaceGiant),

                // ── Open Form Button ──────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeightLG,
                  child: ElevatedButton(
                    onPressed: _openForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDiseaseRegistration
                          ? AppColors.diseaseAccent
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                    ),
                    child: Text(
                      'Open Form',
                      style: AppTextStyles.buttonLarge
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One dropdown for one category of the data set's own category
/// combination (e.g. "Department") — sibling to [PeriodSelectorField],
/// only rendered when the data set actually has a non-default combo.
class _DimensionField extends StatelessWidget {
  final CategoryDimension dimension;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _DimensionField({
    required this.dimension,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dimension.name,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSM),
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            filled: false,
            contentPadding: EdgeInsets.only(bottom: AppDimensions.spaceSM),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          items: [
            for (final option in dimension.options)
              DropdownMenuItem<String>(
                value: option.uid,
                child: Text(option.name, style: AppTextStyles.bodyMedium),
              ),
          ],
          onChanged: onChanged,
          validator: (value) =>
              value == null ? 'Please select ${dimension.name}' : null,
        ),
      ],
    );
  }
}

class _SummaryField extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w400)),
        const SizedBox(height: AppDimensions.spaceSM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
          ),
          child: Text(
            value,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
