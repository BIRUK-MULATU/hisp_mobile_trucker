import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// A single applied filter, shown as a chip/summary instead of
/// "No filters applied" once the user picks something.
class AppliedFilter {
  final String label;
  const AppliedFilter(this.label);
}

/// The 12 quick date-range options shown in the DATE filter grid,
/// laid out 3 columns x 4 rows to match the Figma design.
const List<String> kDateFilterOptions = [
  'Today', 'Yesterday', 'Tomorrow',
  'This Week', 'Last Week', 'Next week',
  'This month', 'Last month', 'Next month',
  'From -To', 'Other', 'Any time',
];

/// Dropdown filter panel shown under the app bar when the
/// "list" icon is tapped. Matches the Figma design: a solid
/// primary-colored sheet with three expandable filter rows
/// (Date, Org Unit, Sync).
///
/// This widget is presentation-only — it reports filter changes
/// via the `on...Changed` callbacks so the parent page can decide
/// how to apply them (e.g. dispatch a bloc event).
class FilterPanel extends StatefulWidget {
  final AppliedFilter? dateFilter;
  final AppliedFilter? orgUnitFilter;
  final AppliedFilter? syncFilter;
  final ValueChanged<AppliedFilter?>? onDateChanged;
  final ValueChanged<AppliedFilter?>? onOrgUnitChanged;
  final ValueChanged<AppliedFilter?>? onSyncChanged;
  final VoidCallback? onOpenOrgUnitTree;

  const FilterPanel({
    super.key,
    this.dateFilter,
    this.orgUnitFilter,
    this.syncFilter,
    this.onDateChanged,
    this.onOrgUnitChanged,
    this.onSyncChanged,
    this.onOpenOrgUnitTree,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  int? _expandedIndex;
  Set<String> _syncSelected = {};

  void _toggle(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceMD,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterRow(
            icon: Icons.calendar_today_rounded,
            label: 'DATE',
            applied: widget.dateFilter,
            expanded: _expandedIndex == 0,
            onTap: () => _toggle(0),
            optionLabels: kDateFilterOptions,
            onOptionSelected: (label) {
              widget.onDateChanged?.call(AppliedFilter(label));
              // Date grid stays open after picking, unlike the other
              // rows, so the user can see their selection highlighted.
            },
            onClear: () {
              widget.onDateChanged?.call(null);
            },
            expandedContent: _DateFilterGrid(
              selected: widget.dateFilter?.label,
              onSelected: (label) =>
                  widget.onDateChanged?.call(AppliedFilter(label)),
            ),
          ),
          const Divider(color: Colors.white24, height: AppDimensions.spaceLG),
          _FilterRow(
            icon: Icons.apartment_rounded,
            label: 'ORG. UNIT',
            applied: widget.orgUnitFilter,
            expanded: _expandedIndex == 1,
            onTap: () => _toggle(1),
            optionLabels: const [
              'My org unit',
              'My org unit + children',
            ],
            onOptionSelected: (label) {
              widget.onOrgUnitChanged?.call(AppliedFilter(label));
              _toggle(1);
            },
            onClear: () {
              widget.onOrgUnitChanged?.call(null);
            },
            expandedContent: _OrgUnitSearchBar(
              onAdd: (text) {
                if (text.trim().isEmpty) return;
                widget.onOrgUnitChanged?.call(AppliedFilter(text.trim()));
              },
              onOpenTree: widget.onOpenOrgUnitTree,
            ),
          ),
          const Divider(color: Colors.white24, height: AppDimensions.spaceLG),
          _FilterRow(
            icon: Icons.sync_rounded,
            label: 'SYNC',
            applied: widget.syncFilter,
            expanded: _expandedIndex == 2,
            onTap: () => _toggle(2),
            optionLabels: const ['Synced', 'Unsync'],
            onOptionSelected: (label) {
              widget.onSyncChanged?.call(AppliedFilter(label));
              _toggle(2);
            },
            onClear: () {
              widget.onSyncChanged?.call(null);
            },
            fullBleedContent: true,
            expandedContent: _SyncFilterList(
              selected: _syncSelected,
              onChanged: (updated) {
                setState(() => _syncSelected = updated);
                widget.onSyncChanged?.call(
                  updated.isEmpty
                      ? null
                      : AppliedFilter(updated.join(', ')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncFilterList extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _SyncFilterList({required this.selected, required this.onChanged});

  static const _options = [
    _SyncOption('Synced', Icons.sync_rounded, Color(0xFF4CAF50)),
    _SyncOption('UnSynced', Icons.sync_rounded, Color(0xFFBDBDBD)),
    _SyncOption('Sync Error', Icons.priority_high_rounded, Color(0xFFE53935)),
    _SyncOption('SMS Synced', null, Color(0xFF37474F)),
  ];

  void _toggle(String label) {
    final updated = Set<String>.from(selected);
    if (updated.contains(label)) {
      updated.remove(label);
    } else {
      updated.add(label);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space,
        vertical: AppDimensions.spaceSM,
      ),
      child: Column(
        children: _options
            .map(
              (option) => _SyncOptionTile(
                option: option,
                checked: selected.contains(option.label),
                onTap: () => _toggle(option.label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SyncOption {
  final String label;
  final IconData? icon;
  final Color color;
  const _SyncOption(this.label, this.icon, this.color);
}

class _SyncOptionTile extends StatelessWidget {
  final _SyncOption option;
  final bool checked;
  final VoidCallback onTap;

  const _SyncOptionTile({
    required this.option,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSM),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: option.icon != null
                  ? Icon(option.icon, color: option.color, size: 18)
                  : Text(
                      'sms',
                      style: TextStyle(
                        color: option.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 1.5),
                borderRadius: BorderRadius.circular(4),
                color: checked ? Colors.white : Colors.transparent,
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primaryDark, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgUnitSearchBar extends StatefulWidget {
  final ValueChanged<String> onAdd;
  final VoidCallback? onOpenTree;

  const _OrgUnitSearchBar({required this.onAdd, this.onOpenTree});

  @override
  State<_OrgUnitSearchBar> createState() => _OrgUnitSearchBarState();
}

class _OrgUnitSearchBarState extends State<_OrgUnitSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconMD),
                const SizedBox(width: AppDimensions.spaceSM),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: widget.onAdd,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle:
                          TextStyle(color: AppColors.textHint),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => widget.onAdd(_controller.text),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: AppDimensions.iconSM),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSM),
        InkWell(
          onTap: widget.onOpenTree,
          child: const Icon(
            Icons.account_tree_rounded,
            color: Colors.white,
            size: AppDimensions.iconLG,
          ),
        ),
      ],
    );
  }
}

class _DateFilterGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _DateFilterGrid({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spaceSM,
      crossAxisSpacing: AppDimensions.spaceXS,
      childAspectRatio: 3.4,
      children: kDateFilterOptions
          .map((option) => _DateRadioOption(
                label: option,
                selected: option == selected,
                onTap: () => onSelected(option),
              ))
          .toList(),
    );
  }
}

class _DateRadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateRadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              color: Colors.transparent,
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppDimensions.spaceXS),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppliedFilter? applied;
  final bool expanded;
  final VoidCallback onTap;
  final List<String> optionLabels;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onClear;
  final Widget? expandedContent;
  final bool fullBleedContent;

  const _FilterRow({
    required this.icon,
    required this.label,
    required this.applied,
    required this.expanded,
    required this.onTap,
    required this.optionLabels,
    required this.onOptionSelected,
    required this.onClear,
    this.expandedContent,
    this.fullBleedContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: AppDimensions.iconMD),
                const SizedBox(width: AppDimensions.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        applied?.label ?? 'No filters applied',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                          fontStyle: applied == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (applied != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: AppDimensions.iconSM),
                    onPressed: onClear,
                    tooltip: 'Clear filter',
                  ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: AppDimensions.iconLG,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: fullBleedContent
              ? Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceSM),
            child: expandedContent,
          )
              : Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.spaceXXL,
                    top: AppDimensions.spaceXS,
                    bottom: AppDimensions.spaceSM,
                  ),
                  child: expandedContent ??
                      Wrap(
                        spacing: AppDimensions.spaceSM,
                        runSpacing: AppDimensions.spaceSM,
                        children: optionLabels
                            .map(
                              (option) => GestureDetector(
                                onTap: () => onOptionSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.spaceMD,
                                    vertical: AppDimensions.spaceXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusFull),
                                  ),
                                  child: Text(
                                    option,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.primary),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
