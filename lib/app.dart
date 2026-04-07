import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/app_router.dart';
import 'package:cotimax/core/theme/app_theme.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CotimaxApp extends ConsumerWidget {
  const CotimaxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final presentation = ref.watch(appPresentationSettingsProvider);
    syncAppPresentationSettings(presentation);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cotimax',
      theme: AppTheme.light(),
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) =>
          ToastViewport(child: child ?? const SizedBox.shrink()),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'MX'), Locale('en', 'US')],
      locale: presentation.locale,
      routerConfig: router,
    );
  }
}
