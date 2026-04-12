import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/app_router.dart';
import 'package:cotimax/core/theme/app_theme.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CotimaxApp extends ConsumerWidget {
  const CotimaxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final presentation = ref.watch(appPresentationSettingsProvider);
    final showThemeOverlay = ref.watch(themeOverlayVisibleProvider);
    syncAppPresentationSettings(presentation);
    AppColors.syncThemeMode(presentation.themeMode);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cotimax',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: presentation.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) => Stack(
        children: [
          KeyedSubtree(
            key: ValueKey(
              'app-${presentation.themeMode.name}-${presentation.locale.toLanguageTag()}',
            ),
            child: ToastViewport(child: child ?? const SizedBox.shrink()),
          ),
          IgnorePointer(
            ignoring: !showThemeOverlay,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: showThemeOverlay
                  ? ColoredBox(
                      key: const ValueKey('theme-loading-overlay'),
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Center(
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 2.8),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      localizationsDelegates: const [
        quill.FlutterQuillLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('es', 'MX'), Locale('en', 'US')],
      locale: presentation.locale,
      routerConfig: router,
    );
  }
}
