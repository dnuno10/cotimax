import 'package:cotimax/features/planes/application/planes_controller.dart';
import 'package:cotimax/features/usuarios/application/usuarios_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = ref.watch(usuariosControllerProvider);
    final plan = ref.watch(suscripcionControllerProvider);

    return ListView(
      children: [
        const PageHeader(
          title: 'Usuarios',
          subtitle: 'Administracion de usuarios, roles y empresas asignadas.',
        ),
        const SizedBox(height: 12),
        plan.when(
          data: (sub) {
            if (sub.planId == 'starter' || sub.planId == 'pro') {
              return const SectionCard(
                title: 'Bloqueo por plan',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu plan actual limita a 1 usuario. Haz upgrade para gestionar multiusuario.',
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        usuarios.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No se pudieron cargar usuarios.',
            onRetry: () => ref.invalidate(usuariosControllerProvider),
          ),
          data: (rows) => CotimaxDataTable(
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Correo')),
              DataColumn(label: Text('Rol')),
              DataColumn(label: Text('Empresas')),
              DataColumn(label: Text('Activo')),
            ],
            rows: rows
                .map(
                  (u) => DataRow(
                    cells: [
                      DataCell(Text(u.nombre)),
                      DataCell(Text(u.correo)),
                      DataCell(
                        Text(u.rol == UserRole.admin ? 'Admin' : 'Usuario'),
                      ),
                      DataCell(Text(u.empresaIds.join(', '))),
                      DataCell(Text(u.activo ? 'Si' : 'No')),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
