import 'dart:async';

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/constants/app_spacing.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/core/utils/delete_dependencies.dart';
import 'package:cotimax/features/auth/application/auth_controller.dart';
import 'package:cotimax/features/configuracion/application/configuracion_controller.dart';
import 'package:cotimax/features/workspace/application/workspace_controller.dart';
import 'package:cotimax/features/workspace/presentation/team_invites_dialog.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

List<(String label, IconData icon, String path)> get appNavEntries => [
  (tr('Inicio', 'Home'), Icons.home_outlined, RoutePaths.dashboard),
  (tr('Clientes', 'Clients'), Icons.people_outline_rounded, RoutePaths.clientes),
  (
    tr('Proveedores', 'Suppliers'),
    Icons.local_shipping_outlined,
    RoutePaths.proveedores,
  ),
  (
    tr('Productos', 'Products'),
    Icons.inventory_2_outlined,
    RoutePaths.productos,
  ),
  (
    tr('Materiales', 'Materials'),
    Icons.category_outlined,
    RoutePaths.materiales,
  ),
  (
    tr('Cotizaciones', 'Quotes'),
    Icons.request_quote_outlined,
    RoutePaths.cotizaciones,
  ),
  (
    tr('Ingresos', 'Income'),
    Icons.trending_up_rounded,
    RoutePaths.ingresos,
  ),
  (
    tr('Gastos', 'Expenses'),
    Icons.trending_down_rounded,
    RoutePaths.gastos,
  ),
  (
    tr('Recordatorios', 'Reminders'),
    Icons.event_outlined,
    RoutePaths.recordatorios,
  ),
  (
    tr('Analítica', 'Analytics'),
    Icons.insights_outlined,
    RoutePaths.analitica,
  ),
  (
    tr('Configuración', 'Settings'),
    Icons.settings_outlined,
    RoutePaths.configuracion,
  ),
  (
    tr('Usuarios', 'Users'),
    Icons.group_outlined,
    RoutePaths.usuarios,
  ),
];

const primaryNavIndexes = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
const secondaryNavIndexes = <int>[10, 11];
const creatablePaths = <String>{
  RoutePaths.clientes,
  RoutePaths.proveedores,
  RoutePaths.productos,
  RoutePaths.materiales,
  RoutePaths.cotizaciones,
  RoutePaths.ingresos,
  RoutePaths.gastos,
  RoutePaths.recordatorios,
};

String formatMxn(num value) => formatMoney(value);

String userRoleLabel(UserRole role) {
  return switch (role) {
    UserRole.admin => tr('Administrador', 'Admin'),
    UserRole.usuario => tr('Usuario', 'User'),
  };
}

String initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) {
    final single = parts.first;
    final trimmed = single.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

const _microInteractionDuration = Duration(milliseconds: 220);
const _microInteractionCurve = Curves.easeOutCubic;
TextStyle get cotimaxDropdownTextStyle => TextStyle(
  color: AppColors.textPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w600,
);
Icon get cotimaxDropdownIcon => Icon(
  Icons.keyboard_arrow_down_rounded,
  size: 18,
  color: AppColors.textSecondary,
);
final BorderRadius cotimaxMenuBorderRadius = BorderRadius.circular(18);

InputDecoration cotimaxDropdownDecoration({
  String? hintText,
  String? helperText,
  bool isDense = false,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    hintText: hintText == null ? null : trText(hintText),
    helperText: helperText == null ? null : trText(helperText),
    isDense: isDense,
    contentPadding:
        contentPadding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

TextEditingController seededTextController([String? text]) {
  final safeText = text ?? '';
  return TextEditingController.fromValue(
    TextEditingValue(
      text: safeText,
      selection: TextSelection.collapsed(offset: safeText.length),
    ),
  );
}

void assignControllerText(TextEditingController controller, String text) {
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

void clearControllerText(TextEditingController controller) {
  assignControllerText(controller, '');
}

String buildActionErrorMessage(Object error, String fallback) {
  final localizedFallback = trText(fallback);
  final detail = _humanizeErrorDetail(error);
  if (detail.isEmpty) return localizedFallback;
  return '$localizedFallback ${tr("Motivo:", "Reason:")} $detail';
}

String _humanizeErrorDetail(Object error) {
  var raw = error.toString().trim();
  if (raw.isEmpty) return '';

  final messageMatch = RegExp(
    r'message:\s*(.*?)(?:,\s*(?:code|details|hint|statusCode):|\)$)',
    caseSensitive: false,
  ).firstMatch(raw);
  final detailsMatch = RegExp(
    r'details:\s*(.*?)(?:,\s*(?:hint|code|statusCode):|\)$)',
    caseSensitive: false,
  ).firstMatch(raw);

  final extractedMessage = messageMatch?.group(1)?.trim();
  final extractedDetails = detailsMatch?.group(1)?.trim();
  if (extractedMessage != null && extractedMessage.isNotEmpty) {
    raw = extractedMessage;
    if (extractedDetails != null &&
        extractedDetails.isNotEmpty &&
        extractedDetails.toLowerCase() != 'null' &&
        !raw.contains(extractedDetails)) {
      raw = '$raw. $extractedDetails';
    }
  }

  raw = raw
      .replaceFirst(RegExp(r'^[A-Za-z_]+Exception:\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final lower = raw.toLowerCase();
  if (lower.isEmpty || lower == 'null') return '';
  if (lower.contains('failed to fetch') ||
      lower.contains('clientexception') ||
      lower.contains('socketexception') ||
      lower.contains('network')) {
    return tr(
      'No se pudo conectar con el servidor.',
      'Could not connect to the server.',
    );
  }
  if (lower.contains('duplicate key value') ||
      lower.contains('unique constraint') ||
      lower.contains('already exists')) {
    return tr(
      'Ya existe un registro con esos datos.',
      'A record with those values already exists.',
    );
  }
  if (lower.contains('foreign key constraint')) {
    return tr(
      'Hay datos relacionados que impiden completar la operación.',
      'Related data prevents completing this action.',
    );
  }
  if (lower.contains('not-null constraint') ||
      lower.contains('null value in column')) {
    return tr(
      'Faltan campos obligatorios por completar.',
      'Required fields are missing.',
    );
  }
  if (lower.contains('invalid input syntax') ||
      lower.contains('invalid uuid') ||
      lower.contains('numeric field overflow')) {
    return tr(
      'Uno de los valores capturados tiene un formato inválido.',
      'One of the entered values has an invalid format.',
    );
  }
  if (lower.contains('row-level security') ||
      lower.contains('permission denied') ||
      lower.contains('app_require_company_access')) {
    return tr(
      'No tienes permisos para realizar esta acción.',
      'You do not have permission to perform this action.',
    );
  }
  if (lower.contains('violates check constraint')) {
    return tr(
      'Uno de los valores no cumple con las reglas requeridas.',
      'One of the values does not satisfy the required rules.',
    );
  }
  return raw;
}

int? parseSequenceNumber(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

String nextSequentialValue(
  Iterable<String?> values, {
  int startingAt = 1,
  int minWidth = 1,
}) {
  var maxValue = startingAt - 1;
  var maxWidth = minWidth;

  for (final raw in values) {
    final sanitized = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.isEmpty) continue;
    final parsed = int.tryParse(sanitized);
    if (parsed == null) continue;
    if (parsed > maxValue) {
      maxValue = parsed;
    }
    if (sanitized.length > maxWidth) {
      maxWidth = sanitized.length;
    }
  }

  final nextValue = maxValue + 1;
  return nextValue.toString().padLeft(maxWidth, '0');
}

bool sequenceValuesMatch(String left, String right) {
  final leftParsed = parseSequenceNumber(left);
  final rightParsed = parseSequenceNumber(right);
  if (leftParsed != null && rightParsed != null) {
    return leftParsed == rightParsed;
  }
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

String sanitizeNumericText(String value) => value.replaceAll(',', '').trim();

double? parseNumericText(String value) {
  return double.tryParse(sanitizeNumericText(value));
}

String formatNumericValue(
  num value, {
  int decimalDigits = 2,
  bool useGrouping = false,
}) {
  final pattern = useGrouping ? '#,##0' : '0';
  final decimals = decimalDigits > 0 ? '.${'0' * decimalDigits}' : '';
  return NumberFormat('$pattern$decimals', 'en_US').format(value);
}

class NumericTextInputFormatter extends TextInputFormatter {
  const NumericTextInputFormatter({
    this.maxDecimalDigits = 2,
    this.useGrouping = false,
    this.moneyInputBehavior = false,
  });

  final int maxDecimalDigits;
  final bool useGrouping;
  final bool moneyInputBehavior;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = sanitizeNumericText(newValue.text);

    if (sanitized.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (!_isValidNumericText(sanitized)) {
      return oldValue;
    }

    final decimalIndex = sanitized.indexOf('.');
    if (decimalIndex != -1) {
      final decimals = sanitized.length - decimalIndex - 1;
      if (decimals > maxDecimalDigits) {
        final shiftedValue = _shiftTrailingOverflowToInteger(
          oldValue: oldValue,
          newValue: newValue,
          sanitizedNewValue: sanitized,
        );
        if (shiftedValue == null) {
          return oldValue;
        }
        final formattedShifted = useGrouping
            ? _applyGroupingToNumericText(shiftedValue)
            : shiftedValue;
        return TextEditingValue(
          text: formattedShifted,
          selection: TextSelection.collapsed(offset: formattedShifted.length),
        );
      }
    }

    final normalized = _normalizeNumericText(sanitized);
    final formatted = useGrouping
        ? _applyGroupingToNumericText(normalized)
        : normalized;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  bool _isValidNumericText(String value) {
    return RegExp(r'^\d*\.?\d*$').hasMatch(value);
  }

  String? _shiftTrailingOverflowToInteger({
    required TextEditingValue oldValue,
    required TextEditingValue newValue,
    required String sanitizedNewValue,
  }) {
    if (!moneyInputBehavior || maxDecimalDigits <= 0) return null;
    if (!newValue.selection.isCollapsed ||
        newValue.selection.baseOffset != newValue.text.length) {
      return null;
    }

    final oldSanitized = sanitizeNumericText(oldValue.text);
    if (oldSanitized.isEmpty || !oldSanitized.contains('.')) return null;

    final oldParts = oldSanitized.split('.');
    if (oldParts.length != 2) return null;
    if (oldParts[1].length != maxDecimalDigits) return null;
    if (oldParts[1].replaceAll('0', '').isNotEmpty) return null;
    if (!sanitizedNewValue.startsWith(oldSanitized)) return null;

    final appendedDigits = sanitizedNewValue.substring(oldSanitized.length);
    if (appendedDigits.isEmpty || !RegExp(r'^\d+$').hasMatch(appendedDigits)) {
      return null;
    }

    final integerPart = oldParts.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final mergedInteger =
        '${integerPart == '0' ? '' : integerPart}$appendedDigits';
    final normalizedInteger = mergedInteger.isEmpty ? '0' : mergedInteger;
    return '$normalizedInteger.${'0' * maxDecimalDigits}';
  }

  String _normalizeNumericText(String value) {
    if (value == '.') return '0.';

    final hasDecimal = value.contains('.');
    final parts = value.split('.');
    var integerPart = parts.first;
    final decimalPart = hasDecimal ? parts[1] : '';

    if (integerPart.isEmpty) {
      integerPart = '0';
    } else {
      integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    }

    if (!hasDecimal) return integerPart;
    return '$integerPart.$decimalPart';
  }

  String _applyGroupingToNumericText(String value) {
    final hasDecimal = value.contains('.');
    final parts = value.split('.');
    final integerPart = parts.first;
    final parsedInteger = int.tryParse(integerPart) ?? 0;
    final groupedInteger = NumberFormat('#,##0', 'en_US').format(parsedInteger);

    if (!hasDecimal) return groupedInteger;
    return '$groupedInteger.${parts[1]}';
  }
}

bool shouldShowChartLabel(int index, int total, {int maxLabels = 5}) {
  if (total <= 1) return true;
  if (index == 0 || index == total - 1) return true;
  if (total <= maxLabels) return true;
  final step = (total / (maxLabels - 1)).ceil();
  return index % step == 0;
}

Widget rankingMedalIcon(int index, {double size = 14}) {
  if (index > 2) return SizedBox.shrink();
  final colors = [Color(0xFFD4AF37), Color(0xFFC0C0C0), Color(0xFFCD7F32)];
  return Icon(FontAwesomeIcons.medal.data, size: size, color: colors[index]);
}

class AmountBadge extends StatelessWidget {
  AmountBadge({required this.amount, required this.positive, super.key});

  final double amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: positive ? AppColors.successSoft : AppColors.errorSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatMxn(amount),
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}

/// Muse-style shell: narrow icon rail on the left, floating pill top bar and a
/// centered content column with generous whitespace.
class AppShell extends StatefulWidget {
  AppShell({
    required this.child,
    required this.location,
    required this.title,
    super.key,
  });

  final Widget child;
  final String location;
  final String title;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarExpanded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openCommandPalette() {
    showCotimaxCommandPalette(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 900;
    final horizontalPadding = mobile ? AppSpacing.md : AppSpacing.xl;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth.clamp(
          0.0,
          AppSpacing.contentMaxWidth + horizontalPadding * 2,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: columnWidth,
            height: constraints.maxHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                mobile ? AppSpacing.sm : AppSpacing.md,
                horizontalPadding,
                AppSpacing.md,
              ),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(widget.location),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _OpenCommandPaletteIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _OpenCommandPaletteIntent(),
      },
      child: Actions(
        actions: {
          _OpenCommandPaletteIntent: CallbackAction<_OpenCommandPaletteIntent>(
            onInvoke: (_) {
              _openCommandPalette();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            drawer: mobile
                ? Drawer(
                    width: 300,
                    child: SidebarNavigation(
                      activePath: widget.location,
                      collapsed: false,
                      mobile: true,
                    ),
                  )
                : null,
            bottomNavigationBar: mobile
                ? _MobileBottomNavigation(activePath: widget.location)
                : null,
            body: mobile
                ? Column(
                    children: [
                      Topbar(
                        title: widget.title,
                        activePath: widget.location,
                        onMenuTap: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        onSearchTap: _openCommandPalette,
                      ),
                      Expanded(child: content),
                    ],
                  )
                : Row(
                    children: [
                      SidebarNavigation(
                        activePath: widget.location,
                        collapsed: !_sidebarExpanded,
                        onToggleCollapsed: () => setState(
                          () => _sidebarExpanded = !_sidebarExpanded,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Topbar(
                              title: widget.title,
                              activePath: widget.location,
                              sidebarExpanded: _sidebarExpanded,
                              onMenuTap: () => setState(
                                () => _sidebarExpanded = !_sidebarExpanded,
                              ),
                              onSearchTap: _openCommandPalette,
                            ),
                            Expanded(child: content),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

String _navLabelForPath(String path) {
  for (final entry in appNavEntries) {
    if (path.startsWith(entry.$3)) return entry.$1;
  }
  return '';
}


/// Round brand orb shown at the top of the rail (Muse avatar style).
class _BrandOrb extends StatelessWidget {
  const _BrandOrb({this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        color: AppColors.container,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/img/cotimax-favicon.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class SidebarNavigation extends ConsumerWidget {
  SidebarNavigation({
    required this.activePath,
    this.collapsed = false,
    this.mobile = false,
    this.onToggleCollapsed,
    super.key,
  });

  final String activePath;
  final bool collapsed;
  final bool mobile;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = mobile ? false : collapsed;
    final usuarioActualAsync = ref.watch(usuarioActualControllerProvider);

    Future<void> logout() async {
      try {
        await ref.read(authControllerProvider.notifier).signOut();
      } catch (error) {
        if (context.mounted) {
          ToastHelper.showError(
            context,
            buildActionErrorMessage(error, 'No se pudo cerrar la sesión.'),
          );
        }
      } finally {
        ref.invalidate(workspaceStatusProvider);
        ref.invalidate(usuarioActualControllerProvider);
        ref.invalidate(empresaPerfilControllerProvider);
        if (context.mounted) {
          context.go(RoutePaths.login);
        }
      }
    }

    final usuario = usuarioActualAsync.value;
    final displayName = usuario == null
        ? trText('Cuenta')
        : (usuario.nombre.trim().isNotEmpty
              ? usuario.nombre.trim()
              : (usuario.correo.trim().isNotEmpty
                    ? usuario.correo.trim()
                    : trText('Cuenta')));
    final roleLabel = usuario == null ? '' : userRoleLabel(usuario.rol);

    Widget navItem(int index) {
      final entry = appNavEntries[index];
      return Padding(
        padding: EdgeInsets.only(bottom: compact ? 6 : 2),
        child: _NavItem(
          entry: entry,
          compact: compact,
          selected: activePath.startsWith(entry.$3),
          showCreate: creatablePaths.contains(entry.$3),
          closeAfterTap: mobile,
        ),
      );
    }

    final accountMenu = _AccountMenuButton(
      compact: compact,
      displayName: displayName,
      roleLabel: roleLabel,
      onLogout: () => unawaited(logout()),
      closeAfterTap: mobile,
    );

    return AnimatedContainer(
      duration: Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: mobile
          ? double.infinity
          : compact
          ? 84
          : 264,
      decoration: BoxDecoration(
        color: mobile ? AppColors.container : AppColors.rail,
        border: mobile
            ? null
            : Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 0 : 14,
            vertical: 18,
          ),
          child: Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.stretch,
            children: [
              if (compact)
                Tooltip(
                  message: 'Cotimax',
                  child: InkWell(
                    customBorder: CircleBorder(),
                    onTap: onToggleCollapsed,
                    child: _BrandOrb(),
                  ),
                )
              else
                Row(
                  children: [
                    _BrandOrb(size: 40),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cotimax',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!mobile)
                      IconButton(
                        tooltip: trText('Contraer menú'),
                        onPressed: onToggleCollapsed,
                        icon: Icon(CupertinoIcons.sidebar_left, size: 20),
                      ),
                  ],
                ),
              SizedBox(height: compact ? 28 : 24),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (!compact) _SidebarSectionLabel('Comercial'),
                      ...primaryNavIndexes.map(navItem),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: compact ? 22 : 8,
                        ),
                        child: Container(height: 1, color: AppColors.border),
                      ),
                      if (!compact) _SidebarSectionLabel('Administración'),
                      ...secondaryNavIndexes.map(navItem),
                      SizedBox(height: 6),
                      _QuickCreateButton(compact: compact, closeAfterTap: mobile),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              accountMenu,
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Text(
        trText(label),
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// "+" square in the rail: opens a quick-create popover (Muse new-item button).
class _QuickCreateButton extends StatelessWidget {
  const _QuickCreateButton({required this.compact, this.closeAfterTap = false});

  final bool compact;
  final bool closeAfterTap;

  @override
  Widget build(BuildContext context) {
    final entries = appNavEntries
        .where((entry) => creatablePaths.contains(entry.$3))
        .toList(growable: false);

    return PopupMenuButton<String>(
      tooltip: trText('Crear nuevo'),
      position: PopupMenuPosition.over,
      offset: Offset(compact ? 64 : 0, 0),
      onSelected: (path) {
        if (closeAfterTap) Navigator.of(context).pop();
        context.go('$path?create=1');
      },
      itemBuilder: (_) => [
        for (final entry in entries)
          PopupMenuItem<String>(
            value: entry.$3,
            height: 42,
            child: Row(
              children: [
                Icon(entry.$2, size: 19, color: AppColors.textPrimary),
                SizedBox(width: 12),
                Text(entry.$1),
              ],
            ),
          ),
      ],
      child: _RailIconSurface(
        compact: compact,
        icon: Icons.add_box_outlined,
        label: trText('Crear nuevo'),
        selected: false,
      ),
    );
  }
}

/// Bottom "≡" button: account popover with profile, settings and logout.
class _AccountMenuButton extends StatelessWidget {
  const _AccountMenuButton({
    required this.compact,
    required this.displayName,
    required this.roleLabel,
    required this.onLogout,
    this.closeAfterTap = false,
  });

  final bool compact;
  final String displayName;
  final String roleLabel;
  final VoidCallback onLogout;
  final bool closeAfterTap;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: trText('Cuenta'),
      position: PopupMenuPosition.over,
      offset: Offset(compact ? 64 : 0, -8),
      onSelected: (value) {
        if (closeAfterTap) Navigator.of(context).pop();
        switch (value) {
          case 'settings':
            context.go(RoutePaths.configuracion);
          case 'users':
            context.go(RoutePaths.usuarios);
          case 'logout':
            onLogout();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 64,
          child: Row(
            children: [
              _InitialsAvatar(name: displayName, size: 38),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (roleLabel.isNotEmpty)
                      Text(
                        roleLabel,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: 'settings',
          height: 42,
          child: _MenuRow(
            icon: Icons.settings_outlined,
            label: trText('Configuración'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'users',
          height: 42,
          child: _MenuRow(
            icon: Icons.group_outlined,
            label: trText('Usuarios'),
          ),
        ),
        PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: 'logout',
          height: 42,
          child: _MenuRow(
            icon: Icons.logout_rounded,
            label: trText('Cerrar sesión'),
          ),
        ),
      ],
      child: compact
          ? _RailIconSurface(
              compact: true,
              icon: Icons.menu_rounded,
              label: displayName,
              selected: false,
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _InitialsAvatar(name: displayName, size: 34),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        if (roleLabel.isNotEmpty)
                          Text(
                            roleLabel,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textPrimary),
        SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, this.size = 36});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.muted, shape: BoxShape.circle),
      child: Text(
        initialsFromName(name),
        style: TextStyle(
          fontSize: size * 0.34,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Shared visual for rail items: 48px circle, muted when selected/hovered.
class _RailIconSurface extends StatefulWidget {
  const _RailIconSurface({
    required this.compact,
    required this.icon,
    required this.label,
    required this.selected,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final bool selected;

  @override
  State<_RailIconSurface> createState() => _RailIconSurfaceState();
}

class _RailIconSurfaceState extends State<_RailIconSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? AppColors.muted
        : _hovered
        ? AppColors.hover
        : AppColors.hover.withValues(alpha: 0);
    final surface = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: _microInteractionDuration,
        curve: _microInteractionCurve,
        width: widget.compact ? 50 : double.infinity,
        height: widget.compact ? 50 : 44,
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(widget.compact ? 999 : 14),
        ),
        child: widget.compact
            ? Icon(widget.icon, size: 23, color: AppColors.textPrimary)
            : Row(
                children: [
                  Icon(widget.icon, size: 21, color: AppColors.textPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
    return widget.compact ? Center(child: surface) : surface;
  }
}

/// Floating white pill used in the top bar (Muse "☰ Chats" / "Invite").
class _TopbarPill extends StatefulWidget {
  const _TopbarPill({
    required this.child,
    this.onTap,
    this.circular = false,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool circular;
  final String? tooltip;

  @override
  State<_TopbarPill> createState() => _TopbarPillState();
}

class _TopbarPillState extends State<_TopbarPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Widget pill = MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _microInteractionDuration,
          curve: _microInteractionCurve,
          height: 44,
          width: widget.circular ? 44 : null,
          padding: widget.circular
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.hover : AppColors.container,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: AppColors.softShadow,
          ),
          child: widget.child,
        ),
      ),
    );
    if (widget.tooltip != null) {
      pill = Tooltip(message: widget.tooltip!, child: pill);
    }
    return pill;
  }
}

class Topbar extends ConsumerWidget {
  Topbar({
    required this.title,
    this.activePath = '',
    this.sidebarExpanded = false,
    this.onMenuTap,
    this.onSearchTap,
    super.key,
  });

  final String title;
  final String activePath;
  final bool sidebarExpanded;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1180;
    final mobile = width < 900;
    final pendingInvitesCount =
        ref.watch(pendingTeamInvitesCountProvider).value ?? 0;
    final sectionLabel = _navLabelForPath(activePath).isNotEmpty
        ? _navLabelForPath(activePath)
        : title;

    return Container(
      height: mobile ? 68 : 76,
      color: AppColors.background,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 24),
      child: Row(
        children: [
          _TopbarPill(
            onTap: onMenuTap,
            tooltip: mobile
                ? null
                : (sidebarExpanded
                      ? trText('Contraer menú')
                      : trText('Expandir menú')),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: mobile ? 150 : 260),
                  child: Text(
                    sectionLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          if (!compact)
            _TopbarPill(
              onTap: onSearchTap,
              child: SizedBox(
                width: 300,
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trText('Buscar'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    _CommandPaletteShortcutHint(),
                  ],
                ),
              ),
            )
          else
            _TopbarPill(
              circular: true,
              onTap: onSearchTap,
              tooltip: trText('Buscar'),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          SizedBox(width: 10),
          _TopbarPill(
            onTap: () {
              ref.invalidate(pendingTeamInvitesProvider);
              showDialog(context: context, builder: (_) => TeamInvitesDialog());
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 21,
                      color: AppColors.textPrimary,
                    ),
                    if (pendingInvitesCount > 0)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.container,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!mobile) ...[
                  SizedBox(width: 8),
                  Text(
                    pendingInvitesCount > 0
                        ? '${trText('Invitaciones')} · ${pendingInvitesCount > 99 ? '99+' : pendingInvitesCount}'
                        : trText('Invitaciones'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandPaletteShortcutHint extends StatelessWidget {
  _CommandPaletteShortcutHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '⌘K',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class BreadCrumbs extends StatelessWidget {
  BreadCrumbs({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (var i = 0; i < items.length; i++)
          Text(
            i == items.length - 1 ? trText(items[i]) : '${trText(items[i])}  ›',
            style: TextStyle(
              color: i == items.length - 1
                  ? AppColors.textSecondary
                  : AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

/// Muse page header: big bold title, calm gray subtitle, pill actions.
class PageHeader extends StatelessWidget {
  PageHeader({
    required this.title,
    required this.subtitle,
    this.actions,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 900;
    final titleText = Text(
      trText(title),
      style: TextStyle(
        fontSize: mobile ? 30 : 40,
        fontWeight: FontWeight.w700,
        letterSpacing: mobile ? -0.6 : -0.9,
        height: 1.05,
        color: AppColors.textPrimary,
      ),
    );
    final subtitleText = subtitle.trim().isEmpty
        ? null
        : Text(
            trText(subtitle),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              fontSize: mobile ? 15 : 17,
              height: 1.4,
            ),
          );

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText,
        if (subtitleText != null) ...[SizedBox(height: 10), subtitleText],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: mobile ? 4 : 8, bottom: 12),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                if (actions != null) ...[
                  SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: actions!),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: heading),
                if (actions != null) ...[
                  SizedBox(width: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: actions!),
                ],
              ],
            ),
    );
  }
}

List<Widget> buildImportExportHeaderActions(
  BuildContext context, {
  required String entityLabel,
}) {
  final translatedEntityLabel = trText(entityLabel);
  return [
    OutlinedButton.icon(
      onPressed: () => ToastHelper.show(
        context,
        tr(
          'Importar $entityLabel disponible pronto.',
          'Import for $translatedEntityLabel coming soon.',
        ),
      ),
      icon: Icon(Icons.file_upload_outlined),
      label: Text(trText('Importar')),
    ),
    OutlinedButton.icon(
      onPressed: () => ToastHelper.show(
        context,
        tr(
          'Exportar $entityLabel disponible pronto.',
          'Export for $translatedEntityLabel coming soon.',
        ),
      ),
      icon: Icon(Icons.file_download_outlined),
      label: Text(trText('Exportar')),
    ),
  ];
}

class KpiStatCard extends StatelessWidget {
  KpiStatCard({
    required this.label,
    required this.value,
    required this.delta,
    super.key,
  });

  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    final positive = delta.startsWith('+');
    final color = positive ? AppColors.success : AppColors.error;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: positive ? AppColors.successSoft : AppColors.errorSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  positive
                      ? Icons.arrow_outward_rounded
                      : Icons.south_east_rounded,
                  size: 13,
                  color: color,
                ),
                SizedBox(width: 4),
                Text(
                  delta,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? resolveContainerHelpText(String title) {
  final normalized = title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  const helpByTitle = <String, String>{
    'configuración general':
        'Aquí defines la base visual de la cotización: plantilla, formato de página, tipografías, paleta de color y reglas de presentación.',
    'cliente':
        'Controla qué datos visibles del cliente se muestran en el documento final para mantener claridad y contexto comercial.',
    'diseño de cotización':
        'Agrupa los ajustes de identidad visual y estructura del PDF para que la cotización mantenga consistencia en todos los folios.',
    'apariencia':
        'Configura el tema visual general de la plataforma, incluyendo estilo, contraste y comportamiento de la interfaz.',
    'zona peligrosa':
        'Incluye acciones sensibles o irreversibles; revisa cuidadosamente antes de confirmar cualquier cambio en esta sección.',
    'detalles de empresa':
        'Concentra la información fiscal, legal y de contacto que se reutiliza en documentos comerciales y configuraciones globales.',
    'valores por defecto de cotización':
        'Define los valores iniciales con los que se crean nuevas cotizaciones para ahorrar captura repetitiva y estandarizar salidas.',
    'localización':
        'Ajusta idioma, zona horaria, formato de fecha y moneda para que los datos se muestren con el estándar de tu operación.',
    'impuestos':
        'Administra tasas y comportamiento fiscal que se aplican en cálculos y totales de documentos comerciales.',
    'resumen de cuenta':
        'Muestra la información principal de la cuenta y el estado operativo de la empresa.',
    'actividad actual':
        'Resume el volumen actual de clientes, productos, materiales y cotizaciones sin límites de uso.',
    'indicadores clave':
        'Resume señales de salud financiera y operativa en métricas de lectura rápida para seguimiento ejecutivo.',
    'impacto de gastos vinculados':
        'Relaciona gastos con ingresos asociados para medir cobertura, retorno y efecto real sobre la rentabilidad.',
    'escenarios y lectura':
        'Compara escenarios conservador, base y expansivo para evaluar sensibilidad y tomar decisiones con contexto de riesgo.',
    'pulso semanal':
        'Visualiza comportamiento reciente semana a semana para detectar cambios de tendencia en etapas tempranas.',
    'cierre mensual':
        'Consolida resultados del periodo mensual para evaluar desempeño, desviaciones y cumplimiento de objetivos.',
    'proyeccion operativa':
        'Estimación de ingresos, gastos y resultado neto en el horizonte seleccionado con base en comportamiento histórico.',
    'tabla de resultados':
        'Desglose tabular de métricas y variaciones para análisis puntual, validación y comparación entre periodos.',
    'ingresos totales':
        'Presenta el acumulado de ingresos del periodo seleccionado y su evolución para evaluar crecimiento comercial.',
    'gastos totales':
        'Presenta el acumulado de egresos del periodo seleccionado para controlar consumo y disciplina presupuestal.',
    'acciones rápidas':
        'Atajos para ejecutar tareas frecuentes sin cambiar de pantalla y acelerar la operación diaria.',
    'acciones rapidas':
        'Atajos para ejecutar tareas frecuentes sin cambiar de pantalla y acelerar la operación diaria.',
    'cotizaciones prioritarias':
        'Lista oportunidades que requieren atención inmediata por monto, antigüedad o estado comercial.',
    'top productos por utilidad':
        'Ranking de productos que más contribuyen a la utilidad para orientar estrategia comercial y de margen.',
    'rentabilidad por cliente':
        'Compara utilidad por cliente para identificar cuentas más valiosas y oportunidades de mejora.',
    'concentracion de ingresos':
        'Mide dependencia de pocos clientes o líneas de negocio para gestionar riesgo de concentración.',
    'ultimos ingresos':
        'Registro reciente de ingresos para verificar captura, origen y comportamiento inmediato del flujo.',
    'ultimos gastos':
        'Registro reciente de gastos para revisar salidas de efectivo y detectar variaciones atípicas.',
    'cotizaciones aprobadas con utilidad':
        'Monitorea cotizaciones confirmadas con margen positivo para evaluar calidad del cierre comercial.',
    'previsualizacion pdf':
        'Muestra una vista previa del documento para validar diseño, estructura y legibilidad antes de compartir.',
    'clientes':
        'Gestiona el catálogo de clientes con su información comercial para cotizar y analizar desempeño por cuenta.',
    'proveedores':
        'Administra proveedores y condiciones para mejorar compras, costos y abastecimiento.',
    'productos':
        'Organiza productos, precios y atributos que se usan en cotizaciones y análisis de rentabilidad.',
    'materiales':
        'Controla materiales, costos y unidades para estimaciones y cálculo preciso de propuestas.',
    'cotizaciones':
        'Da seguimiento al ciclo comercial de cada propuesta desde creación hasta aprobación o cierre.',
    'ingresos':
        'Registra entradas de dinero y su clasificación para medir salud financiera y flujo de caja.',
    'gastos':
        'Registra salidas de dinero, categorías y recurrencia para mantener control del costo operativo.',
    'analítica':
        'Consolida métricas históricas y proyecciones para decisiones basadas en datos.',
  };
  return helpByTitle[normalized];
}

class ContainerHelpTooltip extends StatelessWidget {
  const ContainerHelpTooltip({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: trText(message),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.muted,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.question_mark_rounded,
          size: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Muse / call-card surface: white, large radius, hairline border and a soft
/// diffuse shadow. Titled cards get a header row separated by a hairline.
class SectionCard extends StatelessWidget {
  SectionCard({
    required this.child,
    this.title,
    this.titleIcon,
    this.trailing,
    this.headerBackgroundColor,
    super.key,
  });

  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final Widget? trailing;
  final Color? headerBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final helpText = title == null ? null : resolveContainerHelpText(title!);
    final hasHeaderDivider = title != null && headerBackgroundColor != null;

    Widget header() => Row(
      children: [
        if (titleIcon != null) ...[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Icon(titleIcon, size: 15, color: AppColors.textPrimary),
          ),
          SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            trText(title!),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) ...[
          trailing!,
          if (helpText != null) SizedBox(width: 8),
        ],
        if (helpText != null) ContainerHelpTooltip(message: helpText),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.container,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: hasHeaderDivider
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: header(),
                  ),
                  Container(height: 1, color: AppColors.border),
                  Padding(padding: EdgeInsets.all(20), child: child),
                ],
              )
            : Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[header(), SizedBox(height: 16)],
                    child,
                  ],
                ),
              ),
      ),
    );
  }
}

/// Soft inner panel (call-card transcript / player area).
class MusePanel extends StatelessWidget {
  const MusePanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tone = MusePanelTone.neutral,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final MusePanelTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, borderColor) = switch (tone) {
      MusePanelTone.neutral => (AppColors.muted, AppColors.border),
      MusePanelTone.success => (
        AppColors.successSoft,
        AppColors.success.withValues(alpha: 0.18),
      ),
      MusePanelTone.error => (
        AppColors.errorSoft,
        AppColors.error.withValues(alpha: 0.18),
      ),
    };
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

enum MusePanelTone { neutral, success, error }

/// Pill-shaped tab (Muse settings list / segmented selection).
class CotimaxTabPill extends StatelessWidget {
  const CotimaxTabPill({
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: _microInteractionDuration,
          curve: _microInteractionCurve,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.container : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.border : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                SizedBox(width: 8),
              ],
              Text(
                trText(label),
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muted track that hosts [CotimaxTabPill]s (Muse "Available / Connected").
class CotimaxTabTrack extends StatelessWidget {
  const CotimaxTabTrack({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}



class SearchField extends StatelessWidget {
  SearchField({
    required this.hint,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide.none,
    );
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      showCursor: !readOnly,
      style: TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 16, right: 8),
          child: Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
        hintText: trText(hint),
        prefixIconConstraints: BoxConstraints(minWidth: 44),
        suffixIcon: suffix == null
            ? null
            : Padding(padding: EdgeInsets.only(right: 12), child: suffix),
        suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: pill,
        enabledBorder: pill,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.4,
          ),
        ),
      ),
    );

    if (!readOnly) return field;

    return MouseRegion(cursor: SystemMouseCursors.click, child: field);
  }
}

class FilterBar extends StatelessWidget {
  FilterBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class InlineEmptyMessage extends StatelessWidget {
  InlineEmptyMessage({this.message = 'No hay datos que mostrar.', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Text(
          trText(message),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class EmptyFieldState extends StatelessWidget {
  EmptyFieldState({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    this.hintText = 'No hay datos.',
    super.key,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          enabled: false,
          decoration: InputDecoration(
            hintText: trText(hintText),
            helperText: trText(message),
          ),
        ),
        SizedBox(height: 8),
        TextButton.icon(
          onPressed: onPressed,
          icon: Icon(Icons.add_rounded, size: 16),
          label: Text(trText(buttonLabel)),
        ),
      ],
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  EmptyStateWidget({
    required this.title,
    required this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 56, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MuseEmptyIcon(icon: Icons.inbox_outlined),
                SizedBox(height: 20),
                Text(
                  trText(title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  trText(subtitle),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
                if (action != null) ...[SizedBox(height: 20), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MuseEmptyIcon extends StatelessWidget {
  const _MuseEmptyIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.container,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Icon(icon, size: 32, color: color ?? AppColors.textSecondary),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  ErrorStateWidget({
    required this.message,
    required this.onRetry,
    this.details,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MuseEmptyIcon(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.error,
                ),
                SizedBox(height: 20),
                Text(
                  trText('Ocurrio un error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  trText(message),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
                if (details != null && details!.trim().isNotEmpty) ...[
                  SizedBox(height: 16),
                  MusePanel(
                    padding: EdgeInsets.all(14),
                    child: SelectableText(
                      details!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh_rounded, size: 18),
                  label: Text(trText('Reintentar')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingStateWidget extends StatelessWidget {
  LoadingStateWidget({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 160),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.textSecondary,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: 14),
              Text(
                trText(message!),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SkeletonBox(
                  width: compact ? constraints.maxWidth : 300,
                  height: 52,
                  radius: 16,
                ),
                SkeletonBox(
                  width: compact ? constraints.maxWidth : 190,
                  height: 52,
                  radius: 16,
                ),
                SkeletonBox(
                  width: compact ? constraints.maxWidth : 190,
                  height: 52,
                  radius: 16,
                ),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBox(height: 56, radius: 20),
            SizedBox(height: 12),
            for (var index = 0; index < 5; index++) ...[
              SkeletonBox(height: index == 0 ? 72 : 58, radius: 18),
              SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class SkeletonBox extends StatefulWidget {
  SkeletonBox({this.width, required this.height, this.radius = 14, super.key});

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 920),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(
      begin: 0.46,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class ConfirmDialog extends StatefulWidget {
  ConfirmDialog({
    required this.title,
    required this.message,
    this.onConfirmAsync,
    this.dependencyEntityType,
    this.dependencyIds = const <String>[],
    super.key,
  });

  final String title;
  final String message;
  final Future<void> Function()? onConfirmAsync;
  final String? dependencyEntityType;
  final List<String> dependencyIds;

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  bool _isSubmitting = false;
  bool _isLoadingDependencies = false;
  String _dependencyMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    final entityType = widget.dependencyEntityType?.trim();
    if (entityType == null ||
        entityType.isEmpty ||
        widget.dependencyIds.isEmpty) {
      return;
    }

    setState(() => _isLoadingDependencies = true);
    try {
      final dependencies = await fetchDeleteDependencies(
        entityType: entityType,
        ids: widget.dependencyIds,
      );
      if (!mounted) return;
      setState(() {
        _dependencyMessage = buildDeleteDependencyMessage(dependencies);
        _isLoadingDependencies = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDependencies = false);
    }
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;
    if (widget.onConfirmAsync == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirmAsync!.call();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDependencyMessage = _dependencyMessage.trim().isNotEmpty;

    return AlertDialog(
      title: Text(trText(widget.title)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trText(widget.message)),
          if (_isLoadingDependencies || hasDependencyMessage) ...[
            SizedBox(height: 12),
            MusePanel(
              padding: EdgeInsets.all(14),
              child: _isLoadingDependencies
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            trText('Revisando relaciones antes de eliminar...'),
                          ),
                        ),
                      ],
                    )
                  : Text(_dependencyMessage),
            ),
          ],
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(trText('Cancelar')),
        ),
        ElevatedButton(
          onPressed: _isLoadingDependencies ? null : _handleConfirm,
          child: _isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(trText('Confirmar')),
        ),
      ],
    );
  }
}

Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String entityLabel,
  String? title,
  String? message,
  Future<void> Function()? onConfirmAsync,
  String? dependencyEntityType,
  List<String> dependencyIds = const <String>[],
}) async {
  final translatedEntityLabel = trText(entityLabel);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title:
          title ?? tr('Eliminar $entityLabel', 'Delete $translatedEntityLabel'),
      message:
          message ??
          tr(
            '¿Estás seguro que quieres eliminar este $entityLabel?',
            'Are you sure you want to delete this $translatedEntityLabel?',
          ),
      onConfirmAsync: onConfirmAsync,
      dependencyEntityType: dependencyEntityType,
      dependencyIds: dependencyIds,
    ),
  );
  return confirmed ?? false;
}

class ModalBase extends StatelessWidget {
  ModalBase({
    required this.title,
    required this.child,
    this.showCloseButton = true,
    super.key,
  });

  final String title;
  final Widget child;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.94;
    final minHeight = size.height < 760
        ? size.height * 0.86
        : size.height * 0.82;
    final maxWidth = size.width * 0.94;
    final minWidth = size.width < 1200 ? size.width * 0.9 : size.width * 0.84;
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      backgroundColor: AppColors.container,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.dialogRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth.clamp(340.0, 1240.0).toDouble(),
          maxWidth: maxWidth.clamp(980.0, 1480.0).toDouble(),
          minHeight: minHeight.clamp(420.0, 980.0).toDouble(),
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(28, 22, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      trText(title),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (showCloseButton)
                    _HoverCircleButton(
                      onTap: () => Navigator.of(context).pop(),
                      icon: Icons.close_rounded,
                      size: 38,
                      iconSize: 19,
                      baseColor: AppColors.muted,
                      hoverColor: AppColors.hover,
                      baseIconColor: AppColors.textPrimary,
                      hoverIconColor: AppColors.textPrimary,
                    ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, 20, 28, 24),
                child: FocusTraversalGroup(
                  policy: WidgetOrderTraversalPolicy(),
                  child: SizedBox.expand(child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SideDrawerForm extends StatelessWidget {
  SideDrawerForm({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 560,
      child: SafeArea(
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: SectionCard(title: trText(title), child: child),
        ),
      ),
    );
  }
}

class FormFieldWrapper extends StatelessWidget {
  FormFieldWrapper({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trText(label),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 6),
        child,
      ],
    );
  }
}

class CurrencyInput extends StatelessWidget {
  CurrencyInput({
    required this.controller,
    this.label = 'Monto',
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        inputFormatters: const [
          NumericTextInputFormatter(
            useGrouping: true,
            maxDecimalDigits: 2,
            moneyInputBehavior: true,
          ),
        ],
        decoration: InputDecoration(
          hintText: '0.00',
          suffixText: currentCurrencyCode(),
        ),
      ),
    );
  }
}

class DatePickerField extends StatelessWidget {
  DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(),
          child: Text(
            DateFormat('dd/MM/yyyy', currentIntlLocale()).format(value),
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> showCotimaxDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  Locale? locale,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) {
  final baseTheme = Theme.of(context);
  final scheme = baseTheme.colorScheme;

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    currentDate: currentDate,
    locale: locale,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    builder: (context, child) {
      final themed = baseTheme.copyWith(
        datePickerTheme: baseTheme.datePickerTheme.copyWith(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.65)),
          ),
          headerBackgroundColor: scheme.primary.withValues(alpha: 0.10),
          headerForegroundColor: scheme.onSurface,
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return scheme.onSurface;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return null;
          }),
          todayBorder: BorderSide(color: scheme.primary, width: 1.4),
          todayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return scheme.primary;
          }),
          yearForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return scheme.onSurface;
          }),
          yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return null;
          }),
        ),
      );

      return Theme(data: themed, child: child ?? const SizedBox.shrink());
    },
  );
}

class SelectField<T> extends StatelessWidget {
  SelectField({
    required this.label,
    required this.value,
    required this.options,
    this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<T> options;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 320,
        borderRadius: cotimaxMenuBorderRadius,
        dropdownColor: AppColors.white,
        icon: cotimaxDropdownIcon,
        style: cotimaxDropdownTextStyle,
        decoration: cotimaxDropdownDecoration(),
        items: options
            .map(
              (option) => DropdownMenuItem<T>(
                value: option,
                child: Text(
                  trText(option.toString().split('.').last),
                  overflow: TextOverflow.ellipsis,
                  style: cotimaxDropdownTextStyle,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class MultiSelectField extends StatelessWidget {
  MultiSelectField({
    required this.label,
    required this.options,
    required this.selected,
    super.key,
  });

  final String label;
  final List<String> options;
  final List<String> selected;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: options
            .map(
              (option) => FilterChip(
                selected: selected.contains(option),
                label: Text(trText(option)),
                onSelected: (_) {},
              ),
            )
            .toList(),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  StatusBadge({required this.status, super.key});

  final QuoteStatus status;

  @override
  Widget build(BuildContext context) {
    final map = {
      QuoteStatus.borrador: (AppColors.textSecondary, 'Borrador'),
      QuoteStatus.enviada: (AppColors.primary, 'Enviada'),
      QuoteStatus.aprobada: (AppColors.success, 'Aprobada'),
      QuoteStatus.pagada: (AppColors.success, 'Pagada'),
      QuoteStatus.rechazada: (AppColors.error, 'Rechazada'),
    };
    final style = map[status]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status == QuoteStatus.borrador
            ? AppColors.muted
            : style.$1.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: style.$1, shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          Text(
            trText(style.$2),
            style: TextStyle(
              color: style.$1,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class PdfPreviewCard extends StatelessWidget {
  PdfPreviewCard({required this.folio, super.key});

  final String folio;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Previsualizacion PDF',
      child: SizedBox(
        height: 230,
        child: MusePanel(
          child: Center(
            child: Text(
              'Documento $folio',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  ChartCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: SizedBox(height: 250, child: child),
    );
  }
}

class RowActionMenu extends StatelessWidget {
  RowActionMenu({required this.actions, this.onSelected, super.key});

  final List<PopupMenuEntry<String>> actions;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (_) => actions,
      onSelected: onSelected,
      tooltip: 'Más acciones',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: Offset(0, 6),
      child: _HoverCircleButton(
        onTap: null,
        icon: Icons.more_horiz_rounded,
        size: 34,
        iconSize: 20,
        baseColor: Colors.transparent,
        hoverColor: AppColors.hover,
        baseIconColor: AppColors.textSecondary,
        hoverIconColor: AppColors.textPrimary,
      ),
    );
  }
}

class PaginationWidget extends StatelessWidget {
  PaginationWidget({
    required this.page,
    required this.totalPages,
    required this.onChanged,
    super.key,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: page <= 1 ? null : () => onChanged(1),
          icon: Icon(Icons.first_page_rounded, size: 20),
        ),
        IconButton(
          onPressed: page <= 1 ? null : () => onChanged(page - 1),
          icon: Icon(Icons.chevron_left_rounded, size: 20),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${trText('Página')} $page / $totalPages',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: page >= totalPages ? null : () => onChanged(page + 1),
          icon: Icon(Icons.chevron_right_rounded, size: 20),
        ),
        IconButton(
          onPressed: page >= totalPages ? null : () => onChanged(totalPages),
          icon: Icon(Icons.last_page_rounded, size: 20),
        ),
      ],
    );
  }
}

class CotimaxDataTable extends StatelessWidget {
  CotimaxDataTable({
    required this.columns,
    required this.rows,
    this.title,
    this.trailing,
    this.toolbar,
    this.emptyTitle = 'Sin registros para mostrar.',
    this.emptySubtitle = 'Ajusta el rango o agrega datos para ver actividad.',
    super.key,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String? title;
  final Widget? trailing;
  final Widget? toolbar;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (toolbar != null) ...[toolbar!, SizedBox(height: 12)],
          if (rows.isEmpty)
            _InlineEmptyTableState(title: emptyTitle, subtitle: emptySubtitle)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = columns.isEmpty ? 1 : columns.length;
                const horizontalMargin = 10.0;
                const columnSpacing = 14.0;
                final availableWidth =
                    constraints.maxWidth - (horizontalMargin * 2);
                final baseCellWidth =
                    ((availableWidth - (columnSpacing * (columnCount - 1))) /
                            columnCount)
                        .clamp(84.0, 180.0)
                        .toDouble();
                final normalizedRows = rows
                    .map(
                      (row) => _normalizeDataRow(
                        row,
                        columnCount: columnCount,
                        baseCellWidth: baseCellWidth,
                      ),
                    )
                    .toList(growable: false);

                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        headingRowHeight: 44,
                        columns: columns,
                        rows: normalizedRows,
                        horizontalMargin: horizontalMargin,
                        columnSpacing: columnSpacing,
                        dividerThickness: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

DataRow _normalizeDataRow(
  DataRow row, {
  required int columnCount,
  required double baseCellWidth,
}) {
  return DataRow(
    key: row.key,
    selected: row.selected,
    onSelectChanged: row.onSelectChanged,
    onLongPress: row.onLongPress,
    color: row.color,
    mouseCursor: row.mouseCursor,
    cells: row.cells
        .asMap()
        .entries
        .map(
          (entry) => _normalizeDataCell(
            entry.value,
            columnIndex: entry.key,
            columnCount: columnCount,
            baseCellWidth: baseCellWidth,
          ),
        )
        .toList(growable: false),
  );
}

DataCell _normalizeDataCell(
  DataCell cell, {
  required int columnIndex,
  required int columnCount,
  required double baseCellWidth,
}) {
  final isLastColumn = columnIndex == columnCount - 1;
  final child = isLastColumn
      ? SizedBox(
          width: 44,
          child: Align(alignment: Alignment.centerLeft, child: cell.child),
        )
      : _normalizeDataCellChild(cell.child, maxWidth: baseCellWidth);

  return DataCell(
    child,
    placeholder: cell.placeholder,
    showEditIcon: cell.showEditIcon,
    onTap: cell.onTap,
    onDoubleTap: cell.onDoubleTap,
    onLongPress: cell.onLongPress,
    onTapCancel: cell.onTapCancel,
    onTapDown: cell.onTapDown,
  );
}

Widget _normalizeDataCellChild(Widget child, {required double maxWidth}) {
  if (child is Checkbox) {
    return SizedBox(width: 40, child: child);
  }

  if (child is Text) {
    return SizedBox(
      width: maxWidth,
      child: Text(
        child.data ?? '',
        key: child.key,
        style: child.style,
        strutStyle: child.strutStyle,
        textAlign: child.textAlign,
        textDirection: child.textDirection,
        locale: child.locale,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textScaler: child.textScaler,
        maxLines: 1,
        semanticsLabel: child.semanticsLabel,
        textWidthBasis: child.textWidthBasis,
        textHeightBehavior: child.textHeightBehavior,
        selectionColor: child.selectionColor,
      ),
    );
  }

  if (child is Row) {
    return SizedBox(
      width: maxWidth,
      child: Row(
        key: child.key,
        mainAxisAlignment: child.mainAxisAlignment,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: child.crossAxisAlignment,
        textDirection: child.textDirection,
        verticalDirection: child.verticalDirection,
        textBaseline: child.textBaseline,
        children: child.children
            .map(
              (rowChild) => rowChild is Text
                  ? Flexible(
                      child: Text(
                        rowChild.data ?? '',
                        key: rowChild.key,
                        style: rowChild.style,
                        strutStyle: rowChild.strutStyle,
                        textAlign: rowChild.textAlign,
                        textDirection: rowChild.textDirection,
                        locale: rowChild.locale,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        textScaler: rowChild.textScaler,
                        maxLines: 1,
                        semanticsLabel: rowChild.semanticsLabel,
                        textWidthBasis: rowChild.textWidthBasis,
                        textHeightBehavior: rowChild.textHeightBehavior,
                        selectionColor: rowChild.selectionColor,
                      ),
                    )
                  : rowChild,
            )
            .toList(growable: false),
      ),
    );
  }

  return SizedBox(
    width: maxWidth,
    child: Align(alignment: Alignment.centerLeft, child: child),
  );
}

class TableSelectionToolbar extends StatelessWidget {
  TableSelectionToolbar({
    required this.count,
    required this.entityLabel,
    required this.onClear,
    required this.onDelete,
    this.onEdit,
    this.pluralLabel,
    super.key,
  });

  final int count;
  final String entityLabel;
  final String? pluralLabel;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final singular = trText(entityLabel);
    final plural = trText(pluralLabel ?? '${entityLabel}s');
    final label = count == 1
        ? tr('1 $entityLabel seleccionado', '1 $singular selected')
        : tr('$count $plural seleccionados', '$count $plural selected');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.onInk,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onEdit != null)
            _InkToolbarButton(
              onTap: onEdit!,
              icon: Icons.edit_outlined,
              label: trText('Editar'),
            ),
          _InkToolbarButton(
            onTap: onDelete,
            icon: Icons.delete_outline_rounded,
            label: trText('Eliminar'),
          ),
          _InkToolbarButton(
            onTap: onClear,
            icon: Icons.close_rounded,
            label: trText('Limpiar'),
          ),
        ],
      ),
    );
  }
}

class _InkToolbarButton extends StatelessWidget {
  const _InkToolbarButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onInk.withValues(alpha: 0.10),
      shape: StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.onInk),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.onInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineEmptyTableState extends StatelessWidget {
  _InlineEmptyTableState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.insights_outlined,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            trText(title),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            trText(subtitle),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  _NavItem({
    required this.entry,
    required this.compact,
    required this.selected,
    required this.showCreate,
    this.closeAfterTap = false,
  });

  final (String label, IconData icon, String path) entry;
  final bool compact;
  final bool selected;
  final bool showCreate;
  final bool closeAfterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void go() {
      if (closeAfterTap) Navigator.of(context).pop();
      if (!context.mounted) return;
      context.go(entry.$3);
    }

    final surface = GestureDetector(
      onTap: go,
      child: _RailIconSurface(
        compact: compact,
        icon: entry.$2,
        label: entry.$1,
        selected: selected,
      ),
    );

    if (compact) {
      return Tooltip(
        message: entry.$1,
        waitDuration: Duration(milliseconds: 600),
        verticalOffset: 30,
        child: surface,
      );
    }

    if (!showCreate) return surface;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        surface,
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: _HoverCircleButton(
            onTap: () {
              if (closeAfterTap) Navigator.of(context).pop();
              context.go('${entry.$3}?create=1');
            },
            icon: Icons.add_rounded,
            size: 26,
            iconSize: 16,
            baseColor: Colors.transparent,
            hoverColor: AppColors.container,
            baseIconColor: AppColors.textMuted,
            hoverIconColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MobileBottomNavigation extends ConsumerWidget {
  _MobileBottomNavigation({required this.activePath});

  final String activePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.container,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: primaryNavIndexes.map((index) {
              final entry = appNavEntries[index];
              final selected = activePath.startsWith(entry.$3);
              return Padding(
                padding: EdgeInsets.only(right: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    if (!context.mounted) return;
                    context.go(entry.$3);
                  },
                  child: AnimatedContainer(
                    duration: _microInteractionDuration,
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.muted
                          : AppColors.muted.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Icon(entry.$2, size: 21, color: AppColors.textPrimary),
                        if (selected) ...[
                          SizedBox(width: 8),
                          Text(
                            entry.$1,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _HoverCircleButton extends StatefulWidget {
  _HoverCircleButton({
    required this.onTap,
    required this.icon,
    required this.baseColor,
    required this.hoverColor,
    required this.baseIconColor,
    required this.hoverIconColor,
    this.size = 34,
    this.iconSize = 18,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color baseColor;
  final Color hoverColor;
  final Color baseIconColor;
  final Color hoverIconColor;
  final double size;
  final double iconSize;

  @override
  State<_HoverCircleButton> createState() => _HoverCircleButtonState();
}

class _HoverCircleButtonState extends State<_HoverCircleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final surface = AnimatedContainer(
      duration: _microInteractionDuration,
      curve: _microInteractionCurve,
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _hovered ? widget.hoverColor : widget.baseColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.icon,
        size: widget.iconSize,
        color: _hovered ? widget.hoverIconColor : widget.baseIconColor,
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: widget.onTap == null
          ? surface
          : GestureDetector(onTap: widget.onTap, child: surface),
    );
  }
}


class ToastHelper {
  static void show(
    BuildContext context,
    String message, {
    ToastVariant variant = ToastVariant.exito,
  }) {
    final host = ToastViewport.maybeOf(context) ?? ToastViewportState.current;
    host?.show(trText(message), variant: variant);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, variant: ToastVariant.exito);
  }

  static void showError(BuildContext context, String message) {
    show(context, message, variant: ToastVariant.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message, variant: ToastVariant.advertencia);
  }
}

enum ToastVariant { exito, error, advertencia }

class ToastViewport extends StatefulWidget {
  ToastViewport({required this.child, super.key});

  final Widget child;

  static ToastViewportState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ToastViewportState>();
  }

  @override
  State<ToastViewport> createState() => ToastViewportState();
}

class ToastViewportState extends State<ToastViewport> {
  static ToastViewportState? current;

  Timer? _dismissTimer;
  _ToastMessage? _toast;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    current = this;
  }

  void show(String message, {required ToastVariant variant}) {
    _dismissTimer?.cancel();
    setState(() {
      _toast = _ToastMessage(id: _nextId++, message: message, variant: variant);
    });
    _dismissTimer = Timer(Duration(seconds: 4), dismiss);
  }

  void dismiss() {
    if (_toast == null) return;
    _dismissTimer?.cancel();
    setState(() {
      _toast = null;
    });
  }

  @override
  void dispose() {
    if (identical(current, this)) {
      current = null;
    }
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final toastWidth = media.size.width < 520 ? media.size.width - 32 : 420.0;
    final topInset = media.padding.top + 16;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: topInset,
          right: 16,
          child: IgnorePointer(
            ignoring: _toast == null,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 220),
              reverseDuration: Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: Offset(0.18, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _toast == null
                  ? SizedBox.shrink(key: ValueKey('toast-empty'))
                  : _ToastCard(
                      key: ValueKey(_toast!.id),
                      width: toastWidth,
                      message: _toast!.message,
                      variant: _toast!.variant,
                      onClose: dismiss,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastMessage {
  _ToastMessage({
    required this.id,
    required this.message,
    required this.variant,
  });

  final int id;
  final String message;
  final ToastVariant variant;
}

class _ToastCard extends StatelessWidget {
  _ToastCard({
    required this.width,
    required this.message,
    required this.variant,
    required this.onClose,
    super.key,
  });

  final double width;
  final String message;
  final ToastVariant variant;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (accent, iconData) = switch (variant) {
      ToastVariant.exito => (AppColors.success, Icons.check_rounded),
      ToastVariant.error => (AppColors.error, Icons.close_rounded),
      ToastVariant.advertencia => (
        AppColors.warning,
        Icons.priority_high_rounded,
      ),
    };

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.floatingShadow,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: Colors.white, size: 17),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: AppColors.onInk,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                InkWell(
                  onTap: onClose,
                  customBorder: CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: AppColors.onInk.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showCotimaxCommandPalette(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: (_) => _CommandPaletteDialog(originContext: context),
  );
}

class _CommandPaletteDialog extends StatefulWidget {
  _CommandPaletteDialog({required this.originContext});

  final BuildContext originContext;

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final List<_CommandPaletteEntry> _entries;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _entries = _buildCommandPaletteEntries();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filterCommandPaletteEntries(_entries, _query);
    final noBorder = InputBorder.none;
    return Dialog(
      alignment: Alignment(0, -0.45),
      insetPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      backgroundColor: AppColors.container,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.dialogRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 660, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(26, 12, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (value) => setState(() => _query = value),
                      onSubmitted: (_) {
                        if (matches.isEmpty) return;
                        _selectEntry(matches.first);
                      },
                      style: TextStyle(
                        fontSize: 19,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        hintText: trText('Buscar'),
                        hintStyle: TextStyle(
                          fontSize: 19,
                          color: AppColors.textMuted,
                        ),
                        border: noBorder,
                        enabledBorder: noBorder,
                        focusedBorder: noBorder,
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                  _CommandPaletteShortcutHint(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(height: 1, color: AppColors.border),
            ),
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(18),
                      child: _InlineEmptyTableState(
                        title: 'No encontramos coincidencias.',
                        subtitle:
                            'Prueba con un cliente, un folio, un producto o una acción rápida.',
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(14, 0, 14, 8),
                          child: Text(
                            tr(
                              _query.trim().isEmpty
                                  ? 'Sugerencias'
                                  : '${matches.length} resultados',
                              _query.trim().isEmpty
                                  ? 'Suggestions'
                                  : '${matches.length} results',
                            ),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        for (var i = 0; i < matches.length; i++)
                          _CommandPaletteTile(
                            entry: matches[i],
                            highlighted: i == 0,
                            onTap: () => _selectEntry(matches[i]),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectEntry(_CommandPaletteEntry entry) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.originContext.mounted) return;
      widget.originContext.go(entry.route);
      if (entry.feedbackMessage != null) {
        ToastHelper.show(widget.originContext, entry.feedbackMessage!);
      }
    });
  }
}

class _CommandPaletteTile extends StatefulWidget {
  _CommandPaletteTile({
    required this.entry,
    required this.onTap,
    this.highlighted = false,
  });

  final _CommandPaletteEntry entry;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  State<_CommandPaletteTile> createState() => _CommandPaletteTileState();
}

class _CommandPaletteTileState extends State<_CommandPaletteTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _microInteractionDuration,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.highlighted
                ? AppColors.muted
                : _hovered
                ? AppColors.hover
                : AppColors.hover.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(entry.icon, size: 20, color: AppColors.textPrimary),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trText(entry.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      entry.subtitle.isEmpty
                          ? trText(entry.kind.label)
                          : '${trText(entry.subtitle)} · ${trText(entry.kind.label)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.highlighted || _hovered)
                Icon(
                  Icons.keyboard_return_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}


enum _CommandPaletteKind { action, module, cliente, cotizacion, producto }

extension on _CommandPaletteKind {
  String get label {
    switch (this) {
      case _CommandPaletteKind.action:
        return 'Acción';
      case _CommandPaletteKind.module:
        return 'Módulo';
      case _CommandPaletteKind.cliente:
        return 'Cliente';
      case _CommandPaletteKind.cotizacion:
        return 'Cotización';
      case _CommandPaletteKind.producto:
        return 'Producto';
    }
  }
}

class _CommandPaletteEntry {
  _CommandPaletteEntry({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.searchTerms,
    required this.priority,
    this.feedbackMessage,
    this.pinned = false,
  });

  final _CommandPaletteKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final List<String> searchTerms;
  final int priority;
  final String? feedbackMessage;
  final bool pinned;
}

List<_CommandPaletteEntry> _buildCommandPaletteEntries() {
  final entries = <_CommandPaletteEntry>[
    ...appNavEntries.map(
      (entry) => _CommandPaletteEntry(
        kind: _CommandPaletteKind.module,
        title: entry.$1,
        subtitle: 'Abrir módulo ${entry.$1.toLowerCase()}',
        icon: entry.$2,
        color: AppColors.primary,
        route: entry.$3,
        searchTerms: [entry.$1, entry.$3],
        priority: 52,
        pinned: primaryNavIndexes.contains(appNavEntries.indexOf(entry)),
      ),
    ),
    _CommandPaletteEntry(
      kind: _CommandPaletteKind.action,
      title: 'Nuevo cliente',
      subtitle: 'Crear un nuevo cliente desde cualquier vista',
      icon: FontAwesomeIcons.users.data,
      color: AppColors.accent,
      route: Uri(
        path: RoutePaths.clientes,
        queryParameters: const {'create': '1'},
      ).toString(),
      searchTerms: const ['nuevo cliente', 'crear cliente', 'cliente'],
      priority: 100,
      feedbackMessage: 'Abrimos el flujo para crear un cliente.',
      pinned: true,
    ),
    _CommandPaletteEntry(
      kind: _CommandPaletteKind.action,
      title: 'Nueva cotización',
      subtitle: 'Ir directo al formulario comercial',
      icon: FontAwesomeIcons.fileInvoiceDollar.data,
      color: AppColors.accent,
      route: Uri(
        path: RoutePaths.cotizaciones,
        queryParameters: const {'create': '1'},
      ).toString(),
      searchTerms: const ['nueva cotizacion', 'crear cotizacion', 'cotizacion'],
      priority: 100,
      feedbackMessage: 'Abrimos el flujo para crear una cotización.',
      pinned: true,
    ),
    _CommandPaletteEntry(
      kind: _CommandPaletteKind.action,
      title: 'Nuevo producto',
      subtitle: 'Agregar un producto o servicio',
      icon: FontAwesomeIcons.boxOpen.data,
      color: AppColors.accent,
      route: Uri(
        path: RoutePaths.productos,
        queryParameters: const {'create': '1'},
      ).toString(),
      searchTerms: const ['nuevo producto', 'crear producto', 'servicio'],
      priority: 98,
      feedbackMessage: 'Abrimos el flujo para crear un producto.',
      pinned: true,
    ),
    _CommandPaletteEntry(
      kind: _CommandPaletteKind.action,
      title: 'Registrar ingreso',
      subtitle: 'Capturar un cobro nuevo',
      icon: FontAwesomeIcons.wallet.data,
      color: AppColors.success,
      route: Uri(
        path: RoutePaths.ingresos,
        queryParameters: const {'create': '1'},
      ).toString(),
      searchTerms: const ['registrar ingreso', 'nuevo ingreso', 'cobro'],
      priority: 94,
      feedbackMessage: 'Abrimos el flujo para registrar un ingreso.',
      pinned: true,
    ),
    _CommandPaletteEntry(
      kind: _CommandPaletteKind.action,
      title: 'Registrar gasto',
      subtitle: 'Capturar un gasto nuevo',
      icon: FontAwesomeIcons.receipt.data,
      color: AppColors.warning,
      route: Uri(
        path: RoutePaths.gastos,
        queryParameters: const {'create': '1'},
      ).toString(),
      searchTerms: const ['registrar gasto', 'nuevo gasto', 'egreso'],
      priority: 94,
      feedbackMessage: 'Abrimos el flujo para registrar un gasto.',
      pinned: true,
    ),
  ];
  return entries;
}

List<_CommandPaletteEntry> _filterCommandPaletteEntries(
  List<_CommandPaletteEntry> entries,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return entries.where((item) => item.pinned).take(10).toList();
  }

  final matches = <(_CommandPaletteEntry, int)>[];
  for (final entry in entries) {
    final score = _commandPaletteScore(entry, normalized);
    if (score > 0) {
      matches.add((entry, score));
    }
  }

  matches.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    if (byScore != 0) return byScore;
    return a.$1.title.compareTo(b.$1.title);
  });

  return matches.take(14).map((item) => item.$1).toList();
}

int _commandPaletteScore(_CommandPaletteEntry entry, String query) {
  var score = 0;
  for (final term in entry.searchTerms) {
    final value = term.toLowerCase();
    if (value.startsWith(query)) {
      score = score < 120 ? 120 : score;
      continue;
    }
    if (value.contains(query)) {
      score = score < 72 ? 72 : score;
    }
  }
  if (score == 0) return 0;
  return score + entry.priority;
}

class ImageUploadField extends StatelessWidget {
  ImageUploadField({super.key});

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: 'Logo',
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.upload_file),
        label: Text(trText('Subir imagen')),
      ),
    );
  }
}

class ColorPickerSimple extends StatelessWidget {
  ColorPickerSimple({required this.label, required this.value, super.key});

  final String label;
  final Color value;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: value,
              border: Border.all(color: AppColors.border),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '#${value.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class SummaryCards extends StatelessWidget {
  SummaryCards({required this.items, super.key});

  final List<(String label, String value)> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 1320
        ? 3
        : width > 720
        ? 2
        : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 116,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.$1,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Text(
                item.$2,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
