import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/ethiopian_period_service.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../../data_entry/data/repositories/data_entry_repository_impl.dart';
import '../../../data_entry/domain/usecases/get_data_elements_usecase.dart';
import '../../../data_entry/domain/usecases/save_data_values_usecase.dart';
import '../../../data_entry/presentation/bloc/data_entry_bloc.dart';
import '../../../data_entry/presentation/pages/data_entry_page.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/dataset_section_entity.dart';
import '../../domain/usecases/get_dataset_sections_usecase.dart';

/// Last step of the Capture workflow, for the period already picked:
/// the sections of the chosen dataset. A dataset with no sections
/// skips straight to the form — the whole dataset is one form.
class SectionSelectionPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType;
  final String orgUnitId;
  final String orgUnitName;
  final String period;

  /// Resolves the data set's own category combo, if it has one —
  /// null for the common "default combo" case.
  final String? attributeOptionComboUid;

  /// Tags this dataset as Disease Registration — themes this page
  /// and the form after it with the disease accent.
  final bool isDiseaseRegistration;

  const SectionSelectionPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    required this.periodType,
    required this.orgUnitId,
    required this.orgUnitName,
    required this.period,
    this.attributeOptionComboUid,
    this.isDiseaseRegistration = false,
  });

  @override
  State<SectionSelectionPage> createState() => _SectionSelectionPageState();
}

class _SectionSelectionPageState extends State<SectionSelectionPage> {
  late final GetDataSetSectionsUseCase _getSections;

  List<DataSetSectionEntity>? _sections;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getSections = GetDataSetSectionsUseCase(
      CaptureRepositoryImpl(),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _sections = null;
      _error = null;
    });
    try {
      final sections = await _getSections.call(dataSetId: widget.dataSetId);
      if (!mounted) return;
      if (sections.isEmpty) {
        // No sections — the dataset is captured as one whole form.
        _openForm(replace: true);
        return;
      }
      setState(() => _sections = sections);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _openSection(DataSetSectionEntity section) {
    _openForm(sectionId: section.id, sectionName: section.name);
  }

  /// Builds a fresh bloc, kicks off its load, and opens the form —
  /// `replace` swaps this page out entirely for datasets with no
  /// sections, so the back button from the form returns straight to
  /// period pick instead of an empty section grid.
  Future<void> _openForm({
    String? sectionId,
    String? sectionName,
    bool replace = false,
  }) async {
    final repository = DataEntryRepositoryImpl();
    final bloc = DataEntryBloc(
      getDataElementsUseCase: GetDataElementsUseCase(repository),
      saveDataValuesUseCase: SaveDataValuesUseCase(repository),
      repository: repository,
    );
    bloc.add(DataEntryLoad(
      dataSetId: widget.dataSetId,
      orgUnitId: widget.orgUnitId,
      period: widget.period,
      sectionId: sectionId,
      attributeOptionComboUid: widget.attributeOptionComboUid,
    ));

    final page = MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: DataEntryPage(
          dataSetId: widget.dataSetId,
          dataSetName: widget.dataSetName,
          orgUnitId: widget.orgUnitId,
          orgUnitName: widget.orgUnitName,
          period: widget.period,
          periodType: widget.periodType,
          sectionId: sectionId,
          sectionName: sectionName,
          preloadedBloc: bloc,
          isDiseaseRegistration: widget.isDiseaseRegistration,
          attributeOptionComboUid: widget.attributeOptionComboUid,
        ),
      ),
    );

    if (replace) {
      Navigator.pushReplacement(context, page);
    } else {
      // Awaiting (without relaying the result further) is what sends
      // the user back to this section grid after a save, so they can
      // continue with the next section.
      await Navigator.push(context, page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: widget.isDiseaseRegistration
            ? AppColors.diseaseAccent
            : AppColors.primary,
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
            Text(
              widget.isDiseaseRegistration
                  ? 'Select Section · Disease Registration'
                  : 'Select Section',
              style: AppTextStyles.appBarTitle,
            ),
            Text(
              '${widget.dataSetName} · '
              '${EthiopianPeriodService.formatPeriodId(widget.period)}',
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: AppDimensions.iconHuge, color: AppColors.textSecondary),
              const SizedBox(height: AppDimensions.spaceLG),
              const Text('Could not load sections',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(_error!,
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceXXL),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    final sections = _sections;
    if (sections == null) {
      return const AppLoader(message: 'Loading sections...');
    }
    // A width-capped grid: one column on phones, two on tablets.
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ResponsiveContent(
        maxWidth: 1000,
        child: GridView.builder(
          padding: const EdgeInsets.all(AppDimensions.space),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500,
            mainAxisExtent: 104,
            mainAxisSpacing: AppDimensions.spaceSM,
            crossAxisSpacing: AppDimensions.spaceSM,
          ),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return _SectionCard(
              index: index + 1,
              section: section,
              onTap: () => _openSection(section),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int index;
  final DataSetSectionEntity section;
  final VoidCallback onTap;

  const _SectionCard({
    required this.index,
    required this.section,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final description = section.description;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: Column(
                // Shrink to the text so the Row centers it against the
                // number badge — otherwise the column fills the fixed
                // tile height and the name sticks to the top.
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spaceXXS),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: AppDimensions.iconLG),
          ],
        ),
      ),
    );
  }
}
