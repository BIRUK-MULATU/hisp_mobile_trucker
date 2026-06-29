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
    _controller =
        TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(DataEntryCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        !_isFocused) {
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
      case 'INTEGER':
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
      case 'INTEGER':
      case 'INTEGER_POSITIVE':
      case 'INTEGER_ZERO_OR_POSITIVE':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _isFocused
            ? AppColors.primarySurface
            : AppColors.inputBackground,
        border: Border.all(
          color: _isFocused
              ? AppColors.primary
              : Colors.transparent,
          width: 1.5,
        ),
      ),
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
