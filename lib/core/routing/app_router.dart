import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/auth/application/auth_controller.dart';
import 'package:cotimax/features/auth/presentation/login_page.dart';
import 'package:cotimax/features/auth/presentation/recover_page.dart';
import 'package:cotimax/features/analitica/presentation/analitica_page.dart';
import 'package:cotimax/features/clientes/presentation/clientes_page.dart';
import 'package:cotimax/features/configuracion/presentation/configuracion_page.dart';
import 'package:cotimax/features/cotizaciones/presentation/cotizaciones_page.dart';
import 'package:cotimax/features/dashboard/presentation/dashboard_page.dart';
import 'package:cotimax/features/gastos/presentation/gastos_page.dart';
import 'package:cotimax/features/ingresos/presentation/ingresos_page.dart';
import 'package:cotimax/features/materiales/presentation/materiales_page.dart';
import 'package:cotimax/features/planes/presentation/planes_page.dart';
import 'package:cotimax/features/productos/presentation/productos_page.dart';
import 'package:cotimax/features/proveedores/presentation/proveedores_page.dart';
import 'package:cotimax/features/usuarios/presentation/usuarios_page.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  String pageTitle(String location) {
    if (location.startsWith(RoutePaths.dashboard)) return 'Dashboard';
    if (location.startsWith(RoutePaths.clientes)) return 'Clientes';
    if (location.startsWith(RoutePaths.proveedores)) return 'Proveedores';
    if (location.startsWith(RoutePaths.productos)) {
      return 'Productos / Servicios';
    }
    if (location.startsWith(RoutePaths.materiales)) return 'Materiales';
    if (location.startsWith(RoutePaths.cotizaciones)) return 'Cotizaciones';
    if (location.startsWith(RoutePaths.ingresos)) return 'Ingresos';
    if (location.startsWith(RoutePaths.gastos)) return 'Gastos';
    if (location.startsWith(RoutePaths.analitica)) return 'Analítica';
    if (location.startsWith(RoutePaths.configuracion)) return 'Configuración';
    if (location.startsWith(RoutePaths.usuarios)) return 'Usuarios';
    if (location.startsWith(RoutePaths.planes)) return 'Planes';
    return 'Cotimax';
  }

  return GoRouter(
    initialLocation: RoutePaths.login,
    redirect: (context, state) {
      final isAuthRoute =
          state.uri.path == RoutePaths.login ||
          state.uri.path == RoutePaths.recover;
      if (!auth.isAuthenticated && !isAuthRoute) return RoutePaths.login;
      if (auth.isAuthenticated && isAuthRoute) return RoutePaths.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: RoutePaths.recover,
        builder: (_, __) => const RecoverPage(),
      ),
      ShellRoute(
        builder: (_, state, child) => AppShell(
          location: state.uri.path,
          title: pageTitle(state.uri.path),
          child: child,
        ),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: RoutePaths.clientes,
            builder: (_, __) => const ClientesPage(),
          ),
          GoRoute(
            path: RoutePaths.proveedores,
            builder: (_, __) => const ProveedoresPage(),
          ),
          GoRoute(
            path: RoutePaths.productos,
            builder: (_, __) => const ProductosPage(),
          ),
          GoRoute(
            path: RoutePaths.materiales,
            builder: (_, __) => const MaterialesPage(),
          ),
          GoRoute(
            path: RoutePaths.cotizaciones,
            builder: (_, __) => const CotizacionesPage(),
          ),
          GoRoute(
            path: RoutePaths.ingresos,
            builder: (_, __) => const IngresosPage(),
          ),
          GoRoute(
            path: RoutePaths.gastos,
            builder: (_, __) => const GastosPage(),
          ),
          GoRoute(
            path: RoutePaths.analitica,
            builder: (_, __) => const AnaliticaPage(),
          ),
          GoRoute(
            path: RoutePaths.configuracion,
            builder: (_, __) => const ConfiguracionPage(),
          ),
          GoRoute(
            path: RoutePaths.usuarios,
            builder: (_, __) => const UsuariosPage(),
          ),
          GoRoute(
            path: RoutePaths.planes,
            builder: (_, __) => const PlanesPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, __) =>
        const Scaffold(body: Center(child: Text('Ruta no encontrada'))),
  );
});
