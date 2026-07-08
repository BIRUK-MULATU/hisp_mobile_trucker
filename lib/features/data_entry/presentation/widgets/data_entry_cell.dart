import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';

class DataEntryCell extends StatefulWidget {
  final String dataElementId;
  final String categoryOptionComboId;
  final String initialValue;
  final String valueType;
  final ValueChanged<String> onChanged;
  final bool isReadOnly;

  const DataEntryCell({
    super.key,
    required this.dataElementId,
    required this.categoryOptionComboId,
    required this.initialValue,
    this.valueType = 'NUMBER',
    required this.onChanged,
    this.isReadOnly = false,
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
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))];
      case 'PERCENTAGE':
      case 'INTEGER_POSITIVE':
      case 'INTEGER_ZERO_OR_POSITIVE':
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return [];
    }
  }

  TextInputType get _keyboardType {
    switch (widget.valueType.toUpperCase()) {
      case 'NUMBER':
        return const TextInputType.numberWithOptions(decimal: true);
      case 'INTEGER':
      case 'PERCENTAGE':
      case 'INTEGER_POSITIVE':
      case 'INTEGER_ZERO_OR_POSITIVE':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  BoxDecoration get _cellDecoration => BoxDecoration(
        color:
            _isFocused ? AppColors.primarySurface : AppColors.inputBackground,
        border: Border.all(
          color: _isFocused ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      );

  void _setValue(String value) {
    _controller.text = value;
    setState(() {});
    widget.onChanged(value);
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
              _setValue(next);
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

  @override
  Widget build(BuildContext context) {
    switch (widget.valueType.toUpperCase()) {
      case 'BOOLEAN':
        return _buildBooleanCell();
      case 'TRUE_ONLY':
        return _buildTrueOnlyCell();
    }
    return Container(
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
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
