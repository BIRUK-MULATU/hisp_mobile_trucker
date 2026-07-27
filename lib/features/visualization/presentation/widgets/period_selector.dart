import 'package:flutter/material.dart';

import '../../../../core/data/ethiopian_calendar.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../domain/entities/chart_config.dart';

/// One selectable period option: what goes to analytics + what the
/// user reads.
class PeriodOption {
  final PeriodKind kind;
  final String id;
  final String label;

  const PeriodOption({required this.kind, required this.id, required this.label});
}

/// Relative periods analytics resolves server-side (the server runs
/// the Ethiopian calendar, so "This Month" is the Ethiopian month).
const relativePeriodOptions = [
  PeriodOption(kind: PeriodKind.relative, id: 'THIS_YEAR', label: 'This Year'),
  PeriodOption(kind: PeriodKind.relative, id: 'THIS_MONTH', label: 'This Month'),
  PeriodOption(kind: PeriodKind.relative, id: 'LAST_MONTH', label: 'Last Month'),
  PeriodOption(
      kind: PeriodKind.relative, id: 'LAST_3_MONTHS', label: 'Last 3 Months'),
];

/// Fixed periods: only the current and previous Ethiopian months are
/// offered, as concrete period ids.
List<PeriodOption> fixedPeriodOptions() {
  final months =
      EthiopianCalendar.generatePeriods(periodType: 'Monthly', count: 2);
  return [
    for (var i = 0; i < months.length; i++)
      PeriodOption(
        kind: PeriodKind.fixed,
        id: months[i].id,
        label: '${i == 0 ? 'This Month' : 'Last Month'} · ${months[i].label}',
      ),
  ];
}

/// Period section of the builder: a Relative/Fixed switch above the
/// category's radio options.
class PeriodSelector extends StatefulWidget {
  final PeriodOption? selected;
  final ValueChanged<PeriodOption> onChanged;

  const PeriodSelector({super.key, this.selected, required this.onChanged});

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  late PeriodKind _kind = widget.selected?.kind ?? PeriodKind.relative;
  late final List<PeriodOption> _fixed = fixedPeriodOptions();

  @override
  Widget build(BuildContext context) {
    final options =
        _kind == PeriodKind.relative ? relativePeriodOptions : _fixed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final kind in PeriodKind.values) ...[
              ChoiceChip(
                label: Text(
                    kind == PeriodKind.relative ? 'Relative Period' : 'Fixed Period'),
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: _kind == kind ? Colors.white : AppColors.textPrimary,
                ),
                selected: _kind == kind,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.backgroundGrey,
                onSelected: (_) => setState(() => _kind = kind),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        RadioGroup<String>(
          groupValue:
              widget.selected?.kind == _kind ? widget.selected?.id : null,
          onChanged: (id) {
            final option = options.where((o) => o.id == id).firstOrNull;
            if (option != null) widget.onChanged(option);
          },
          child: Column(
            children: [
              for (final option in options)
                RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: Text(option.label, style: AppTextStyles.bodyMedium),
                  value: option.id,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
