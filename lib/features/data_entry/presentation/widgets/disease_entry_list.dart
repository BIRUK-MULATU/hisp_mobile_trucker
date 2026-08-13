import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../domain/entities/data_element_entity.dart';
import 'data_entry_table.dart';

/// Disease Registration's data entry layout: there can be hundreds
/// of possible diseases, so instead of listing all of them the form
/// only shows ones that already have data ("recorded" — filled in a
/// previous session). "Select for new disease" is a searchable
/// picker (browsable on tap, filters as you type) for everything
/// else; picking one opens a new form ABOVE the existing ones
/// (prepended, auto-expanded). Everything below that — the
/// accordion, its combo rows, the rejected-value banner — is the
/// exact same [DataEntryTable] the Routine app uses; this widget
/// only decides WHICH data elements are visible and in what order.
class DiseaseEntryList extends StatefulWidget {
  final List<DataElementEntity> dataElements;
  final Map<String, DataValueEntity> dataValues;
  final String orgUnitId;
  final String period;

  /// True once the period's expiry deadline has passed — cells go
  /// view-only and "Select for new disease" (there'd be nothing
  /// meaningful to type into a fresh one) is hidden.
  final bool readOnly;

  /// App-tour anchor for "Select for new disease" (see data_entry_page
  /// .dart) — null outside the tour, no behavior change.
  final GlobalKey? searchShowcaseKey;

  const DiseaseEntryList({
    super.key,
    required this.dataElements,
    required this.dataValues,
    required this.orgUnitId,
    required this.period,
    this.readOnly = false,
    this.searchShowcaseKey,
  });

  @override
  State<DiseaseEntryList> createState() => _DiseaseEntryListState();
}

class _DiseaseEntryListState extends State<DiseaseEntryList> {
  final _newDiseaseController = TextEditingController();
  final _newDiseaseFocusNode = FocusNode();
  String _newDiseaseQuery = '';

  // Diseases picked via search this session, most-recently-picked
  // first — shown (and opened) even before they have a value, since
  // the user is actively filling one in right now.
  final List<String> _pickedIds = [];

  @override
  void initState() {
    super.initState();
    // Dropdown opens on focus (browse everything) and stays open
    // while typing (search narrows it) — not just while typing.
    _newDiseaseFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newDiseaseController.dispose();
    _newDiseaseFocusNode.dispose();
    super.dispose();
  }

  /// Wraps [child] in a Showcase when the app tour supplied a key;
  /// otherwise returns it untouched.
  Widget _showcaseSearchField(Widget child) {
    final key = widget.searchShowcaseKey;
    if (key == null) return child;
    return Showcase(
      key: key,
      title: 'Add a disease',
      description: 'Search or browse every disease not yet recorded — '
          'picking one opens a fresh form above.',
      child: child,
    );
  }

  bool _isRecorded(DataElementEntity e) {
    for (final combo in e.categoryOptionCombos) {
      final v = widget.dataValues['${e.id}_${combo.id}'];
      if (v != null && v.value.trim().isNotEmpty) return true;
    }
    return false;
  }

  void _pickDisease(DataElementEntity element) {
    setState(() {
      _pickedIds.remove(element.id);
      _pickedIds.insert(0, element.id); // newest pick goes on top
      _newDiseaseController.clear();
      _newDiseaseQuery = '';
    });
    _newDiseaseFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final e in widget.dataElements) e.id: e};

    final recordedIds = [
      for (final e in widget.dataElements)
        if (_isRecorded(e)) e.id,
    ];

    // Picked-this-session first (newest on top), then everything
    // already recorded that wasn't just re-picked.
    final visibleIds = [
      ..._pickedIds,
      for (final id in recordedIds)
        if (!_pickedIds.contains(id)) id,
    ];
    final visible = [for (final id in visibleIds) byId[id]!];

    final notRecorded = [
      for (final e in widget.dataElements)
        if (!_isRecorded(e) && !_pickedIds.contains(e.id)) e,
    ];

    final newFilter = _newDiseaseQuery.trim().toLowerCase();
    final newDropdownOpen = _newDiseaseFocusNode.hasFocus;
    final newSuggestions = newFilter.isEmpty
        ? notRecorded
        : [
            for (final e in notRecorded)
              if (e.displayName.toLowerCase().contains(newFilter)) e,
          ];

    return Column(
      children: [
        // ── Select for new disease — hidden once the period is
        // closed: there'd be nothing meaningful to type into a
        // freshly-added, still-empty disease ───────────────
        if (!widget.readOnly) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.space,
                AppDimensions.spaceSM,
                AppDimensions.space,
                AppDimensions.spaceSM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _showcaseSearchField(
                  SearchField(
                    controller: _newDiseaseController,
                    focusNode: _newDiseaseFocusNode,
                    hint: 'Select for new disease',
                    value: _newDiseaseQuery,
                    onChanged: (q) => setState(() => _newDiseaseQuery = q),
                    trailing: IconButton(
                      icon: Icon(
                        newDropdownOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: newDropdownOpen ? 'Collapse' : 'Expand',
                      onPressed: () => newDropdownOpen
                          ? _newDiseaseFocusNode.unfocus()
                          : _newDiseaseFocusNode.requestFocus(),
                    ),
                  ),
                ),
                if (newDropdownOpen)
                  Container(
                    margin: const EdgeInsets.only(top: AppDimensions.spaceXS),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.divider),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: newSuggestions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppDimensions.space),
                            child: Text(
                              notRecorded.isEmpty
                                  ? 'Every disease has already been added'
                                  : 'No matching disease',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: newSuggestions.length,
                            itemBuilder: (context, i) {
                              final e = newSuggestions[i];
                              return ListTile(
                                dense: true,
                                title: Text(e.displayName,
                                    style: AppTextStyles.bodyMedium),
                                trailing: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: AppColors.diseaseAccent),
                                onTap: () => _pickDisease(e),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
        ],

        // ── The recorded/picked diseases, Routine-style ──
        // Wrapped so leaving the search field WITHOUT picking
        // anything (tapping the list, scrolling, going back to it)
        // closes the dropdown instead of leaving it open until a
        // disease is finally picked. Unfocusing this specific node
        // (not a global FocusScope.unfocus()) can never fight the
        // search field gaining focus on its own tap, or steal focus
        // from a data entry cell below.
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _newDiseaseFocusNode.unfocus,
            child: visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceXXL),
                      child: Text(
                        widget.readOnly
                            ? 'Nothing was recorded for this closed period.'
                            : 'No diseases yet — use "Select for new '
                                'disease" above to add one.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                // Re-keyed on the top (most-recently-picked) element
                // so DataEntryTable's "first element starts expanded"
                // opens the new pick, not whatever was first before.
                : DataEntryTable(
                    key: ValueKey(visibleIds.first),
                    dataElements: visible,
                    dataValues: widget.dataValues,
                    orgUnitId: widget.orgUnitId,
                    period: widget.period,
                    showElementTotal: true,
                    showHeaderSumBadge: false,
                    readOnly: widget.readOnly,
                  ),
          ),
        ),
      ],
    );
  }
}
