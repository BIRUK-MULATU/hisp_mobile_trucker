import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/indicator_display_service.dart'
    show DisplayIndicator;
import '../../../../core/data/validation_service.dart'
    show ExpressionEvaluator, UnsupportedExpression;
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../audit_log/presentation/widgets/cell_history_sheet.dart';
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

  /// Filters the visible sections by data element name — forms with
  /// many elements (e.g. long disease lists) need this to stay
  /// usable. Empty/null shows everything.
  final String? searchQuery;

  /// Appends a read-only Total row (sum of every category option
  /// combo currently entered) at the end of each expanded element —
  /// Disease Registration only; Routine leaves this off.
  final bool showElementTotal;

  /// The small sum badge beside a disaggregated element's name in its
  /// (collapsed or expanded) header. Routine keeps it; Disease
  /// Registration turns it off — with potentially hundreds of
  /// diseases listed, a number beside every name read as clutter.
  final bool showHeaderSumBadge;

  /// True once the period's expiry deadline has passed — every cell
  /// becomes view-only (still fully visible, just not editable).
  final bool readOnly;

  const DataEntryTable({
    super.key,
    required this.dataElements,
    required this.dataValues,
    required this.orgUnitId,
    required this.period,
    this.searchQuery,
    this.showElementTotal = false,
    this.showHeaderSumBadge = true,
    this.readOnly = false,
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

  // Accordion: opening one element auto-closes whatever else was
  // open (Routine and Disease Registration share this widget, so
  // both get it) — tapping the ALREADY-open one just collapses it.
  void _toggle(String elementId) {
    setState(() {
      if (_expandedIds.contains(elementId)) {
        _expandedIds.remove(elementId);
      } else {
        _expandedIds
          ..clear()
          ..add(elementId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataElements.isEmpty) {
      return const Center(
        child: Text('No data elements found'),
      );
    }

    // Controller data elements (see ControllerElementService): every
    // element a CLOSED controller gates is left out of the form
    // entirely — "closed until we say yes".
    final hiddenIds = <String>{};
    for (final e in widget.dataElements) {
      if (e.isController && !_controllerIsOpen(e)) {
        hiddenIds.addAll(e.controlledElementIds);
      }
    }

    final query = widget.searchQuery?.trim().toLowerCase() ?? '';
    final visibleElements = [
      for (final e in widget.dataElements)
        if (!hiddenIds.contains(e.id) &&
            (query.isEmpty || e.displayName.toLowerCase().contains(query)))
          e,
    ];
    if (visibleElements.isEmpty) {
      return Center(
        child: Text('No results for "${widget.searchQuery}"',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
      );
    }

    // Labeled data elements (see ElementLabelService) are pulled
    // together under one heading — several elements can share a
    // label (e.g. an aggregated/non-aggregated pair), so the first
    // occurrence of a label emits the heading AND every element that
    // shares it; later occurrences are skipped (already placed).
    // Unlabeled elements render exactly where they already are.
    final rows = <Object>[];
    final emittedLabels = <String>{};
    for (final e in visibleElements) {
      final label = e.label;
      if (label == null) {
        rows.add(e);
        continue;
      }
      if (!emittedLabels.add(label)) continue; // already placed
      rows.add(label);
      rows.addAll(visibleElements.where((e2) => e2.label == label));
    }

    // Sections are built lazily — large datasets would otherwise
    // inflate thousands of text fields at once.
    final list = ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return row is String
            ? _buildLabelHeading(row)
            : _buildSection(row as DataElementEntity);
      },
    );

    // Server-rejected values must be impossible to miss — red cells
    // alone can sit below the fold on long forms, so this counts the
    // WHOLE form, not just what the search currently shows.
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
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: list),
      ],
    );
  }

  // A shared KPI/indicator heading above a cluster of labeled
  // elements (see ElementLabelService) — distinct from an element's
  // own header so it doesn't read as another data element row.
  Widget _buildLabelHeading(String label) {
    return Container(
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          const Icon(Icons.label_rounded,
              color: AppColors.primary, size: AppDimensions.iconSM),
          const SizedBox(width: AppDimensions.spaceXS),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Element-total operand (no coc) or one specific combo's value —
  // same lookup shape ExpressionEvaluator/ValidationService use, just
  // read from the in-memory form instead of the database, so a
  // displayable indicator updates on every keystroke, in any section.
  double? _indicatorLookup(String dataElementId, String? comboId) {
    if (comboId != null) {
      final raw = widget.dataValues['${dataElementId}_$comboId']?.value;
      return double.tryParse((raw ?? '').trim());
    }
    double? total;
    for (final v in widget.dataValues.values) {
      if (v.dataElementId != dataElementId) continue;
      final n = double.tryParse(v.value.trim());
      if (n != null) total = (total ?? 0) + n;
    }
    return total;
  }

  // Read-only calculated indicator row — null (render nothing) when
  // its formula uses syntax the offline engine can't evaluate (e.g.
  // N{otherIndicator}), same "skip, never guess" rule validation
  // rules follow.
  Widget? _buildIndicatorRow(DisplayIndicator indicator) {
    final double value;
    try {
      final numerator =
          ExpressionEvaluator(indicator.numerator, _indicatorLookup).evaluate();
      final denominator =
          ExpressionEvaluator(indicator.denominator, _indicatorLookup)
              .evaluate();
      if (denominator == 0) {
        return _indicatorRowContainer(indicator.name, '—');
      }
      value = numerator / denominator * indicator.factor;
    } on UnsupportedExpression {
      return null;
    }
    final display = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return _indicatorRowContainer(indicator.name, display);
  }

  Widget _indicatorRowContainer(String name, String value) {
    return Container(
      width: double.infinity,
      color: AppColors.textSecondary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSM,
        vertical: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          const Tooltip(
            message: 'Automatically calculated — not entered directly',
            child: Icon(Icons.calculate_outlined,
                color: AppColors.textSecondary, size: AppDimensions.iconSM),
          ),
          const SizedBox(width: AppDimensions.spaceXS),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceSM,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sum of every combo currently entered for this element — shared by
  // the always-visible header badge and the expanded footer row.
  static (double total, bool anyValue) _comboTotal(
    Map<String, DataValueEntity> dataValues,
    DataElementEntity element,
    List<CategoryOptionCombo> combos,
  ) {
    var total = 0.0;
    var anyValue = false;
    for (final combo in combos) {
      final raw = dataValues['${element.id}_${combo.id}']?.value;
      final n = double.tryParse((raw ?? '').trim());
      if (n != null) {
        total += n;
        anyValue = true;
      }
    }
    return (total, anyValue);
  }

  static String _formatTotal(double total) => total == total.roundToDouble()
      ? total.toInt().toString()
      : total.toString();

  // A controller "opens" its group exactly when its own value is the
  // literal string "true" — 'false' and '' (never answered / cycled
  // back) both keep it closed.
  bool _controllerIsOpen(DataElementEntity controller) {
    for (final combo in controller.categoryOptionCombos) {
      final raw = widget.dataValues['${controller.id}_${combo.id}']?.value;
      if (raw?.trim().toLowerCase() == 'true') return true;
    }
    return false;
  }

  // Gate passed to a controller's DataEntryCell: opening is never
  // destructive, so it's allowed straight through. Closing an
  // ALREADY-open controller first confirms — only if there's actually
  // entered data under it to lose — then clears every combo of every
  // element it controls, reusing the exact same DataEntryValueChanged
  // event the per-cell "Clear value" action already uses (an empty
  // value is how the sync pipeline deletes a data value).
  Future<bool> _confirmControllerChange(
      DataElementEntity controller, String next) async {
    if (next == 'true' || !_controllerIsOpen(controller)) return true;

    final toClear = [
      for (final v in widget.dataValues.values)
        if (controller.controlledElementIds.contains(v.dataElementId) &&
            v.value.trim().isNotEmpty)
          v,
    ];
    if (toClear.isEmpty) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Clear entered data?'),
        content: Text(
          'Switching "${controller.displayName}" to No will erase the '
          '${toClear.length} value${toClear.length == 1 ? '' : 's'} '
          'already entered under it, and hide those fields again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear and close'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;

    final bloc = context.read<DataEntryBloc>();
    for (final v in toClear) {
      bloc.add(DataEntryValueChanged(
        dataElementId: v.dataElementId,
        categoryOptionComboId: v.categoryOptionComboId,
        value: '',
      ));
    }
    return true;
  }

  // Element display name, with a red "*" appended for a compulsory
  // element (DHIS2 dataSetElement.compulsory) — must be filled before
  // the data set can be marked complete.
  static Widget _elementNameText(DataElementEntity element, TextStyle style) {
    if (!element.compulsory) return Text(element.displayName, style: style);
    return Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: element.displayName),
        const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
      ]),
    );
  }

  Widget _buildSection(DataElementEntity element) {
    final combos = _combosFor(element);

    // Read-only calculated indicators anchored to this element (see
    // IndicatorDisplayService) — rendered directly above it, before
    // anything the user actually enters.
    final indicatorRows = [
      for (final ind in element.displayIndicators)
        if (_buildIndicatorRow(ind) case final w?) w,
    ];

    // No real disaggregation: just the data set's own single
    // "default" category option combo, which has nothing meaningful
    // to name. Skip the accordion — and the literal "default" label
    // — entirely and put the input field directly beside the element
    // name. A genuine single-option CUSTOM combo (real name, just
    // happens to have one choice) still gets the normal accordion,
    // since that name IS meaningful.
    if (combos.length == 1 && combos.first.name == 'default') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...indicatorRows,
          _buildFlatRow(element, combos.first),
          const Divider(height: 1, color: AppColors.divider),
        ],
      );
    }

    final expanded = _expandedIds.contains(element.id);

    // Filled / total summary so a collapsed section still tells the
    // user whether anything inside it is left to enter — greyed
    // combos are never enterable, so they don't belong in the count
    // ("3/4" would be permanently unreachable if the 4th is greyed).
    final enterableCombos = combos.where((c) => !c.isGreyed).toList();
    var filled = 0;
    for (final combo in enterableCombos) {
      final value = widget.dataValues['${element.id}_${combo.id}'];
      if (value != null && value.value.isNotEmpty) filled++;
    }
    final hasError = widget.dataValues.values
        .any((v) => v.dataElementId == element.id && v.syncError != null);

    // Disaggregated elements (more than the one default combo) are
    // exactly the ones a validation rule sums across — surface that
    // sum right beside the element name so it's visible without
    // expanding the section.
    final isDisaggregated = combos.length > 1;
    final showSumBadge = isDisaggregated && widget.showHeaderSumBadge;
    final (total, anyValue) = showSumBadge
        ? _comboTotal(widget.dataValues, element, combos)
        : (0.0, false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...indicatorRows,
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
              color:
                  expanded ? AppColors.primary.withValues(alpha: 0.04) : null,
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _elementNameText(
                    element,
                    AppTextStyles.bodySmall.copyWith(
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
                if (showSumBadge) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceSM,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Text(
                      anyValue ? _formatTotal(total) : '—',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSM),
                ],
                Text(
                  '$filled/${enterableCombos.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: filled == enterableCombos.length
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
        if (expanded) ...[
          ...combos.map((combo) => _buildComboRow(element, combo)),
          if (widget.showElementTotal) _buildTotalRow(element, combos),
        ],

        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }

  // Single-combo element: name + input on one row, no accordion and
  // no "default" combo label — there's only ever one field, so
  // nothing to expand into.
  Widget _buildFlatRow(DataElementEntity element, CategoryOptionCombo combo) {
    final key = '${element.id}_${combo.id}';
    final existing = widget.dataValues[key];
    final hasError = existing?.syncError != null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSM,
        vertical: AppDimensions.spaceSM,
      ),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _elementNameText(
              element,
              AppTextStyles.bodySmall.copyWith(
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
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            onTap: () => showCellHistorySheet(
              context,
              dataElementId: element.id,
              dataElementName: element.displayName,
              comboId: combo.id,
              comboName: combo.displayName,
              orgUnitId: widget.orgUnitId,
              period: widget.period,
              localValue: existing?.value,
              localIsModified: existing?.isModified ?? false,
              localSyncState: existing?.syncState,
              localSyncError: existing?.syncError,
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppDimensions.spaceXS),
              child: Icon(Icons.history_rounded,
                  size: AppDimensions.iconSM, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceXS),
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
                isReadOnly: widget.readOnly,
                isGreyed: combo.isGreyed,
                confirmChange: element.isController
                    ? (next) => _confirmControllerChange(element, next)
                    : null,
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
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            onTap: () => showCellHistorySheet(
              context,
              dataElementId: element.id,
              dataElementName: element.displayName,
              comboId: combo.id,
              comboName: combo.displayName,
              orgUnitId: widget.orgUnitId,
              period: widget.period,
              localValue: existing?.value,
              localIsModified: existing?.isModified ?? false,
              localSyncState: existing?.syncState,
              localSyncError: existing?.syncError,
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppDimensions.spaceXS),
              child: Icon(Icons.history_rounded,
                  size: AppDimensions.iconSM, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceXS),
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
                isReadOnly: widget.readOnly,
                isGreyed: combo.isGreyed,
                confirmChange: element.isController
                    ? (next) => _confirmControllerChange(element, next)
                    : null,
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

  // Updates live as the user types, since it reads straight from
  // widget.dataValues (refreshed on every DataEntryValueChanged).
  Widget _buildTotalRow(
      DataElementEntity element, List<CategoryOptionCombo> combos) {
    final (total, anyValue) = _comboTotal(widget.dataValues, element, combos);
    final display = anyValue ? _formatTotal(total) : '—';

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.space,
        right: AppDimensions.spaceSM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total',
              style: AppTextStyles.bodySmall
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration:
                    const BoxDecoration(color: AppColors.inputBackground),
                child: Text(
                  display,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
