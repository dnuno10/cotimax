import 'package:cotimax/core/localization/app_localization.dart';
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
import 'package:cotimax/features/workspace/application/workspace_controller.dart';
import 'package:cotimax/features/workspace/presentation/workspace_setup_page.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final workspaceStatus = ref.watch(workspaceStatusProvider);

  String pageTitle(String location) {
    if (location.startsWith(RoutePaths.dashboard)) {
      return tr('Inicio', 'Home');
    }
    if (location.startsWith(RoutePaths.clientes)) {
      return tr('Clientes', 'Clients');
    }
    if (location.startsWith(RoutePaths.proveedores)) {
      return tr('Proveedores', 'Suppliers');
    }
    if (location.startsWith(RoutePaths.productos)) {
      return tr('Productos / Servicios', 'Products / Services');
    }
    if (location.startsWith(RoutePaths.materiales)) {
      return tr('Materiales', 'Materials');
    }
    if (location.startsWith(RoutePaths.cotizaciones)) {
      return tr('Cotizaciones', 'Quotes');
    }
    if (location.startsWith(RoutePaths.ingresos)) {
      return tr('Ingresos', 'Income');
    }
    if (location.startsWith(RoutePaths.gastos)) {
      return tr('Gastos', 'Expenses');
    }
    if (location.startsWith(RoutePaths.analitica)) {
      return tr('Analítica', 'Analytics');
    }
    if (location.startsWith(RoutePaths.configuracion)) {
      return tr('Configuración', 'Settings');
    }
    if (location.startsWith(RoutePaths.usuarios)) {
      return tr('Usuarios', 'Users');
    }
    if (location.startsWith(RoutePaths.planes)) {
      return tr('Planes', 'Plans');
    }
    return 'Cotimax';
  }

  return GoRouter(
    initialLocation: RoutePaths.login,
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute =
          path == RoutePaths.login || path == RoutePaths.recover;
      final isWorkspaceSetupRoute = path == RoutePaths.workspaceSetup;

      if (!auth.isAuthenticated && !isAuthRoute && !isWorkspaceSetupRoute) {
        return RoutePaths.login;
      }

      if (!auth.isAuthenticated && isWorkspaceSetupRoute) {
        return RoutePaths.login;
      }

      if (auth.isAuthenticated && isAuthRoute) {
        return RoutePaths.workspaceSetup;
      }

      if (auth.isAuthenticated && !isWorkspaceSetupRoute) {
        final hasCompany = workspaceStatus.valueOrNull?.hasCompany == true;
        if (!hasCompany) {
          return RoutePaths.workspaceSetup;
        }
      }

      if (auth.isAuthenticated && isWorkspaceSetupRoute) {
        final hasCompany = workspaceStatus.valueOrNull?.hasCompany == true;
        if (hasCompany) {
          return RoutePaths.dashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: RoutePaths.recover,
        builder: (_, __) => const RecoverPage(),
      ),
      GoRoute(
        path: RoutePaths.workspaceSetup,
        builder: (_, __) => const WorkspaceSetupPage(),
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
    errorBuilder: (_, __) => Scaffold(
      body: Center(child: Text(tr('Ruta no encontrada', 'Route not found'))),
    ),
  );
});
