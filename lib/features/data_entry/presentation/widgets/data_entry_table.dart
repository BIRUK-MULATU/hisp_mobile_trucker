import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/app_breakpoints.dart';
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

    // A dataset can mix category combos (age/sex disaggregated
    // elements next to plain ones), so elements are grouped by
    // combo and every group gets its own header row. Axes are
    // swapped relative to the DHIS2 web app: data elements run
    // across the top and category option combos down the side.
    final groups = <String, List<DataElementEntity>>{};
    for (final element in dataElements) {
      final key = element.categoryComboId ?? 'default';
      groups.putIfAbsent(key, () => []).add(element);
    }

    final items = <_TableItem>[];
    for (final group in groups.values) {
      items.add(_TableItem.header(group));
      for (final combo in _rowCombosFor(group.first)) {
        items.add(_TableItem.row(combo, group));
      }
    }

    // The group with the most data elements decides the table width.
    var maxColumns = 1;
    for (final group in groups.values) {
      if (group.length > maxColumns) {
        maxColumns = group.length;
      }
    }

    final table = LayoutBuilder(
      builder: (context, constraints) {
        // Phone-sized minimums; on wider screens the label column
        // grows and the cells stretch to fill the viewport so the
        // table doesn't sit in a narrow strip on tablets.
        final labelWidth =
            constraints.maxWidth >= AppBreakpoints.tablet ? 220.0 : 140.0;
        var cellWidth = 90.0;
        final naturalWidth = labelWidth + cellWidth * maxColumns;
        if (constraints.maxWidth > naturalWidth) {
          cellWidth = ((constraints.maxWidth - labelWidth) / maxColumns)
              .clamp(90.0, 220.0);
        }
        final tableWidth = labelWidth + cellWidth * maxColumns;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            // Rows are built lazily — large datasets would otherwise
            // inflate thousands of text fields at once.
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.isHeader) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Column Headers (one per combo group) ──
                      _buildColumnHeaders(item.elements, labelWidth, cellWidth),
                      const Divider(height: 1, color: AppColors.divider),
                    ],
                  );
                }
                // ── Data Row (one category option combo) ─────
                return _DataEntryRow(
                  combo: item.combo!,
                  elements: item.elements,
                  dataValues: dataValues,
                  orgUnitId: orgUnitId,
                  period: period,
                  labelWidth: labelWidth,
                  cellWidth: cellWidth,
                );
              },
            ),
          ),
        );
      },
    );

    // Server-rejected values must be impossible to miss — red cells
    // alone can sit below the fold on long forms.
    final formIds = {for (final e in dataElements) e.id};
    final rejectedCount = dataValues.values
        .where((v) => v.syncError != null && formIds.contains(v.dataElementId))
        .length;
    if (rejectedCount == 0) return table;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.error.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space,
            vertical: AppDimensions.spaceSM,
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: AppDimensions.iconMD),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: Text(
                  '$rejectedCount value${rejectedCount == 1 ? '' : 's'} '
                  'rejected by the server — long-press the red cells for '
                  'details, then correct and save to resend.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: table),
      ],
    );
  }

  static List<CategoryOptionCombo> _rowCombosFor(DataElementEntity element) {
    if (element.categoryOptionCombos.isNotEmpty) {
      return element.categoryOptionCombos;
    }
    // Fallback — default combo
    return const [CategoryOptionCombo(id: 'default', name: 'Value')];
  }

  Widget _buildColumnHeaders(
      List<DataElementEntity> elements, double labelWidth, double cellWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Empty left cell (row label space) ────────
        SizedBox(width: labelWidth),

        // ── Column headers (data element names) ───────
        ...elements.map(
          (element) => Container(
            width: cellWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXS,
              vertical: AppDimensions.spaceSM,
            ),
            child: Text(
              element.displayName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Lazy-list item: either a group header or a data row ────────
class _TableItem {
  final CategoryOptionCombo? combo;
  final List<DataElementEntity> elements;

  const _TableItem.header(this.elements) : combo = null;
  const _TableItem.row(CategoryOptionCombo this.combo, this.elements);

  bool get isHeader => combo == null;
}

// ── Single Data Row (one category option combo) ────────────────
class _DataEntryRow extends StatelessWidget {
  final CategoryOptionCombo combo;
  final List<DataElementEntity> elements;
  final Map<String, DataValueEntity> dataValues;
  final String orgUnitId;
  final String period;
  final double labelWidth;
  final double cellWidth;

  const _DataEntryRow({
    required this.combo,
    required this.elements,
    required this.dataValues,
    required this.orgUnitId,
    required this.period,
    required this.labelWidth,
    required this.cellWidth,
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
              width: labelWidth,
              constraints: const BoxConstraints(minHeight: 48),
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
                combo.displayName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Input Cells ──────────────────────────
            // A cell is only rendered when the row combo belongs to
            // the column element's own category combo, so a value is
            // never saved against a combo from a different category
            // combo (server rejects those with 409/E7634).
            ...elements.map((element) {
              final ownCombos = DataEntryTable._rowCombosFor(element);
              if (!ownCombos.any((c) => c.id == combo.id)) {
                return SizedBox(width: cellWidth);
              }
              final key = '${element.id}_${combo.id}';
              final existing = dataValues[key];

              return SizedBox(
                width: cellWidth,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DataEntryCell(
                    key: ValueKey(key),
                    dataElementId: element.id,
                    categoryOptionComboId: combo.id,
                    initialValue: existing?.value ?? '',
                    valueType: element.valueType,
                    options: element.options,
                    errorText: existing?.syncError,
                    onChanged: (value) {
                      context.read<DataEntryBloc>().add(
                            DataEntryValueChanged(
                              dataElementId: element.id,
                              categoryOptionComboId: combo.id,
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
