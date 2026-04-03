import 'package:cotimax/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class FinanceIconOption {
  const FinanceIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const List<FinanceIconOption> financeIconOptions = [
  FinanceIconOption(
    key: 'wallet',
    label: 'Cartera',
    icon: Icons.wallet_rounded,
  ),
  FinanceIconOption(
    key: 'payments',
    label: 'Pagos',
    icon: Icons.payments_rounded,
  ),
  FinanceIconOption(
    key: 'attach_money',
    label: 'Dinero',
    icon: Icons.attach_money_rounded,
  ),
  FinanceIconOption(
    key: 'account_balance',
    label: 'Banco',
    icon: Icons.account_balance_rounded,
  ),
  FinanceIconOption(
    key: 'credit_card',
    label: 'Tarjeta',
    icon: Icons.credit_card_rounded,
  ),
  FinanceIconOption(
    key: 'receipt_long',
    label: 'Recibo',
    icon: Icons.receipt_long_rounded,
  ),
  FinanceIconOption(
    key: 'point_of_sale',
    label: 'Caja',
    icon: Icons.point_of_sale_rounded,
  ),
  FinanceIconOption(
    key: 'storefront',
    label: 'Tienda',
    icon: Icons.storefront_rounded,
  ),
  FinanceIconOption(
    key: 'shopping_cart',
    label: 'Carrito',
    icon: Icons.shopping_cart_rounded,
  ),
  FinanceIconOption(
    key: 'shopping_bag',
    label: 'Bolsa',
    icon: Icons.shopping_bag_rounded,
  ),
  FinanceIconOption(
    key: 'inventory_2',
    label: 'Inventario',
    icon: Icons.inventory_2_rounded,
  ),
  FinanceIconOption(
    key: 'local_shipping',
    label: 'Envio',
    icon: Icons.local_shipping_rounded,
  ),
  FinanceIconOption(key: 'sell', label: 'Venta', icon: Icons.sell_rounded),
  FinanceIconOption(
    key: 'savings',
    label: 'Ahorro',
    icon: Icons.savings_rounded,
  ),
  FinanceIconOption(
    key: 'trending_up',
    label: 'Ingreso',
    icon: Icons.trending_up_rounded,
  ),
  FinanceIconOption(
    key: 'trending_down',
    label: 'Egreso',
    icon: Icons.trending_down_rounded,
  ),
  FinanceIconOption(
    key: 'insights',
    label: 'Reporte',
    icon: Icons.insights_rounded,
  ),
  FinanceIconOption(
    key: 'pie_chart',
    label: 'Grafica',
    icon: Icons.pie_chart_rounded,
  ),
  FinanceIconOption(
    key: 'bar_chart',
    label: 'Barras',
    icon: Icons.bar_chart_rounded,
  ),
  FinanceIconOption(
    key: 'leaderboard',
    label: 'Ranking',
    icon: Icons.leaderboard_rounded,
  ),
  FinanceIconOption(
    key: 'campaign',
    label: 'Marketing',
    icon: Icons.campaign_rounded,
  ),
  FinanceIconOption(
    key: 'ads_click',
    label: 'Publicidad',
    icon: Icons.ads_click_rounded,
  ),
  FinanceIconOption(key: 'public', label: 'Web', icon: Icons.public_rounded),
  FinanceIconOption(
    key: 'language',
    label: 'Idioma',
    icon: Icons.language_rounded,
  ),
  FinanceIconOption(key: 'groups', label: 'Equipo', icon: Icons.groups_rounded),
  FinanceIconOption(
    key: 'person',
    label: 'Persona',
    icon: Icons.person_rounded,
  ),
  FinanceIconOption(
    key: 'person_add',
    label: 'Nuevo cliente',
    icon: Icons.person_add_alt_1_rounded,
  ),
  FinanceIconOption(
    key: 'support_agent',
    label: 'Soporte',
    icon: Icons.support_agent_rounded,
  ),
  FinanceIconOption(key: 'badge', label: 'Nomina', icon: Icons.badge_rounded),
  FinanceIconOption(key: 'work', label: 'Trabajo', icon: Icons.work_rounded),
  FinanceIconOption(
    key: 'business_center',
    label: 'Negocio',
    icon: Icons.business_center_rounded,
  ),
  FinanceIconOption(
    key: 'apartment',
    label: 'Oficina',
    icon: Icons.apartment_rounded,
  ),
  FinanceIconOption(
    key: 'home_work',
    label: 'Renta',
    icon: Icons.home_work_rounded,
  ),
  FinanceIconOption(
    key: 'construction',
    label: 'Obra',
    icon: Icons.construction_rounded,
  ),
  FinanceIconOption(
    key: 'build',
    label: 'Herramienta',
    icon: Icons.build_rounded,
  ),
  FinanceIconOption(
    key: 'handyman',
    label: 'Mantenimiento',
    icon: Icons.handyman_rounded,
  ),
  FinanceIconOption(
    key: 'engineering',
    label: 'Ingenieria',
    icon: Icons.engineering_rounded,
  ),
  FinanceIconOption(
    key: 'plumbing',
    label: 'Plomeria',
    icon: Icons.plumbing_rounded,
  ),
  FinanceIconOption(
    key: 'electrical_services',
    label: 'Electricidad',
    icon: Icons.electrical_services_rounded,
  ),
  FinanceIconOption(
    key: 'electric_bolt',
    label: 'Luz',
    icon: Icons.electric_bolt_rounded,
  ),
  FinanceIconOption(
    key: 'water_drop',
    label: 'Agua',
    icon: Icons.water_drop_rounded,
  ),
  FinanceIconOption(
    key: 'local_gas_station',
    label: 'Gasolina',
    icon: Icons.local_gas_station_rounded,
  ),
  FinanceIconOption(
    key: 'commute',
    label: 'Transporte',
    icon: Icons.commute_rounded,
  ),
  FinanceIconOption(
    key: 'directions_car',
    label: 'Auto',
    icon: Icons.directions_car_rounded,
  ),
  FinanceIconOption(key: 'flight', label: 'Viaje', icon: Icons.flight_rounded),
  FinanceIconOption(
    key: 'hotel',
    label: 'Hospedaje',
    icon: Icons.hotel_rounded,
  ),
  FinanceIconOption(
    key: 'restaurant',
    label: 'Comida',
    icon: Icons.restaurant_rounded,
  ),
  FinanceIconOption(
    key: 'local_cafe',
    label: 'Cafe',
    icon: Icons.local_cafe_rounded,
  ),
  FinanceIconOption(
    key: 'lunch_dining',
    label: 'Alimentos',
    icon: Icons.lunch_dining_rounded,
  ),
  FinanceIconOption(
    key: 'medical_services',
    label: 'Salud',
    icon: Icons.medical_services_rounded,
  ),
  FinanceIconOption(
    key: 'fitness_center',
    label: 'Gym',
    icon: Icons.fitness_center_rounded,
  ),
  FinanceIconOption(
    key: 'school',
    label: 'Educacion',
    icon: Icons.school_rounded,
  ),
  FinanceIconOption(
    key: 'menu_book',
    label: 'Cursos',
    icon: Icons.menu_book_rounded,
  ),
  FinanceIconOption(
    key: 'computer',
    label: 'Computadora',
    icon: Icons.computer_rounded,
  ),
  FinanceIconOption(
    key: 'laptop_mac',
    label: 'Laptop',
    icon: Icons.laptop_mac_rounded,
  ),
  FinanceIconOption(
    key: 'desktop_windows',
    label: 'Escritorio',
    icon: Icons.desktop_windows_rounded,
  ),
  FinanceIconOption(
    key: 'smartphone',
    label: 'Celular',
    icon: Icons.smartphone_rounded,
  ),
  FinanceIconOption(
    key: 'headset_mic',
    label: 'Audio',
    icon: Icons.headset_mic_rounded,
  ),
  FinanceIconOption(
    key: 'print',
    label: 'Impresion',
    icon: Icons.print_rounded,
  ),
  FinanceIconOption(
    key: 'devices',
    label: 'Dispositivos',
    icon: Icons.devices_rounded,
  ),
  FinanceIconOption(key: 'cloud', label: 'Nube', icon: Icons.cloud_rounded),
  FinanceIconOption(key: 'dns', label: 'Servidor', icon: Icons.dns_rounded),
  FinanceIconOption(
    key: 'router',
    label: 'Internet',
    icon: Icons.router_rounded,
  ),
  FinanceIconOption(
    key: 'security',
    label: 'Seguridad',
    icon: Icons.security_rounded,
  ),
  FinanceIconOption(
    key: 'shield',
    label: 'Proteccion',
    icon: Icons.shield_rounded,
  ),
  FinanceIconOption(key: 'lock', label: 'Bloqueo', icon: Icons.lock_rounded),
  FinanceIconOption(
    key: 'verified',
    label: 'Validado',
    icon: Icons.verified_rounded,
  ),
  FinanceIconOption(
    key: 'description',
    label: 'Documento',
    icon: Icons.description_rounded,
  ),
  FinanceIconOption(
    key: 'folder',
    label: 'Carpeta',
    icon: Icons.folder_rounded,
  ),
  FinanceIconOption(
    key: 'inventory',
    label: 'Stock',
    icon: Icons.inventory_rounded,
  ),
  FinanceIconOption(
    key: 'qr_code_2',
    label: 'QR',
    icon: Icons.qr_code_2_rounded,
  ),
  FinanceIconOption(
    key: 'warehouse',
    label: 'Almacen',
    icon: Icons.warehouse_rounded,
  ),
  FinanceIconOption(key: 'store', label: 'Sucursal', icon: Icons.store_rounded),
  FinanceIconOption(
    key: 'local_mall',
    label: 'Mall',
    icon: Icons.local_mall_rounded,
  ),
  FinanceIconOption(key: 'redeem', label: 'Regalo', icon: Icons.redeem_rounded),
  FinanceIconOption(
    key: 'card_giftcard',
    label: 'Promocion',
    icon: Icons.card_giftcard_rounded,
  ),
  FinanceIconOption(
    key: 'loyalty',
    label: 'Lealtad',
    icon: Icons.loyalty_rounded,
  ),
  FinanceIconOption(
    key: 'workspace_premium',
    label: 'Premium',
    icon: Icons.workspace_premium_rounded,
  ),
  FinanceIconOption(
    key: 'emoji_events',
    label: 'Premio',
    icon: Icons.emoji_events_rounded,
  ),
  FinanceIconOption(
    key: 'celebration',
    label: 'Evento',
    icon: Icons.celebration_rounded,
  ),
  FinanceIconOption(
    key: 'schedule',
    label: 'Horario',
    icon: Icons.schedule_rounded,
  ),
  FinanceIconOption(
    key: 'calendar_month',
    label: 'Calendario',
    icon: Icons.calendar_month_rounded,
  ),
  FinanceIconOption(key: 'today', label: 'Hoy', icon: Icons.today_rounded),
  FinanceIconOption(
    key: 'event_repeat',
    label: 'Recurrente',
    icon: Icons.event_repeat_rounded,
  ),
  FinanceIconOption(key: 'alarm', label: 'Alerta', icon: Icons.alarm_rounded),
  FinanceIconOption(
    key: 'notifications',
    label: 'Notificacion',
    icon: Icons.notifications_rounded,
  ),
  FinanceIconOption(key: 'mail', label: 'Correo', icon: Icons.mail_rounded),
  FinanceIconOption(key: 'call', label: 'Llamada', icon: Icons.call_rounded),
  FinanceIconOption(key: 'chat', label: 'Mensaje', icon: Icons.chat_rounded),
  FinanceIconOption(
    key: 'forum',
    label: 'Conversacion',
    icon: Icons.forum_rounded,
  ),
  FinanceIconOption(
    key: 'handshake',
    label: 'Acuerdo',
    icon: Icons.handshake_rounded,
  ),
  FinanceIconOption(key: 'gavel', label: 'Legal', icon: Icons.gavel_rounded),
  FinanceIconOption(
    key: 'account_balance_wallet',
    label: 'Billetera',
    icon: Icons.account_balance_wallet_rounded,
  ),
  FinanceIconOption(
    key: 'request_quote',
    label: 'Cotización',
    icon: Icons.request_quote_rounded,
  ),
  FinanceIconOption(key: 'paid', label: 'Cobrado', icon: Icons.paid_rounded),
  FinanceIconOption(
    key: 'price_check',
    label: 'Precio',
    icon: Icons.price_check_rounded,
  ),
  FinanceIconOption(
    key: 'calculate',
    label: 'Calculo',
    icon: Icons.calculate_rounded,
  ),
  FinanceIconOption(
    key: 'percent',
    label: 'Porcentaje',
    icon: Icons.percent_rounded,
  ),
  FinanceIconOption(
    key: 'monitor_heart',
    label: 'KPI',
    icon: Icons.monitor_heart_rounded,
  ),
  FinanceIconOption(
    key: 'auto_graph',
    label: 'Tendencia',
    icon: Icons.auto_graph_rounded,
  ),
  FinanceIconOption(
    key: 'timeline',
    label: 'Linea de tiempo',
    icon: Icons.timeline_rounded,
  ),
  FinanceIconOption(key: 'star', label: 'Favorito', icon: Icons.star_rounded),
  FinanceIconOption(
    key: 'check_circle',
    label: 'Confirmado',
    icon: Icons.check_circle_rounded,
  ),
  FinanceIconOption(key: 'flag', label: 'Objetivo', icon: Icons.flag_rounded),
  FinanceIconOption(key: 'bolt', label: 'Rapido', icon: Icons.bolt_rounded),
  FinanceIconOption(key: 'eco', label: 'Sostenible', icon: Icons.eco_rounded),
];

FinanceIconOption financeIconByKey(String key) {
  return financeIconOptions.firstWhere(
    (option) => option.key == key,
    orElse: () => financeIconOptions.first,
  );
}

class FinanceIconAvatar extends StatelessWidget {
  const FinanceIconAvatar({
    required this.iconKey,
    this.size = 34,
    this.backgroundColor,
    this.iconColor,
    super.key,
  });

  final String iconKey;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final option = financeIconByKey(iconKey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.background,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        option.icon,
        size: size * 0.52,
        color: iconColor ?? AppColors.primary,
      ),
    );
  }
}

class FinanceIconPicker extends StatefulWidget {
  const FinanceIconPicker({
    required this.selectedKey,
    required this.onChanged,
    super.key,
  });

  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  State<FinanceIconPicker> createState() => _FinanceIconPickerState();
}

class _FinanceIconPickerState extends State<FinanceIconPicker> {
  @override
  Widget build(BuildContext context) {
    final selected = financeIconByKey(widget.selectedKey);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openPickerDialog(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            FinanceIconAvatar(
              iconKey: selected.key,
              size: 42,
              backgroundColor: AppColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Abre un dialogo compacto para cambiarlo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _openPickerDialog(context),
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: const Text('Elegir'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPickerDialog(BuildContext context) async {
    final selectedKey = await showDialog<String>(
      context: context,
      builder: (_) => _FinanceIconDialog(selectedKey: widget.selectedKey),
    );

    if (!mounted || selectedKey == null) return;
    widget.onChanged(selectedKey);
  }
}

class _FinanceIconDialog extends StatefulWidget {
  const _FinanceIconDialog({required this.selectedKey});

  final String selectedKey;

  @override
  State<_FinanceIconDialog> createState() => _FinanceIconDialogState();
}

class _FinanceIconDialogState extends State<_FinanceIconDialog> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = financeIconByKey(widget.selectedKey);
    final visible = financeIconOptions.where((option) {
      if (_query.isEmpty) return true;
      final query = _query.toLowerCase();
      return option.label.toLowerCase().contains(query) ||
          option.key.toLowerCase().contains(query);
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seleccionar icono',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${visible.length} iconos disponibles',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    FinanceIconAvatar(
                      iconKey: selected.key,
                      size: 42,
                      backgroundColor: AppColors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Toca un icono para seleccionarlo',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Buscar icono por nombre',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: GridView.builder(
                    itemCount: visible.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      final option = visible[index];
                      final isSelected = option.key == widget.selectedKey;
                      return Tooltip(
                        message: option.label,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.of(context).pop(option.key),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Icon(
                              option.icon,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
