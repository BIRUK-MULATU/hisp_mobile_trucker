import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../data_entry/data/datasources/data_entry_remote_datasource.dart';
import '../../../data_entry/data/repositories/data_entry_repository_impl.dart';
import '../../../data_entry/domain/entities/data_element_entity.dart';
import '../../../data_entry/domain/usecases/get_data_elements_usecase.dart';
import '../../../data_entry/domain/usecases/save_data_values_usecase.dart';
import '../../../data_entry/presentation/bloc/data_entry_bloc.dart';
import '../../../data_entry/presentation/pages/data_entry_page.dart';
import '../widgets/period_selector_field.dart';
import 'org_unit_selector_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddRecordPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType;

  const AddRecordPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    this.periodType = 'Monthly',
  });

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = SecureStorage();

  String? _orgUnitName;
  String? _orgUnitId;
  String? _selectedPeriodId;

  // ── Prefetch state ─────────────────────────────────────────
  late final DataEntryRepositoryImpl _repository;
  late final GetDataElementsUseCase _getDataElementsUseCase;
  late final SaveDataValuesUseCase _saveDataValuesUseCase;
  late final DataEntryBloc _dataEntryBloc;

  bool _isPrefetching = false;
  bool _isPrefetchDone = false;

  @override
  void initState() {
    super.initState();

    // Initialize repository and bloc once
    _repository = DataEntryRepositoryImpl(
      remoteDataSource: DataEntryRemoteDataSourceImpl(
        apiClient: ApiClient(),
      ),
    );
    _getDataElementsUseCase =
        GetDataElementsUseCase(_repository);
    _saveDataValuesUseCase =
        SaveDataValuesUseCase(_repository);

    // Create bloc and immediately start prefetching
    // data elements — before user even picks a period
    _dataEntryBloc = DataEntryBloc(
      getDataElementsUseCase: _getDataElementsUseCase,
      saveDataValuesUseCase: _saveDataValuesUseCase,
      repository: _repository,
    );

    _loadOrgUnit();
    _prefetchDataElements();
  }

  @override
  void dispose() {
    _dataEntryBloc.close();
    super.dispose();
  }

  Future<void> _loadOrgUnit() async {
    final orgUnit = await _secureStorage.getPrimaryOrgUnit();
    if (mounted && orgUnit != null) {
      setState(() {
        _orgUnitId = orgUnit['id'] as String?;
        _orgUnitName = orgUnit['displayName'] as String?
            ?? orgUnit['name'] as String?
            ?? orgUnit['shortName'] as String?;
      });
    }
  }

  // ── Prefetch data elements in background ──────────────────
  Future<void> _prefetchDataElements() async {
    setState(() => _isPrefetching = true);
    try {
      // Load data elements silently
      await _getDataElementsUseCase.call(
          dataSetId: widget.dataSetId);
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

  Future<void> _openOrgUnitSelector() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrgUnitSelectorPage(preSelectedId: _orgUnitId),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _orgUnitId = result['id'] as String?;
        _orgUnitName = result['name'] as String?;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_orgUnitId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No organisation unit found. Contact your administrator.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Trigger load with selected org unit + period
      // Data elements already cached — only org unit
      // and period specific data values need fetching
      _dataEntryBloc.add(DataEntryLoad(
        dataSetId: widget.dataSetId,
        orgUnitId: _orgUnitId!,
        period: _selectedPeriodId!,
      ));

      // Navigate immediately — data is already loading
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: _dataEntryBloc,
            child: DataEntryPage(
              dataSetId: widget.dataSetId,
              dataSetName: widget.dataSetName,
              orgUnitId: _orgUnitId!,
              orgUnitName: _orgUnitName ?? '',
              period: _selectedPeriodId!,
              periodType: widget.periodType,
              preloadedBloc: _dataEntryBloc,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.dataSetName,
          style: AppTextStyles.appBarTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // ── Show prefetch indicator in AppBar ─────
        actions: [
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spaceLG),

              _TopIconSection(
                  onClose: () => Navigator.pop(context)),

              const SizedBox(height: AppDimensions.spaceXXL),

              _OrgUnitField(
                orgUnitName: _orgUnitName,
                onTap: _openOrgUnitSelector,
              ),

              const SizedBox(height: AppDimensions.spaceXXL),

              PeriodSelectorField(
                selectedPeriod: _selectedPeriodId,
                periodType: widget.periodType,
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
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
    );
  }
}

class _TopIconSection extends StatelessWidget {
  final VoidCallback onClose;
  const _TopIconSection({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: const Icon(Icons.grid_view_rounded,
              color: AppColors.primary,
              size: AppDimensions.iconXL),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrgUnitField extends StatelessWidget {
  final String? orgUnitName;
  final VoidCallback? onTap;
  const _OrgUnitField({this.orgUnitName, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Org unit',
              style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400)),
          const SizedBox(height: AppDimensions.spaceSM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                bottom: AppDimensions.spaceSM),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: AppColors.border, width: 1.0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    orgUnitName ?? 'Loading...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: orgUnitName != null
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: AppDimensions.iconMD,
                    color: AppColors.textHint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
