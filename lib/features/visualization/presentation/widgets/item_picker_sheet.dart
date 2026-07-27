import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/chart_config.dart';

/// Searchable bottom-sheet picker for metadata items. Single-select
/// pops immediately with the tapped item; multi-select collects
/// checkmarks behind a Done button. Groups and datasets run into the
/// hundreds on the national instance, so search is not optional.
Future<List<ChartItemRef>?> showItemPicker(
  BuildContext context, {
  required String title,
  required List<ChartItemRef> items,
  bool multi = false,
  List<ChartItemRef> initialSelected = const [],
}) {
  return showModalBottomSheet<List<ChartItemRef>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG)),
    ),
    builder: (context) => _ItemPickerSheet(
      title: title,
      items: items,
      multi: multi,
      initialSelected: initialSelected,
    ),
  );
}

class _ItemPickerSheet extends StatefulWidget {
  final String title;
  final List<ChartItemRef> items;
  final bool multi;
  final List<ChartItemRef> initialSelected;

  const _ItemPickerSheet({
    required this.title,
    required this.items,
    required this.multi,
    required this.initialSelected,
  });

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  String _query = '';
  late final Map<String, ChartItemRef> _selected = {
    for (final i in widget.initialSelected) i.id: i,
  };

  List<ChartItemRef> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return [
      for (final i in widget.items)
        if (i.name.toLowerCase().contains(q)) i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return SafeArea(
      child: Padding(
        // Keep the sheet above the keyboard while searching.
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space,
                  AppDimensions.space,
                  AppDimensions.space,
                  AppDimensions.spaceSM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title,
                          style: AppTextStyles.headingSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (widget.multi)
                      Text(
                        '${_selected.length} selected',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMD),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No results',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final checked = _selected.containsKey(item.id);
                          return widget.multi
                              ? CheckboxListTile(
                                  dense: true,
                                  activeColor: AppColors.primary,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(item.name,
                                      style: AppTextStyles.bodyMedium),
                                  value: checked,
                                  onChanged: (v) => setState(() => v == true
                                      ? _selected[item.id] = item
                                      : _selected.remove(item.id)),
                                )
                              : ListTile(
                                  dense: true,
                                  title: Text(item.name,
                                      style: AppTextStyles.bodyMedium),
                                  trailing: checked
                                      ? const Icon(Icons.check_rounded,
                                          color: AppColors.primary)
                                      : null,
                                  onTap: () =>
                                      Navigator.pop(context, [item]),
                                );
                        },
                      ),
              ),
              if (widget.multi) ...[
                const Divider(height: 1, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightMD,
                    child: ElevatedButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.pop(
                              context, _selected.values.toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
