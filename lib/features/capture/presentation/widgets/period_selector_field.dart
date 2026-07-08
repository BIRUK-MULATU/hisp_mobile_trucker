import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/data/ethiopian_period_service.dart';
import '../../../../core/data/period_access.dart';
import '../../../../core/metadata/data_set.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

class PeriodSelectorField extends StatefulWidget {
  final String? selectedPeriod;
  final String periodType;

  /// When given, periods come from EthiopianPeriodService with
  /// open/expired gating from the dataset's expiryDays — closed
  /// periods are shown but not selectable. Without it the plain
  /// calendar list is used (all selectable).
  final String? dataSetId;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const PeriodSelectorField({
    super.key,
    this.selectedPeriod,
    this.periodType = 'Monthly',
    this.dataSetId,
    required this.onChanged,
    this.validator,
  });

  @override
  State<PeriodSelectorField> createState() => _PeriodSelectorFieldState();
}

class _Choice {
  const _Choice(this.id, this.label, this.enabled, this.note);
  final String id;
  final String label;
  final bool enabled;
  final String? note;
}

class _PeriodSelectorFieldState extends State<PeriodSelectorField> {
  List<_Choice> _choices = const [];
  bool _clockTampered = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PeriodSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periodType != widget.periodType ||
        oldWidget.dataSetId != widget.dataSetId) {
      _load();
    }
  }

  Future<void> _load() async {
    final plain = EthiopianCalendar.generatePeriods(
      periodType: widget.periodType,
      count: 24,
    );
    var choices = [
      for (final p in plain) _Choice(p.id, p.label, true, null),
    ];
    var tampered = false;

    final dataSetId = widget.dataSetId;
    if (dataSetId != null && AppSession.instance.isLoggedIn) {
      try {
        final db = AppSession.instance.service.db;
        final ds = await DataSetResource(db).getById(dataSetId);
        if (ds != null) {
          tampered = AppSession.instance.clockTampered;
          final periods = await EthiopianPeriodService(db)
              .periodsFor(dataSet: ds, count: 24);
          choices = [
            for (var i = 0; i < periods.length; i++)
              _Choice(
                periods[i].id,
                periods[i].labelAmharic,
                // Tampered clock: only the newest open period stays
                // enterable — backdating claims are suspect.
                periods[i].status == PeriodStatus.open && (!tampered || i == 0),
                switch (periods[i].status) {
                  PeriodStatus.open => null,
                  PeriodStatus.expired => 'closed',
                  PeriodStatus.notYetOpen => 'not open yet',
                },
              ),
          ];
        }
      } catch (_) {
        // Metadata not synced yet — the plain list stands.
      }
    }

    if (mounted) {
      setState(() {
        _choices = choices;
        _clockTampered = tampered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label in English ───────────────────────
        Text(
          'Report Period',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: AppDimensions.spaceSM),

        // ── Dropdown with Amharic months ───────────
        DropdownButtonFormField<String>(
          key: ValueKey(widget.selectedPeriod ?? 'none'),
          initialValue: widget.selectedPeriod,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            filled: false,
            contentPadding: EdgeInsets.only(bottom: AppDimensions.spaceSM),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
          items: [
            for (final c in _choices)
              DropdownMenuItem<String>(
                value: c.id,
                enabled: c.enabled,
                child: Text(
                  c.note == null ? c.label : '${c.label}  (${c.note})',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: c.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
          onChanged: widget.onChanged,
          validator: widget.validator ??
              (value) => value == null ? 'Please select a report period' : null,
        ),

        if (_clockTampered) ...[
          const SizedBox(height: AppDimensions.spaceSM),
          Text(
            'This device\'s clock was set backwards. Only the current '
            'period is open until the app reconnects to the server.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
