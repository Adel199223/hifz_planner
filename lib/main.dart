import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app/app_preferences.dart';
import 'app/router.dart';
import 'data/providers/database_providers.dart';
import 'l10n/app_language.dart';
import 'theme/quran_themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized(
    windows: true,
    linux: true,
  );
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
