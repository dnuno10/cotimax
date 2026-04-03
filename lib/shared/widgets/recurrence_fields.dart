import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

class WeekdayOption {
  const WeekdayOption({required this.value, required this.label});

  final int value;
  final String label;
}

const List<WeekdayOption> weekdayOptions = [
  WeekdayOption(value: 1, label: 'Lun'),
  WeekdayOption(value: 2, label: 'Mar'),
  WeekdayOption(value: 3, label: 'Mie'),
  WeekdayOption(value: 4, label: 'Jue'),
  WeekdayOption(value: 5, label: 'Vie'),
  WeekdayOption(value: 6, label: 'Sab'),
  WeekdayOption(value: 7, label: 'Dom'),
];

String weekdaySummary(Iterable<int> values) {
  final labels = weekdayOptions
      .where((option) => values.contains(option.value))
      .map((option) => option.label)
      .toList();
  if (labels.isEmpty) return 'Sin dias seleccionados';
  return labels.join(', ');
}

class RecurrenceConfigurationCard extends StatelessWidget {
  const RecurrenceConfigurationCard({
    required this.title,
    required this.isRecurring,
    required this.frequency,
    required this.selectedWeekdays,
    required this.onRecurringChanged,
    required this.onFrequencyChanged,
    required this.onToggleWeekday,
    this.titleIcon = FontAwesomeIcons.arrowsRotate,
    super.key,
  });

  final String title;
  final bool isRecurring;
  final RecurrenceFrequency frequency;
  final Set<int> selectedWeekdays;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<RecurrenceFrequency?> onFrequencyChanged;
  final ValueChanged<int> onToggleWeekday;
  final IconData titleIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    FaIcon(titleIcon, size: 14, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: isRecurring, onChanged: onRecurringChanged),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isRecurring
                ? 'Activa una regla para generar el movimiento de forma recurrente.'
                : 'Desactiva esta opcion si el movimiento solo ocurre una vez.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (isRecurring) ...[
            const SizedBox(height: 12),
            FormFieldWrapper(
              label: 'Frecuencia',
              child: DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: frequency,
                isExpanded: true,
                menuMaxHeight: 320,
                borderRadius: cotimaxMenuBorderRadius,
                dropdownColor: AppColors.white,
                icon: cotimaxDropdownIcon,
                style: cotimaxDropdownTextStyle,
                decoration: cotimaxDropdownDecoration(),
                items: RecurrenceFrequency.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                          style: cotimaxDropdownTextStyle,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onFrequencyChanged,
              ),
            ),
            if (frequency.supportsWeekdaySelection) ...[
              const SizedBox(height: 12),
              FormFieldWrapper(
                label: 'Dias de la semana',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: weekdayOptions
                      .map(
                        (option) => FilterChip(
                          selected: selectedWeekdays.contains(option.value),
                          label: Text(option.label),
                          onSelected: (_) => onToggleWeekday(option.value),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                weekdaySummary(selectedWeekdays),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
