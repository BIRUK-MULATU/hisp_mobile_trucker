import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/value_type_validator.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/data_element_entity.dart';

class DataEntryCell extends StatefulWidget {
  final String dataElementId;
  final String categoryOptionComboId;
  final String initialValue;
  final String valueType;
  final ValueChanged<String> onChanged;
  final bool isReadOnly;

  /// DHIS2's own "greyed field" — this exact (element, combo) cell is
  /// not a valid combination and is ALWAYS disabled, regardless of
  /// [isReadOnly]/period state. Renders as a plain dimmed placeholder,
  /// never a real input of any value type.
  final bool isGreyed;

  /// Non-empty = option-set element: the cell becomes a picker and
  /// only the options' codes may be stored (server rule E7621).
  final List<OptionEntity> options;

  /// Server rejection text — marks the cell red until it is re-edited.
  /// Long-pressing the cell shows the message.
  final String? errorText;

  /// Gate checked ONLY on a tap-driven change (boolean/option/checkbox
  /// cells — free-typed text never calls this, there's no single
  /// discrete "change" to gate). Returning false leaves the cell
  /// exactly as it was: [onChanged] is never called and the displayed
  /// value doesn't move. Null skips the gate entirely, the default.
  final Future<bool> Function(String newValue)? confirmChange;

  const DataEntryCell({
    super.key,
    required this.dataElementId,
    required this.categoryOptionComboId,
    required this.initialValue,
    this.valueType = 'NUMBER',
    required this.onChanged,
    this.isReadOnly = false,
    this.isGreyed = false,
    this.options = const [],
    this.errorText,
    this.confirmChange,
  });

  @override
  State<DataEntryCell> createState() => _DataEntryCellState();
}

class _DataEntryCellState extends State<DataEntryCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(DataEntryCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !_isFocused) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<TextInputFormatter> get _inputFormatters {
    switch (widget.valueType.toUpperCase()) {
      case 'NUMBER':
        // Decimals allowed; the server validates the full format.
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))];
      case 'INTEGER':
      case 'INTEGER_NEGATIVE':
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))];
      // Decimals allowed, no sign — validateDataValue rejects <0 (and
      // >100/>1) itself, so the formatter only needs to keep out
      // non-numeric characters, not enforce the range.
      case 'PERCENTAGE':
      case 'UNIT_INTERVAL':
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
      case 'INTEGER_POSITIVE':
      case 'INTEGER_ZERO_OR_POSITIVE':
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return [];
    }
  }

  // Deliberately never `signed: true`. Many OEM keyboards (Samsung's
  // default IME confirmed) don't reliably honor it — the "-" key is
  // either missing or silently swallowed via a composing-region reset.
  // Negative entry for INTEGER/INTEGER_NEGATIVE/NUMBER instead goes
  // through the explicit ± toggle (see _canBeNegative/_toggleSign),
  // which is IME-independent.
  TextInputType get _keyboardType {
    switch (widget.valueType.toUpperCase()) {
      case 'NUMBER':
      case 'PERCENTAGE':
      case 'UNIT_INTERVAL':
        return const TextInputType.numberWithOptions(decimal: true);
      case 'INTEGER':
      case 'INTEGER_NEGATIVE':
      case 'INTEGER_POSITIVE':
      case 'INTEGER_ZERO_OR_POSITIVE':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  /// Value-type violation for the current text (null = valid). Local
  /// invalidity outranks a stale server rejection: it describes what is
  /// in the cell right now.
  String? get _localError => validateDataValue(
        widget.valueType,
        _controller.text,
        optionCodes: widget.options.isEmpty
            ? null
            : {for (final o in widget.options) o.code},
      );

  bool get _hasError => widget.errorText != null || _localError != null;

  BoxDecoration get _cellDecoration => BoxDecoration(
        color: _isFocused
            ? AppColors.primarySurface
            : _hasError
                ? AppColors.error.withValues(alpha: 0.08)
                : AppColors.inputBackground,
        border: Border.all(
          color: _hasError
              ? AppColors.error
              : _isFocused
                  ? AppColors.primary
                  : Colors.transparent,
          width: 1.5,
        ),
      );

  /// The problem must be reachable on a phone: long-press the red
  /// cell (Tooltip) — no hover needed.
  Widget _withErrorHint(Widget cell) {
    final local = _localError;
    final message = local ?? // current text problem wins
        (widget.errorText != null
            ? 'Rejected by server: ${widget.errorText}'
            : null);
    if (message == null) return cell;
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.longPress,
      child: cell,
    );
  }

  void _setValue(String value) {
    _controller.text = value;
    setState(() {});
    widget.onChanged(value);
  }

  static const _negativeCapableTypes = {'NUMBER', 'INTEGER', 'INTEGER_NEGATIVE'};

  bool get _canBeNegative =>
      _negativeCapableTypes.contains(widget.valueType.toUpperCase());

  bool get _isNegative => _controller.text.trim().startsWith('-');

  // IME-independent negative toggle — see _keyboardType for why this
  // exists instead of relying on the keyboard's own sign key. Works
  // whether the cell is empty (types just "-", ready for digits) or
  // already has a value (flips its sign in place).
  void _toggleSign() {
    if (widget.isReadOnly) return;
    final v = _controller.text;
    _setValue(v.startsWith('-') ? v.substring(1) : '-$v');
  }

  Future<void> _applyChange(String value) async {
    if (widget.confirmChange != null) {
      final ok = await widget.confirmChange!(value);
      if (!ok || !mounted) return;
    }
    _setValue(value);
  }

  // YES/NO element — free text would be rejected by the server
  // with E7619 (value_not_bool); only true/false/empty may be sent.
  // A tap cycles — → Yes → No → —. Deliberately NOT a dropdown:
  // its overlay menu outlives the bloc-driven table rebuild and
  // crashes with a framework `_dependents.isEmpty` assertion.
  Widget _buildBooleanCell() {
    final current = _controller.text.trim().toLowerCase();
    final value = (current == 'true' || current == 'false') ? current : '';
    final label = value == 'true'
        ? 'Yes'
        : value == 'false'
            ? 'No'
            : '—';
    final color = value == 'true'
        ? AppColors.success
        : value == 'false'
            ? AppColors.error
            : AppColors.textSecondary;
    return InkWell(
      onTap: widget.isReadOnly
          ? null
          : () {
              final next = value == ''
                  ? 'true'
                  : value == 'true'
                      ? 'false'
                      : '';
              _applyChange(next);
            },
      child: Container(
        height: 40,
        decoration: _cellDecoration,
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // YES-only element — server accepts just "true" or empty.
  Widget _buildTrueOnlyCell() {
    final checked = _controller.text.trim().toLowerCase() == 'true';
    return Container(
      height: 40,
      decoration: _cellDecoration,
      alignment: Alignment.center,
      child: Checkbox(
        value: checked,
        activeColor: AppColors.primary,
        onChanged: widget.isReadOnly
            ? null
            : (v) => _setValue((v ?? false) ? 'true' : ''),
      ),
    );
  }

  // Option-set element — only the set's option codes are valid
  // (E7621), so the cell is a picker. A bottom sheet, NOT a dropdown:
  // same overlay-outlives-rebuild crash as the boolean cell above.
  Widget _buildOptionCell() {
    final code = _controller.text.trim();
    OptionEntity? selected;
    for (final o in widget.options) {
      if (o.code == code) {
        selected = o;
        break;
      }
    }
    // A stored value not in the set (old data): show the raw code —
    // the red border + tooltip already explain the problem.
    final label = selected?.name ?? (code.isEmpty ? '—' : code);
    return InkWell(
      onTap: widget.isReadOnly ? null : _pickOption,
      child: Container(
        height: 40,
        decoration: _cellDecoration,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            color:
                code.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _pickOption() async {
    final current = _controller.text.trim();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSM),
          children: [
            for (final o in widget.options)
              ListTile(
                title: Text(o.name, style: AppTextStyles.bodyMedium),
                trailing: o.code == current
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, o.code),
              ),
            if (current.isNotEmpty)
              ListTile(
                leading:
                    const Icon(Icons.clear_rounded, color: AppColors.error),
                title: Text(
                  'Clear value',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(ctx, ''),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) _setValue(picked);
  }

  // Not applicable — the server rejects it (E7616 category_option_combo_
  // not_accessible-style errors) if it's ever sent, so it's never a
  // real input of any value type, just a fixed dimmed placeholder.
  Widget _buildGreyedCell() {
    return Tooltip(
      message: "This combination isn't applicable and can't be entered.",
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.divider,
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '—',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGreyed) return _buildGreyedCell();
    if (widget.options.isNotEmpty) {
      return _withErrorHint(_buildOptionCell());
    }
    switch (widget.valueType.toUpperCase()) {
      case 'BOOLEAN':
        return _withErrorHint(_buildBooleanCell());
      case 'TRUE_ONLY':
        return _withErrorHint(_buildTrueOnlyCell());
    }
    return _withErrorHint(Container(
      height: 40,
      decoration: _cellDecoration,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: widget.isReadOnly,
        keyboardType: _keyboardType,
        inputFormatters: _inputFormatters,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          prefixIcon: _canBeNegative ? _signToggleButton() : null,
          // tightFor (not a bare minWidth) — a min-only constraint lets
          // Flutter hand the prefix MORE than 28px whenever the field
          // itself needs less (e.g. empty/unfocused), which silently ate
          // the entire cell's tap area and made the field untappable.
          prefixIconConstraints: _canBeNegative
              ? const BoxConstraints.tightFor(width: 28, height: 24)
              : null,
        ),
        onChanged: (value) {
          setState(() {}); // repaint the validity border live
          widget.onChanged(value);
        },
      ),
    ));
  }

  // "-" typed via the OS keyboard still works when the IME cooperates
  // (the formatter allows it) — this button is the guaranteed fallback
  // for every device, tap-driven so it never depends on the IME.
  Widget _signToggleButton() {
    return InkWell(
      onTap: widget.isReadOnly ? null : _toggleSign,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      child: Container(
        alignment: Alignment.center,
        child: Text(
          '±',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: _isNegative ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
