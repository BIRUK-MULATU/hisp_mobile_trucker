import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/sync/manual_sync.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../../../shared/widgets/sync_snackbar.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/dataset_entity.dart';
import '../../domain/usecases/get_org_unit_datasets_usecase.dart';
import '../widgets/dataset_card.dart';
import 'period_selection_page.dart';

/// Second step of the Capture workflow: the datasets assigned to the
/// selected organisation unit. Reports already in progress live in
/// Home's Report Period list, not here.
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
  late final CaptureRepositoryImpl _repository;
  late final GetOrgUnitDataSetsUseCase _getDataSets;

  bool _searchActive = false;
  String _searchQuery = '';

  List<DataSetEntity>? _dataSets;
  String? _error;

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _repository = CaptureRepositoryImpl();
    _getDataSets = GetOrgUnitDataSetsUseCase(_repository);
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

  /// Same manual sync as the home app bar: push pending work, then
  /// reload so the cards' chips tell the new truth.
  Future<void> _onSyncTapped() async {
    if (_isSyncing) return;
    if (!AppSession.instance.isLoggedIn) return;
    final result = await runManualSync(
      onPushStart: () => setState(() => _isSyncing = true),
    );
    if (!mounted) return;
    setState(() => _isSyncing = false);
    showSyncResultSnackBar(context, result);
    if (result.pushedAnything) await _load();
  }

  Future<void> _openDataSet(DataSetEntity dataSet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeriodSelectionPage(
          dataSetId: dataSet.id,
          dataSetName: dataSet.name,
          periodType: dataSet.periodType,
          orgUnitId: widget.orgUnitId,
          orgUnitName: widget.orgUnitName,
          isDiseaseRegistration: dataSet.isDiseaseRegistration,
        ),
      ),
    );
    // Back from the form: values may have been saved (or pushed) —
    // reload so the synced/unsync chips tell the truth.
    if (mounted) await _load();
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: _searchActive ? 0 : null,
        actions: [
          if (!_searchActive) const ConnectivityIndicator(),
          IconButton(
            icon: Icon(
              _searchActive ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.white,
              size: AppDimensions.iconLG,
            ),
            onPressed: _toggleSearch,
            tooltip: _searchActive ? 'Close search' : 'Search datasets',
          ),
          if (!_searchActive) ...[
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        semanticsLabel: 'Syncing',
                      ),
                    )
                  : const Icon(
                      Icons.sync_rounded,
                      color: Colors.white,
                      size: AppDimensions.iconLG,
                    ),
              onPressed: _isSyncing ? null : _onSyncTapped,
              tooltip: 'Sync all',
            ),
            const SizedBox(width: AppDimensions.spaceXS),
          ],
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _searchActive
            ? Container(
                height: 40,
                margin: const EdgeInsets.only(right: AppDimensions.spaceSM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (q) => setState(() => _searchQuery = q),
                  cursorColor: AppColors.primary,
                  textAlignVertical: TextAlignVertical.center,
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.black87),
                  decoration: InputDecoration(
                    filled: false,
                    isDense: true,
                    hintText: 'Search datasets...',
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.black38,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: AppDimensions.iconLG,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space,
                      vertical: 10,
                    ),
                  ),
                ),
              )
            : Column(
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
      body: _buildDatasetsBody(),
    );
  }

  List<DataSetEntity> _filterDataSets(List<DataSetEntity> dataSets) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return dataSets;
    return [
      for (final d in dataSets)
        if (d.name.toLowerCase().contains(q)) d,
    ];
  }

  Widget _buildDatasetsBody() {
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final allDataSets = _dataSets;
    if (allDataSets == null) {
      return const AppLoader(message: 'Loading datasets...');
    }
    if (allDataSets.isEmpty) {
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
    final dataSets = _filterDataSets(allDataSets);
    if (dataSets.isEmpty) {
      final query = _searchQuery.trim();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: AppDimensions.iconHuge, color: AppColors.textSecondary),
              const SizedBox(height: AppDimensions.spaceLG),
              const Text('No results', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'No datasets match "$query".',
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
