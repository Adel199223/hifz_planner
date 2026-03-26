import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/audio_platform_bootstrap.dart';
import 'app/app_preferences.dart';
import 'app/router.dart';
import 'data/providers/database_providers.dart';
import 'l10n/app_language.dart';
import 'theme/quran_themes.dart';

Object? _webSemanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ensurePlatformAudioInitialized();
  if (kIsWeb) {
    _webSemanticsHandle ??= WidgetsBinding.instance.ensureSemantics();
  }
  runApp(
    ProviderScope(
      overrides: [
        ayahAudioServiceProvider.overrideWith(createStreamingAyahAudioService),
      ],
      child: const HifzPlannerApp(),
    ),
  );
}

class HifzPlannerApp extends ConsumerWidget {
  const HifzPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preferences = ref.watch(appPreferencesProvider);

    return MaterialApp.router(
      title: 'Hifz Planner',
      debugShowCheckedModeBanner: false,
      theme: QuranThemes.sepia(),
      darkTheme: QuranThemes.dark(),
      themeMode: preferences.theme == AppThemeChoice.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      locale: preferences.language.locale,
      supportedLocales: AppLanguage.values
          .map((language) => language.locale)
          .toList(growable: false),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

