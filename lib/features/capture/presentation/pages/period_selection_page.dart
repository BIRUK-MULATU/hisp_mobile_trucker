import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../../data_entry/data/repositories/data_entry_repository_impl.dart';
import '../../../data_entry/domain/usecases/get_data_elements_usecase.dart';
import '../widgets/period_selector_field.dart';
import 'section_selection_page.dart';

/// Second-to-last step of the Capture workflow: pick the report
/// period (and category-combo, if any) before choosing a section.
/// The form metadata is prefetched in the background while the user
/// picks, so opening a section is instant.
class PeriodSelectionPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType;
  final String orgUnitId;
  final String orgUnitName;

  /// Tags this dataset as Disease Registration — themes this page
  /// and every step after it with the disease accent.
  final bool isDiseaseRegistration;

  const PeriodSelectionPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    required this.periodType,
    required this.orgUnitId,
    required this.orgUnitName,
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

  // ── Prefetch form metadata while the user picks ────────────
  // Section isn't known yet at this step, so this warms the whole
  // dataset's elements — a superset of whatever section is chosen
  // next, which still shortens that page's own read.
  Future<void> _prefetchDataElements() async {
    setState(() => _isPrefetching = true);
    try {
      await _getDataElementsUseCase.call(dataSetId: widget.dataSetId);
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

  Future<void> _onContinue() async {
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

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectionSelectionPage(
          dataSetId: widget.dataSetId,
          dataSetName: widget.dataSetName,
          periodType: widget.periodType,
          orgUnitId: widget.orgUnitId,
          orgUnitName: widget.orgUnitName,
          period: _selectedPeriodId!,
          attributeOptionComboUid: attributeOptionComboUid,
          isDiseaseRegistration: widget.isDiseaseRegistration,
        ),
      ),
    );

    // The form popped after a save — return to the dataset list so
    // the synced/unsync chips there tell the truth.
    if (result != null && mounted) {
      Navigator.pop(context, result);
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
              widget.dataSetName,
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

                // ── Continue Button ──────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeightLG,
                  child: ElevatedButton(
                    onPressed: _onContinue,
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
                      'Continue',
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
