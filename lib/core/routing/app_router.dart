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
import 'package:cotimax/features/recordatorios/presentation/recordatorios_page.dart';
import 'package:cotimax/features/usuarios/presentation/usuarios_page.dart';
import 'package:cotimax/features/workspace/application/workspace_controller.dart';
import 'package:cotimax/features/workspace/presentation/workspace_setup_page.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.read(_routerRefreshProvider);

  String normalizeRedirectLike(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('/#/')) {
      value = value.substring(2);
    } else if (value.startsWith('#/')) {
      value = value.substring(1);
    }
    return value;
  }

  String? sanitizeRedirectParam(String? raw) {
    final value = normalizeRedirectLike(raw ?? '');
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.scheme.isNotEmpty || uri.host.isNotEmpty) return null;
    final candidate = (uri.fragment.startsWith('/') && uri.path == '/')
        ? uri.fragment
        : uri.path;
    if (!candidate.startsWith('/')) return null;
    if (candidate == RoutePaths.login || candidate == RoutePaths.recover) {
      return null;
    }
    final normalized = Uri(
      path: candidate,
      queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
    ).toString();
    return normalized;
  }

  String withRedirect(String path, String redirectTo) {
    return Uri(path: path, queryParameters: {'redirect': redirectTo}).toString();
  }

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
    if (location.startsWith(RoutePaths.recordatorios)) {
      return tr('Recordatorios', 'Reminders');
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
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final workspaceStatus = ref.read(workspaceStatusProvider);
      final path = state.uri.path;
      final isAuthRoute =
          path == RoutePaths.login || path == RoutePaths.recover;
      final isWorkspaceSetupRoute = path == RoutePaths.workspaceSetup;
      final redirectTo = sanitizeRedirectParam(state.uri.queryParameters['redirect']);
      final effectiveTarget = sanitizeRedirectParam(state.uri.toString()) ??
          sanitizeRedirectParam(state.matchedLocation) ??
          state.uri.path;

      if (!auth.isAuthenticated && !isAuthRoute && !isWorkspaceSetupRoute) {
        return withRedirect(RoutePaths.login, effectiveTarget);
      }

      if (!auth.isAuthenticated && isWorkspaceSetupRoute) {
        return withRedirect(RoutePaths.login, redirectTo ?? RoutePaths.dashboard);
      }

      if (auth.isAuthenticated && isAuthRoute) {
        final hasCompany = workspaceStatus.valueOrNull?.hasCompany == true;
        if (!hasCompany) {
          return redirectTo == null
              ? RoutePaths.workspaceSetup
              : withRedirect(RoutePaths.workspaceSetup, redirectTo);
        }
        return redirectTo ?? RoutePaths.dashboard;
      }

      if (auth.isAuthenticated && !isWorkspaceSetupRoute) {
        final hasCompany = workspaceStatus.valueOrNull?.hasCompany == true;
        if (!hasCompany) {
          final intended = redirectTo ?? sanitizeRedirectParam(state.uri.toString()) ?? RoutePaths.dashboard;
          return withRedirect(RoutePaths.workspaceSetup, intended);
        }
      }

      if (auth.isAuthenticated && isWorkspaceSetupRoute) {
        final hasCompany = workspaceStatus.valueOrNull?.hasCompany == true;
        if (hasCompany) {
          return redirectTo ?? RoutePaths.dashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.login, builder: (_, __) => LoginPage()),
      GoRoute(path: RoutePaths.recover, builder: (_, __) => RecoverPage()),
      GoRoute(
        path: RoutePaths.workspaceSetup,
        builder: (_, __) => WorkspaceSetupPage(),
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
            builder: (_, __) => DashboardPage(),
          ),
          GoRoute(
            path: RoutePaths.clientes,
            builder: (_, __) => ClientesPage(),
          ),
          GoRoute(
            path: RoutePaths.proveedores,
            builder: (_, __) => ProveedoresPage(),
          ),
          GoRoute(
            path: RoutePaths.productos,
            builder: (_, __) => ProductosPage(),
          ),
          GoRoute(
            path: RoutePaths.materiales,
            builder: (_, __) => MaterialesPage(),
          ),
          GoRoute(
            path: RoutePaths.cotizaciones,
            builder: (_, __) => CotizacionesPage(),
          ),
          GoRoute(
            path: RoutePaths.ingresos,
            builder: (_, __) => IngresosPage(),
          ),
          GoRoute(path: RoutePaths.gastos, builder: (_, __) => GastosPage()),
          GoRoute(
            path: RoutePaths.recordatorios,
            builder: (_, __) => RecordatoriosPage(),
          ),
          GoRoute(
            path: RoutePaths.analitica,
            builder: (_, __) => AnaliticaPage(),
          ),
          GoRoute(
            path: RoutePaths.configuracion,
            builder: (_, __) => ConfiguracionPage(),
          ),
          GoRoute(
            path: RoutePaths.usuarios,
            builder: (_, __) => UsuariosPage(),
          ),
          GoRoute(path: RoutePaths.planes, builder: (_, __) => PlanesPage()),
        ],
      ),
    ],
    errorBuilder: (_, __) => Scaffold(
      body: Center(child: Text(tr('Ruta no encontrada', 'Route not found'))),
    ),
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _authSub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
    _workspaceSub = _ref.listen<AsyncValue<WorkspaceStatus>>(
      workspaceStatusProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _authSub;
  late final ProviderSubscription<AsyncValue<WorkspaceStatus>> _workspaceSub;

  @override
  void dispose() {
    _authSub.close();
    _workspaceSub.close();
    super.dispose();
  }
}
