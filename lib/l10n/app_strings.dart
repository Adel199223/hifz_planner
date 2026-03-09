import 'app_language.dart';

class AppStrings {
  const AppStrings._(this.appLanguage);

  final AppLanguage appLanguage;

  static AppStrings of(AppLanguage language) => AppStrings._(language);

  String _t(String key, String english) {
    final languageOverrides = _overrides[appLanguage];
    return languageOverrides?[key] ?? english;
  }

  String _fmt(String template, Map<String, Object?> values) {
    var result = template;
    values.forEach((key, value) {
      result = result.replaceAll('{$key}', '${value ?? ''}');
    });
    return result;
  }

  String get menu => _t('menu', 'Menu');
  String get close => _t('close', 'Close');
  String get language => _t('language', 'Language');
  String get changeTheme => _t('change_theme', 'Change Theme');
  String get themeSepia => _t('theme_sepia', 'Sepia');
  String get themeDark => _t('theme_dark', 'Dark');
  String get read => _t('read', 'Read');
  String get learn => _t('learn', 'Learn');
  String get myQuran => _t('my_quran', 'My Quran');
  String get myQuranSubtitle => _t(
    'my_quran_subtitle',
    'Keep your place, saved study, and listening setup together.',
  );
  String get quranRadio => _t('quran_radio', 'Quran Radio');
  String get reciters => _t('reciters', 'Reciters');
  String get reader => _t('reader', 'Reader');
  String get bookmarks => _t('bookmarks', 'Bookmarks');
  String get notes => _t('notes', 'Notes');
  String get plan => _t('plan', 'Plan');
  String get myPlan => _t('my_plan', 'My Plan');
  String get today => _t('today', 'Today');
  String get library => _t('library', 'Library');
  String get settings => _t('settings', 'Settings');
  String get about => _t('about', 'About');
  String get tools => _t('tools', 'Tools');
  String get explore => _t('explore', 'Explore');
  String get retry => _t('retry', 'Retry');
  String get done => _t('done', 'Done');
  String get reset => _t('reset', 'Reset');
  String get save => _t('save', 'Save');
  String get cancel => _t('cancel', 'Cancel');
  String get copy => _t('copy', 'Copy');
  String get share => _t('share', 'Share');
  String get more => _t('more', 'More');
  String get comingSoon => _t('coming_soon', 'Coming soon.');
  String get myQuranContinueReadingTitle =>
      _t('my_quran_continue_reading_title', 'Continue reading');
  String get myQuranContinueReadingButton =>
      _t('my_quran_continue_reading_button', 'Continue reading');
  String get myQuranContinueReadingFallback =>
      _t('my_quran_continue_reading_fallback', 'Start from Reader');
  String get myQuranContinueReadingDescription => _t(
    'my_quran_continue_reading_description',
    'Pick up where you last opened Reader.',
  );
  String get myQuranNoRecentReading => _t(
    'my_quran_no_recent_reading',
    'No recent reading saved yet. Open Reader to start from a place you can return to later.',
  );
  String myQuranResumeFromPage(int pageNumber) => _fmt(
    _t('my_quran_resume_from_page', 'Resume on Page {page}'),
    <String, Object>{'page': pageNumber},
  );
  String myQuranResumeVerse(int surah, int ayah) => _fmt(
    _t(
      'my_quran_resume_verse',
      'Resume Surah {surah}, Ayah {ayah}',
    ),
    <String, Object>{'surah': surah, 'ayah': ayah},
  );
  String get myQuranOpenReader => _t('my_quran_open_reader', 'Open Reader');
  String get myQuranSavedForLaterTitle =>
      _t('my_quran_saved_for_later_title', 'Saved for later');
  String myQuranSavedCounts(int bookmarks, int notes) => _fmt(
    _t('my_quran_saved_counts', 'Bookmarks: {bookmarks} · Notes: {notes}'),
    <String, Object>{'bookmarks': bookmarks, 'notes': notes},
  );
  String get myQuranNoSavedItems => _t(
    'my_quran_no_saved_items',
    'No saved items yet. Use Save for later or notes while you read.',
  );
  String get myQuranSavedForLaterDescription => _t(
    'my_quran_saved_for_later_description',
    'Open Library to revisit saved verses and notes.',
  );
  String get myQuranLatestBookmark =>
      _t('my_quran_latest_bookmark', 'Latest bookmark');
  String get myQuranLatestNote =>
      _t('my_quran_latest_note', 'Latest note');
  String myQuranLatestNoteSummary(String title, String body) => _fmt(
    _t('my_quran_latest_note_summary', '{title}: {body}'),
    <String, Object>{'title': title, 'body': body},
  );
  String get myQuranOpenLibrary => _t('my_quran_open_library', 'Open Library');
  String get myQuranListeningSetupTitle =>
      _t('my_quran_listening_setup_title', 'Listening setup');
  String myQuranListeningSetupSummary(String speed, String repeat) => _fmt(
    _t('my_quran_listening_setup_summary', 'Speed {speed} · Repeat {repeat}'),
    <String, Object>{'speed': speed, 'repeat': repeat},
  );
  String get myQuranOpenReciters =>
      _t('my_quran_open_reciters', 'Open Reciters');
  String get myQuranLoadFailed =>
      _t('my_quran_load_failed', 'Failed to load My Quran.');
  String get myQuranStudySetupTitle =>
      _t('my_quran_study_setup_title', 'Study setup');
  String get myQuranStudySetupDescription => _t(
    'my_quran_study_setup_description',
    'Choose the meaning help you want in Reader and whether Practice from Memory should autoplay the next ayah.',
  );
  String myQuranMeaningSetupSummary(
    String translation,
    String wordHelp,
    String transliteration,
  ) => _fmt(
    _t(
      'my_quran_meaning_setup_summary',
      'Meaning help: translation {translation}, word help {wordHelp}, transliteration {transliteration}.',
    ),
    <String, Object>{
      'translation': translation,
      'wordHelp': wordHelp,
      'transliteration': transliteration,
    },
  );
  String myQuranPracticeSetupSummary(String autoplay) => _fmt(
    _t(
      'my_quran_practice_setup_summary',
      'Practice from Memory: autoplay {autoplay}.',
    ),
    <String, Object>{'autoplay': autoplay},
  );
  String get myQuranStudySetupReciterHint => _t(
    'my_quran_study_setup_reciter_hint',
    'Use Listening setup if you want to change reciter.',
  );
  String get onLabel => _t('on_label', 'On');
  String get offLabel => _t('off_label', 'Off');
  String get unknown => _t('unknown', 'Unknown');
  String get practiceFromMemoryTitle =>
      _t('practice_from_memory_title', 'Practice from Memory');
  String get startNewPractice => _t('start_new_practice', 'Start new practice');
  String get continueReviewPractice =>
      _t('continue_review_practice', 'Continue review practice');
  String get doDelayedCheck => _t('do_delayed_check', 'Do delayed check');

  String get verseByVerse => _t('verse_by_verse', 'Verse by Verse');
  String get reading => _t('reading', 'Reading');
  String get surah => _t('surah', 'Surah');
  String get verse => _t('verse', 'Verse');
  String get juz => _t('juz', 'Juz');
  String get page => _t('page', 'Page');
  String get listen => _t('listen', 'Listen');
  String get playFromHere => _t('play_from_here', 'Play from here');
  String get pause => _t('pause', 'Pause');
  String get resume => _t('resume', 'Resume');
  String get next => _t('next', 'Next');
  String get previous => _t('previous', 'Previous');
  String get audioOptions => _t('audio_options', 'Audio options');
  String get download => _t('download', 'Download');
  String get manageRepeatSettings =>
      _t('manage_repeat_settings', 'Manage repeat settings');
  String get experience => _t('experience', 'Experience');
  String get playbackSpeed => _t('playback_speed', 'Speed');
  String get repeat => _t('repeat', 'Repeat');
  String get repeatOff => _t('repeat_off', 'Off');
  String get repeat1x => _t('repeat_1x', '1x');
  String get repeat2x => _t('repeat_2x', '2x');
  String get repeat3x => _t('repeat_3x', '3x');
  String get selectReciter => _t('select_reciter', 'Select Reciter');
  String get searchReciter => _t('search_reciter', 'Search Reciter');
  String get tajweedColors => _t('tajweed_colors', 'Tajweed colors');
  String get tajweedLegendSilentLetter =>
      _t('tajweed_legend_silent_letter', 'Silent letter');
  String get tajweedLegendNormalMadd2 =>
      _t('tajweed_legend_normal_madd_2', 'Normal madd (2)');
  String get tajweedLegendSeparatedMadd246 =>
      _t('tajweed_legend_separated_madd_246', 'Separated madd (2/4/6)');
  String get tajweedLegendConnectedMadd45 =>
      _t('tajweed_legend_connected_madd_45', 'Connected madd (4/5)');
  String get tajweedLegendNecessaryMadd6 =>
      _t('tajweed_legend_necessary_madd_6', 'Necessary madd (6)');
  String get tajweedLegendGhunnaIkhfa =>
      _t('tajweed_legend_ghunna_ikhfa', "Ghunna/ikhfa'");
  String get tajweedLegendQalqalaEcho =>
      _t('tajweed_legend_qalqala_echo', 'Qalqala (echo)');
  String get tajweedLegendTafkhimHeavy =>
      _t('tajweed_legend_tafkhim_heavy', 'Tafkhim (heavy)');
  String get translation => _t('translation', 'Translation');
  String get arabic => _t('arabic', 'Arabic');
  String get wordByWord => _t('word_by_word', 'Word help');
  String get tafsirs => _t('tafsirs', 'Tafsirs');
  String get lessons => _t('lessons', 'Lessons');
  String get reflections => _t('reflections', 'Reflections');

  String get bookmarkVerse => _t('bookmark_verse', 'Save for later');
  String get addEditNote => _t('add_edit_note', 'Add/Edit note');
  String get copyTextUthmani => _t('copy_text_uthmani', 'Copy text (Uthmani)');
  String get studyThisVerse => _t('study_this_verse', 'Study this verse');
  String get openSettings => _t('open_settings', 'Open settings');
  String get closeSettings => _t('close_settings', 'Close settings');
  String get translationUnavailable =>
      _t('translation_unavailable', 'Translation unavailable');
  String get meaningUnavailable =>
      _t('meaning_unavailable', 'Meaning unavailable for this word.');
  String get meaningAidsOff => _t('meaning_aids_off', 'Meaning aids are off.');
  String get scriptStyle => _t('script_style', 'Script style');
  String get uthmani => _t('uthmani', 'Uthmani');
  String get tajweed => _t('tajweed', 'Tajweed');
  String get indoPakSoon => _t('indopak_soon', 'IndoPak (Soon)');
  String get showTajweedRulesWhileReading => _t(
    'show_tajweed_rules_while_reading',
    'Show Tajweed rules while reading',
  );
  String get fontSize => _t('font_size', 'Font size');
  String get selectedReciter => _t('selected_reciter', 'Selected Reciter');
  String get preview => _t('preview', 'Preview');
  String get word => _t('word', 'Word');
  String get transliteration => _t('transliteration', 'Transliteration');
  String get showVerseTranslation =>
      _t('show_verse_translation', 'Show verse translation');
  String get showWordHelp => _t('show_word_help', 'Show word help');
  String get showTransliteration =>
      _t('show_transliteration', 'Show transliteration');
  String get wordHelp => _t('word_help', 'Word help');
  String get wordHelpUnavailableForVerse => _t(
    'word_help_unavailable_for_verse',
    'Word help is unavailable for this verse right now.',
  );
  String get wordHelpDescription => _t(
    'word_help_description',
    'Word help appears when you hover or tap a word in Reading mode.',
  );
  String get hoverWordToPreviewMeaning => _t(
    'hover_word_to_preview_meaning',
    'Hover or tap a word to preview meaning.',
  );
  String get basmalaTranslation => _t(
    'basmala_translation',
    'In the Name of Allah - the Most Compassionate, Most Merciful',
  );

  String translationLabel(String label) => _fmt(
    _t('translation_label', 'Translation: {label}'),
    <String, Object>{'label': label},
  );
  String translationFollowsAppLanguage(String label) => _fmt(
    _t(
      'translation_follows_app_language',
      'Translation follows the app language right now: {label}.',
    ),
    <String, Object>{'label': label},
  );
  String pageLabel(int pageNumber) => _fmt(
    _t('page_label', 'Page {page}'),
    <String, Object>{'page': pageNumber},
  );
  String juzLabel(int juzNumber) =>
      _fmt(_t('juz_label', 'Juz {juz}'), <String, Object>{'juz': juzNumber});
  String hizbLabel(int hizbNumber) => _fmt(
    _t('hizb_label', 'Hizb {hizb}'),
    <String, Object>{'hizb': hizbNumber},
  );
  String surahLabel(int surahNumber) => _fmt(
    _t('surah_label', 'Surah {surah}'),
    <String, Object>{'surah': surahNumber},
  );
  String ayahLabel(int ayahNumber) => _fmt(
    _t('ayah_label', 'Ayah {ayah}'),
    <String, Object>{'ayah': ayahNumber},
  );
  String surahAyahLabel(int surahNumber, int ayahNumber) => _fmt(
    _t('surah_ayah_label', '{surah}:{ayah}'),
    <String, Object>{'surah': surahNumber, 'ayah': ayahNumber},
  );

  String get learnTitle => _t('learn_title', 'Learning Plans');
  String get learnSubtitle => _t(
    'learn_subtitle',
    'Start practice from memory or adjust your long-term Quran plan.',
  );
  String get learnPracticeFromMemoryTitle =>
      _t('learn_practice_from_memory_title', 'Practice from Memory');
  String get learnPracticeFromMemorySubtitle => _t(
    'learn_practice_from_memory_subtitle',
    'Choose a simple practice path for today. If a direct session is not ready yet, the app will guide you through Today.',
  );
  String get learnPracticeOrderTitle =>
      _t('learn_practice_order_title', 'Best order for today');
  String get learnPracticeOrderFirst => _t(
    'learn_practice_order_first',
    '1. Do delayed check first when it is ready.',
  );
  String get learnPracticeOrderSecond => _t(
    'learn_practice_order_second',
    '2. Continue review practice before adding new work.',
  );
  String get learnPracticeOrderThird => _t(
    'learn_practice_order_third',
    '3. Start new practice after review feels stable.',
  );
  String get learnPracticeNewSubtitle => _t(
    'learn_practice_new_subtitle',
    'Begin today’s next new portion with guided practice.',
  );
  String get learnPracticeReviewSubtitle => _t(
    'learn_practice_review_subtitle',
    'Return to the oldest due portion first.',
  );
  String get learnPracticeDelayedCheckSubtitle => _t(
    'learn_practice_delayed_check_subtitle',
    'Protect recent memorization with a delayed recall check.',
  );
  String get learnPracticeDirectStatus =>
      _t('learn_practice_direct_status', 'Ready now');
  String get learnPracticeFallbackStatus =>
      _t('learn_practice_fallback_status', 'Opens Today for guidance');
  String get learnPracticeFallbackNote => _t(
    'learn_practice_fallback_note',
    'If a direct session is not ready yet, this opens Today and guides your next best practice step.',
  );
  String get hifzPlanTitle => _t('hifz_plan_title', 'Hifz Plan');
  String get hifzPlanSubtitle =>
      _t('hifz_plan_subtitle', 'Create and maintain your memorization plan.');
  String get openHifzPlan => _t('open_hifz_plan', 'Open Hifz Plan');
  String get aboutTitle => _t('about_title', 'About');

  String get bookmarksTitle => _t('bookmarks_title', 'Bookmarks');
  String get libraryTitle => _t('library_title', 'Library');
  String get librarySubtitle =>
      _t('library_subtitle', 'Keep your saved places and notes together.');
  String get libraryBookmarksDescription => _t(
    'library_bookmarks_description',
    'Reopen saved verses and continue studying where you left off.',
  );
  String get libraryNotesDescription => _t(
    'library_notes_description',
    'Review your verse notes with enough context to keep studying.',
  );
  String get todayOtherPracticeModesTitle =>
      _t('today_other_practice_modes_title', 'Other practice modes today');
  String get todayOtherPracticeModesHint => _t(
    'today_other_practice_modes_hint',
    'If you still have time, you can switch to one of these next.',
  );
  String get openBookmarks => _t('open_bookmarks', 'Open Bookmarks');
  String get openNotes => _t('open_notes', 'Open Notes');
  String get failedToLoadBookmarks =>
      _t('failed_to_load_bookmarks', 'Failed to load bookmarks.');
  String get failedToLoadReciters =>
      _t('failed_to_load_reciters', 'Failed to load reciters.');
  String get noBookmarksYet => _t('no_bookmarks_yet', 'No bookmarks yet.');
  String savedLabel(String timestamp) => _fmt(
    _t('saved_label', 'Saved {timestamp}'),
    <String, Object>{'timestamp': timestamp},
  );
  String get savedForLaterStudy =>
      _t('saved_for_later_study', 'Saved for later study');
  String surahAyahListLabel(int surahNumber, int ayahNumber) => _fmt(
    _t('surah_ayah_list_label', 'Surah {surah}, Ayah {ayah}'),
    <String, Object>{'surah': surahNumber, 'ayah': ayahNumber},
  );
  String get goToVerse => _t('go_to_verse', 'Reopen in Reader');
  String get goToPage => _t('go_to_page', 'Go to page');

  String get notesTitle => _t('notes_title', 'Notes');
  String get failedToLoadNotes =>
      _t('failed_to_load_notes', 'Failed to load notes.');
  String get noNotesYet => _t('no_notes_yet', 'No notes yet.');
  String get untitled => _t('untitled', 'Untitled');
  String get noteUpdated => _t('note_updated', 'Note updated.');
  String get noteUpdateFailed =>
      _t('note_update_failed', 'Note update failed.');
  String get noteSaveFailed => _t('note_save_failed', 'Failed to save note.');
  String get failedToUpdateNote =>
      _t('failed_to_update_note', 'Failed to update note.');
  String get addNote => _t('add_note', 'Add note');
  String get editNote => _t('edit_note', 'Edit note');
  String get noteTitleOptional => _t('note_title_optional', 'Title (optional)');
  String get noteBody => _t('note_body', 'Note body');
  String get bodyRequired => _t('body_required', 'Body is required.');
  String linkedVerseLabel(int surahNumber, int ayahNumber, {int? pageNumber}) {
    final template = pageNumber == null
        ? _t('linked_verse', 'Linked verse: Surah {surah}, Ayah {ayah}')
        : _t(
            'linked_verse_with_page',
            'Linked verse: Surah {surah}, Ayah {ayah} (Page {page})',
          );
    return _fmt(template, <String, Object?>{
      'surah': surahNumber,
      'ayah': ayahNumber,
      'page': pageNumber,
    });
  }

  String get settingsTitle => _t('settings_title', 'Settings');
  String get readyToImportBundledQuranAssets => _t(
    'ready_to_import_bundled_quran_assets',
    "Ready to import bundled Qur'an assets.",
  );
  String get startingQuranTextImport =>
      _t('starting_quran_text_import', "Starting Qur'an text import...");
  String get alreadyImported => _t('already_imported', 'Already imported');
  String get importSkippedAyahTableHasData => _t(
    'import_skipped_ayah_table_has_data',
    'Import skipped: ayah table already has data.',
  );
  String importCompleteSummary(int insertedRows, int ignoredRows) => _fmt(
    _t(
      'import_complete_summary',
      'Import complete: {inserted} inserted, {ignored} ignored.',
    ),
    <String, Object>{'inserted': insertedRows, 'ignored': ignoredRows},
  );
  String quranTextImportFailed(String error) => _fmt(
    _t('quran_text_import_failed', "Qur'an text import failed: {error}"),
    <String, Object>{'error': error},
  );
  String get startingPageMetadataImport =>
      _t('starting_page_metadata_import', 'Starting page metadata import...');
  String get pageMetadataAlreadyUpToDate => _t(
    'page_metadata_already_up_to_date',
    'Page metadata already up to date',
  );
  String pageMetadataImportCompleteSummary({
    required int updatedRows,
    required int unchangedRows,
    required int missingRows,
    required int parsedRows,
  }) => _fmt(
    _t(
      'page_metadata_import_complete_summary',
      'Page metadata import complete: {updated} updated, {unchanged} unchanged, {missing} missing, {parsed} parsed.',
    ),
    <String, Object>{
      'updated': updatedRows,
      'unchanged': unchangedRows,
      'missing': missingRows,
      'parsed': parsedRows,
    },
  );
  String pageMetadataImportFailed(String error) => _fmt(
    _t('page_metadata_import_failed', 'Page metadata import failed: {error}'),
    <String, Object>{'error': error},
  );
  String get completed => _t('completed', 'completed');
  String get importQuranText => _t('import_quran_text', "Import Qur'an Text");
  String get importPageMetadata =>
      _t('import_page_metadata', 'Import Page Metadata');

  String get todayTitle => _t('today_title', 'Today');
  String get todayDoThisNext => _t('today_do_this_next', 'Do this next');
  String get todayWhyItMatters =>
      _t('today_why_it_matters', 'Why it matters today');
  String get todayShortDayTitle =>
      _t('today_short_day_title', 'If you only have 10 minutes');
  String get todayOpenMyPlan => _t('today_open_my_plan', 'Open My Plan');
  String get todayRecoveryEntryHint => _t(
    'today_recovery_entry_hint',
    'Need a lighter day? Open My Plan to reduce today’s load or switch into recovery.',
  );
  String get todayRecoveryModeHint => _t(
    'today_recovery_mode_hint',
    'Recovery mode is active. Keep today light and protect review before new memorization.',
  );
  String get todayMinimumDayAction =>
      _t('today_minimum_day_action', 'Do the minimum day');
  String get todayMinimumDayHint => _t(
    'today_minimum_day_hint',
    'Minimum viable day: complete the top priority check or first review row, then stop without guilt.',
  );
  String get todayNewWorkPausedExplanation => _t(
    'today_new_work_paused_explanation',
    'New work is paused for now so delayed checks or overdue review can stabilize first.',
  );
  String get todayNewWorkReducedExplanation => _t(
    'today_new_work_reduced_explanation',
    'New work is lighter today because review pressure is taking more of the available time.',
  );
  String get recoveryAssistantTitle =>
      _t('recovery_assistant_title', 'Recovery assistant');
  String get recoveryAssistantQuestion =>
      _t('recovery_assistant_question', 'What happened most recently?');
  String get recoveryAssistantRecommendationTitle =>
      _t('recovery_assistant_recommendation_title', 'Recommended next step');
  String get recoveryScenarioMissedSession =>
      _t('recovery_scenario_missed_session', 'I missed one session');
  String get recoveryScenarioMissedDay =>
      _t('recovery_scenario_missed_day', 'I missed one full day');
  String get recoveryScenarioSeveralDays =>
      _t('recovery_scenario_several_days', 'I missed several days');
  String get recoveryScenarioHeavyBacklog => _t(
    'recovery_scenario_heavy_backlog',
    'My review backlog feels too heavy',
  );
  String get recoveryRecommendationMissedSession => _t(
    'recovery_recommendation_missed_session',
    'Use the minimum day first, finish one high-priority item, then continue only if time still feels realistic.',
  );
  String get recoveryRecommendationMissedDay => _t(
    'recovery_recommendation_missed_day',
    'Lower today’s expectations, clear delayed checks first, and reopen My Plan only if the next few days still look too heavy.',
  );
  String get recoveryRecommendationSeveralDays => _t(
    'recovery_recommendation_several_days',
    'Treat the next stretch as recovery: reduce new work, clear the oldest review and delayed checks, and rebuild normal pace gradually.',
  );
  String get recoveryRecommendationHeavyBacklog => _t(
    'recovery_recommendation_heavy_backlog',
    'Use backlog burn-down mode for a few days: protect review, pause aggressive new work, and let the queue shrink before speeding up again.',
  );
  String get todayFocusStage4Title =>
      _t('today_focus_stage4_title', 'Protect yesterday’s memorization first');
  String get todayFocusStage4Reason => _t(
    'today_focus_stage4_reason',
    'Delayed checks come first because they confirm the newest memorization stayed strong.',
  );
  String get todayFocusStage4ShortDay => _t(
    'today_focus_stage4_short_day',
    'Start the first delayed check. Even one strong check protects the most fragile work.',
  );
  String get todayFocusStage4Action =>
      _t('today_focus_stage4_action', 'Do delayed check');
  String get todayFocusReviewTitle =>
      _t('today_focus_review_title', 'Clear the oldest due review first');
  String get todayFocusReviewReason => _t(
    'today_focus_review_reason',
    'Review comes before new memorization so earlier work stays reliable.',
  );
  String get todayFocusReviewShortDay => _t(
    'today_focus_review_short_day',
    'Finish the first review practice and leave the rest for later.',
  );
  String get todayFocusReviewAction =>
      _t('today_focus_review_action', 'Continue review practice');
  String get todayFocusNewTitle =>
      _t('today_focus_new_title', 'Today is clear for new memorization');
  String get todayFocusNewReason => _t(
    'today_focus_new_reason',
    'Delayed checks and due review are under control, so you can spend today’s energy on one new portion.',
  );
  String get todayFocusNewShortDay => _t(
    'today_focus_new_short_day',
    'Start the first new practice session and stop after one strong pass if time is tight.',
  );
  String get todayFocusNewAction =>
      _t('today_focus_new_action', 'Start new practice');
  String get todayCompletionTitle =>
      _t('today_completion_title', 'You are done for today');
  String get todayCompletionMessage => _t(
    'today_completion_message',
    'Today’s planned memorization and review are complete.',
  );
  String get todayCompletionStartTitle =>
      _t('today_completion_start_title', 'A real start counts');
  String get todayCompletionStartMessage => _t(
    'today_completion_start_message',
    'You finished a real day of practice. That is enough to start building consistency.',
  );
  String get todayCompletionSparseTitle =>
      _t('today_completion_sparse_title', 'A calm restart still counts');
  String get todayCompletionSparseMessage => _t(
    'today_completion_sparse_message',
    'You completed real work today. A few calm days like this are enough to rebuild trust in the plan.',
  );
  String get todayCompletionRecoveryTitle =>
      _t('today_completion_recovery_title', 'Recovery work still counts');
  String get todayCompletionRecoveryMessage => _t(
    'today_completion_recovery_message',
    'You protected retention with a lighter day. That is a safe win while the plan is stabilizing.',
  );
  String get todayEmptyTitle =>
      _t('today_empty_title', 'Nothing is scheduled yet');
  String get todayEmptyMessage => _t(
    'today_empty_message',
    'Open My Plan to set a realistic daily rhythm and see today’s next steps here.',
  );
  String get todayEmptySparseTitle =>
      _t('today_empty_sparse_title', 'Today can stay light');
  String get todayEmptySparseMessage => _t(
    'today_empty_sparse_message',
    'You are getting back into rhythm. Open My Plan if you want a clearer next step for the week.',
  );
  String get todayEmptyRecoveryTitle =>
      _t('today_empty_recovery_title', 'A recovery pause can be intentional');
  String get todayEmptyRecoveryMessage => _t(
    'today_empty_recovery_message',
    'The planner is keeping today light so you can stabilize safely. Open My Plan if you want to review or lighten the week further.',
  );
  String get plannedReviews => _t('planned_reviews', 'Planned Reviews');
  String get noPlannedReviewsLeft =>
      _t('no_planned_reviews_left', 'No planned reviews left.');
  String dueDayLabel(int dueDay) => _fmt(
    _t('due_day_label', 'Due day {day}'),
    <String, Object>{'day': dueDay},
  );
  String get newMemorization => _t('new_memorization', 'New Memorization');
  String get noPlannedNewUnitsLeft =>
      _t('no_planned_new_units_left', 'No planned new units left.');
  String get openInReader => _t('open_in_reader', 'Open in Reader');
  String get openCompanionChain =>
      _t('open_companion_chain', 'Open Companion Chain');
  String get stage4DueSectionTitle =>
      _t('stage4_due_section_title', 'Delayed checks');
  String get todayStage4Explanation => _t(
    'today_stage4_explanation',
    'Delayed checks come first because they test whether recent memorization stayed strong.',
  );
  String get stage4NoDueItems =>
      _t('stage4_no_due_items', 'No delayed checks are due.');
  String stage4TierSummary(
    int emerging,
    int ready,
    int stable,
    int maintained,
  ) => _fmt(
    _t(
      'stage4_tier_summary',
      'Tiers - Emerging: {emerging}, Ready: {ready}, Stable: {stable}, Maintained: {maintained}',
    ),
    <String, Object>{
      'emerging': emerging,
      'ready': ready,
      'stable': stable,
      'maintained': maintained,
    },
  );
  String get stage4DueKindPreSleepOptional =>
      _t('stage4_due_kind_pre_sleep_optional', 'Pre-sleep optional check');
  String get stage4DueKindNextDayRequired =>
      _t('stage4_due_kind_next_day_required', 'Next-day required check');
  String get stage4DueKindRetryRequired =>
      _t('stage4_due_kind_retry_required', 'Retry required');
  String stage4DueItemSummary(
    String dueKind,
    int overdueDays,
    int unresolvedTargets,
  ) => _fmt(
    _t(
      'stage4_due_item_summary',
      '{dueKind} - overdue {overdueDays}d - unresolved targets {unresolvedTargets}',
    ),
    <String, Object>{
      'dueKind': dueKind,
      'overdueDays': overdueDays,
      'unresolvedTargets': unresolvedTargets,
    },
  );
  String get stage4OpenAction => _t('stage4_open_action', 'Do delayed check');
  String get stage4OverrideNewAction =>
      _t('stage4_override_new_action', 'Override once and allow new practice');
  String get stage4OverrideDialogTitle =>
      _t('stage4_override_dialog_title', 'Delayed check override');
  String get stage4OverrideDialogMessage => _t(
    'stage4_override_dialog_message',
    'A required delayed check is still due. Continue anyway and log the override?',
  );
  String get stage4OverrideDialogConfirm =>
      _t('stage4_override_dialog_confirm', 'Override');
  String get stage4OverrideApplied => _t(
    'stage4_override_applied',
    'Override logged. New practice unlocked for today.',
  );
  String get stage4OverrideFailed =>
      _t('stage4_override_failed', 'Failed to log override. Please try again.');
  String get pageMetadataRequiredToOpenInReader => _t(
    'page_metadata_required_to_open_in_reader',
    'Page metadata required to open in Reader.',
  );
  String get selfCheckGrade => _t('self_check_grade', 'Self-check grade');
  String plannedReviewMinutes(Object value) => _fmt(
    _t('planned_review_minutes', 'Planned review minutes: {value}'),
    <String, Object>{'value': value},
  );
  String plannedNewMinutes(Object value) => _fmt(
    _t('planned_new_minutes', 'Planned new minutes: {value}'),
    <String, Object>{'value': value},
  );
  String reviewPressureLabel(Object value) => _fmt(
    _t('review_pressure_label', 'Review pressure: {value}'),
    <String, Object>{'value': value},
  );
  String get recoveryModeActive => _t(
    'recovery_mode_active',
    'Recovery mode active: new memorization paused',
  );
  String get todaySessions => _t('today_sessions', 'Today Sessions');
  String get noSessionsPlanned =>
      _t('no_sessions_planned', 'No sessions planned.');
  String get newAndReviewFocus => _t('new_and_review_focus', 'New + Review');
  String get reviewOnlyFocus => _t('review_only_focus', 'Review-only');
  String get sessionStatusPending => _t('session_status_pending', 'pending');
  String get sessionStatusCompleted =>
      _t('session_status_completed', 'completed');
  String get sessionStatusMissed => _t('session_status_missed', 'missed');
  String get sessionStatusDueSoon => _t('session_status_due_soon', 'due-soon');
  String sessionMinutes(int minutes) => _fmt(
    _t('session_minutes', '{minutes} min'),
    <String, Object>{'minutes': minutes},
  );
  String get untimedSessionLabel => _t('untimed_session_label', 'Untimed');
  String get failedToLoadTodayPlan =>
      _t('failed_to_load_today_plan', 'Failed to load today plan.');
  String get gradeSaved => _t('grade_saved', 'Grade saved.');
  String get failedToSaveGrade =>
      _t('failed_to_save_grade', 'Failed to save grade.');
  String get rangeUnavailable => _t('range_unavailable', 'Range unavailable');
  String get gradeGood => _t('grade_good', 'Good');
  String get gradeMedium => _t('grade_medium', 'Medium');
  String get gradeHard => _t('grade_hard', 'Hard');
  String get gradeVeryHard => _t('grade_very_hard', 'Very hard');
  String get gradeFail => _t('grade_fail', 'Fail');

  String get planSetupTitle => _t('plan_setup_title', 'Set up My Plan');
  String get planSetupSubtitle => _t(
    'plan_setup_subtitle',
    'Pick a pace, choose realistic time, and activate your plan. You can fine-tune the details later.',
  );
  String get planPresetQuestion =>
      _t('plan_preset_question', '1) How ambitious should this plan be?');
  String get planPresetEasy => _t('plan_preset_easy', 'Easy');
  String get planPresetEasyDescription => _t(
    'plan_preset_easy_description',
    'Protect review first and keep new work light.',
  );
  String get planPresetNormal => _t('plan_preset_normal', 'Normal');
  String get planPresetNormalDescription => _t(
    'plan_preset_normal_description',
    'Balanced new memorization with strong review support.',
  );
  String get planPresetIntensive => _t('plan_preset_intensive', 'Intensive');
  String get planPresetIntensiveDescription => _t(
    'plan_preset_intensive_description',
    'Move faster if your schedule is stable.',
  );
  String get planGuidedNote => _t(
    'plan_guided_note',
    'If life is busy or you are catching up, start with Easy. You can still fine-tune revision-only behavior in Advanced.',
  );
  String get planAdvancedTitle => _t('plan_advanced_title', 'Advanced');
  String get planAdvancedSubtitle => _t(
    'plan_advanced_subtitle',
    'Open this only if you want to fine-tune scheduling, forecast, calibration, or recovery rules.',
  );
  String get planOpenAdvanced => _t('plan_open_advanced', 'Show Advanced');
  String get planHideAdvanced => _t('plan_hide_advanced', 'Hide Advanced');
  String get planFineTuneTitle =>
      _t('plan_fine_tune_title', 'Fine-tune this plan');
  String get planSummaryPace => _t('plan_summary_pace', 'Pace');
  String get planSummaryTime => _t('plan_summary_time', 'Time');
  String get planSummaryNewLimit =>
      _t('plan_summary_new_limit', 'New work limit');
  String get planSummaryReviewPriority =>
      _t('plan_summary_review_priority', 'Review priority');
  String get planHealthTitle => _t('plan_health_title', 'Plan health');
  String get planHealthOnTrack => _t('plan_health_on_track', 'On track');
  String get planHealthTight => _t('plan_health_tight', 'Tight');
  String get planHealthOverloaded => _t('plan_health_overloaded', 'Overloaded');
  String get planHealthOnTrackSummary => _t(
    'plan_health_on_track_summary',
    'Review pressure is under control and the plan still has room for steady new memorization.',
  );
  String get planHealthTightSummary => _t(
    'plan_health_tight_summary',
    'Review and delayed checks are taking more of the day, so new work should stay lighter until pressure drops.',
  );
  String get planHealthOverloadedSummary => _t(
    'plan_health_overloaded_summary',
    'Delayed checks or review pressure are too heavy right now. Stabilize first, then add new work again.',
  );
  String get planBacklogBurnDownHint => _t(
    'plan_backlog_burn_down_hint',
    'Backlog burn-down: clear delayed checks and the oldest review first for the next few days before increasing new work.',
  );
  String get planMinimumDayHint => _t(
    'plan_minimum_day_hint',
    'If time collapses, use the minimum viable day in Today instead of abandoning the day completely.',
  );
  String get planRecoverySuggestionHint => _t(
    'plan_recovery_suggestion_hint',
    'If missed work keeps repeating, open the Recovery assistant from Today and switch to a lighter posture before the backlog grows.',
  );
  String get goalFocusTitle => _t('goal_focus_title', "This week's goal");
  String get goalFocusSteadyProgress =>
      _t('goal_focus_steady_progress', 'Steady progress');
  String get goalFocusProtectRetention =>
      _t('goal_focus_protect_retention', 'Protect retention');
  String get goalFocusRecoveryAndStabilize =>
      _t('goal_focus_recovery_and_stabilize', 'Recovery and stabilize');
  String get todayGoalGoodDayLabel =>
      _t('today_goal_good_day_label', 'A good day');
  String get todayGoalSupportLabel =>
      _t('today_goal_support_label', 'How today helps the goal');
  String get todayGoalShortDayLabel =>
      _t('today_goal_short_day_label', 'If the day gets short');
  String get todayGoalGoodDaySteady => _t(
    'today_goal_good_day_steady',
    'A good day means finishing the main task and, if time allows, the rest of today\'s planned work.',
  );
  String get todayGoalGoodDayProtect => _t(
    'today_goal_good_day_protect',
    'A good day means protecting due work first, even if new practice stays lighter.',
  );
  String get todayGoalGoodDayRecovery => _t(
    'today_goal_good_day_recovery',
    'A good day means doing the safest essential work without forcing a full load.',
  );
  String get todayGoalSupportSteady => _t(
    'today_goal_support_steady',
    'Today\'s main task supports steady progress by keeping your plan moving without overload.',
  );
  String get todayGoalSupportProtect => _t(
    'today_goal_support_protect',
    'Today\'s main task supports retention by protecting review and delayed checks first.',
  );
  String get todayGoalSupportRecovery => _t(
    'today_goal_support_recovery',
    'Today\'s main task supports recovery by lowering pressure and rebuilding consistency.',
  );
  String get todayGoalShortDaySteady => _t(
    'today_goal_short_day_steady',
    'On a short day, the top planned task still counts as a real win.',
  );
  String get todayGoalShortDayProtect => _t(
    'today_goal_short_day_protect',
    'On a short day, finishing the highest-priority due work is enough.',
  );
  String get todayGoalShortDayRecovery => _t(
    'today_goal_short_day_recovery',
    'On a short day, the minimum day is a success, not a setback.',
  );
  String get planGoalSummaryHint => _t(
    'plan_goal_summary_hint',
    'This changes automatically with your current plan pressure.',
  );
  String get planGoalSummaryHintStart => _t(
    'plan_goal_summary_hint_start',
    'Start with a few real sessions this week. The summary will fill in automatically.',
  );
  String get planGoalSummaryHintSparse => _t(
    'plan_goal_summary_hint_sparse',
    'A calm, repeatable week is enough. A few more real sessions will make this summary clearer.',
  );
  String get planGoalSummaryHintRecovery => _t(
    'plan_goal_summary_hint_recovery',
    'This week is about stabilizing safely, not proving speed.',
  );
  String get planGoalSummarySteady => _t(
    'plan_goal_summary_steady',
    'Your plan is light enough to aim for steady, sustainable progress this week.',
  );
  String get planGoalSummaryProtect => _t(
    'plan_goal_summary_protect',
    'Your plan should protect retention first this week, even if new work stays lighter.',
  );
  String get planGoalSummaryRecovery => _t(
    'plan_goal_summary_recovery',
    'Your safest weekly goal is to stabilize and reduce pressure before pushing harder.',
  );
  String get goalCoachingTitle =>
      _t('goal_coaching_title', 'Recommended adjustment');
  String get goalCoachingProgressRuleLabel =>
      _t('goal_coaching_progress_rule_label', 'What counts as progress');
  String get goalCoachingProgressRuleValue => _t(
    'goal_coaching_progress_rule_value',
    'Only real completed practice, review, or delayed check work counts. Opening a screen alone does not.',
  );
  String get goalCoachingStaySteadyTitle =>
      _t('goal_coaching_stay_steady_title', 'Stay steady');
  String get goalCoachingStaySteadyDetail => _t(
    'goal_coaching_stay_steady_detail',
    'Recent work looks steady enough that you do not need to tighten or lighten the plan right now.',
  );
  String get goalCoachingUseMinimumDayTitle =>
      _t('goal_coaching_use_minimum_day_title', 'Use the minimum day for now');
  String get goalCoachingUseMinimumDayDetail => _t(
    'goal_coaching_use_minimum_day_detail',
    'If time or energy is tight, finishing one safe essential task is enough to keep the plan alive today.',
  );
  String get goalCoachingProtectRetentionTitle => _t(
    'goal_coaching_protect_retention_title',
    'Protect retention for a few days',
  );
  String get goalCoachingProtectRetentionDetail => _t(
    'goal_coaching_protect_retention_detail',
    'Let reviews and delayed checks take the safer share of your time until the backlog and quality feel steadier again.',
  );
  String get goalCoachingLightenSetupTodayTitle => _t(
    'goal_coaching_lighten_setup_today_title',
    'Reopen My Plan and lighten the setup',
  );
  String get goalCoachingLightenSetupTodayDetail => _t(
    'goal_coaching_lighten_setup_today_detail',
    'Recent strain suggests the current setup is too heavy. Open My Plan and lower the load before the backlog grows.',
  );
  String get goalCoachingLightenSetupPlanTitle =>
      _t('goal_coaching_lighten_setup_plan_title', 'Lighten the setup here');
  String get goalCoachingLightenSetupPlanDetail => _t(
    'goal_coaching_lighten_setup_plan_detail',
    'Recent strain suggests the current setup is too heavy. Lower the guided load here before pushing harder again.',
  );
  String get weeklyProgressTitle => _t('weekly_progress_title', 'Last 7 days');
  String get weeklyProgressConsistencyLabel =>
      _t('weekly_progress_consistency_label', 'Consistency');
  String get weeklyProgressCompletedWorkLabel =>
      _t('weekly_progress_completed_work_label', 'Completed work');
  String get weeklyProgressRecentQualityLabel =>
      _t('weekly_progress_recent_quality_label', 'Recent review quality');
  String get weeklyProgressTrendStart => _t(
    'weekly_progress_trend_start',
    'Start building consistency with one real practice, review, or delayed check today.',
  );
  String get weeklyProgressTrendSteady => _t(
    'weekly_progress_trend_steady',
    'Your recent work supports a steady weekly rhythm.',
  );
  String get weeklyProgressTrendBuilding => _t(
    'weekly_progress_trend_building',
    'You are building consistency. Keep the main task simple and repeatable.',
  );
  String get weeklyProgressTrendSparse => _t(
    'weekly_progress_trend_sparse',
    'You are getting back into rhythm. A few calm, real sessions are enough this week.',
  );
  String get weeklyProgressTrendProtect => _t(
    'weekly_progress_trend_protect',
    'Recent work is happening, but retention still needs the safer share of your time.',
  );
  String get weeklyProgressTrendRecovery => _t(
    'weekly_progress_trend_recovery',
    'Recovery still counts. A lighter but real day protects the plan.',
  );
  String get weeklyProgressConsistencyStart => _t(
    'weekly_progress_consistency_start',
    'No meaningful history yet. One real day is enough to begin.',
  );
  String weeklyProgressConsistencyValue(int days) => _fmt(
    _t(
      'weekly_progress_consistency_value',
      '{days} active days in the last 7 days.',
    ),
    <String, Object>{'days': days},
  );
  String get weeklyProgressCountsStart => _t(
    'weekly_progress_counts_start',
    'Completed work will start showing here after your first real session.',
  );
  String weeklyProgressCountsValue(
    int reviews,
    int delayedChecks,
    int practiceCompletions,
  ) => _fmt(
    _t(
      'weekly_progress_counts_value',
      '{reviews} reviews, {delayedChecks} delayed checks, {practiceCompletions} practice completions.',
    ),
    <String, Object>{
      'reviews': reviews,
      'delayedChecks': delayedChecks,
      'practiceCompletions': practiceCompletions,
    },
  );
  String get weeklyProgressQualitySteady =>
      _t('weekly_progress_quality_steady', 'Mostly steady');
  String get weeklyProgressQualityMixed =>
      _t('weekly_progress_quality_mixed', 'Mixed');
  String get weeklyProgressQualityStrained =>
      _t('weekly_progress_quality_strained', 'Needs a gentler pace');
  String get weeklyProgressQualityNotEnoughData => _t(
    'weekly_progress_quality_not_enough_data',
    'Not enough review data yet',
  );
  String get weeklyProgressNoteLabel =>
      _t('weekly_progress_note_label', 'How to read this');
  String get weeklyProgressNoteStart => _t(
    'weekly_progress_note_start',
    'One real session is enough to begin. This block fills in automatically as you complete real work.',
  );
  String get weeklyProgressNoteSparse => _t(
    'weekly_progress_note_sparse',
    'A gentle return still counts. Keep the next few sessions simple and repeatable.',
  );
  String get weeklyProgressNoteSteady => _t(
    'weekly_progress_note_steady',
    'Keep repeating the main task and let steady days add up.',
  );
  String get weeklyProgressNoteProtect => _t(
    'weekly_progress_note_protect',
    'Let reviews and delayed checks keep the safer share of your time until pressure drops.',
  );
  String get weeklyProgressNoteRecovery => _t(
    'weekly_progress_note_recovery',
    'A lighter week still counts while the planner is helping you stabilize safely.',
  );
  String weeklyProgressRecentQualityLine(String value) => _fmt(
    _t('weekly_progress_recent_quality_line', 'Recent review quality: {value}'),
    <String, Object>{'value': value},
  );
  String planSummaryTimeValue(int weeklyMinutes, int dailyMinutes) => _fmt(
    _t(
      'plan_summary_time_value',
      '{weekly} minutes per week, about {daily} minutes per day.',
    ),
    <String, Object>{'weekly': weeklyMinutes, 'daily': dailyMinutes},
  );
  String planSummaryNewLimitValue(int pages, int units) => _fmt(
    _t(
      'plan_summary_new_limit_value',
      'Up to {pages} new pages or {units} new units on a study day.',
    ),
    <String, Object>{'pages': pages, 'units': units},
  );
  String get planReviewPriorityEasy => _t(
    'plan_review_priority_easy',
    'Give extra room to review and slow down new work when pressure rises.',
  );
  String get planReviewPriorityNormal => _t(
    'plan_review_priority_normal',
    'Keep a balanced mix of review protection and steady new memorization.',
  );
  String get planReviewPriorityIntensive => _t(
    'plan_review_priority_intensive',
    'Push new memorization harder when your schedule can support it.',
  );

  String onboardingQuestionnaire(int questionCount) => _fmt(
    _t(
      'onboarding_questionnaire',
      'Onboarding Questionnaire ({count} questions)',
    ),
    <String, Object>{'count': questionCount},
  );
  String get forecastDeterministicSimulation =>
      _t('forecast_deterministic_simulation', 'Forecast');
  String get automaticSchedulingTitle =>
      _t('automatic_scheduling_title', 'Automatic Scheduling');
  String get twoSessionsPerDay =>
      _t('two_sessions_per_day', '2 sessions per day');
  String get setExactTimesQuestion =>
      _t('set_exact_times_question', 'Set exact times?');
  String sessionTimeLabel(String sessionLabel, String value) => _fmt(
    _t('session_time_label', 'Session {session}: {value}'),
    <String, Object>{'session': sessionLabel, 'value': value},
  );
  String get studyDaysLabel => _t('study_days_label', 'Study days');
  String get advancedSchedulingMode =>
      _t('advanced_scheduling_mode', 'Advanced scheduling mode');
  String get availabilityModelLabel =>
      _t('availability_model_label', 'Availability model');
  String get availabilityMinutesPerDay =>
      _t('availability_minutes_per_day', 'Minutes per day');
  String get availabilityMinutesPerWeek =>
      _t('availability_minutes_per_week', 'Minutes per week');
  String get availabilitySpecificHours =>
      _t('availability_specific_hours', 'Specific hours (windows)');
  String get minutesPerDayLabel =>
      _t('minutes_per_day_label', 'Minutes per day');
  String get minutesPerWeekLabel =>
      _t('minutes_per_week_label', 'Minutes per week');
  String get timingStrategyLabel =>
      _t('timing_strategy_label', 'Timing strategy');
  String get timingStrategyUntimed => _t('timing_strategy_untimed', 'Untimed');
  String get timingStrategyFixed => _t('timing_strategy_fixed', 'Fixed times');
  String get timingStrategyAuto => _t('timing_strategy_auto', 'Auto-placement');
  String get flexOutsideWindowsLabel =>
      _t('flex_outside_windows_label', 'Allow placement outside windows');
  String get revisionOnlyDaysLabel =>
      _t('revision_only_days_label', 'Revision-only days');
  String get specificHoursWindowsLabel =>
      _t('specific_hours_windows_label', 'Specific hours windows');
  String get addWindowLabel => _t('add_window_label', 'Add window');
  String get noWindowsConfigured =>
      _t('no_windows_configured', 'No windows configured.');
  String get noWeeklyPlanYet =>
      _t('no_weekly_plan_yet', 'No weekly plan available yet.');
  String get weeklyCalendarTitle =>
      _t('weekly_calendar_title', 'Weekly Calendar (Next 7 Days)');
  String get dayMarkedHoliday =>
      _t('day_marked_holiday', 'Day marked as holiday.');
  String get dayNotEnabled =>
      _t('day_not_enabled', 'Day is not enabled for study.');
  String weeklySessionLine(
    String sessionLabel,
    String focus,
    int minutes,
    String timeLabel,
    String status,
  ) => _fmt(
    _t(
      'weekly_session_line',
      '{session} • {focus} • {minutes} min • {time} • {status}',
    ),
    <String, Object>{
      'session': sessionLabel,
      'focus': focus,
      'minutes': minutes,
      'time': timeLabel,
      'status': status,
    },
  );
  String get skipDayLabel => _t('skip_day_label', 'Skip day / holiday');
  String overrideSessionTime(String sessionLabel) => _fmt(
    _t('override_session_time', 'Override Session {session} time'),
    <String, Object>{'session': sessionLabel},
  );
  String get weekdayShortMon => _t('weekday_short_mon', 'Mon');
  String get weekdayShortTue => _t('weekday_short_tue', 'Tue');
  String get weekdayShortWed => _t('weekday_short_wed', 'Wed');
  String get weekdayShortThu => _t('weekday_short_thu', 'Thu');
  String get weekdayShortFri => _t('weekday_short_fri', 'Fri');
  String get weekdayShortSat => _t('weekday_short_sat', 'Sat');
  String get weekdayShortSun => _t('weekday_short_sun', 'Sun');
  String get runForecast => _t('run_forecast', 'Refresh Forecast');
  String get running => _t('running', 'Running...');
  String get forecastSummaryIntro => _t(
    'forecast_summary_intro',
    'Start with the plain-language summary, then use the details only if you need them.',
  );
  String get forecastSummarySteadyProgress => _t(
    'forecast_summary_steady_progress',
    'Your current plan looks sustainable if today’s pattern stays consistent.',
  );
  String get forecastSummaryWatchLoad => _t(
    'forecast_summary_watch_load',
    'You can keep moving, but review pressure is likely to slow new memorization.',
  );
  String get forecastSummaryProtectReview => _t(
    'forecast_summary_protect_review',
    'Review load is heavy right now. Protect retention first before expecting steady new work.',
  );
  String get forecastSummaryInsufficientData => _t(
    'forecast_summary_insufficient_data',
    'Forecast needs more usable data before it can give a reliable completion picture.',
  );
  String forecastConfidenceLine(String confidence) => _fmt(
    _t('forecast_confidence_line', 'Confidence: {confidence}'),
    <String, Object>{'confidence': confidence},
  );
  String get forecastConfidenceHigh => _t('forecast_confidence_high', 'High');
  String get forecastConfidenceMedium =>
      _t('forecast_confidence_medium', 'Medium');
  String get forecastConfidenceLow => _t('forecast_confidence_low', 'Low');
  String get forecastConfidenceHighHint => _t(
    'forecast_confidence_high_hint',
    'This estimate is backed by recent calibration and a stable planner signal.',
  );
  String forecastConfidenceMediumHint(int sampleCount) => _fmt(
    _t(
      'forecast_confidence_medium_hint',
      'This estimate is useful, but it still relies on some assumptions. Calibration samples logged: {count}.',
    ),
    <String, Object>{'count': sampleCount},
  );
  String forecastConfidenceLowHint(int sampleCount) => _fmt(
    _t(
      'forecast_confidence_low_hint',
      'This estimate is based on limited calibration or incomplete forecast data. Calibration samples logged: {count}.',
    ),
    <String, Object>{'count': sampleCount},
  );
  String get forecastPaceTrendAligned => _t(
    'forecast_pace_trend_aligned',
    'Recent calibration is close to your active pace, so the planner is staying near your current baseline.',
  );
  String get forecastPaceTrendSlightlySlower => _t(
    'forecast_pace_trend_slightly_slower',
    'Recent calibration is a bit slower than your active pace, so the planner is protecting a little more review time.',
  );
  String get forecastPaceTrendMuchSlower => _t(
    'forecast_pace_trend_much_slower',
    'Recent calibration is clearly slower than your active pace, so the planner is holding back new work more aggressively for now.',
  );
  String get forecastPaceTrendSlightlyFaster => _t(
    'forecast_pace_trend_slightly_faster',
    'Recent calibration is a bit faster than your active pace, so the planner can allow a little more new work while keeping review protected.',
  );
  String estimatedCompletion(String date) => _fmt(
    _t('estimated_completion', 'Estimated completion: {date}'),
    <String, Object>{'date': date},
  );
  String get completionEstimateUnavailable =>
      _t('completion_estimate_unavailable', 'Completion estimate unavailable.');
  String weeklyMinutesCurve(String curveText) => _fmt(
    _t('weekly_minutes_curve', 'Weekly minutes: {curve}'),
    <String, Object>{'curve': curveText},
  );
  String revisionOnlyRatioCurve(String curveText) => _fmt(
    _t('revision_only_ratio_curve', 'Revision-only ratio: {curve}'),
    <String, Object>{'curve': curveText},
  );
  String avgNewPagesPerDayCurve(String curveText) => _fmt(
    _t('avg_new_pages_per_day_curve', 'Avg new pages/day: {curve}'),
    <String, Object>{'curve': curveText},
  );
  String get suggestedPlanEditable =>
      _t('suggested_plan_editable', 'Your plan summary');
  String get dailyMinutesByWeekday =>
      _t('daily_minutes_by_weekday', 'Daily minutes by weekday');
  String derivedDailyDefault(int value) => _fmt(
    _t('derived_daily_default', 'Derived daily default: {value}'),
    <String, Object>{'value': value},
  );
  String weekdayMinutesChip(String dayKey, int minutes) => _fmt(
    _t('weekday_minutes_chip', '{day}: {minutes}'),
    <String, Object>{'day': dayKey, 'minutes': minutes},
  );
  String get avgNewMinutesPerAyah =>
      _t('avg_new_minutes_per_ayah', 'Avg new minutes per ayah');
  String get avgReviewMinutesPerAyah =>
      _t('avg_review_minutes_per_ayah', 'Avg review minutes per ayah');
  String get requirePageMetadata =>
      _t('require_page_metadata', 'Require page metadata');
  String get activating => _t('activating', 'Activating...');
  String get activate => _t('activate', 'Activate');
  String get calibrationModeOptional =>
      _t('calibration_mode_optional', 'Teach the planner your pace (optional)');
  String get calibrationIntro => _t(
    'calibration_intro',
    'Log a few real sessions so the planner can estimate your pace more realistically.',
  );
  String get newMemorizationSample =>
      _t('new_memorization_sample', 'New memorization sample');
  String get reviewSample => _t('review_sample', 'Review sample');
  String get addNewSample => _t('add_new_sample', 'Add new sample');
  String get addReviewSample => _t('add_review_sample', 'Add review sample');
  String newSamplesPreview(int count, String median) => _fmt(
    _t('new_samples_preview', 'New samples: {count}, median: {median}'),
    <String, Object>{'count': count, 'median': median},
  );
  String reviewSamplesPreview(int count, String median) => _fmt(
    _t('review_samples_preview', 'Review samples: {count}, median: {median}'),
    <String, Object>{'count': count, 'median': median},
  );
  String get typicalGradeDistributionPercent => _t(
    'typical_grade_distribution_percent',
    'Typical grade distribution (%)',
  );
  String get applyTiming => _t('apply_timing', 'Apply timing');
  String get applyNow => _t('apply_now', 'Use today');
  String get applyFromTomorrow =>
      _t('apply_from_tomorrow', 'Use starting tomorrow');
  String get applying => _t('applying', 'Applying...');
  String get applyCalibration => _t('apply_calibration', 'Use This Pace');
  String calibrationGuidanceNeedMore(int count) => _fmt(
    _t(
      'calibration_guidance_need_more',
      'You have {count} logged samples. Add a few more real sessions for a stronger estimate.',
    ),
    <String, Object>{'count': count},
  );
  String calibrationGuidanceReady(int count) => _fmt(
    _t(
      'calibration_guidance_ready',
      'You have {count} logged samples. This is enough to update the planner pace with reasonable confidence.',
    ),
    <String, Object>{'count': count},
  );
  String get timeInput => _t('time_input', '2) How much time is realistic?');
  String get weeklyTotal => _t('weekly_total', 'Weekly total');
  String get perWeekday => _t('per_weekday', 'Per weekday');
  String get weeklyMinutes => _t('weekly_minutes', 'Weekly minutes');
  String get fluency =>
      _t('fluency', '3) How comfortable are you with memorizing right now?');
  String get fluencyFluent => _t('fluency_fluent', 'fluent');
  String get fluencyDeveloping => _t('fluency_developing', 'developing');
  String get fluencySupport => _t('fluency_support', 'support');
  String get profile => _t('profile', 'Planner profile');
  String get profileSupport => _t('profile_support', 'support');
  String get profileStandard => _t('profile_standard', 'standard');
  String get profileAccelerated => _t('profile_accelerated', 'accelerated');
  String get forceRevisionOnly =>
      _t('force_revision_only', 'Protect review when overdue');
  String get dailyNewItemCaps =>
      _t('daily_new_item_caps', 'Daily new-work limits');
  String get maxNewPagesPerDay =>
      _t('max_new_pages_per_day', 'Max new pages per day');
  String get maxNewUnitsPerDay =>
      _t('max_new_units_per_day', 'Max new units per day');
  String get durationMinutes => _t('duration_minutes', 'Duration (minutes)');
  String get ayahCount => _t('ayah_count', 'Ayah count');
  String get enterValidPositiveValuesBeforeActivating => _t(
    'enter_valid_positive_values_before_activating',
    'Please enter valid positive values before activating.',
  );
  String get planActivatedSuccessfully =>
      _t('plan_activated_successfully', 'Plan activated successfully.');
  String get failedToActivatePlanTryAgain => _t(
    'failed_to_activate_plan_try_again',
    'Failed to activate plan. Please try again.',
  );
  String get enterPositiveDurationAndAyahCount => _t(
    'enter_positive_duration_and_ayah_count',
    'Enter positive duration and ayah count.',
  );
  String get calibrationSampleAdded =>
      _t('calibration_sample_added', 'Calibration sample added.');
  String failedToAddSample(String error) => _fmt(
    _t('failed_to_add_sample', 'Failed to add sample: {error}'),
    <String, Object>{'error': error},
  );
  String get calibrationAppliedImmediately =>
      _t('calibration_applied_immediately', 'Planner pace updated for today.');
  String get calibrationQueuedForTomorrow => _t(
    'calibration_queued_for_tomorrow',
    'Planner pace will update tomorrow.',
  );
  String calibrationApplyFailed(String error) => _fmt(
    _t('calibration_apply_failed', 'Could not update planner pace: {error}'),
    <String, Object>{'error': error},
  );
  String forecastFailed(String error) => _fmt(
    _t('forecast_failed', 'Forecast failed: {error}'),
    <String, Object>{'error': error},
  );

  String get companionProgressiveRevealTitle =>
      _t('companion_progressive_reveal_title', 'Progressive Reveal Chain');
  String get companionPracticeTitle =>
      _t('companion_practice_title', 'Practice from Memory');
  String companionCurrentVersePosition(int current, int total) => _fmt(
    _t('companion_current_verse_position', 'Verse {current} of {total}'),
    <String, Object>{'current': current, 'total': total},
  );
  String get companionActiveHintLabel =>
      _t('companion_active_hint_label', 'Current hint');
  String get companionHintLevelH0 =>
      _t('companion_hint_level_h0', 'No hint in use.');
  String get companionHintUnavailable =>
      _t('companion_hint_unavailable', 'Hint unavailable');
  String get companionTafsirCuePlaceholder => _t(
    'companion_tafsir_cue_placeholder',
    'Meaning cue (Tafsir al-Muyassar placeholder)',
  );
  String get companionPlayCurrentAyah =>
      _t('companion_play_current_ayah', 'Listen to current ayah');
  String get companionAutoplayNextAyah =>
      _t('companion_autoplay_next_ayah', 'Autoplay next ayah');
  String get companionAutoplayOn => _t('companion_autoplay_on', 'Autoplay on');
  String get companionAutoplayOff =>
      _t('companion_autoplay_off', 'Autoplay off');
  String get companionRecordStart =>
      _t('companion_record_start', 'Start attempt');
  String get companionWhatToDoNowLabel =>
      _t('companion_what_to_do_now_label', 'What to do now');
  String get companionReviewPracticeTitle =>
      _t('companion_review_practice_title', 'Review from memory');
  String get companionDelayedCheckTitle =>
      _t('companion_delayed_check_title', 'Delayed check');
  String get companionStage1ModeLabel =>
      _t('companion_stage1_mode_label', 'What to do now');
  String get companionStage1ModeModelEcho =>
      _t('companion_stage1_mode_model_echo', 'Listen and follow');
  String get companionStage1ModeColdProbe =>
      _t('companion_stage1_mode_cold_probe', 'Try it from memory');
  String get companionStage1ModeCorrection =>
      _t('companion_stage1_mode_correction', 'Listen to the correction');
  String get companionStage1ModeSpacedReprobe =>
      _t('companion_stage1_mode_spaced_reprobe', 'Try it from memory again');
  String get companionStage1ModeCheckpoint =>
      _t('companion_stage1_mode_checkpoint', 'Quick memory check');
  String get companionStage1ModeCumulative =>
      _t('companion_stage1_mode_cumulative', 'Put the passage together');
  String get companionStage1ReciteNow =>
      _t('companion_stage1_recite_now', 'Listen first, then try it.');
  String get companionStage1ReciteNowHiddenPrompt => _t(
    'companion_stage1_recite_now_hidden_prompt',
    'Recite now from memory.',
  );
  String get companionStage1CorrectionRequiredMessage => _t(
    'companion_stage1_correction_required_message',
    'Listen to the correction before you try again.',
  );
  String get companionStage1CorrectionAction =>
      _t('companion_stage1_correction_action', 'Hear the correction');
  String get companionStage1AutoCheckTitle =>
      _t('companion_stage1_auto_check_title', 'Quick check');
  String get companionStage1AutoCheckRequiredSelection => _t(
    'companion_stage1_auto_check_required_selection',
    'Choose an answer for the quick check first.',
  );
  String get companionStage1HintLockedMessage => _t(
    'companion_stage1_hint_locked_message',
    'Try once from memory before using a hint.',
  );
  String companionStage1WeakVerses(int count) => _fmt(
    _t(
      'companion_stage1_weak_verses',
      'Verses to reinforce before moving on: {count}',
    ),
    <String, Object>{'count': count},
  );
  String get companionStage2ModeLabel =>
      _t('companion_stage2_mode_label', 'What to do now');
  String get companionStage2ModeMinimalCueRecall =>
      _t('companion_stage2_mode_minimal_cue_recall', 'Recite with a small cue');
  String get companionStage2ModeDiscrimination => _t(
    'companion_stage2_mode_discrimination',
    'Choose the right continuation',
  );
  String get companionStage2ModeLinking =>
      _t('companion_stage2_mode_linking', 'Connect to the next verse');
  String get companionStage2ModeCorrection =>
      _t('companion_stage2_mode_correction', 'Listen to the correction');
  String get companionStage2ModeCheckpoint =>
      _t('companion_stage2_mode_checkpoint', 'Quick memory check');
  String get companionStage2ModeRemediation =>
      _t('companion_stage2_mode_remediation', 'Reinforce the weak part');
  String get companionStage2ReciteNow =>
      _t('companion_stage2_recite_now', 'Use the cue and keep reciting.');
  String get companionStage2CorrectionRequiredMessage => _t(
    'companion_stage2_correction_required_message',
    'Listen to the correction before you try this cue step again.',
  );
  String get companionStage2CorrectionAction =>
      _t('companion_stage2_correction_action', 'Hear the correction');
  String get companionStage3ModeLabel =>
      _t('companion_stage3_mode_label', 'What to do now');
  String get companionStage3ModeWeakPrelude => _t(
    'companion_stage3_mode_weak_prelude',
    'Strengthen the weak verses first',
  );
  String get companionStage3ModeHiddenRecall =>
      _t('companion_stage3_mode_hidden_recall', 'Recite from memory');
  String get companionStage3ModeLinking =>
      _t('companion_stage3_mode_linking', 'Connect the verses');
  String get companionStage3ModeDiscrimination => _t(
    'companion_stage3_mode_discrimination',
    'Choose the right continuation',
  );
  String get companionStage3ModeCorrection =>
      _t('companion_stage3_mode_correction', 'Listen to the correction');
  String get companionStage3ModeCheckpoint =>
      _t('companion_stage3_mode_checkpoint', 'Quick memory check');
  String get companionStage3ModeRemediation =>
      _t('companion_stage3_mode_remediation', 'Reinforce the weak part');
  String get companionStage3ReciteNow => _t(
    'companion_stage3_recite_now',
    'Recite from memory with the text hidden.',
  );
  String get companionStage3CorrectionRequiredMessage => _t(
    'companion_stage3_correction_required_message',
    'Listen to the correction before you try again.',
  );
  String get companionStage3CorrectionAction =>
      _t('companion_stage3_correction_action', 'Hear the correction');
  String get companionStage4ModeLabel =>
      _t('companion_stage4_mode_label', 'What to do now');
  String get companionStage4ModeColdStart =>
      _t('companion_stage4_mode_cold_start', 'Start from memory');
  String get companionStage4ModeRandomStart =>
      _t('companion_stage4_mode_random_start', 'Start from a random point');
  String get companionStage4ModeLinking =>
      _t('companion_stage4_mode_linking', 'Connect the verses');
  String get companionStage4ModeDiscrimination => _t(
    'companion_stage4_mode_discrimination',
    'Choose the right continuation',
  );
  String get companionStage4ModeCorrection =>
      _t('companion_stage4_mode_correction', 'Listen to the correction');
  String get companionStage4ModeCheckpoint =>
      _t('companion_stage4_mode_checkpoint', 'Quick memory check');
  String get companionStage4ModeRemediation =>
      _t('companion_stage4_mode_remediation', 'Reinforce the weak part');
  String get companionStage4ReciteNow =>
      _t('companion_stage4_recite_now', 'Do your delayed check from memory.');
  String get companionStage4CorrectionRequiredMessage => _t(
    'companion_stage4_correction_required_message',
    'Listen to the correction before you retry this delayed check.',
  );
  String get companionStage4CorrectionAction =>
      _t('companion_stage4_correction_action', 'Hear the correction');
  String companionStage4DueBanner(String dueKind) => _fmt(
    _t('companion_stage4_due_banner', 'Delayed check for today: {dueKind}'),
    <String, Object>{'dueKind': dueKind},
  );
  String companionStage4UnresolvedTargets(int count) => _fmt(
    _t(
      'companion_stage4_unresolved_targets',
      'Still needs work on {count} verse(s).',
    ),
    <String, Object>{'count': count},
  );
  String companionStage3WeakPreludeBanner(int count) => _fmt(
    _t(
      'companion_stage3_weak_prelude_banner',
      'Strengthen {count} weak verse(s) first, then continue.',
    ),
    <String, Object>{'count': count},
  );
  String get companionHintButton => _t('companion_hint_button', 'Show hint');
  String get companionRepeatButton =>
      _t('companion_repeat_button', 'Repeat verse');
  String get companionNextButton => _t('companion_next_button', 'Next verse');
  String companionStageProgress(int current, int total) => _fmt(
    _t('companion_stage_progress', 'Practice step {current}/{total}'),
    <String, Object>{'current': current, 'total': total},
  );
  String get companionStageGuidedVisible =>
      _t('companion_stage_guided_visible', 'Listen and follow');
  String get companionStageCuedRecall =>
      _t('companion_stage_cued_recall', 'Recite with a cue');
  String get companionStageHiddenReveal =>
      _t('companion_stage_hidden_reveal', 'Recite from memory');
  String get companionSkipStageButton =>
      _t('companion_skip_stage_button', 'Skip this step');
  String get companionSkipStageTitle =>
      _t('companion_skip_stage_title', 'Skip this practice step?');
  String companionSkipStageBody(String stageLabel) => _fmt(
    _t(
      'companion_skip_stage_body',
      'Skip {stage} for this session and move to the next step.',
    ),
    <String, Object>{'stage': stageLabel},
  );
  String get companionSkipStageConfirm =>
      _t('companion_skip_stage_confirm', 'Skip');
  String get companionStageSkipped =>
      _t('companion_stage_skipped', 'Practice step skipped.');
  String get companionMarkCorrect =>
      _t('companion_mark_correct', 'I got it right');
  String get companionMarkIncorrect =>
      _t('companion_mark_incorrect', 'I need correction');
  String companionFailedToSaveAttempt(String error) => _fmt(
    _t(
      'companion_failed_to_save_attempt',
      'Failed to save companion attempt: {error}',
    ),
    <String, Object>{'error': error},
  );
  String get companionRepeatPrompt => _t(
    'companion_repeat_prompt',
    'Repeat the current verse, then start the next attempt when you are ready.',
  );
  String get companionVersePassed => _t('companion_verse_passed', 'Done');
  String get companionVerseRevealed => _t('companion_verse_revealed', 'Shown');
  String get companionVerseHidden => _t('companion_verse_hidden', 'Hidden');
  String get companionHiddenPlaceholder =>
      _t('companion_hidden_placeholder', '••••••••••');
  String companionProficiency(String value) => _fmt(
    _t('companion_proficiency', 'Memory strength: {value}'),
    <String, Object>{'value': value},
  );
  String get companionSessionComplete =>
      _t('companion_session_complete', 'Practice complete');
  String companionSummaryPassed(int passed, int total) => _fmt(
    _t('companion_summary_passed', 'Completed verses: {passed}/{total}'),
    <String, Object>{'passed': passed, 'total': total},
  );
  String companionSummaryHint(String value) => _fmt(
    _t('companion_summary_hint', 'Average help used: {value}'),
    <String, Object>{'value': value},
  );
  String companionSummaryStrength(String value) => _fmt(
    _t('companion_summary_strength', 'Average memory strength: {value}'),
    <String, Object>{'value': value},
  );
  String get companionNoSessionState =>
      _t('companion_no_session_state', 'No practice session is available.');
  String get enterAllQPercentagesOrBlank => _t(
    'enter_all_q_percentages_or_blank',
    'Enter all q percentages (5,4,3,2,0) or leave all blank.',
  );
  String qMustBeIntegerPercentage(int q) => _fmt(
    _t('q_must_be_integer_percentage', 'q{q} must be an integer percentage.'),
    <String, Object>{'q': q},
  );
  String get qPercentagesMustSum100 =>
      _t('q_percentages_must_sum_100', 'q percentages must sum to 100.');

  String get failedToLoadAyahs =>
      _t('failed_to_load_ayahs', 'Failed to load ayahs.');
  String get noMushafDataAvailable =>
      _t('no_mushaf_data_available', 'No Mushaf data available.');
  String get noMushafTextAvailable =>
      _t('no_mushaf_text_available', 'No Mushaf text available.');
  String get failedToLoadMushafPage =>
      _t('failed_to_load_mushaf_page', 'Failed to load Mushaf page.');
  String get failedToLoadPages =>
      _t('failed_to_load_pages', 'Failed to load pages.');
  String get noPagesAvailable =>
      _t('no_pages_available', 'No pages available.');
  String noAyahsForSurah(int surahNumber) => _fmt(
    _t('no_ayahs_for_surah', 'No ayahs found for Surah {surah}.'),
    <String, Object>{'surah': surahNumber},
  );
  String noAyahsForPage(int? pageNumber) => _fmt(
    _t('no_ayahs_for_page', 'No ayahs found for Page {page}.'),
    <String, Object>{'page': pageNumber ?? ''},
  );
  String get failedToLoadVerses =>
      _t('failed_to_load_verses', 'Failed to load verses.');
  String get noVersesAvailableForSelectedSurah => _t(
    'no_verses_available_for_selected_surah',
    'No verses available for selected surah.',
  );
  String get failedToLoadJuzIndex =>
      _t('failed_to_load_juz_index', 'Failed to load Juz index.');
  String get noJuzEntriesFound =>
      _t('no_juz_entries_found', 'No Juz entries found.');
  String get searchSurah => _t('search_surah', 'Search Surah');
  String get verseNumber => _t('verse_number', 'Verse number');
  String get verseNumberHint => _t('verse_number_hint', 'Verse number');
  String get searchJuz => _t('search_juz', 'Search Juz');
  String get searchPage => _t('search_page', 'Search Page');
  String get noPageMetadataImportInSettings => _t(
    'no_page_metadata_import_in_settings',
    'No page metadata found. Import Page Metadata in Settings.',
  );
  String get targetAyahNoPageMetadataYet => _t(
    'target_ayah_no_page_metadata',
    'Target ayah has no page metadata yet.',
  );
  String get targetAyahPageUnavailable => _t(
    'target_ayah_page_unavailable_import',
    'Target ayah page is not available in imported metadata.',
  );
  String get tajweedTagsUnavailableShowingPlain => _t(
    'tajweed_tags_unavailable_showing_plain',
    'Tajweed tags unavailable. Showing plain text.',
  );
  String noPageMetadataForSurah(int surahNumber) => _fmt(
    _t(
      'no_page_metadata_for_surah',
      'No page metadata found for Surah {surah}.',
    ),
    <String, Object>{'surah': surahNumber},
  );
  String noPageMetadataForSurahAyah(int surahNumber, int ayahNumber) => _fmt(
    _t(
      'no_page_metadata_for_surah_ayah',
      'No page metadata found for {surah}:{ayah}.',
    ),
    <String, Object>{'surah': surahNumber, 'ayah': ayahNumber},
  );
  String get targetAyahNotVisibleOnSelectedPage => _t(
    'target_ayah_not_visible_on_selected_page',
    'Target ayah is not visible on the selected page.',
  );
  String ayahNotFoundInSurah(int ayahNumber, int surahNumber) => _fmt(
    _t(
      'ayah_not_found_in_surah',
      'Ayah {ayah} was not found in Surah {surah}.',
    ),
    <String, Object>{'ayah': ayahNumber, 'surah': surahNumber},
  );
  String get verseAlreadyBookmarked =>
      _t('verse_already_bookmarked', 'Verse already bookmarked.');
  String get bookmarkSaved => _t('bookmark_saved', 'Bookmark saved.');
  String get failedToSaveBookmark =>
      _t('failed_to_save_bookmark', 'Failed to save bookmark.');
  String get noteAdded => _t('note_added', 'Note added.');
  String get copiedVerseText => _t('copied_verse_text', 'Copied verse text.');
  String get failedToCopyVerseText =>
      _t('failed_to_copy_verse_text', 'Failed to copy verse text.');
  String audioLoadFailed(String error) => _fmt(
    _t('audio_load_failed', 'Audio playback failed: {error}'),
    <String, Object>{'error': error},
  );
  String get audioPluginUnavailable => _t(
    'audio_plugin_unavailable',
    'Audio plugin unavailable. Restart app after full rebuild.',
  );
  String get audioNetworkError => _t(
    'audio_network_error',
    'Audio source unavailable. Check your internet connection.',
  );
  String reciterNotAvailableForStreaming(String reciter) => _fmt(
    _t(
      'reciter_not_available_for_streaming',
      '{reciter} is not available for streaming right now.',
    ),
    <String, Object>{'reciter': reciter},
  );
  String reciterAppliedWithBitrate(String reciter, int bitrate) => _fmt(
    _t('reciter_applied_with_bitrate', '{reciter} selected ({bitrate} kbps).'),
    <String, Object>{'reciter': reciter, 'bitrate': bitrate},
  );
  String get audioControlsComingSoon =>
      _t('audio_controls_coming_soon', 'Audio controls are coming soon.');
  String get downloadComingSoon =>
      _t('download_coming_soon', 'Download is coming soon.');
  String get experienceComingSoon =>
      _t('experience_coming_soon', 'Experience settings are coming soon.');
  String elapsedTimeLabel(String value) => _fmt(
    _t('elapsed_time_label', 'Elapsed {value}'),
    <String, Object>{'value': value},
  );
  String totalTimeLabel(String value) => _fmt(
    _t('total_time_label', 'Total {value}'),
    <String, Object>{'value': value},
  );
  String get shareComingSoon =>
      _t('share_coming_soon', 'Share is coming soon.');
  String get tafsirsComingSoon =>
      _t('tafsirs_coming_soon', 'Tafsirs are coming soon.');
  String get lessonsComingSoon =>
      _t('lessons_coming_soon', 'Lessons are coming soon.');
  String get reflectionsComingSoon =>
      _t('reflections_coming_soon', 'Reflections are coming soon.');
  String get translationSettingsComingSoon => _t(
    'translation_settings_coming_soon',
    'Translation settings are coming soon.',
  );
  String get wordByWordSettingsComingSoon => _t(
    'word_by_word_settings_coming_soon',
    'Word by Word settings are coming soon.',
  );
  String get verseActionsUnavailable => _t(
    'verse_actions_unavailable',
    'Verse actions unavailable for this page data.',
  );

  static const Map<AppLanguage, Map<String, String>>
  _overrides = <AppLanguage, Map<String, String>>{
    AppLanguage.french: <String, String>{
      'close': 'Fermer',
      'language': 'Langue',
      'change_theme': 'Changer le thème',
      'theme_dark': 'Sombre',
      'read': 'Lire',
      'learn': 'Apprendre',
      'my_quran': 'Mon Coran',
      'my_quran_subtitle':
          "Gardez votre place, vos éléments sauvegardés et votre configuration d'écoute ensemble.",
      'my_quran_study_setup_title': "Configuration d'étude",
      'my_quran_study_setup_description':
          "Choisissez l’aide de sens à afficher dans Lecture et si Pratique par cœur doit lancer automatiquement l’ayah suivante.",
      'my_quran_meaning_setup_summary':
          'Aide de sens : traduction {translation}, aide mot à mot {wordHelp}, translittération {transliteration}.',
      'my_quran_practice_setup_summary':
          'Pratique par cœur : lecture auto {autoplay}.',
      'my_quran_study_setup_reciter_hint':
          'Utilisez Configuration d’écoute si vous voulez changer de récitateur.',
      'on_label': 'activé',
      'off_label': 'désactivé',
      'quran_radio': 'Radio Coran',
      'reciters': 'Récitateurs',
      'reader': 'Lecteur',
      'bookmarks': 'Signets',
      'notes': 'Notes',
      'plan': 'Plan',
      'my_plan': 'Mon plan',
      'today': "Aujourd'hui",
      'library': 'Bibliothèque',
      'settings': 'Paramètres',
      'about': 'À propos',
      'tools': 'Outils',
      'explore': 'Explorer',
      'retry': 'Réessayer',
      'done': 'Fait',
      'copy': 'Copier',
      'share': 'Partager',
      'more': 'Plus',
      'my_quran_continue_reading_title': 'Continuer la lecture',
      'my_quran_continue_reading_button': 'Continuer la lecture',
      'my_quran_continue_reading_fallback': 'Commencer dans le Lecteur',
      'my_quran_continue_reading_description':
          'Reprenez là où vous avez ouvert le Lecteur pour la dernière fois.',
      'my_quran_no_recent_reading':
          "Aucune lecture récente enregistrée. Ouvrez le Lecteur pour commencer à un endroit que vous pourrez retrouver plus tard.",
      'my_quran_resume_from_page': 'Reprendre à la page {page}',
      'my_quran_open_reader': 'Ouvrir le Lecteur',
      'my_quran_saved_for_later_title': 'Sauvegardé pour plus tard',
      'my_quran_saved_counts': 'Signets : {bookmarks} · Notes : {notes}',
      'my_quran_no_saved_items':
          "Aucun élément sauvegardé pour l'instant. Utilisez Sauvegarder pour plus tard ou les notes pendant votre lecture.",
      'my_quran_saved_for_later_description':
          'Ouvrez la Bibliothèque pour revoir vos versets et notes sauvegardés.',
      'my_quran_open_library': 'Ouvrir la Bibliothèque',
      'my_quran_listening_setup_title': "Configuration d'écoute",
      'my_quran_listening_setup_summary': 'Vitesse {speed} · Répéter {repeat}',
      'my_quran_open_reciters': 'Ouvrir les récitateurs',
      'my_quran_load_failed': 'Impossible de charger Mon Coran.',
      'verse_by_verse': 'Ayah par Ayah',
      'reading': 'Lecture',
      'surah': 'Sourate',
      'verse': 'Ayah',
      'juz': 'Juz',
      'page': 'Page',
      'listen': 'Écouter',
      'play_from_here': "Lire à partir d'ici",
      'pause': 'Pause',
      'resume': 'Reprendre',
      'next': 'Suivant',
      'previous': 'Précédent',
      'audio_options': 'Options audio',
      'download': 'Télécharger',
      'manage_repeat_settings': 'Gérer les paramètres de répétition',
      'experience': 'Expérience',
      'playback_speed': 'Vitesse',
      'repeat': 'Répéter',
      'repeat_off': 'Désactivé',
      'repeat_1x': '1x',
      'repeat_2x': '2x',
      'repeat_3x': '3x',
      'select_reciter': 'Choisir un récitateur',
      'search_reciter': 'Rechercher un récitateur',
      'tajweed_colors': 'Couleurs du Tajwid',
      'tajweed_legend_silent_letter': 'Lettre muette',
      'tajweed_legend_normal_madd_2': 'Madd naturel (2)',
      'tajweed_legend_separated_madd_246': 'Madd séparé (2/4/6)',
      'tajweed_legend_connected_madd_45': 'Madd joint (4/5)',
      'tajweed_legend_necessary_madd_6': 'Madd obligatoire (6)',
      'tajweed_legend_ghunna_ikhfa': "Ghunnah/ikhfa'",
      'tajweed_legend_qalqala_echo': 'Qalqalah (écho)',
      'tajweed_legend_tafkhim_heavy': 'Tafkhim (lourd)',
      'tafsirs': 'Tafsirs',
      'lessons': 'Leçons',
      'reflections': 'Réflexions',
      'translation': 'Traduction',
      'arabic': 'Arabe',
      'word_by_word': 'Aide mot à mot',
      'script_style': "Style d'écriture",
      'show_tajweed_rules_while_reading':
          'Afficher les règles de tajwid pendant la lecture',
      'font_size': 'Taille de police',
      'selected_reciter': 'Récitateur sélectionné',
      'verse_actions_unavailable':
          "Actions de l'ayah indisponibles pour ces données de page.",
      'translation_unavailable': 'Traduction indisponible',
      'meaning_unavailable': 'Sens indisponible pour ce mot.',
      'meaning_aids_off': 'Les aides de sens sont désactivées.',
      'study_this_verse': 'Étudier ce verset',
      'bookmark_verse': 'Enregistrer pour plus tard',
      'transliteration': 'Translittération',
      'show_verse_translation': 'Afficher la traduction du verset',
      'show_word_help': 'Afficher l’aide mot à mot',
      'show_transliteration': 'Afficher la translittération',
      'word_help': 'Aide mot à mot',
      'word_help_unavailable_for_verse':
          'L’aide mot à mot est indisponible pour ce verset pour le moment.',
      'word_help_description':
          'L’aide mot à mot apparaît quand vous survolez ou touchez un mot en mode Lecture.',
      'hover_word_to_preview_meaning':
          'Survolez ou touchez un mot pour prévisualiser son sens.',
      'audio_load_failed': "Échec de la lecture audio : {error}",
      'failed_to_load_reciters': 'Échec du chargement des récitateurs.',
      'download_coming_soon': 'Le téléchargement arrive bientôt.',
      'experience_coming_soon': "Les paramètres d'expérience arrivent bientôt.",
      'audio_plugin_unavailable':
          "Plugin audio indisponible. Redémarrez l'application après une reconstruction complète.",
      'audio_network_error':
          'Source audio indisponible. Vérifiez votre connexion internet.',
      'reciter_not_available_for_streaming':
          '{reciter} est indisponible en streaming pour le moment.',
      'reciter_applied_with_bitrate': '{reciter} sélectionné ({bitrate} kbps).',
      'elapsed_time_label': 'Écoulé {value}',
      'total_time_label': 'Total {value}',
      'translation_label': 'Traduction : {label}',
      'translation_follows_app_language':
          'La traduction suit actuellement la langue de l’application : {label}.',
      'page_label': 'Page {page}',
      'juz_label': 'Juz {juz}',
      'hizb_label': 'Hizb {hizb}',
      'surah_label': 'Sourate {surah}',
      'ayah_label': 'Ayah {ayah}',
      'search_surah': 'Rechercher une sourate',
      'learn_title': "Plans d'apprentissage",
      'bookmarks_title': 'Signets',
      'library_title': 'Bibliothèque',
      'library_subtitle':
          'Gardez vos emplacements enregistrés et vos notes au même endroit.',
      'library_bookmarks_description':
          'Rouvrez vos versets enregistrés et reprenez votre étude là où vous vous êtes arrêté.',
      'library_notes_description':
          'Relisez vos notes sur les versets avec assez de contexte pour continuer à étudier.',
      'open_bookmarks': 'Ouvrir les signets',
      'open_notes': 'Ouvrir les notes',
      'failed_to_load_bookmarks': 'Échec du chargement des signets.',
      'no_bookmarks_yet': 'Aucun signet pour le moment.',
      'saved_label': 'Enregistré {timestamp}',
      'saved_for_later_study': 'Enregistré pour plus tard',
      'surah_ayah_list_label': 'Sourate {surah}, Ayah {ayah}',
      'go_to_verse': 'Rouvrir dans le lecteur',
      'go_to_page': 'Aller à la page',
      'notes_title': 'Notes',
      'failed_to_load_notes': 'Échec du chargement des notes.',
      'no_notes_yet': 'Aucune note pour le moment.',
      'untitled': 'Sans titre',
      'failed_to_update_note': 'Échec de la mise à jour de la note.',
      'edit_note': 'Modifier la note',
      'note_title_optional': 'Titre (optionnel)',
      'note_body': 'Corps de la note',
      'body_required': 'Le corps est requis.',
      'add_note': 'Ajouter une note',
      'note_save_failed': "Échec de l'enregistrement de la note.",
      'linked_verse': 'Ayah lié : Sourate {surah}, Ayah {ayah}',
      'linked_verse_with_page':
          'Ayah lié : Sourate {surah}, Ayah {ayah} (Page {page})',
      'settings_title': 'Paramètres',
      'import_quran_text': 'Importer le texte du Coran',
      'import_page_metadata': 'Importer les métadonnées de page',
      'today_title': "Aujourd'hui",
      'planned_reviews': 'Révisions planifiées',
      'no_planned_reviews_left': 'Aucune révision planifiée restante.',
      'due_day_label': 'Jour prévu {day}',
      'new_memorization': 'Nouvelle mémorisation',
      'no_planned_new_units_left': 'Aucune nouvelle unité planifiée restante.',
      'open_in_reader': 'Ouvrir dans le lecteur',
      'page_metadata_required_to_open_in_reader':
          'Les métadonnées de page sont requises pour ouvrir dans le lecteur.',
      'self_check_grade': 'Auto-évaluation',
      'failed_to_load_today_plan': "Échec du chargement du plan d'aujourd'hui.",
      'grade_saved': 'Évaluation enregistrée.',
      'failed_to_save_grade': "Échec de l'enregistrement de l'évaluation.",
      'today_completion_start_title': 'Un vrai début compte',
      'today_completion_start_message':
          'Vous avez accompli une vraie journée de pratique. Cela suffit pour commencer à construire la régularité.',
      'today_completion_sparse_title': 'Une reprise calme compte aussi',
      'today_completion_sparse_message':
          'Vous avez accompli un vrai travail aujourd’hui. Quelques jours calmes comme celui-ci suffisent pour reconstruire la confiance dans le plan.',
      'today_completion_recovery_title':
          'Le travail de récupération compte aussi',
      'today_completion_recovery_message':
          'Vous avez protégé la rétention avec une journée plus légère. C’est une victoire sûre pendant que le plan se stabilise.',
      'today_empty_sparse_title': 'La journée peut rester légère',
      'today_empty_sparse_message':
          'Vous reprenez doucement le rythme. Ouvrez Mon plan si vous voulez une prochaine étape plus claire pour la semaine.',
      'today_empty_recovery_title':
          'Une pause de récupération peut être intentionnelle',
      'today_empty_recovery_message':
          'Le plan garde cette journée légère pour que vous puissiez vous stabiliser en sécurité. Ouvrez Mon plan si vous voulez revoir ou alléger davantage la semaine.',
      'range_unavailable': 'Plage indisponible',
      'grade_good': 'Bon',
      'grade_medium': 'Moyen',
      'grade_hard': 'Difficile',
      'grade_very_hard': 'Très difficile',
      'grade_fail': 'Échec',
      'plan_setup_title': 'Configurer Mon plan',
      'plan_setup_subtitle':
          'Choisissez un rythme, un temps réaliste, puis activez votre plan. Vous pourrez affiner les détails plus tard.',
      'plan_preset_question': '1) Quel niveau d’ambition voulez-vous ?',
      'plan_preset_easy': 'Facile',
      'plan_preset_easy_description':
          'Protège d’abord les révisions et garde le nouveau travail léger.',
      'plan_preset_normal': 'Normal',
      'plan_preset_normal_description':
          'Nouveau hifz équilibré avec un bon soutien des révisions.',
      'plan_preset_intensive': 'Intensif',
      'plan_preset_intensive_description':
          'Avancez plus vite si votre emploi du temps est stable.',
      'plan_guided_note':
          'Si votre période est chargée ou si vous rattrapez du retard, commencez par Facile. Vous pourrez encore ajuster le mode révision dans Avancé.',
      'plan_advanced_title': 'Avancé',
      'plan_advanced_subtitle':
          'Ouvrez ceci seulement si vous voulez ajuster la planification, les prévisions, l’étalonnage ou les règles de rattrapage.',
      'plan_open_advanced': 'Afficher Avancé',
      'plan_hide_advanced': 'Masquer Avancé',
      'plan_fine_tune_title': 'Affiner ce plan',
      'plan_summary_pace': 'Rythme',
      'plan_summary_time': 'Temps',
      'plan_summary_new_limit': 'Limite de nouveau travail',
      'plan_summary_review_priority': 'Priorité des révisions',
      'plan_summary_time_value':
          '{weekly} minutes par semaine, environ {daily} minutes par jour.',
      'plan_summary_new_limit_value':
          'Jusqu’à {pages} nouvelles pages ou {units} nouvelles unités lors d’un jour d’étude.',
      'plan_review_priority_easy':
          'Donnez plus de place aux révisions et ralentissez le nouveau travail quand la pression monte.',
      'plan_review_priority_normal':
          'Gardez un mélange équilibré entre protection des révisions et nouveau hifz régulier.',
      'plan_review_priority_intensive':
          'Poussez davantage le nouveau hifz quand votre emploi du temps le permet.',
      'goal_focus_title': 'Objectif de cette semaine',
      'goal_focus_steady_progress': 'Progrès réguliers',
      'goal_focus_protect_retention': 'Protéger la rétention',
      'goal_focus_recovery_and_stabilize': 'Récupérer et stabiliser',
      'today_goal_good_day_label': 'Une bonne journée',
      'today_goal_support_label': "Comment la tâche du jour aide",
      'today_goal_short_day_label': 'Si la journée se raccourcit',
      'today_goal_good_day_steady':
          'Une bonne journée consiste à terminer la tâche principale et, si le temps le permet, le reste du travail prévu.',
      'today_goal_good_day_protect':
          'Une bonne journée consiste d’abord à protéger le travail dû, même si le nouveau travail reste plus léger.',
      'today_goal_good_day_recovery':
          'Une bonne journée consiste à faire le travail essentiel le plus sûr sans forcer une charge complète.',
      'today_goal_support_steady':
          "La tâche principale d'aujourd'hui soutient un progrès régulier en faisant avancer le plan sans surcharge.",
      'today_goal_support_protect':
          "La tâche principale d'aujourd'hui protège la rétention en donnant d'abord la priorité aux révisions et aux vérifications différées.",
      'today_goal_support_recovery':
          "La tâche principale d'aujourd'hui soutient la récupération en baissant la pression et en reconstruisant la régularité.",
      'today_goal_short_day_steady':
          "Lors d'une journée courte, la tâche principale prévue compte déjà comme une vraie réussite.",
      'today_goal_short_day_protect':
          'Lors d’une journée courte, terminer le travail dû le plus prioritaire suffit.',
      'today_goal_short_day_recovery':
          "Lors d'une journée courte, le jour minimum est une réussite, pas un recul.",
      'plan_goal_summary_hint':
          'Cela change automatiquement selon la pression actuelle de votre plan.',
      'plan_goal_summary_hint_start':
          'Commencez par quelques vraies séances cette semaine. Le résumé se remplira automatiquement.',
      'plan_goal_summary_hint_sparse':
          'Une semaine calme et répétable suffit. Quelques vraies séances de plus rendront ce résumé plus clair.',
      'plan_goal_summary_hint_recovery':
          'Cette semaine consiste à se stabiliser en sécurité, pas à prouver sa vitesse.',
      'plan_goal_summary_steady':
          'Votre plan est assez léger pour viser des progrès réguliers et durables cette semaine.',
      'plan_goal_summary_protect':
          'Votre plan doit protéger la rétention d’abord cette semaine, même si le nouveau travail reste plus léger.',
      'plan_goal_summary_recovery':
          'L’objectif le plus sûr cette semaine est de vous stabiliser et de réduire la pression avant d’accélérer.',
      'weekly_progress_title': '7 derniers jours',
      'weekly_progress_consistency_label': 'Régularité',
      'weekly_progress_completed_work_label': 'Travail accompli',
      'weekly_progress_recent_quality_label': 'Qualité récente des révisions',
      'weekly_progress_trend_start':
          "Commencez à construire votre régularité avec une vraie séance aujourd'hui : pratique, révision ou vérification différée.",
      'weekly_progress_trend_steady':
          'Votre travail récent soutient un rythme hebdomadaire stable.',
      'weekly_progress_trend_building':
          'Vous construisez votre régularité. Gardez la tâche principale simple et répétable.',
      'weekly_progress_trend_sparse':
          'Vous reprenez votre rythme. Quelques séances calmes et réelles suffisent cette semaine.',
      'weekly_progress_trend_protect':
          'Le travail avance, mais la rétention a encore besoin de la part la plus sûre de votre temps.',
      'weekly_progress_trend_recovery':
          'La récupération compte aussi. Une journée plus légère mais réelle protège le plan.',
      'weekly_progress_consistency_start':
          'Pas encore d’historique significatif. Une vraie journée suffit pour commencer.',
      'weekly_progress_consistency_value':
          '{days} jours actifs sur les 7 derniers jours.',
      'weekly_progress_counts_start':
          'Le travail accompli apparaîtra ici après votre première vraie séance.',
      'weekly_progress_counts_value':
          '{reviews} révisions, {delayedChecks} vérifications différées, {practiceCompletions} pratiques terminées.',
      'weekly_progress_quality_steady': 'Plutôt stable',
      'weekly_progress_quality_mixed': 'Mitigée',
      'weekly_progress_quality_strained': 'Besoin d’un rythme plus doux',
      'weekly_progress_quality_not_enough_data':
          'Pas encore assez de données de révision',
      'weekly_progress_note_label': 'Comment le lire',
      'weekly_progress_note_start':
          'Une vraie séance suffit pour commencer. Ce bloc se remplit automatiquement à mesure que vous accomplissez un vrai travail.',
      'weekly_progress_note_sparse':
          'Un retour en douceur compte aussi. Gardez les prochaines séances simples et répétables.',
      'weekly_progress_note_steady':
          'Continuez à répéter la tâche principale et laissez les journées régulières s’additionner.',
      'weekly_progress_note_protect':
          'Laissez les révisions et vérifications différées garder la part la plus sûre de votre temps jusqu’à ce que la pression baisse.',
      'weekly_progress_note_recovery':
          'Une semaine plus légère compte aussi pendant que le plan vous aide à vous stabiliser en sécurité.',
      'weekly_progress_recent_quality_line':
          'Qualité récente des révisions : {value}',
      'no_ayahs_for_surah': 'Aucun ayah trouvé pour la sourate {surah}.',
      'no_ayahs_for_page': 'Aucun ayah trouvé pour la page {page}.',
      'onboarding_questionnaire':
          "Questionnaire d'intégration ({count} questions)",
      'run_forecast': 'Lancer la prévision',
      'running': 'Exécution...',
      'suggested_plan_editable': 'Résumé de votre plan',
      'daily_minutes_by_weekday': 'Minutes quotidiennes par jour',
      'avg_new_minutes_per_ayah': 'Moyenne minutes nouvelles par ayah',
      'avg_review_minutes_per_ayah': 'Moyenne minutes révision par ayah',
      'require_page_metadata': 'Exiger les métadonnées de page',
      'activate': 'Activer',
      'activating': 'Activation...',
      'calibration_mode_optional': 'Mode calibration (optionnel)',
      'time_input': '2) Quel temps est réaliste ?',
      'weekly_total': 'Total hebdomadaire',
      'per_weekday': 'Par jour',
      'weekly_minutes': 'Minutes hebdomadaires',
      'fluency':
          '3) À quel point êtes-vous à l’aise avec le hifz en ce moment ?',
      'fluency_fluent': 'fluide',
      'fluency_developing': 'en progression',
      'fluency_support': 'support',
      'profile': 'Profil du planificateur',
      'profile_support': 'support',
      'profile_standard': 'standard',
      'profile_accelerated': 'accéléré',
      'force_revision_only': 'Protéger les révisions en cas de surcharge',
      'daily_new_item_caps': 'Limites quotidiennes du nouveau travail',
      'max_new_pages_per_day': 'Max nouvelles pages par jour',
      'max_new_units_per_day': 'Max nouvelles unités par jour',
      'duration_minutes': 'Durée (minutes)',
      'ayah_count': "Nombre d'ayahs",
      'about_title': 'À propos',
      'open_hifz_plan': 'Ouvrir le plan de Hifz',
      'open_companion_chain': 'Ouvrir la chaine compagnon',
      'planned_review_minutes': 'Minutes de revision prevues : {value}',
      'planned_new_minutes': 'Minutes de nouveau prevues : {value}',
      'review_pressure_label': 'Pression de revision : {value}',
      'recovery_mode_active':
          'Mode recuperation actif : nouvelle memorisation en pause',
      'today_sessions': "Sessions d'aujourd'hui",
      'no_sessions_planned': 'Aucune session planifiee.',
      'new_and_review_focus': 'Nouveau + revision',
      'review_only_focus': 'Revision uniquement',
      'session_status_pending': 'en attente',
      'session_status_completed': 'terminee',
      'session_status_missed': 'manquee',
      'session_status_due_soon': 'bientot due',
      'session_minutes': '{minutes} min',
      'untimed_session_label': 'Sans heure',
      'automatic_scheduling_title': 'Planification automatique',
      'two_sessions_per_day': '2 sessions par jour',
      'set_exact_times_question': 'Definir des heures exactes ?',
      'session_time_label': 'Session {session} : {value}',
      'study_days_label': "Jours d'etude",
      'advanced_scheduling_mode': 'Mode de planification avance',
      'availability_model_label': 'Modele de disponibilite',
      'availability_minutes_per_day': 'Minutes par jour',
      'availability_minutes_per_week': 'Minutes par semaine',
      'availability_specific_hours': 'Heures specifiques (plages)',
      'minutes_per_day_label': 'Minutes par jour',
      'minutes_per_week_label': 'Minutes par semaine',
      'timing_strategy_label': 'Strategie horaire',
      'timing_strategy_untimed': 'Sans heure',
      'timing_strategy_fixed': 'Heures fixes',
      'timing_strategy_auto': 'Placement automatique',
      'flex_outside_windows_label': 'Autoriser hors des plages',
      'revision_only_days_label': 'Jours revision uniquement',
      'specific_hours_windows_label': 'Plages horaires specifiques',
      'add_window_label': 'Ajouter une plage',
      'no_windows_configured': 'Aucune plage configuree.',
      'no_weekly_plan_yet': 'Aucun plan hebdomadaire disponible.',
      'weekly_calendar_title': 'Calendrier hebdomadaire (7 prochains jours)',
      'day_marked_holiday': 'Jour marque comme ferie.',
      'day_not_enabled': "Jour non active pour l'etude.",
      'weekly_session_line':
          '{session} • {focus} • {minutes} min • {time} • {status}',
      'skip_day_label': 'Ignorer le jour / ferie',
      'override_session_time': 'Remplacer heure Session {session}',
      'weekday_short_mon': 'Lun',
      'weekday_short_tue': 'Mar',
      'weekday_short_wed': 'Mer',
      'weekday_short_thu': 'Jeu',
      'weekday_short_fri': 'Ven',
      'weekday_short_sat': 'Sam',
      'weekday_short_sun': 'Dim',
      'companion_progressive_reveal_title': 'Chaine de revelation progressive',
      'companion_current_verse_position': 'Ayah actuelle : {current}/{total}',
      'companion_active_hint_label': 'Indice actif',
      'companion_hint_level_h0': 'Aucun indice demande.',
      'companion_hint_unavailable': 'Indice indisponible',
      'companion_tafsir_cue_placeholder':
          'Indice de sens (placeholder Tafsir al-Muyassar)',
      'companion_play_current_ayah': "Ecouter l'ayah actuelle",
      'companion_autoplay_next_ayah': "Lecture auto ayah suivante",
      'companion_autoplay_on': 'Lecture auto activee',
      'companion_autoplay_off': 'Lecture auto desactivee',
      'companion_record_start': 'Enregistrer / Demarrer',
      'companion_hint_button': 'Indice',
      'companion_repeat_button': 'Repeter',
      'companion_next_button': 'Suivant',
      'companion_stage_progress': 'Etape {current}/{total}',
      'companion_stage_guided_visible': 'Guide visible',
      'companion_stage_cued_recall': 'Rappel avec indice',
      'companion_stage_hidden_reveal': 'Revelation cachee',
      'companion_skip_stage_button': "Passer l'etape",
      'companion_skip_stage_title': "Passer l'etape en cours ?",
      'companion_skip_stage_body':
          'Passer {stage} pour cette session et continuer a l\'etape suivante.',
      'companion_skip_stage_confirm': 'Passer',
      'companion_stage_skipped': 'Etape passee.',
      'companion_mark_correct': 'Marquer correct',
      'companion_mark_incorrect': 'Marquer incorrect',
      'companion_failed_to_save_attempt':
          "Echec de l'enregistrement de la tentative compagnon : {error}",
      'companion_repeat_prompt':
          "Repetez l'ayah actuelle puis appuyez sur Enregistrer/Demarrer.",
      'companion_verse_passed': 'Reussie',
      'companion_verse_revealed': 'Revelee',
      'companion_verse_hidden': 'Cachee',
      'companion_hidden_placeholder': '••••••••••',
      'companion_proficiency': 'Maitrise : {value}',
      'companion_session_complete': 'Session terminee',
      'companion_summary_passed': 'Reussies : {passed}/{total}',
      'companion_summary_hint': "Niveau d'indice moyen : {value}",
      'companion_summary_strength': 'Force moyenne de recuperation : {value}',
      'companion_no_session_state': 'Aucun etat de session compagnon.',
    },
    AppLanguage.portuguese: <String, String>{
      'close': 'Fechar',
      'language': 'Idioma',
      'change_theme': 'Mudar tema',
      'theme_dark': 'Escuro',
      'read': 'Ler',
      'learn': 'Aprender',
      'my_quran': 'Meu Alcorão',
      'my_quran_subtitle':
          'Mantenha seu lugar, seus estudos salvos e sua configuração de escuta juntos.',
      'my_quran_study_setup_title': 'Configuração de estudo',
      'my_quran_study_setup_description':
          'Escolha a ajuda de significado que você quer no Leitor e se Praticar de Memória deve reproduzir automaticamente a próxima ayah.',
      'my_quran_meaning_setup_summary':
          'Ajuda de significado: tradução {translation}, ajuda palavra por palavra {wordHelp}, transliteração {transliteration}.',
      'my_quran_practice_setup_summary':
          'Praticar de Memória: reprodução automática {autoplay}.',
      'my_quran_study_setup_reciter_hint':
          'Use Configuração de escuta se quiser mudar o recitador.',
      'on_label': 'ativado',
      'off_label': 'desativado',
      'quran_radio': 'Rádio Alcorão',
      'reciters': 'Recitadores',
      'reader': 'Leitor',
      'bookmarks': 'Favoritos',
      'notes': 'Notas',
      'plan': 'Plano',
      'my_plan': 'Meu plano',
      'today': 'Hoje',
      'library': 'Biblioteca',
      'settings': 'Configurações',
      'about': 'Sobre',
      'tools': 'Ferramentas',
      'explore': 'Explorar',
      'retry': 'Tentar novamente',
      'done': 'Feito',
      'copy': 'Copiar',
      'share': 'Compartilhar',
      'more': 'Mais',
      'my_quran_continue_reading_title': 'Continuar leitura',
      'my_quran_continue_reading_button': 'Continuar leitura',
      'my_quran_continue_reading_fallback': 'Começar no Leitor',
      'my_quran_continue_reading_description':
          'Retome de onde você abriu o Leitor pela última vez.',
      'my_quran_no_recent_reading':
          'Nenhuma leitura recente foi salva ainda. Abra o Leitor para começar de um lugar ao qual você possa voltar depois.',
      'my_quran_resume_from_page': 'Retomar na página {page}',
      'my_quran_open_reader': 'Abrir Leitor',
      'my_quran_saved_for_later_title': 'Salvo para depois',
      'my_quran_saved_counts': 'Favoritos: {bookmarks} · Notas: {notes}',
      'my_quran_no_saved_items':
          'Nenhum item salvo ainda. Use Salvar para depois ou notas enquanto lê.',
      'my_quran_saved_for_later_description':
          'Abra a Biblioteca para rever versículos e notas salvos.',
      'my_quran_open_library': 'Abrir Biblioteca',
      'my_quran_listening_setup_title': 'Configuração de escuta',
      'my_quran_listening_setup_summary':
          'Velocidade {speed} · Repetição {repeat}',
      'my_quran_open_reciters': 'Abrir recitadores',
      'my_quran_load_failed': 'Falha ao carregar Meu Alcorão.',
      'verse_by_verse': 'Verso por verso',
      'reading': 'Lendo',
      'surah': 'Surah',
      'verse': 'Versículo',
      'juz': 'Juz',
      'page': 'Página',
      'listen': 'Ouvir',
      'play_from_here': 'Reproduzir a partir daqui',
      'pause': 'Pausar',
      'resume': 'Retomar',
      'next': 'Próximo',
      'previous': 'Anterior',
      'audio_options': 'Opções de áudio',
      'download': 'Baixar',
      'manage_repeat_settings': 'Gerenciar configurações de repetição',
      'experience': 'Experiência',
      'playback_speed': 'Velocidade',
      'repeat': 'Repetir',
      'repeat_off': 'Desativado',
      'repeat_1x': '1x',
      'repeat_2x': '2x',
      'repeat_3x': '3x',
      'select_reciter': 'Selecionar recitador',
      'search_reciter': 'Pesquisar recitador',
      'tajweed_colors': 'Cores de Tajweed',
      'tajweed_legend_silent_letter': 'Letra silenciosa',
      'tajweed_legend_normal_madd_2': 'Madd normal (2)',
      'tajweed_legend_separated_madd_246': 'Madd separado (2/4/6)',
      'tajweed_legend_connected_madd_45': 'Madd conectado (4/5)',
      'tajweed_legend_necessary_madd_6': 'Madd necessário (6)',
      'tajweed_legend_ghunna_ikhfa': "Ghunna/ikhfa'",
      'tajweed_legend_qalqala_echo': 'Qalqala (eco)',
      'tajweed_legend_tafkhim_heavy': 'Tafkhim (pesado)',
      'translation': 'Tradução',
      'arabic': 'Árabe',
      'word_by_word': 'Ajuda palavra por palavra',
      'tafsirs': 'Tafsirs',
      'lessons': 'Lições',
      'reflections': 'Reflexões',
      'font_size': 'Tamanho da fonte',
      'selected_reciter': 'Recitador selecionado',
      'translation_unavailable': 'Tradução indisponível',
      'meaning_unavailable': 'Significado indisponível para esta palavra.',
      'meaning_aids_off': 'As ajudas de significado estão desativadas.',
      'study_this_verse': 'Estudar este versículo',
      'bookmark_verse': 'Salvar para depois',
      'transliteration': 'Transliteração',
      'show_verse_translation': 'Mostrar tradução do versículo',
      'show_word_help': 'Mostrar ajuda palavra por palavra',
      'show_transliteration': 'Mostrar transliteração',
      'word_help': 'Ajuda palavra por palavra',
      'word_help_unavailable_for_verse':
          'A ajuda palavra por palavra está indisponível para este versículo no momento.',
      'word_help_description':
          'A ajuda palavra por palavra aparece quando você passa o cursor ou toca em uma palavra no modo Leitura.',
      'hover_word_to_preview_meaning':
          'Passe o cursor ou toque em uma palavra para visualizar o significado.',
      'audio_load_failed': 'Falha na reprodução de áudio: {error}',
      'failed_to_load_reciters': 'Falha ao carregar recitadores.',
      'download_coming_soon': 'Download em breve.',
      'experience_coming_soon': 'Configurações de experiência em breve.',
      'audio_plugin_unavailable':
          'Plugin de áudio indisponível. Reinicie o app após reconstrução completa.',
      'audio_network_error':
          'Fonte de áudio indisponível. Verifique sua conexão com a internet.',
      'reciter_not_available_for_streaming':
          '{reciter} não está disponível para streaming no momento.',
      'reciter_applied_with_bitrate': '{reciter} selecionado ({bitrate} kbps).',
      'elapsed_time_label': 'Decorrido {value}',
      'total_time_label': 'Total {value}',
      'translation_label': 'Tradução: {label}',
      'translation_follows_app_language':
          'A tradução segue o idioma do app agora: {label}.',
      'page_label': 'Página {page}',
      'search_surah': 'Pesquisar Surah',
      'learn_title': 'Planos de aprendizado',
      'bookmarks_title': 'Favoritos',
      'library_title': 'Biblioteca',
      'library_subtitle':
          'Mantenha seus lugares salvos e notas no mesmo lugar.',
      'library_bookmarks_description':
          'Reabra os versículos salvos e continue estudando de onde você parou.',
      'library_notes_description':
          'Revise suas notas de versículos com contexto suficiente para continuar estudando.',
      'open_bookmarks': 'Abrir favoritos',
      'open_notes': 'Abrir notas',
      'failed_to_load_bookmarks': 'Falha ao carregar favoritos.',
      'no_bookmarks_yet': 'Ainda não há favoritos.',
      'saved_label': 'Salvo {timestamp}',
      'saved_for_later_study': 'Salvo para estudar depois',
      'surah_ayah_list_label': 'Surah {surah}, Ayah {ayah}',
      'go_to_verse': 'Reabrir no Leitor',
      'go_to_page': 'Ir para página',
      'notes_title': 'Notas',
      'failed_to_load_notes': 'Falha ao carregar notas.',
      'no_notes_yet': 'Ainda não há notas.',
      'untitled': 'Sem título',
      'failed_to_update_note': 'Falha ao atualizar nota.',
      'edit_note': 'Editar nota',
      'note_title_optional': 'Título (opcional)',
      'note_body': 'Corpo da nota',
      'body_required': 'O corpo é obrigatório.',
      'add_note': 'Adicionar nota',
      'note_save_failed': 'Falha ao salvar nota.',
      'linked_verse': 'Versículo vinculado: Surah {surah}, Ayah {ayah}',
      'linked_verse_with_page':
          'Versículo vinculado: Surah {surah}, Ayah {ayah} (Página {page})',
      'settings_title': 'Configurações',
      'import_quran_text': 'Importar Texto do Alcorão',
      'import_page_metadata': 'Importar Metadados de Página',
      'today_title': 'Hoje',
      'planned_reviews': 'Revisões planejadas',
      'no_planned_reviews_left': 'Não há revisões planejadas restantes.',
      'due_day_label': 'Dia previsto {day}',
      'new_memorization': 'Nova memorização',
      'no_planned_new_units_left':
          'Não há novas unidades planejadas restantes.',
      'open_in_reader': 'Abrir no leitor',
      'page_metadata_required_to_open_in_reader':
          'Metadados de página são necessários para abrir no leitor.',
      'self_check_grade': 'Autoavaliação',
      'failed_to_load_today_plan': 'Falha ao carregar plano de hoje.',
      'grade_saved': 'Nota salva.',
      'failed_to_save_grade': 'Falha ao salvar nota.',
      'today_completion_start_title': 'Um começo real conta',
      'today_completion_start_message':
          'Você concluiu um dia real de prática. Isso já basta para começar a construir consistência.',
      'today_completion_sparse_title': 'Um recomeço calmo também conta',
      'today_completion_sparse_message':
          'Você concluiu trabalho real hoje. Alguns dias calmos assim já bastam para reconstruir a confiança no plano.',
      'today_completion_recovery_title': 'Trabalho de recuperação também conta',
      'today_completion_recovery_message':
          'Você protegeu a retenção com um dia mais leve. Isso é uma vitória segura enquanto o plano se estabiliza.',
      'today_empty_sparse_title': 'Hoje pode continuar leve',
      'today_empty_sparse_message':
          'Você está voltando ao ritmo. Abra Meu Plano se quiser um próximo passo mais claro para a semana.',
      'today_empty_recovery_title':
          'Uma pausa de recuperação pode ser intencional',
      'today_empty_recovery_message':
          'O planejador está deixando hoje mais leve para você se estabilizar com segurança. Abra Meu Plano se quiser revisar ou aliviar mais a semana.',
      'range_unavailable': 'Intervalo indisponível',
      'grade_good': 'Bom',
      'grade_medium': 'Médio',
      'grade_hard': 'Difícil',
      'grade_very_hard': 'Muito difícil',
      'grade_fail': 'Falha',
      'plan_setup_title': 'Configurar Meu Plano',
      'plan_setup_subtitle':
          'Escolha um ritmo, um tempo realista e ative seu plano. Você pode ajustar os detalhes depois.',
      'plan_preset_question': '1) Quão ambicioso este plano deve ser?',
      'plan_preset_easy': 'Fácil',
      'plan_preset_easy_description':
          'Protege a revisão primeiro e mantém o trabalho novo leve.',
      'plan_preset_normal': 'Normal',
      'plan_preset_normal_description':
          'Memorização nova equilibrada com forte suporte de revisão.',
      'plan_preset_intensive': 'Intensivo',
      'plan_preset_intensive_description':
          'Avance mais rápido se sua rotina for estável.',
      'plan_guided_note':
          'Se a vida estiver corrida ou você estiver recuperando atraso, comece em Fácil. Você ainda pode ajustar o modo só revisão em Avançado.',
      'plan_advanced_title': 'Avançado',
      'plan_advanced_subtitle':
          'Abra isto apenas se quiser ajustar agendamento, previsão, calibração ou regras de recuperação.',
      'plan_open_advanced': 'Mostrar Avançado',
      'plan_hide_advanced': 'Ocultar Avançado',
      'plan_fine_tune_title': 'Ajustar este plano',
      'plan_summary_pace': 'Ritmo',
      'plan_summary_time': 'Tempo',
      'plan_summary_new_limit': 'Limite de trabalho novo',
      'plan_summary_review_priority': 'Prioridade de revisão',
      'plan_summary_time_value':
          '{weekly} minutos por semana, cerca de {daily} minutos por dia.',
      'plan_summary_new_limit_value':
          'Até {pages} novas páginas ou {units} novas unidades em um dia de estudo.',
      'plan_review_priority_easy':
          'Dê mais espaço para revisão e diminua o trabalho novo quando a pressão aumentar.',
      'plan_review_priority_normal':
          'Mantenha um equilíbrio entre proteger a revisão e seguir com nova memorização.',
      'plan_review_priority_intensive':
          'Acelere a nova memorização quando sua rotina puder sustentar isso.',
      'goal_focus_title': 'Objetivo desta semana',
      'goal_focus_steady_progress': 'Progresso constante',
      'goal_focus_protect_retention': 'Proteger a retenção',
      'goal_focus_recovery_and_stabilize': 'Recuperar e estabilizar',
      'today_goal_good_day_label': 'Um bom dia',
      'today_goal_support_label': 'Como a tarefa principal ajuda',
      'today_goal_short_day_label': 'Se o dia ficar curto',
      'today_goal_good_day_steady':
          'Um bom dia significa concluir a tarefa principal e, se o tempo permitir, o restante do trabalho planejado para hoje.',
      'today_goal_good_day_protect':
          'Um bom dia significa proteger primeiro o trabalho vencido, mesmo que a prática nova fique mais leve.',
      'today_goal_good_day_recovery':
          'Um bom dia significa fazer o trabalho essencial mais seguro sem forçar uma carga completa.',
      'today_goal_support_steady':
          'A principal tarefa de hoje apoia um progresso constante ao manter seu plano andando sem sobrecarga.',
      'today_goal_support_protect':
          'A principal tarefa de hoje apoia a retenção ao proteger primeiro as revisões e as verificações adiadas.',
      'today_goal_support_recovery':
          'A principal tarefa de hoje apoia a recuperação ao reduzir a pressão e reconstruir a consistência.',
      'today_goal_short_day_steady':
          'Num dia curto, a principal tarefa planejada ainda conta como uma vitória real.',
      'today_goal_short_day_protect':
          'Num dia curto, concluir o trabalho vencido de maior prioridade já é suficiente.',
      'today_goal_short_day_recovery':
          'Num dia curto, o dia mínimo é um sucesso, não um retrocesso.',
      'plan_goal_summary_hint':
          'Isso muda automaticamente conforme a pressão atual do seu plano.',
      'plan_goal_summary_hint_start':
          'Comece com algumas sessões reais nesta semana. O resumo vai se preencher automaticamente.',
      'plan_goal_summary_hint_sparse':
          'Uma semana calma e repetível já basta. Mais algumas sessões reais deixarão este resumo mais claro.',
      'plan_goal_summary_hint_recovery':
          'Esta semana é para se estabilizar com segurança, não para provar velocidade.',
      'plan_goal_summary_steady':
          'Seu plano está leve o bastante para buscar um progresso constante e sustentável nesta semana.',
      'plan_goal_summary_protect':
          'Seu plano deve proteger a retenção primeiro nesta semana, mesmo que o trabalho novo fique mais leve.',
      'plan_goal_summary_recovery':
          'A meta mais segura desta semana é estabilizar e reduzir a pressão antes de acelerar de novo.',
      'weekly_progress_title': 'Últimos 7 dias',
      'weekly_progress_consistency_label': 'Consistência',
      'weekly_progress_completed_work_label': 'Trabalho concluído',
      'weekly_progress_recent_quality_label': 'Qualidade recente das revisões',
      'weekly_progress_trend_start':
          'Comece a construir consistência com uma sessão real hoje: prática, revisão ou verificação adiada.',
      'weekly_progress_trend_steady':
          'Seu trabalho recente sustenta um ritmo semanal estável.',
      'weekly_progress_trend_building':
          'Você está construindo consistência. Mantenha a tarefa principal simples e repetível.',
      'weekly_progress_trend_sparse':
          'Você está retomando o ritmo. Algumas sessões calmas e reais já bastam nesta semana.',
      'weekly_progress_trend_protect':
          'Há trabalho recente, mas a retenção ainda precisa da parte mais segura do seu tempo.',
      'weekly_progress_trend_recovery':
          'Recuperação também conta. Um dia mais leve, mas real, protege o plano.',
      'weekly_progress_consistency_start':
          'Ainda não há histórico significativo. Um dia real já basta para começar.',
      'weekly_progress_consistency_value':
          '{days} dias ativos nos últimos 7 dias.',
      'weekly_progress_counts_start':
          'O trabalho concluído começará a aparecer aqui após sua primeira sessão real.',
      'weekly_progress_counts_value':
          '{reviews} revisões, {delayedChecks} verificações adiadas, {practiceCompletions} práticas concluídas.',
      'weekly_progress_quality_steady': 'Principalmente estável',
      'weekly_progress_quality_mixed': 'Mista',
      'weekly_progress_quality_strained': 'Precisa de um ritmo mais leve',
      'weekly_progress_quality_not_enough_data':
          'Ainda não há dados de revisão suficientes',
      'weekly_progress_note_label': 'Como ler isto',
      'weekly_progress_note_start':
          'Uma sessão real já basta para começar. Este bloco se preenche automaticamente conforme você conclui trabalho real.',
      'weekly_progress_note_sparse':
          'Uma volta suave também conta. Mantenha as próximas sessões simples e repetíveis.',
      'weekly_progress_note_steady':
          'Continue repetindo a tarefa principal e deixe os dias constantes se acumularem.',
      'weekly_progress_note_protect':
          'Deixe revisões e verificações adiadas ficarem com a parte mais segura do seu tempo até a pressão cair.',
      'weekly_progress_note_recovery':
          'Uma semana mais leve também conta enquanto o planejador ajuda você a se estabilizar com segurança.',
      'weekly_progress_recent_quality_line':
          'Qualidade recente das revisões: {value}',
      'no_ayahs_for_surah': 'Nenhum ayah encontrado para a Surah {surah}.',
      'no_ayahs_for_page': 'Nenhum ayah encontrado para a Página {page}.',
      'onboarding_questionnaire': 'Questionário inicial ({count} perguntas)',
      'run_forecast': 'Executar previsão',
      'running': 'Executando...',
      'suggested_plan_editable': 'Resumo do seu plano',
      'daily_minutes_by_weekday': 'Minutos diários por dia da semana',
      'avg_new_minutes_per_ayah': 'Média de minutos novos por ayah',
      'avg_review_minutes_per_ayah': 'Média de minutos de revisão por ayah',
      'require_page_metadata': 'Exigir metadados de página',
      'activate': 'Ativar',
      'activating': 'Ativando...',
      'calibration_mode_optional': 'Modo de calibração (opcional)',
      'time_input': '2) Quanto tempo é realista?',
      'weekly_total': 'Total semanal',
      'per_weekday': 'Por dia da semana',
      'weekly_minutes': 'Minutos semanais',
      'fluency': '3) Quão confortável você está com a memorização agora?',
      'fluency_fluent': 'fluente',
      'fluency_developing': 'em desenvolvimento',
      'fluency_support': 'suporte',
      'profile': 'Perfil do planejador',
      'profile_support': 'suporte',
      'profile_standard': 'padrão',
      'profile_accelerated': 'acelerado',
      'force_revision_only': 'Proteger revisão quando houver atraso',
      'daily_new_item_caps': 'Limites diários de trabalho novo',
      'max_new_pages_per_day': 'Máx. novas páginas por dia',
      'max_new_units_per_day': 'Máx. novas unidades por dia',
      'duration_minutes': 'Duração (minutos)',
      'ayah_count': 'Contagem de ayahs',
      'about_title': 'Sobre',
      'open_hifz_plan': 'Abrir Plano de Hifz',
      'open_companion_chain': 'Abrir cadeia do companheiro',
      'planned_review_minutes': 'Minutos de revisao planejados: {value}',
      'planned_new_minutes': 'Minutos de novo planejados: {value}',
      'review_pressure_label': 'Pressao de revisao: {value}',
      'recovery_mode_active':
          'Modo de recuperacao ativo: nova memorizacao pausada',
      'today_sessions': 'Sessoes de hoje',
      'no_sessions_planned': 'Nenhuma sessao planejada.',
      'new_and_review_focus': 'Novo + revisao',
      'review_only_focus': 'Apenas revisao',
      'session_status_pending': 'pendente',
      'session_status_completed': 'concluida',
      'session_status_missed': 'perdida',
      'session_status_due_soon': 'vence em breve',
      'session_minutes': '{minutes} min',
      'untimed_session_label': 'Sem horario',
      'automatic_scheduling_title': 'Agendamento automatico',
      'two_sessions_per_day': '2 sessoes por dia',
      'set_exact_times_question': 'Definir horarios exatos?',
      'session_time_label': 'Sessao {session}: {value}',
      'study_days_label': 'Dias de estudo',
      'advanced_scheduling_mode': 'Modo de agendamento avancado',
      'availability_model_label': 'Modelo de disponibilidade',
      'availability_minutes_per_day': 'Minutos por dia',
      'availability_minutes_per_week': 'Minutos por semana',
      'availability_specific_hours': 'Horas especificas (janelas)',
      'minutes_per_day_label': 'Minutos por dia',
      'minutes_per_week_label': 'Minutos por semana',
      'timing_strategy_label': 'Estrategia de horario',
      'timing_strategy_untimed': 'Sem horario',
      'timing_strategy_fixed': 'Horarios fixos',
      'timing_strategy_auto': 'Posicionamento automatico',
      'flex_outside_windows_label': 'Permitir fora das janelas',
      'revision_only_days_label': 'Dias somente revisao',
      'specific_hours_windows_label': 'Janelas de horas especificas',
      'add_window_label': 'Adicionar janela',
      'no_windows_configured': 'Nenhuma janela configurada.',
      'no_weekly_plan_yet': 'Nenhum plano semanal disponivel.',
      'weekly_calendar_title': 'Calendario semanal (proximos 7 dias)',
      'day_marked_holiday': 'Dia marcado como feriado.',
      'day_not_enabled': 'Dia nao habilitado para estudo.',
      'weekly_session_line':
          '{session} • {focus} • {minutes} min • {time} • {status}',
      'skip_day_label': 'Pular dia / feriado',
      'override_session_time': 'Substituir horario da Sessao {session}',
      'weekday_short_mon': 'Seg',
      'weekday_short_tue': 'Ter',
      'weekday_short_wed': 'Qua',
      'weekday_short_thu': 'Qui',
      'weekday_short_fri': 'Sex',
      'weekday_short_sat': 'Sab',
      'weekday_short_sun': 'Dom',
      'companion_progressive_reveal_title': 'Cadeia de revelacao progressiva',
      'companion_current_verse_position': 'Ayah atual: {current}/{total}',
      'companion_active_hint_label': 'Dica ativa',
      'companion_hint_level_h0': 'Nenhuma dica solicitada.',
      'companion_hint_unavailable': 'Dica indisponivel',
      'companion_tafsir_cue_placeholder':
          'Dica de significado (placeholder Tafsir al-Muyassar)',
      'companion_play_current_ayah': 'Ouvir ayah atual',
      'companion_autoplay_next_ayah': 'Reproducao auto da proxima ayah',
      'companion_autoplay_on': 'Reproducao auto ativada',
      'companion_autoplay_off': 'Reproducao auto desativada',
      'companion_record_start': 'Gravar / Iniciar',
      'companion_hint_button': 'Dica',
      'companion_repeat_button': 'Repetir',
      'companion_next_button': 'Proximo',
      'companion_stage_progress': 'Etapa {current}/{total}',
      'companion_stage_guided_visible': 'Guiado visivel',
      'companion_stage_cued_recall': 'Recordacao por pista',
      'companion_stage_hidden_reveal': 'Revelacao oculta',
      'companion_skip_stage_button': 'Pular etapa',
      'companion_skip_stage_title': 'Pular etapa atual?',
      'companion_skip_stage_body':
          'Pular {stage} nesta sessao e continuar para a proxima etapa.',
      'companion_skip_stage_confirm': 'Pular',
      'companion_stage_skipped': 'Etapa pulada.',
      'companion_mark_correct': 'Marcar correto',
      'companion_mark_incorrect': 'Marcar incorreto',
      'companion_failed_to_save_attempt':
          'Falha ao salvar tentativa do companheiro: {error}',
      'companion_repeat_prompt':
          'Repita a ayah atual e pressione Gravar/Iniciar quando estiver pronto.',
      'companion_verse_passed': 'Aprovada',
      'companion_verse_revealed': 'Revelada',
      'companion_verse_hidden': 'Oculta',
      'companion_hidden_placeholder': '••••••••••',
      'companion_proficiency': 'Proficiencia: {value}',
      'companion_session_complete': 'Sessao concluida',
      'companion_summary_passed': 'Aprovadas: {passed}/{total}',
      'companion_summary_hint': 'Nivel medio de dica: {value}',
      'companion_summary_strength': 'Forca media de recuperacao: {value}',
      'companion_no_session_state': 'Nenhum estado de sessao do companheiro.',
    },
    AppLanguage.arabic: <String, String>{
      'menu': 'القائمة',
      'close': 'إغلاق',
      'language': 'اللغة',
      'change_theme': 'تغيير النمط',
      'theme_sepia': 'سيبيا',
      'theme_dark': 'داكن',
      'read': 'اقرأ',
      'learn': 'تعلّم',
      'my_quran': 'قرآني',
      'my_quran_subtitle':
          'اجمع موضعك والعناصر المحفوظة وإعدادات الاستماع في مكان واحد.',
      'my_quran_study_setup_title': 'إعداد الدراسة',
      'my_quran_study_setup_description':
          'اختر وسائل المعنى التي تريدها في القارئ وما إذا كانت ممارسة الحفظ ستشغّل الآية التالية تلقائياً.',
      'my_quran_meaning_setup_summary':
          'وسائل المعنى: الترجمة {translation}، مساعدة الكلمات {wordHelp}، النقل الصوتي {transliteration}.',
      'my_quran_practice_setup_summary':
          'ممارسة الحفظ: التشغيل التلقائي {autoplay}.',
      'my_quran_study_setup_reciter_hint':
          'استخدم إعدادات الاستماع إذا أردت تغيير القارئ.',
      'on_label': 'مفعل',
      'off_label': 'متوقف',
      'quran_radio': 'راديو القرآن',
      'reciters': 'القراء',
      'reader': 'القارئ',
      'bookmarks': 'العلامات',
      'notes': 'الملاحظات',
      'plan': 'الخطة',
      'my_plan': 'خطتي',
      'today': 'اليوم',
      'library': 'المكتبة',
      'settings': 'الإعدادات',
      'about': 'حول',
      'tools': 'الأدوات',
      'explore': 'استكشف',
      'retry': 'أعد المحاولة',
      'done': 'تم',
      'copy': 'نسخ',
      'share': 'مشاركة',
      'more': 'المزيد',
      'my_quran_continue_reading_title': 'متابعة القراءة',
      'my_quran_continue_reading_button': 'متابعة القراءة',
      'my_quran_continue_reading_fallback': 'ابدأ من القارئ',
      'my_quran_continue_reading_description':
          'تابع من الموضع الذي فتحت عنده القارئ آخر مرة.',
      'my_quran_no_recent_reading':
          'لا توجد قراءة حديثة محفوظة بعد. افتح القارئ لتبدأ من موضع يمكنك الرجوع إليه لاحقًا.',
      'my_quran_resume_from_page': 'المتابعة من الصفحة {page}',
      'my_quran_open_reader': 'فتح القارئ',
      'my_quran_saved_for_later_title': 'محفوظ لوقت لاحق',
      'my_quran_saved_counts': 'العلامات: {bookmarks} · الملاحظات: {notes}',
      'my_quran_no_saved_items':
          'لا توجد عناصر محفوظة بعد. استخدم "احفظ لوقت لاحق" أو الملاحظات أثناء القراءة.',
      'my_quran_saved_for_later_description':
          'افتح المكتبة لمراجعة الآيات والملاحظات المحفوظة.',
      'my_quran_open_library': 'فتح المكتبة',
      'my_quran_listening_setup_title': 'إعدادات الاستماع',
      'my_quran_listening_setup_summary': 'السرعة {speed} · التكرار {repeat}',
      'my_quran_open_reciters': 'فتح القراء',
      'my_quran_load_failed': 'تعذر تحميل قرآني.',
      'reset': 'إعادة تعيين',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'verse_by_verse': 'آية بآية',
      'reading': 'القراءة',
      'surah': 'سورة',
      'verse': 'آية',
      'juz': 'جزء',
      'page': 'صفحة',
      'listen': 'استمع',
      'play_from_here': 'تشغيل من هنا',
      'pause': 'إيقاف مؤقت',
      'resume': 'استئناف',
      'next': 'التالي',
      'previous': 'السابق',
      'audio_options': 'خيارات الصوت',
      'download': 'تنزيل',
      'manage_repeat_settings': 'إدارة إعدادات التكرار',
      'experience': 'التجربة',
      'playback_speed': 'السرعة',
      'repeat': 'تكرار',
      'repeat_off': 'إيقاف',
      'repeat_1x': '1x',
      'repeat_2x': '2x',
      'repeat_3x': '3x',
      'select_reciter': 'اختر القارئ',
      'search_reciter': 'ابحث عن قارئ',
      'tajweed_colors': 'ألوان التجويد',
      'tajweed_legend_silent_letter': 'الحرف الساكن',
      'tajweed_legend_normal_madd_2': 'مد حركتان',
      'tajweed_legend_separated_madd_246': 'المد المنفصل (2 / 4 / 6 حركات)',
      'tajweed_legend_connected_madd_45': 'المد المتصل (4 أو 5 حركات)',
      'tajweed_legend_necessary_madd_6': 'المد اللازم (6 حركات)',
      'tajweed_legend_ghunna_ikhfa': 'غنة / إخفاء',
      'tajweed_legend_qalqala_echo': 'قلقلة',
      'tajweed_legend_tafkhim_heavy': 'تفخيم الصوت',
      'translation': 'الترجمة',
      'arabic': 'العربية',
      'word_by_word': 'مساعدة الكلمات',
      'tafsirs': 'تفاسير',
      'lessons': 'فوائد',
      'reflections': 'تدبرات',
      'bookmark_verse': 'احفظها لوقت لاحق',
      'add_edit_note': 'إضافة/تعديل ملاحظة',
      'copy_text_uthmani': 'نسخ النص (عثماني)',
      'study_this_verse': 'ادرس هذه الآية',
      'translation_unavailable': 'الترجمة غير متاحة',
      'meaning_unavailable': 'المعنى غير متاح لهذه الكلمة.',
      'meaning_aids_off': 'وسائل المعنى متوقفة.',
      'transliteration': 'النقل الصوتي',
      'show_verse_translation': 'إظهار ترجمة الآية',
      'show_word_help': 'إظهار مساعدة الكلمة',
      'show_transliteration': 'إظهار النقل الصوتي',
      'word_help': 'مساعدة الكلمات',
      'word_help_unavailable_for_verse':
          'مساعدة الكلمات غير متاحة لهذه الآية الآن.',
      'word_help_description':
          'تظهر مساعدة الكلمة عند المرور فوق الكلمة أو لمسها في وضع القراءة.',
      'hover_word_to_preview_meaning':
          'مرّر فوق كلمة أو المسها لمعاينة المعنى.',
      'audio_load_failed': 'فشل تشغيل الصوت: {error}',
      'failed_to_load_reciters': 'تعذر تحميل قائمة القراء.',
      'download_coming_soon': 'ميزة التنزيل قريبًا.',
      'experience_coming_soon': 'إعدادات التجربة قريبًا.',
      'audio_plugin_unavailable':
          'ملحق الصوت غير متاح. أعد تشغيل التطبيق بعد إعادة البناء الكاملة.',
      'audio_network_error': 'مصدر الصوت غير متاح. تحقق من اتصال الإنترنت.',
      'reciter_not_available_for_streaming':
          'القارئ {reciter} غير متاح للبث حالياً.',
      'reciter_applied_with_bitrate':
          'تم اختيار {reciter} ({bitrate} كيلوبت/ث).',
      'elapsed_time_label': 'الوقت المنقضي {value}',
      'total_time_label': 'المدة الكلية {value}',
      'translation_follows_app_language':
          'تتبع الترجمة لغة التطبيق حالياً: {label}.',
      'script_style': 'نمط الخط',
      'uthmani': 'عثماني',
      'tajweed': 'تجويد',
      'show_tajweed_rules_while_reading': 'إظهار قواعد التجويد أثناء القراءة',
      'font_size': 'حجم الخط',
      'selected_reciter': 'القارئ المحدد',
      'preview': 'معاينة',
      'word': 'كلمة',
      'translation_label': 'الترجمة: {label}',
      'page_label': 'صفحة {page}',
      'juz_label': 'جزء {juz}',
      'hizb_label': 'حزب {hizb}',
      'surah_label': 'سورة {surah}',
      'ayah_label': 'آية {ayah}',
      'search_surah': 'ابحث عن سورة',
      'learn_title': 'خطط التعلّم',
      'bookmarks_title': 'العلامات',
      'library_title': 'المكتبة',
      'library_subtitle': 'احتفظ بمواضعك المحفوظة وملاحظاتك في مكان واحد.',
      'library_bookmarks_description':
          'أعد فتح الآيات المحفوظة وتابع الدراسة من حيث توقفت.',
      'library_notes_description':
          'راجع ملاحظاتك على الآيات مع سياق كافٍ لمواصلة الدراسة.',
      'open_bookmarks': 'فتح العلامات',
      'open_notes': 'فتح الملاحظات',
      'failed_to_load_bookmarks': 'تعذر تحميل العلامات.',
      'no_bookmarks_yet': 'لا توجد علامات بعد.',
      'saved_label': 'تم الحفظ {timestamp}',
      'saved_for_later_study': 'محفوظة للدراسة لاحقًا',
      'surah_ayah_list_label': 'سورة {surah}، آية {ayah}',
      'go_to_verse': 'إعادة فتحها في القارئ',
      'go_to_page': 'الانتقال إلى الصفحة',
      'notes_title': 'الملاحظات',
      'failed_to_load_notes': 'تعذر تحميل الملاحظات.',
      'no_notes_yet': 'لا توجد ملاحظات بعد.',
      'untitled': 'بدون عنوان',
      'failed_to_update_note': 'فشل تحديث الملاحظة.',
      'edit_note': 'تعديل الملاحظة',
      'note_title_optional': 'العنوان (اختياري)',
      'note_body': 'نص الملاحظة',
      'body_required': 'المحتوى مطلوب.',
      'add_note': 'إضافة ملاحظة',
      'note_save_failed': 'فشل حفظ الملاحظة.',
      'linked_verse': 'الآية المرتبطة: سورة {surah}، آية {ayah}',
      'linked_verse_with_page':
          'الآية المرتبطة: سورة {surah}، آية {ayah} (صفحة {page})',
      'settings_title': 'الإعدادات',
      'import_quran_text': 'استيراد نص القرآن',
      'import_page_metadata': 'استيراد بيانات الصفحات',
      'today_title': 'اليوم',
      'planned_reviews': 'المراجعات المخطط لها',
      'no_planned_reviews_left': 'لا توجد مراجعات متبقية.',
      'due_day_label': 'اليوم المستحق {day}',
      'new_memorization': 'حفظ جديد',
      'no_planned_new_units_left': 'لا توجد وحدات جديدة متبقية.',
      'open_in_reader': 'افتح في القارئ',
      'page_metadata_required_to_open_in_reader':
          'بيانات الصفحة مطلوبة للفتح في القارئ.',
      'self_check_grade': 'تقييم ذاتي',
      'failed_to_load_today_plan': 'تعذر تحميل خطة اليوم.',
      'grade_saved': 'تم حفظ التقييم.',
      'failed_to_save_grade': 'فشل حفظ التقييم.',
      'today_completion_start_title': 'بداية حقيقية تُحسب',
      'today_completion_start_message':
          'أكملت يومًا حقيقيًا من التدريب. وهذا يكفي لبدء بناء الانتظام.',
      'today_completion_sparse_title': 'العودة الهادئة تُحسب أيضًا',
      'today_completion_sparse_message':
          'أكملت عملًا حقيقيًا اليوم. بضع أيام هادئة كهذا تكفي لإعادة الثقة بالخطة.',
      'today_completion_recovery_title': 'عمل التعافي يُحسب أيضًا',
      'today_completion_recovery_message':
          'لقد حميت التثبيت بيوم أخف. وهذا نجاح آمن بينما تستعيد الخطة توازنها.',
      'today_empty_sparse_title': 'يمكن أن يبقى اليوم خفيفًا',
      'today_empty_sparse_message':
          'أنت تعود إلى الإيقاع بهدوء. افتح خطتي إذا أردت خطوة أسبوعية أوضح.',
      'today_empty_recovery_title': 'قد تكون استراحة التعافي مقصودة',
      'today_empty_recovery_message':
          'المخطط يبقي اليوم خفيفًا لتستعيد التوازن بأمان. افتح خطتي إذا أردت مراجعة الأسبوع أو تخفيفه أكثر.',
      'range_unavailable': 'النطاق غير متاح',
      'grade_good': 'جيد',
      'grade_medium': 'متوسط',
      'grade_hard': 'صعب',
      'grade_very_hard': 'صعب جدًا',
      'grade_fail': 'رسوب',
      'plan_setup_title': 'إعداد خطتي',
      'plan_setup_subtitle':
          'اختر وتيرة مناسبة ووقتًا واقعيًا ثم فعّل خطتك. يمكنك ضبط التفاصيل لاحقًا.',
      'plan_preset_question': '1) ما مستوى الطموح الذي تريده لهذه الخطة؟',
      'plan_preset_easy': 'سهل',
      'plan_preset_easy_description':
          'يقدّم المراجعة أولًا ويجعل العمل الجديد خفيفًا.',
      'plan_preset_normal': 'عادي',
      'plan_preset_normal_description': 'حفظ جديد متوازن مع دعم قوي للمراجعة.',
      'plan_preset_intensive': 'مكثف',
      'plan_preset_intensive_description': 'تقدّم أسرع إذا كان جدولك مستقرًا.',
      'plan_guided_note':
          'إذا كانت ظروفك مشغولة أو كنت تلحق ما فاتك فابدأ بخيار سهل. ويمكنك لاحقًا ضبط وضع المراجعة فقط من الإعدادات المتقدمة.',
      'plan_advanced_title': 'متقدم',
      'plan_advanced_subtitle':
          'افتح هذا فقط إذا أردت ضبط الجدولة أو التوقعات أو المعايرة أو قواعد التعافي.',
      'plan_open_advanced': 'إظهار المتقدم',
      'plan_hide_advanced': 'إخفاء المتقدم',
      'plan_fine_tune_title': 'ضبط هذه الخطة',
      'plan_summary_pace': 'الوتيرة',
      'plan_summary_time': 'الوقت',
      'plan_summary_new_limit': 'حد العمل الجديد',
      'plan_summary_review_priority': 'أولوية المراجعة',
      'plan_summary_time_value':
          '{weekly} دقيقة في الأسبوع، حوالي {daily} دقيقة في اليوم.',
      'plan_summary_new_limit_value':
          'حتى {pages} صفحات جديدة أو {units} وحدات جديدة في يوم الدراسة.',
      'plan_review_priority_easy':
          'امنح المراجعة مساحة أكبر وخفف العمل الجديد عند ارتفاع الضغط.',
      'plan_review_priority_normal':
          'حافظ على توازن بين حماية المراجعة واستمرار الحفظ الجديد.',
      'plan_review_priority_intensive':
          'ادفع الحفظ الجديد أكثر عندما يسمح جدولك بذلك.',
      'goal_focus_title': 'هدف هذا الأسبوع',
      'goal_focus_steady_progress': 'تقدّم ثابت',
      'goal_focus_protect_retention': 'احمِ التثبيت',
      'goal_focus_recovery_and_stabilize': 'التعافي واستعادة التوازن',
      'today_goal_good_day_label': 'اليوم الجيد',
      'today_goal_support_label': 'كيف تدعم مهمة اليوم الهدف',
      'today_goal_short_day_label': 'إذا ضاق وقت اليوم',
      'today_goal_good_day_steady':
          'اليوم الجيد يعني إنجاز المهمة الرئيسية، ثم إكمال بقية العمل المخطط إذا سمح الوقت.',
      'today_goal_good_day_protect':
          'اليوم الجيد يعني حماية العمل المستحق أولًا، حتى لو بقي العمل الجديد أخف.',
      'today_goal_good_day_recovery':
          'اليوم الجيد يعني أداء العمل الأساسي الآمن دون فرض حمل كامل.',
      'today_goal_support_steady':
          'مهمة اليوم الرئيسية تدعم التقدم الثابت بإبقاء الخطة تتحرك من دون ضغط زائد.',
      'today_goal_support_protect':
          'مهمة اليوم الرئيسية تدعم التثبيت عبر تقديم المراجعة والفحص المؤجل أولًا.',
      'today_goal_support_recovery':
          'مهمة اليوم الرئيسية تدعم التعافي عبر خفض الضغط وإعادة بناء الاستمرارية.',
      'today_goal_short_day_steady':
          'في اليوم القصير، تبقى المهمة الأساسية المخططة إنجازًا حقيقيًا.',
      'today_goal_short_day_protect':
          'في اليوم القصير، يكفي إنهاء أعلى عمل مستحق أولوية.',
      'today_goal_short_day_recovery':
          'في اليوم القصير، يُعد اليوم الأدنى نجاحًا لا تراجعًا.',
      'plan_goal_summary_hint': 'يتغير هذا تلقائيًا حسب ضغط خطتك الحالي.',
      'plan_goal_summary_hint_start':
          'ابدأ ببضع جلسات حقيقية هذا الأسبوع. سيمتلئ الملخص تلقائيًا.',
      'plan_goal_summary_hint_sparse':
          'يكفي أسبوع هادئ وقابل للتكرار. وستجعل بضع جلسات حقيقية إضافية هذا الملخص أوضح.',
      'plan_goal_summary_hint_recovery':
          'هذا الأسبوع مخصص لاستعادة التوازن بأمان، لا لإثبات السرعة.',
      'plan_goal_summary_steady':
          'خطتك خفيفة بما يكفي لاستهداف تقدّم ثابت ومستدام هذا الأسبوع.',
      'plan_goal_summary_protect':
          'ينبغي أن تركز خطتك هذا الأسبوع على حماية التثبيت أولًا، حتى لو بقي العمل الجديد أخف.',
      'plan_goal_summary_recovery':
          'الهدف الأكثر أمانًا هذا الأسبوع هو استعادة التوازن وتقليل الضغط قبل زيادة الوتيرة.',
      'weekly_progress_title': 'آخر 7 أيام',
      'weekly_progress_consistency_label': 'الانتظام',
      'weekly_progress_completed_work_label': 'العمل المنجز',
      'weekly_progress_recent_quality_label': 'جودة المراجعة مؤخرًا',
      'weekly_progress_trend_start':
          'ابدأ ببناء الانتظام من خلال جلسة حقيقية اليوم: تدريب أو مراجعة أو تحقق مؤجل.',
      'weekly_progress_trend_steady':
          'عملك الأخير يدعم إيقاعًا أسبوعيًا ثابتًا.',
      'weekly_progress_trend_building':
          'أنت تبني الانتظام. اجعل المهمة الأساسية بسيطة وقابلة للتكرار.',
      'weekly_progress_trend_sparse':
          'أنت تعود إلى الإيقاع. بضع جلسات هادئة وحقيقية تكفي هذا الأسبوع.',
      'weekly_progress_trend_protect':
          'يوجد عمل حديث، لكن التثبيت ما زال يحتاج إلى الحصة الأكثر أمانًا من وقتك.',
      'weekly_progress_trend_recovery':
          'التعافي يُحسب أيضًا. يوم أخف لكنه حقيقي يحمي الخطة.',
      'weekly_progress_consistency_start':
          'لا يوجد سجل ذو معنى بعد. يوم حقيقي واحد يكفي للبداية.',
      'weekly_progress_consistency_value': '{days} أيام نشطة خلال آخر 7 أيام.',
      'weekly_progress_counts_start':
          'سيظهر العمل المنجز هنا بعد أول جلسة حقيقية لك.',
      'weekly_progress_counts_value':
          '{reviews} مراجعات، {delayedChecks} تحققات مؤجلة، {practiceCompletions} جلسات تدريب مكتملة.',
      'weekly_progress_quality_steady': 'مستقرة في الغالب',
      'weekly_progress_quality_mixed': 'مختلطة',
      'weekly_progress_quality_strained': 'تحتاج إلى وتيرة ألطف',
      'weekly_progress_quality_not_enough_data':
          'لا توجد بيانات مراجعة كافية بعد',
      'weekly_progress_note_label': 'كيف تقرأ هذا',
      'weekly_progress_note_start':
          'جلسة حقيقية واحدة تكفي للبداية. سيمتلئ هذا الجزء تلقائيًا كلما أنجزت عملًا حقيقيًا.',
      'weekly_progress_note_sparse':
          'العودة الهادئة تُحسب أيضًا. اجعل الجلسات القادمة بسيطة وقابلة للتكرار.',
      'weekly_progress_note_steady':
          'واصل تكرار المهمة الأساسية ودع الأيام الثابتة تتراكم.',
      'weekly_progress_note_protect':
          'دع المراجعات والتحققات المؤجلة تأخذ الحصة الأكثر أمانًا من وقتك حتى ينخفض الضغط.',
      'weekly_progress_note_recovery':
          'الأسبوع الأخف يُحسب أيضًا بينما يساعدك المخطط على استعادة التوازن بأمان.',
      'weekly_progress_recent_quality_line': 'جودة المراجعة مؤخرًا: {value}',
      'no_ayahs_for_surah': 'لا توجد آيات للسورة {surah}.',
      'no_ayahs_for_page': 'لا توجد آيات للصفحة {page}.',
      'onboarding_questionnaire': 'استبيان البداية ({count} أسئلة)',
      'run_forecast': 'تشغيل التنبؤ',
      'running': 'جارٍ التشغيل...',
      'suggested_plan_editable': 'ملخص خطتك',
      'daily_minutes_by_weekday': 'الدقائق اليومية حسب أيام الأسبوع',
      'avg_new_minutes_per_ayah': 'متوسط دقائق الجديد لكل آية',
      'avg_review_minutes_per_ayah': 'متوسط دقائق المراجعة لكل آية',
      'require_page_metadata': 'يتطلب بيانات الصفحة',
      'activate': 'تفعيل',
      'activating': 'جارٍ التفعيل...',
      'calibration_mode_optional': 'وضع المعايرة (اختياري)',
      'time_input': '2) ما الوقت الواقعي المتاح؟',
      'weekly_total': 'الإجمالي الأسبوعي',
      'per_weekday': 'لكل يوم',
      'weekly_minutes': 'الدقائق الأسبوعية',
      'fluency': '3) ما مدى راحتك مع الحفظ الآن؟',
      'fluency_fluent': 'متقن',
      'fluency_developing': 'قيد التطوير',
      'fluency_support': 'دعم',
      'profile': 'ملف التخطيط',
      'profile_support': 'دعم',
      'profile_standard': 'قياسي',
      'profile_accelerated': 'متسارع',
      'force_revision_only': 'حماية المراجعة عند تراكم التأخير',
      'daily_new_item_caps': 'حدود العمل الجديد اليومية',
      'max_new_pages_per_day': 'أقصى صفحات جديدة يوميًا',
      'max_new_units_per_day': 'أقصى وحدات جديدة يوميًا',
      'duration_minutes': 'المدة (دقائق)',
      'ayah_count': 'عدد الآيات',
      'about_title': 'حول',
      'open_hifz_plan': 'فتح خطة الحفظ',
      'open_companion_chain': 'فتح سلسلة المرافق',
      'planned_review_minutes': 'دقائق المراجعة المخططة: {value}',
      'planned_new_minutes': 'دقائق الجديد المخططة: {value}',
      'review_pressure_label': 'ضغط المراجعة: {value}',
      'recovery_mode_active': 'وضع التعافي نشط: إيقاف الحفظ الجديد مؤقتًا',
      'today_sessions': 'جلسات اليوم',
      'no_sessions_planned': 'لا توجد جلسات مخططة.',
      'new_and_review_focus': 'جديد + مراجعة',
      'review_only_focus': 'مراجعة فقط',
      'session_status_pending': 'قيد الانتظار',
      'session_status_completed': 'مكتملة',
      'session_status_missed': 'فاتت',
      'session_status_due_soon': 'مستحقة قريبًا',
      'session_minutes': '{minutes} دقيقة',
      'untimed_session_label': 'غير محددة الوقت',
      'automatic_scheduling_title': 'الجدولة التلقائية',
      'two_sessions_per_day': 'جلستان يوميًا',
      'set_exact_times_question': 'تحديد أوقات دقيقة؟',
      'session_time_label': 'الجلسة {session}: {value}',
      'study_days_label': 'أيام الدراسة',
      'advanced_scheduling_mode': 'وضع الجدولة المتقدم',
      'availability_model_label': 'نموذج التوفر',
      'availability_minutes_per_day': 'دقائق لكل يوم',
      'availability_minutes_per_week': 'دقائق لكل أسبوع',
      'availability_specific_hours': 'ساعات محددة (نوافذ)',
      'minutes_per_day_label': 'الدقائق لكل يوم',
      'minutes_per_week_label': 'الدقائق لكل أسبوع',
      'timing_strategy_label': 'استراتيجية التوقيت',
      'timing_strategy_untimed': 'غير محدد الوقت',
      'timing_strategy_fixed': 'أوقات ثابتة',
      'timing_strategy_auto': 'توزيع تلقائي',
      'flex_outside_windows_label': 'السماح خارج النوافذ',
      'revision_only_days_label': 'أيام مراجعة فقط',
      'specific_hours_windows_label': 'نوافذ الساعات المحددة',
      'add_window_label': 'إضافة نافذة',
      'no_windows_configured': 'لا توجد نوافذ مهيأة.',
      'no_weekly_plan_yet': 'لا توجد خطة أسبوعية متاحة حتى الآن.',
      'weekly_calendar_title': 'التقويم الأسبوعي (الأيام السبعة القادمة)',
      'day_marked_holiday': 'اليوم محدد كإجازة.',
      'day_not_enabled': 'اليوم غير مفعّل للدراسة.',
      'weekly_session_line':
          '{session} • {focus} • {minutes} دقيقة • {time} • {status}',
      'skip_day_label': 'تخطي اليوم / إجازة',
      'override_session_time': 'تجاوز وقت الجلسة {session}',
      'weekday_short_mon': 'الإثنين',
      'weekday_short_tue': 'الثلاثاء',
      'weekday_short_wed': 'الأربعاء',
      'weekday_short_thu': 'الخميس',
      'weekday_short_fri': 'الجمعة',
      'weekday_short_sat': 'السبت',
      'weekday_short_sun': 'الأحد',
      'companion_progressive_reveal_title': 'سلسلة الكشف التدريجي',
      'companion_current_verse_position': 'الآية الحالية: {current}/{total}',
      'companion_active_hint_label': 'التلميح النشط',
      'companion_hint_level_h0': 'لم يتم طلب تلميح بعد.',
      'companion_hint_unavailable': 'التلميح غير متاح',
      'companion_tafsir_cue_placeholder':
          'إشارة المعنى (عنصر نائب لتفسير الميسر)',
      'companion_play_current_ayah': 'تشغيل الآية الحالية',
      'companion_autoplay_next_ayah': 'تشغيل تلقائي للآية التالية',
      'companion_autoplay_on': 'التشغيل التلقائي مفعل',
      'companion_autoplay_off': 'التشغيل التلقائي متوقف',
      'companion_record_start': 'تسجيل / بدء',
      'companion_hint_button': 'تلميح',
      'companion_repeat_button': 'إعادة',
      'companion_next_button': 'التالي',
      'companion_stage_progress': 'المرحلة {current}/{total}',
      'companion_stage_guided_visible': 'موجّه ظاهر',
      'companion_stage_cued_recall': 'استرجاع بالمفتاح',
      'companion_stage_hidden_reveal': 'كشف مخفي',
      'companion_skip_stage_button': 'تخطي المرحلة',
      'companion_skip_stage_title': 'تخطي المرحلة الحالية؟',
      'companion_skip_stage_body':
          'تخطي {stage} في هذه الجلسة والمتابعة إلى المرحلة التالية.',
      'companion_skip_stage_confirm': 'تخطي',
      'companion_stage_skipped': 'تم تخطي المرحلة.',
      'companion_mark_correct': 'تحديد كصحيح',
      'companion_mark_incorrect': 'تحديد كغير صحيح',
      'companion_failed_to_save_attempt': 'تعذر حفظ محاولة المرافق: {error}',
      'companion_repeat_prompt':
          'أعد الآية الحالية ثم اضغط تسجيل/بدء عندما تكون جاهزًا.',
      'companion_verse_passed': 'تم الاجتياز',
      'companion_verse_revealed': 'تم الكشف',
      'companion_verse_hidden': 'مخفية',
      'companion_hidden_placeholder': '••••••••••',
      'companion_proficiency': 'مستوى الإتقان: {value}',
      'companion_session_complete': 'اكتملت الجلسة',
      'companion_summary_passed': 'المجتاز: {passed}/{total}',
      'companion_summary_hint': 'متوسط مستوى التلميح: {value}',
      'companion_summary_strength': 'متوسط قوة الاسترجاع: {value}',
      'companion_no_session_state': 'لا توجد حالة جلسة للمرافق.',
      'basmala_translation': 'بسم الله الرحمن الرحيم',
    },
  };
}
