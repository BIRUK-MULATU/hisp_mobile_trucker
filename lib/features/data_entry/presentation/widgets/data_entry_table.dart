import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/data_element_entity.dart';
import '../bloc/data_entry_bloc.dart';
import 'data_entry_cell.dart';

class DataEntryTable extends StatelessWidget {
  final List<DataElementEntity> dataElements;
  final Map<String, DataValueEntity> dataValues;
  final String orgUnitId;
  final String period;

  const DataEntryTable({
    super.key,
    required this.dataElements,
    required this.dataValues,
    required this.orgUnitId,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (dataElements.isEmpty) {
      return const Center(
        child: Text('No data elements found'),
      );
    }

    // Get all unique category option combos (columns)
    final List<CategoryOptionCombo> columns = _getColumns();

    // The widest row decides the table width — rows use their own
    // element's combos, which can differ in count per element.
    var maxColumns = columns.length;
    for (final element in dataElements) {
      if (element.categoryOptionCombos.length > maxColumns) {
        maxColumns = element.categoryOptionCombos.length;
      }
    }
    final tableWidth = 140.0 + 90.0 * maxColumns;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        // Rows are built lazily — large datasets would otherwise
        // inflate thousands of text fields at once.
        child: ListView.builder(
          itemCount: dataElements.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Column Headers ──────────────────
                  _buildColumnHeaders(columns),
                  const Divider(
                      height: 1, color: AppColors.divider),
                ],
              );
            }
            // ── Data Row ────────────────────────────
            return _DataEntryRow(
              element: dataElements[index - 1],
              columns: columns,
              dataValues: dataValues,
              orgUnitId: orgUnitId,
              period: period,
            );
          },
        ),
      ),
    );
  }

  List<CategoryOptionCombo> _getColumns() {
    if (dataElements.isEmpty) return [];

    // Use first element's category combos as columns
    // (all elements in a section share same category combo)
    final first = dataElements.first;
    if (first.categoryOptionCombos.isNotEmpty) {
      return first.categoryOptionCombos;
    }

    // Fallback — default combo
    return [
      const CategoryOptionCombo(
        id: 'default',
        name: 'Value',
      )
    ];
  }

  Widget _buildColumnHeaders(List<CategoryOptionCombo> columns) {
    return Row(
      children: [
        // ── Empty left cell (row label space) ────────
        const SizedBox(width: 140),

        // ── Column headers ────────────────────────────
        ...columns.map(
          (col) => Container(
            width: 90,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXS,
              vertical: AppDimensions.spaceSM,
            ),
            child: Text(
              col.displayName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Single Data Row ────────────────────────────────────────────
class _DataEntryRow extends StatelessWidget {
  final DataElementEntity element;
  final List<CategoryOptionCombo> columns;
  final Map<String, DataValueEntity> dataValues;
  final String orgUnitId;
  final String period;

  const _DataEntryRow({
    required this.element,
    required this.columns,
    required this.dataValues,
    required this.orgUnitId,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Row Label with blue left border ─────
            Container(
              width: 140,
              constraints:
                  const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceSM,
                vertical: AppDimensions.spaceSM,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                element.displayName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Input Cells ──────────────────────────
            // Use this element's own category option combos so a value
            // is never saved against a combo that belongs to a
            // different data element's category combo (rejected by the
            // server with a 409/E7634 conflict).
            ...(element.categoryOptionCombos.isNotEmpty
                    ? element.categoryOptionCombos
                    : columns)
                .map((col) {
              final key = '${element.id}_${col.id}';
              final existing = dataValues[key];

              return SizedBox(
                width: 90,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DataEntryCell(
                    key: ValueKey(key),
                    dataElementId: element.id,
                    categoryOptionComboId: col.id,
                    initialValue: existing?.value ?? '',
                    valueType: element.valueType,
                    onChanged: (value) {
                      context.read<DataEntryBloc>().add(
                            DataEntryValueChanged(
                              dataElementId: element.id,
                              categoryOptionComboId: col.id,
                              value: value,
                            ),
                          );
                    },
                  ),
                ),
              );
            }),
          ],
        ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}
