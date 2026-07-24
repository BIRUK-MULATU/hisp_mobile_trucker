import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/data_element_entity.dart';
import '../bloc/data_entry_bloc.dart';
import 'data_entry_cell.dart';

/// Data entry form laid out as collapsible sections instead of a
/// grid: every data element is a tappable header and expanding it
/// lists that element's category option combos, one input row each.
/// The first element starts expanded; the rest start collapsed so
/// long forms stay scannable.
class DataEntryTable extends StatefulWidget {
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
  State<DataEntryTable> createState() => _DataEntryTableState();
}

class _DataEntryTableState extends State<DataEntryTable> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.dataElements.isNotEmpty) {
      _expandedIds.add(widget.dataElements.first.id);
    }
    // Rejected values must not hide inside a collapsed section —
    // open every element that has one.
    for (final value in widget.dataValues.values) {
      if (value.syncError != null) _expandedIds.add(value.dataElementId);
    }
  }

  // The repository guarantees at least the instance's real default COC
  // per element — no invented placeholder id here: 'default' is not a
  // uid the server accepts, and it poisoned pushed values.
  static List<CategoryOptionCombo> _combosFor(DataElementEntity element) =>
      element.categoryOptionCombos;

  void _toggle(String elementId) {
    setState(() {
      if (!_expandedIds.remove(elementId)) _expandedIds.add(elementId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataElements.isEmpty) {
      return const Center(
        child: Text('No data elements found'),
      );
    }

    // Sections are built lazily — large datasets would otherwise
    // inflate thousands of text fields at once.
    final list = ListView.builder(
      itemCount: widget.dataElements.length,
      itemBuilder: (context, index) =>
          _buildSection(widget.dataElements[index]),
    );

    // Server-rejected values must be impossible to miss — red cells
    // alone can sit below the fold on long forms.
    final formIds = {for (final e in widget.dataElements) e.id};
    final rejectedCount = widget.dataValues.values
        .where((v) => v.syncError != null && formIds.contains(v.dataElementId))
        .length;
    if (rejectedCount == 0) return list;

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
        Expanded(child: list),
      ],
    );
  }

  Widget _buildSection(DataElementEntity element) {
    final expanded = _expandedIds.contains(element.id);
    final combos = _combosFor(element);

    // Filled / total summary so a collapsed section still tells the
    // user whether anything inside it is left to enter.
    var filled = 0;
    for (final combo in combos) {
      final value = widget.dataValues['${element.id}_${combo.id}'];
      if (value != null && value.value.isNotEmpty) filled++;
    }
    final hasError = widget.dataValues.values.any((v) =>
        v.dataElementId == element.id &&
        v.syncError != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Element header (tap to collapse/expand) ──────────
        InkWell(
          onTap: () => _toggle(element.id),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceSM,
              vertical: AppDimensions.spaceSM,
            ),
            decoration: BoxDecoration(
              color: expanded
                  ? AppColors.primary.withValues(alpha: 0.04)
                  : null,
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    element.displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (hasError) ...[
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: AppDimensions.iconSM),
                  const SizedBox(width: AppDimensions.spaceXS),
                ],
                Text(
                  '$filled/${combos.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: filled == combos.length
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: AppDimensions.iconMD,
                ),
              ],
            ),
          ),
        ),

        // ── Category option combo rows ───────────────────────
        if (expanded)
          ...combos.map((combo) => _buildComboRow(element, combo)),

        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _buildComboRow(DataElementEntity element, CategoryOptionCombo combo) {
    final key = '${element.id}_${combo.id}';
    final existing = widget.dataValues[key];

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.space,
        right: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              combo.displayName,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          SizedBox(
            width: 140,
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
          ),
        ],
      ),
    );
  }
}
