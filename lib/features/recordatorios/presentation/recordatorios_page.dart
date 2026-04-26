import 'dart:math' as math;

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/clientes/application/clientes_controller.dart';
import 'package:cotimax/features/cotizaciones/application/cotizaciones_controller.dart';
import 'package:cotimax/features/recordatorios/application/recordatorios_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:cotimax/shared/widgets/finance_icon_picker.dart';
import 'package:cotimax/shared/widgets/recurrence_fields.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RecordatoriosPage extends ConsumerStatefulWidget {
  const RecordatoriosPage({super.key});

  @override
  ConsumerState<RecordatoriosPage> createState() => _RecordatoriosPageState();
}

class _RecordatoriosPageState extends ConsumerState<RecordatoriosPage> {
  bool _handledCreateRoute = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final recordatoriosAsync = ref.watch(recordatoriosControllerProvider);
    final cotizacionesCatalogo =
        ref.watch(cotizacionesControllerProvider).valueOrNull ??
        const <Cotizacion>[];
    final cotizacionesById = {
      for (final cotizacion in cotizacionesCatalogo)
        cotizacion.id: cotizacion.folio,
    };
    final shouldCreate =
        GoRouterState.of(context).uri.queryParameters['create'] == '1';

    if (!shouldCreate) {
      _handledCreateRoute = false;
    } else if (!_handledCreateRoute) {
      _handledCreateRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openReminderForm(context, initialDate: _selectedDay);
        if (mounted) {
          context.go(RoutePaths.recordatorios);
        }
      });
    }

    return ListView(
      children: [
        PageHeader(
          title: 'Recordatorios',
          subtitle: '',
          actions: [
            ElevatedButton.icon(
              onPressed: () =>
                  _openReminderForm(context, initialDate: _selectedDay),
              icon: const Icon(Icons.add_alert_rounded),
              label: Text(trText('Nuevo recordatorio')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Calendario de recordatorios',
          titleIcon: FontAwesomeIcons.calendarDays,
          child: recordatoriosAsync.when(
            loading: LoadingSkeleton.new,
            error: (_, __) => ErrorStateWidget(
              message: 'No se pudieron cargar los recordatorios.',
              onRetry: () => ref.invalidate(recordatoriosControllerProvider),
            ),
            data: (recordatorios) => _ReminderCalendarSection(
              recordatorios: recordatorios,
              cotizacionesById: cotizacionesById,
              selectedMonth: _selectedMonth,
              selectedDay: _selectedDay,
              onMonthChanged: (value) => setState(() {
                _selectedMonth = DateTime(value.year, value.month);
              }),
              onDaySelected: (value) =>
                  setState(() => _selectedDay = DateUtils.dateOnly(value)),
              onAddPressed: () =>
                  _openReminderForm(context, initialDate: _selectedDay),
              onEditPressed: (item) => _openReminderForm(
                context,
                item: item,
                initialDate: _selectedDay,
              ),
              onDeletePressed: _deleteReminder,
            ),
          ),
        ),
      ],
    );
  }

  void _openReminderForm(
    BuildContext context, {
    Recordatorio? item,
    DateTime? initialDate,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: item == null ? 'Nuevo recordatorio' : 'Editar recordatorio',
        child: _RecordatorioForm(item: item, initialDate: initialDate),
      ),
    );
  }

  Future<void> _deleteReminder(Recordatorio item) async {
    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: 'recordatorio',
      onConfirmAsync: () async {
        try {
          await ref.read(recordatoriosRepositoryProvider).delete(item.id);
          if (!mounted) return;
          ref.invalidate(recordatoriosControllerProvider);
          ToastHelper.showSuccess(context, 'Recordatorio eliminado.');
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(
              error,
              'No se pudo eliminar el recordatorio.',
            ),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }
}

class _ReminderCalendarSection extends StatelessWidget {
  const _ReminderCalendarSection({
    required this.recordatorios,
    required this.cotizacionesById,
    required this.selectedMonth,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onAddPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  final List<Recordatorio> recordatorios;
  final Map<String, String> cotizacionesById;
  final DateTime selectedMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onAddPressed;
  final ValueChanged<Recordatorio> onEditPressed;
  final ValueChanged<Recordatorio> onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month);
    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;
    final offset = monthStart.weekday - 1;
    final totalCells = (((offset + daysInMonth) / 7).ceil()) * 7;
    final counts = _reminderCountsForMonth(recordatorios, monthStart);
    final remindersOfSelectedDay = _recordatoriosForDate(
      recordatorios,
      selectedDay,
    );
    final weekdayLabels = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final selectedLabel = DateFormat(
      'EEEE d MMMM yyyy',
      currentIntlLocale(),
    ).format(selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onMonthChanged(
                DateTime(selectedMonth.year, selectedMonth.month - 1),
              ),
              icon: const Icon(Icons.chevron_left_rounded),
              splashRadius: 20,
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy', currentIntlLocale()).format(monthStart),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onMonthChanged(
                DateTime(selectedMonth.year, selectedMonth.month + 1),
              ),
              icon: const Icon(Icons.chevron_right_rounded),
              splashRadius: 20,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.08,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - offset + 1;
            final inMonth = dayNumber > 0 && dayNumber <= daysInMonth;
            final cellDate = inMonth
                ? DateTime(selectedMonth.year, selectedMonth.month, dayNumber)
                : null;
            final normalizedDate = cellDate == null
                ? null
                : _dateOnly(cellDate);
            final reminderCount = normalizedDate == null
                ? 0
                : (counts[_reminderDateKey(normalizedDate)] ?? 0);
            final isSelected =
                normalizedDate != null &&
                DateUtils.isSameDay(normalizedDate, selectedDay);
            final isToday =
                normalizedDate != null &&
                DateUtils.isSameDay(normalizedDate, DateTime.now());

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: normalizedDate == null
                  ? null
                  : () => onDaySelected(normalizedDate),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: !inMonth
                      ? AppColors.background
                      : isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : reminderCount > 0
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inMonth ? '$dayNumber' : '',
                      style: TextStyle(
                        color: !inMonth
                            ? AppColors.textMuted
                            : isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (reminderCount > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$reminderCount',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trText('Recordatorios del día'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _capitalizeFirst(selectedLabel),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: Text(trText('Agregar')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (remindersOfSelectedDay.isEmpty)
          EmptyFieldState(
            hintText: 'Sin recordatorios para este día.',
            message:
                'Selecciona otro día o crea un recordatorio para esta fecha.',
            buttonLabel: 'Nuevo recordatorio',
            onPressed: onAddPressed,
          )
        else
          Column(
            children: remindersOfSelectedDay
                .map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FinanceIconAvatar(iconKey: item.iconKey, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nombre,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (item.descripcion.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.descripcion,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  _ReminderMetaItem(
                                    icon: Icons.repeat_rounded,
                                    label: item.recurrente
                                        ? _recurrenceDescription(
                                            item.recurrencia,
                                            item.diasSemana,
                                          )
                                        : trText('Solo este día'),
                                    accent: AppColors.accent,
                                  ),
                                  if (item.clienteNombre.trim().isNotEmpty)
                                    _ReminderMetaItem(
                                      icon: Icons.person_outline_rounded,
                                      label: item.clienteNombre,
                                      accent: AppColors.primary,
                                    ),
                                  if ((cotizacionesById[item.cotizacionId] ??
                                          '')
                                      .trim()
                                      .isNotEmpty)
                                    _ReminderMetaItem(
                                      icon: Icons.receipt_long_outlined,
                                      label:
                                          cotizacionesById[item.cotizacionId]!,
                                      accent: AppColors.success,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        RowActionMenu(
                          onSelected: (action) {
                            if (action == 'edit') {
                              onEditPressed(item);
                              return;
                            }
                            if (action == 'delete') {
                              onDeletePressed(item);
                            }
                          },
                          actions: [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(trText('Editar')),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(trText('Eliminar')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _RecordatorioForm extends ConsumerStatefulWidget {
  const _RecordatorioForm({this.item, this.initialDate});

  final Recordatorio? item;
  final DateTime? initialDate;

  @override
  ConsumerState<_RecordatorioForm> createState() => _RecordatorioFormState();
}

class _RecordatorioFormState extends ConsumerState<_RecordatorioForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _fechaController;
  late final TextEditingController _fechaInicioRecurrenciaController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final FocusNode _nombreFocusNode;
  late final FocusNode _fechaFocusNode;
  late final FocusNode _descripcionFocusNode;
  late final FocusNode _clienteFocusNode;
  late final FocusNode _cotizacionFocusNode;
  String _iconKey = 'calendar_month';
  String _selectedClientId = '';
  String _selectedQuoteId = '';
  bool _recurrente = false;
  RecurrenceFrequency _recurrencia = RecurrenceFrequency.ninguna;
  final Set<int> _diasSemana = <int>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _nombreFocusNode = FocusNode();
    _fechaFocusNode = FocusNode();
    _descripcionFocusNode = FocusNode();
    _clienteFocusNode = FocusNode();
    _cotizacionFocusNode = FocusNode();
    final item = widget.item;
    final fallbackDate = widget.initialDate ?? DateTime.now();
    _fechaController = seededTextController(
      DateFormat('yyyy-MM-dd').format(item?.fecha ?? fallbackDate),
    );
    _fechaInicioRecurrenciaController = seededTextController(
      DateFormat(
        'yyyy-MM-dd',
      ).format(item?.fechaInicioRecurrencia ?? item?.fecha ?? fallbackDate),
    );
    _nombreController = seededTextController(item?.nombre ?? '');
    _descripcionController = seededTextController(item?.descripcion ?? '');
    _iconKey = item?.iconKey ?? 'calendar_month';
    _selectedClientId = item?.clienteId ?? '';
    _selectedQuoteId = item?.cotizacionId ?? '';
    _recurrente = item?.recurrente ?? false;
    _recurrencia = item?.recurrencia ?? RecurrenceFrequency.ninguna;
    _diasSemana.addAll(item?.diasSemana ?? const <int>[]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fechaController.dispose();
    _fechaInicioRecurrenciaController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _nombreFocusNode.dispose();
    _fechaFocusNode.dispose();
    _descripcionFocusNode.dispose();
    _clienteFocusNode.dispose();
    _cotizacionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientes =
        ref.watch(clientesControllerProvider).valueOrNull ?? const <Cliente>[];
    final cotizaciones =
        ref.watch(cotizacionesControllerProvider).valueOrNull ??
        const <Cotizacion>[];
    final clientOptions = [
      (value: '', label: 'Sin cliente'),
      ...clientes.map(
        (item) => (
          value: item.id,
          label: item.nombre.trim().isEmpty ? item.empresa : item.nombre,
        ),
      ),
    ];
    final filteredQuotes = _selectedClientId.trim().isEmpty
        ? cotizaciones
        : cotizaciones
              .where((item) => item.clienteId == _selectedClientId)
              .toList(growable: false);
    final quoteOptions = [
      (value: '', label: 'Sin cotización'),
      ...filteredQuotes.map((item) => (value: item.id, label: item.folio)),
    ];

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SectionCard(
                      title: 'Datos del recordatorio',
                      titleIcon: FontAwesomeIcons.bell,
                      headerBackgroundColor: AppColors.background,
                      child: Column(
                        children: [
                          FormFieldWrapper(
                            label: 'Icono del recordatorio',
                            child: Focus(
                              canRequestFocus: false,
                              skipTraversal: true,
                              child: FinanceIconPicker(
                                selectedKey: _iconKey,
                                onChanged: (value) =>
                                    setState(() => _iconKey = value),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ResponsiveReminderFormRow(
                            left: FocusTraversalOrder(
                              order: NumericFocusOrder(1),
                              child: FormFieldWrapper(
                                label: 'Nombre',
                                child: TextField(
                                  focusNode: _nombreFocusNode,
                                  controller: _nombreController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: trText('Ej. Llamar al cliente'),
                                  ),
                                ),
                              ),
                            ),
                            right: FocusTraversalOrder(
                              order: NumericFocusOrder(2),
                              child: FormFieldWrapper(
                                label: 'Fecha',
                                child: TextField(
                                  focusNode: _fechaFocusNode,
                                  controller: _fechaController,
                                  readOnly: true,
                                  onTap: _pickReminderDate,
                                  decoration: InputDecoration(
                                    hintText: trText('AAAA-MM-DD'),
                                    suffixIcon: const Icon(
                                      Icons.calendar_month_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(3),
                            child: FormFieldWrapper(
                              label: 'Descripción',
                              child: TextField(
                                focusNode: _descripcionFocusNode,
                                controller: _descripcionController,
                                textInputAction: TextInputAction.next,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: trText(
                                    'Detalle del recordatorio o tarea',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ResponsiveReminderFormRow(
                            left: FocusTraversalOrder(
                              order: NumericFocusOrder(4),
                              child: FormFieldWrapper(
                                label: 'Cliente relacionado',
                                child: DropdownButtonFormField<String>(
                                  focusNode: _clienteFocusNode,
                                  initialValue:
                                      clientOptions.any(
                                        (item) =>
                                            item.value == _selectedClientId,
                                      )
                                      ? _selectedClientId
                                      : '',
                                  isExpanded: true,
                                  menuMaxHeight: 320,
                                  borderRadius: cotimaxMenuBorderRadius,
                                  dropdownColor: AppColors.white,
                                  icon: cotimaxDropdownIcon,
                                  style: cotimaxDropdownTextStyle,
                                  decoration: cotimaxDropdownDecoration(),
                                  items: clientOptions
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item.value,
                                          child: Text(
                                            trText(item.label),
                                            overflow: TextOverflow.ellipsis,
                                            style: cotimaxDropdownTextStyle,
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClientId = value ?? '';
                                      if (_selectedClientId.trim().isNotEmpty &&
                                          _selectedQuoteId.trim().isNotEmpty) {
                                        final linkedQuote = cotizaciones.where(
                                          (item) => item.id == _selectedQuoteId,
                                        );
                                        if (linkedQuote.isNotEmpty &&
                                            linkedQuote.first.clienteId !=
                                                _selectedClientId) {
                                          _selectedQuoteId = '';
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            right: FocusTraversalOrder(
                              order: NumericFocusOrder(5),
                              child: FormFieldWrapper(
                                label: 'Cotización relacionada',
                                child: DropdownButtonFormField<String>(
                                  focusNode: _cotizacionFocusNode,
                                  initialValue:
                                      quoteOptions.any(
                                        (item) =>
                                            item.value == _selectedQuoteId,
                                      )
                                      ? _selectedQuoteId
                                      : '',
                                  isExpanded: true,
                                  menuMaxHeight: 320,
                                  borderRadius: cotimaxMenuBorderRadius,
                                  dropdownColor: AppColors.white,
                                  icon: cotimaxDropdownIcon,
                                  style: cotimaxDropdownTextStyle,
                                  decoration: cotimaxDropdownDecoration(),
                                  items: quoteOptions
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item.value,
                                          child: Text(
                                            trText(item.label),
                                            overflow: TextOverflow.ellipsis,
                                            style: cotimaxDropdownTextStyle,
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedQuoteId = value;
                                      if (value.trim().isNotEmpty) {
                                        final linkedQuote = cotizaciones.where(
                                          (item) => item.id == value,
                                        );
                                        if (linkedQuote.isNotEmpty &&
                                            linkedQuote.first.clienteId
                                                .trim()
                                                .isNotEmpty) {
                                          _selectedClientId =
                                              linkedQuote.first.clienteId;
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    RecurrenceConfigurationCard(
                      title: 'Recurrencia del recordatorio',
                      titleIcon: FontAwesomeIcons.arrowsRotate,
                      isRecurring: _recurrente,
                      frequency: _recurrencia,
                      selectedWeekdays: _diasSemana,
                      startDateController: _fechaInicioRecurrenciaController,
                      startDateLabel: 'Fecha de inicio',
                      startDateHelperText:
                          'A partir de esta fecha se calcularán las ocurrencias del recordatorio.',
                      onStartDateTap: _pickRecurrenceStartDate,
                      onRecurringChanged: (value) {
                        setState(() {
                          _recurrente = value;
                          if (!value) {
                            _recurrencia = RecurrenceFrequency.ninguna;
                            _diasSemana.clear();
                          }
                        });
                      },
                      onFrequencyChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _recurrencia = value;
                          if (!value.supportsWeekdaySelection) {
                            _diasSemana.clear();
                          }
                        });
                      },
                      onToggleWeekday: (value) {
                        setState(() {
                          if (_diasSemana.contains(value)) {
                            _diasSemana.remove(value);
                          } else {
                            _diasSemana.add(value);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(trText('Cancelar')),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.item == null
                              ? Icons.add_alert_rounded
                              : Icons.save_rounded,
                        ),
                  label: Text(
                    widget.item == null
                        ? 'Crear recordatorio'
                        : 'Guardar recordatorio',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ToastHelper.showWarning(context, 'Ingresa el nombre del recordatorio.');
      return;
    }

    final clientes =
        ref.read(clientesControllerProvider).valueOrNull ?? const <Cliente>[];
    final now = DateTime.now();
    final fecha = DateTime.tryParse(_fechaController.text.trim()) ?? now;
    final fechaInicio =
        DateTime.tryParse(_fechaInicioRecurrenciaController.text.trim()) ??
        fecha;
    final cliente = clientes.where((item) => item.id == _selectedClientId);
    final item = Recordatorio(
      id: widget.item?.id ?? '',
      nombre: nombre,
      descripcion: _descripcionController.text.trim(),
      fecha: fecha,
      fechaInicioRecurrencia: _recurrente ? fechaInicio : null,
      fechaFin: widget.item?.fechaFin,
      activo: true,
      recurrente: _recurrente,
      recurrencia: _recurrente ? _recurrencia : RecurrenceFrequency.ninguna,
      diasSemana: _recurrente
          ? (() {
              final dias = _diasSemana.toList();
              dias.sort();
              return dias;
            })()
          : const [],
      iconKey: _iconKey,
      clienteId: _selectedClientId.trim(),
      clienteNombre: cliente.isEmpty
          ? widget.item?.clienteNombre ?? ''
          : cliente.first.nombre.trim().isEmpty
          ? cliente.first.empresa
          : cliente.first.nombre,
      cotizacionId: _selectedQuoteId.trim(),
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(recordatoriosRepositoryProvider).upsert(item);
      ref.invalidate(recordatoriosControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.item == null
            ? 'Recordatorio creado correctamente.'
            : 'Recordatorio actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo guardar el recordatorio.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickReminderDate() async {
    final initialDate =
        DateTime.tryParse(_fechaController.text.trim()) ?? DateTime.now();
    final picked = await showCotimaxDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: initialDate,
      locale: currentAppLocale(),
      helpText: trText('Selecciona la fecha'),
      cancelText: trText('Cancelar'),
      confirmText: trText('Aceptar'),
    );
    if (picked == null || !mounted) return;
    assignControllerText(
      _fechaController,
      DateFormat('yyyy-MM-dd').format(picked),
    );
  }

  Future<void> _pickRecurrenceStartDate() async {
    final initialDate =
        DateTime.tryParse(_fechaInicioRecurrenciaController.text.trim()) ??
        DateTime.tryParse(_fechaController.text.trim()) ??
        DateTime.now();
    final picked = await showCotimaxDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: initialDate,
      locale: currentAppLocale(),
      helpText: trText('Selecciona la fecha'),
      cancelText: trText('Cancelar'),
      confirmText: trText('Aceptar'),
    );
    if (picked == null || !mounted) return;
    assignControllerText(
      _fechaInicioRecurrenciaController,
      DateFormat('yyyy-MM-dd').format(picked),
    );
  }
}

class _ResponsiveReminderFormRow extends StatelessWidget {
  const _ResponsiveReminderFormRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _ReminderMetaItem extends StatelessWidget {
  const _ReminderMetaItem({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _recurrenceDescription(
  RecurrenceFrequency frequency,
  List<int> diasSemana,
) {
  if (frequency.supportsWeekdaySelection) {
    return '${frequency.label} • ${weekdaySummary(diasSemana)}';
  }
  return frequency.label;
}

Map<String, int> _reminderCountsForMonth(
  List<Recordatorio> items,
  DateTime month,
) {
  final monthStart = DateTime(month.year, month.month);
  final monthEnd = DateTime(month.year, month.month + 1, 0);
  final counts = <String, int>{};
  for (
    var day = monthStart;
    !day.isAfter(monthEnd);
    day = day.add(const Duration(days: 1))
  ) {
    final normalized = _dateOnly(day);
    final total = items
        .where((item) => _recordatorioOccursOnDate(item, day))
        .length;
    if (total > 0) {
      counts[_reminderDateKey(normalized)] = total;
    }
  }
  return counts;
}

List<Recordatorio> _recordatoriosForDate(
  List<Recordatorio> items,
  DateTime date,
) {
  final normalized = _dateOnly(date);
  final rows = items
      .where((item) => _recordatorioOccursOnDate(item, normalized))
      .toList(growable: false);
  rows.sort((a, b) {
    if (a.recurrente != b.recurrente) {
      return a.recurrente ? 1 : -1;
    }
    return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
  });
  return rows;
}

bool _recordatorioOccursOnDate(Recordatorio item, DateTime date) {
  if (!item.activo) return false;
  final target = _dateOnly(date);
  final baseDate = _dateOnly(item.fecha);
  if (!item.recurrente || item.recurrencia == RecurrenceFrequency.ninguna) {
    return DateUtils.isSameDay(baseDate, target);
  }

  final start = _dateOnly(item.fechaInicioRecurrencia ?? item.fecha);
  if (target.isBefore(start)) return false;
  final end = item.fechaFin == null ? null : _dateOnly(item.fechaFin!);
  if (end != null && target.isAfter(end)) return false;

  switch (item.recurrencia) {
    case RecurrenceFrequency.ninguna:
      return DateUtils.isSameDay(baseDate, target);
    case RecurrenceFrequency.cadaDia:
      return true;
    case RecurrenceFrequency.diasDeLaSemana:
      return item.diasSemana.contains(target.weekday);
    case RecurrenceFrequency.finDeSemana:
      return target.weekday == DateTime.saturday ||
          target.weekday == DateTime.sunday;
    case RecurrenceFrequency.cadaSemana:
      return _matchesWeeklyInterval(target, start, 1);
    case RecurrenceFrequency.cadaDosSemanas:
      return _matchesWeeklyInterval(target, start, 2);
    case RecurrenceFrequency.cadaCuatroSemanas:
      return _matchesWeeklyInterval(target, start, 4);
    case RecurrenceFrequency.cadaMes:
      return _matchesMonthlyInterval(target, start, 1);
    case RecurrenceFrequency.cadaDosMeses:
      return _matchesMonthlyInterval(target, start, 2);
    case RecurrenceFrequency.cadaTresMeses:
      return _matchesMonthlyInterval(target, start, 3);
    case RecurrenceFrequency.cadaCuatroMeses:
      return _matchesMonthlyInterval(target, start, 4);
    case RecurrenceFrequency.cadaSeisMeses:
      return _matchesMonthlyInterval(target, start, 6);
    case RecurrenceFrequency.cadaAnio:
      return _matchesYearlyInterval(target, start);
  }
}

bool _matchesWeeklyInterval(DateTime target, DateTime start, int everyWeeks) {
  final difference = target.difference(start).inDays;
  return difference >= 0 &&
      target.weekday == start.weekday &&
      difference % (7 * everyWeeks) == 0;
}

bool _matchesMonthlyInterval(DateTime target, DateTime start, int everyMonths) {
  final months = (target.year - start.year) * 12 + (target.month - start.month);
  if (months < 0 || months % everyMonths != 0) return false;
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  final expectedDay = math.min(start.day, lastDay);
  return target.day == expectedDay;
}

bool _matchesYearlyInterval(DateTime target, DateTime start) {
  if (target.year < start.year) return false;
  final lastDay = DateTime(target.year, start.month + 1, 0).day;
  final expectedDay = math.min(start.day, lastDay);
  return target.month == start.month && target.day == expectedDay;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _reminderDateKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _capitalizeFirst(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
