import 'package:flutter/material.dart';
import '../../../../shared/theme/app_breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/connectivity_indicator.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/entities/dataset_section_entity.dart';
import '../../domain/usecases/get_dataset_sections_usecase.dart';
import 'period_selection_page.dart';

/// Third step of the Capture workflow: the sections of the chosen
/// dataset. A dataset with no sections skips straight to the period
/// step — the whole dataset is one form.
class SectionSelectionPage extends StatefulWidget {
  final String dataSetId;
  final String dataSetName;
  final String periodType;
  final String orgUnitId;
  final String orgUnitName;

  const SectionSelectionPage({
    super.key,
    required this.dataSetId,
    required this.dataSetName,
    required this.periodType,
    required this.orgUnitId,
    required this.orgUnitName,
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PeriodSelectionPage(
              dataSetId: widget.dataSetId,
              dataSetName: widget.dataSetName,
              periodType: widget.periodType,
              orgUnitId: widget.orgUnitId,
              orgUnitName: widget.orgUnitName,
            ),
          ),
        );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeriodSelectionPage(
          dataSetId: widget.dataSetId,
          dataSetName: widget.dataSetName,
          periodType: widget.periodType,
          orgUnitId: widget.orgUnitId,
          orgUnitName: widget.orgUnitName,
          sectionId: section.id,
          sectionName: section.name,
        ),
      ),
    );
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
            const Text('Select Section', style: AppTextStyles.appBarTitle),
            Text(
              widget.dataSetName,
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
    return ResponsiveContent(
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
