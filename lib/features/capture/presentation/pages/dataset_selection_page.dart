import 'package:flutter/material.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/usecases/get_org_unit_datasets_usecase.dart';
import '../widgets/dataset_card.dart';
import 'section_selection_page.dart';

/// Second step of the Capture workflow: the datasets assigned to
/// the selected organisation unit on the configured DHIS2 instance.
class DatasetSelectionPage extends StatefulWidget {
  final String orgUnitId;
  final String orgUnitName;

  const DatasetSelectionPage({
    super.key,
    required this.orgUnitId,
    required this.orgUnitName,
  });

  @override
  State<DatasetSelectionPage> createState() => _DatasetSelectionPageState();
}

class _DatasetSelectionPageState extends State<DatasetSelectionPage> {
  late final GetOrgUnitDataSetsUseCase _getDataSets;

  List<DataSetEntity>? _dataSets;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getDataSets = GetOrgUnitDataSetsUseCase(
      CaptureRepositoryImpl(),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _dataSets = null;
      _error = null;
    });
    try {
      final dataSets = await _getDataSets.call(orgUnitId: widget.orgUnitId);
      if (mounted) setState(() => _dataSets = dataSets);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _openDataSet(DataSetEntity dataSet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectionSelectionPage(
          dataSetId: dataSet.id,
          dataSetName: dataSet.name,
          periodType: dataSet.periodType,
          orgUnitId: widget.orgUnitId,
          orgUnitName: widget.orgUnitName,
        ),
      ),
    );
    // Back from the form: values may have been saved (or pushed) —
    // reload so the synced/unsync chips tell the truth.
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: const [
          ConnectivityIndicator(),
          SizedBox(width: AppDimensions.space),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Dataset', style: AppTextStyles.appBarTitle),
            Text(
              widget.orgUnitName,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final dataSets = _dataSets;
    if (dataSets == null) {
      return const AppLoader(message: 'Loading datasets...');
    }
    if (dataSets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_rounded,
                  size: AppDimensions.iconHuge, color: AppColors.textSecondary),
              const SizedBox(height: AppDimensions.spaceLG),
              const Text('No datasets available',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'No datasets are assigned to '
                '${widget.orgUnitName}.\nPick a different '
                'organisation unit or contact your administrator.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      // A width-capped grid: one column on phones, two on tablets,
      // never stretching cards across a whole desktop window.
      child: ResponsiveContent(
        maxWidth: 1000,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMD),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500,
            // Tall enough for a 2-line title + chips row plus the
            // card's own margin/padding (a 108 extent overflowed).
            mainAxisExtent: 128,
          ),
          itemCount: dataSets.length,
          itemBuilder: (context, index) {
            final dataSet = dataSets[index];
            return DataSetCard(
              dataSet: dataSet,
              onTap: () => _openDataSet(dataSet),
            );
          },
        ),
      ),
    );
  }
}

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
            const Icon(Icons.cloud_off_rounded,
                size: AppDimensions.iconHuge, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceLG),
            const Text('Could not load datasets',
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
