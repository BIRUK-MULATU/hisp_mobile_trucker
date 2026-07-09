import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  const PeriodSelectionPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    required this.periodType,
    required this.orgUnitId,
    required this.orgUnitName,
    this.sectionId,
    this.sectionName,
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

    _dataEntryBloc.add(DataEntryLoad(
      dataSetId: widget.dataSetId,
      orgUnitId: widget.orgUnitId,
      period: _selectedPeriodId!,
      sectionId: widget.sectionId,
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
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sectionName ?? widget.dataSetName,
          style: AppTextStyles.appBarTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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

                const SizedBox(height: AppDimensions.spaceGiant),

                // ── Open Form Button ──────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeightLG,
                  child: ElevatedButton(
                    onPressed: _openForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
