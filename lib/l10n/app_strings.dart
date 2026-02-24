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
  String get quranRadio => _t('quran_radio', 'Quran Radio');
  String get reciters => _t('reciters', 'Reciters');
  String get reader => _t('reader', 'Reader');
  String get bookmarks => _t('bookmarks', 'Bookmarks');
  String get notes => _t('notes', 'Notes');
  String get plan => _t('plan', 'Plan');
  String get today => _t('today', 'Today');
  String get settings => _t('settings', 'Settings');
  String get about => _t('about', 'About');
  String get retry => _t('retry', 'Retry');
  String get done => _t('done', 'Done');
  String get reset => _t('reset', 'Reset');
  String get save => _t('save', 'Save');
  String get cancel => _t('cancel', 'Cancel');
  String get copy => _t('copy', 'Copy');
  String get share => _t('share', 'Share');
  String get more => _t('more', 'More');
  String get comingSoon => _t('coming_soon', 'Coming soon.');
  String get unknown => _t('unknown', 'Unknown');

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
  String get wordByWord => _t('word_by_word', 'Word By Word');
  String get tafsirs => _t('tafsirs', 'Tafsirs');
  String get lessons => _t('lessons', 'Lessons');
  String get reflections => _t('reflections', 'Reflections');

  String get bookmarkVerse => _t('bookmark_verse', 'Bookmark verse');
  String get addEditNote => _t('add_edit_note', 'Add/Edit note');
  String get copyTextUthmani => _t('copy_text_uthmani', 'Copy text (Uthmani)');
  String get openSettings => _t('open_settings', 'Open settings');
  String get closeSettings => _t('close_settings', 'Close settings');
  String get translationUnavailable =>
      _t('translation_unavailable', 'Translation unavailable');
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
  String get basmalaTranslation => _t(
        'basmala_translation',
        'In the Name of Allah - the Most Compassionate, Most Merciful',
      );

  String translationLabel(String label) => _fmt(
        _t('translation_label', 'Translation: {label}'),
        <String, Object>{'label': label},
      );
  String pageLabel(int pageNumber) => _fmt(
        _t('page_label', 'Page {page}'),
        <String, Object>{'page': pageNumber},
      );
  String juzLabel(int juzNumber) => _fmt(
        _t('juz_label', 'Juz {juz}'),
        <String, Object>{'juz': juzNumber},
      );
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
        'Build your long-term Quran routine and track progress over time.',
      );
  String get hifzPlanTitle => _t('hifz_plan_title', 'Hifz Plan');
  String get hifzPlanSubtitle => _t(
        'hifz_plan_subtitle',
        'Create and maintain your memorization plan.',
      );
  String get openHifzPlan => _t('open_hifz_plan', 'Open Hifz Plan');
  String get aboutTitle => _t('about_title', 'About');

  String get bookmarksTitle => _t('bookmarks_title', 'Bookmarks');
  String get failedToLoadBookmarks =>
      _t('failed_to_load_bookmarks', 'Failed to load bookmarks.');
  String get failedToLoadReciters =>
      _t('failed_to_load_reciters', 'Failed to load reciters.');
  String get noBookmarksYet => _t('no_bookmarks_yet', 'No bookmarks yet.');
  String savedLabel(String timestamp) => _fmt(
        _t('saved_label', 'Saved {timestamp}'),
        <String, Object>{'timestamp': timestamp},
      );
  String surahAyahListLabel(int surahNumber, int ayahNumber) => _fmt(
        _t('surah_ayah_list_label', 'Surah {surah}, Ayah {ayah}'),
        <String, Object>{'surah': surahNumber, 'ayah': ayahNumber},
      );
  String get goToVerse => _t('go_to_verse', 'Go to verse');
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
    return _fmt(
      template,
      <String, Object?>{
        'surah': surahNumber,
        'ayah': ayahNumber,
        'page': pageNumber,
      },
    );
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
  }) =>
      _fmt(
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
        _t('page_metadata_import_failed',
            'Page metadata import failed: {error}'),
        <String, Object>{'error': error},
      );
  String get completed => _t('completed', 'completed');
  String get importQuranText => _t('import_quran_text', "Import Qur'an Text");
  String get importPageMetadata =>
      _t('import_page_metadata', 'Import Page Metadata');

  String get todayTitle => _t('today_title', 'Today');
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

  String onboardingQuestionnaire(int questionCount) => _fmt(
        _t('onboarding_questionnaire',
            'Onboarding Questionnaire ({count} questions)'),
        <String, Object>{'count': questionCount},
      );
  String get forecastDeterministicSimulation => _t(
      'forecast_deterministic_simulation',
      'Forecast (Deterministic Simulation)');
  String get runForecast => _t('run_forecast', 'Run Forecast');
  String get running => _t('running', 'Running...');
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
      _t('suggested_plan_editable', 'Suggested Plan (Editable)');
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
      _t('calibration_mode_optional', 'Calibration Mode (Optional)');
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
        _t(
          'review_samples_preview',
          'Review samples: {count}, median: {median}',
        ),
        <String, Object>{'count': count, 'median': median},
      );
  String get typicalGradeDistributionPercent => _t(
        'typical_grade_distribution_percent',
        'Typical grade distribution (%)',
      );
  String get applyTiming => _t('apply_timing', 'Apply timing');
  String get applyNow => _t('apply_now', 'Apply now');
  String get applyFromTomorrow =>
      _t('apply_from_tomorrow', 'Apply from tomorrow');
  String get applying => _t('applying', 'Applying...');
  String get applyCalibration => _t('apply_calibration', 'Apply Calibration');
  String get timeInput => _t('time_input', '1) Time input');
  String get weeklyTotal => _t('weekly_total', 'Weekly total');
  String get perWeekday => _t('per_weekday', 'Per weekday');
  String get weeklyMinutes => _t('weekly_minutes', 'Weekly minutes');
  String get fluency => _t('fluency', '2) Fluency');
  String get fluencyFluent => _t('fluency_fluent', 'fluent');
  String get fluencyDeveloping => _t('fluency_developing', 'developing');
  String get fluencySupport => _t('fluency_support', 'support');
  String get profile => _t('profile', '3) Profile');
  String get profileSupport => _t('profile_support', 'support');
  String get profileStandard => _t('profile_standard', 'standard');
  String get profileAccelerated => _t('profile_accelerated', 'accelerated');
  String get forceRevisionOnly =>
      _t('force_revision_only', '4) Force Revision Only');
  String get dailyNewItemCaps =>
      _t('daily_new_item_caps', '5-6) Daily new-item caps');
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
      _t('calibration_applied_immediately', 'Calibration applied immediately.');
  String get calibrationQueuedForTomorrow =>
      _t('calibration_queued_for_tomorrow', 'Calibration queued for tomorrow.');
  String calibrationApplyFailed(String error) => _fmt(
        _t('calibration_apply_failed', 'Calibration apply failed: {error}'),
        <String, Object>{'error': error},
      );
  String forecastFailed(String error) => _fmt(
        _t('forecast_failed', 'Forecast failed: {error}'),
        <String, Object>{'error': error},
      );
  String get enterAllQPercentagesOrBlank => _t(
        'enter_all_q_percentages_or_blank',
        'Enter all q percentages (5,4,3,2,0) or leave all blank.',
      );
  String qMustBeIntegerPercentage(int q) => _fmt(
        _t('q_must_be_integer_percentage',
            'q{q} must be an integer percentage.'),
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
      'target_ayah_no_page_metadata', 'Target ayah has no page metadata yet.');
  String get targetAyahPageUnavailable => _t(
        'target_ayah_page_unavailable_import',
        'Target ayah page is not available in imported metadata.',
      );
  String get tajweedTagsUnavailableShowingPlain => _t(
        'tajweed_tags_unavailable_showing_plain',
        'Tajweed tags unavailable. Showing plain text.',
      );
  String noPageMetadataForSurah(int surahNumber) => _fmt(
        _t('no_page_metadata_for_surah',
            'No page metadata found for Surah {surah}.'),
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
        _t('ayah_not_found_in_surah',
            'Ayah {ayah} was not found in Surah {surah}.'),
        <String, Object>{'ayah': ayahNumber, 'surah': surahNumber},
      );
  String get verseAlreadyBookmarked =>
      _t('verse_already_bookmarked', 'Verse already bookmarked.');
  String get bookmarkSaved => _t('bookmark_saved', 'Bookmark saved.');
  String get failedToSaveBookmark =>
      _t('failed_to_save_bookmark', 'Failed to save bookmark.');
  String get noteAdded => _t('note_added', 'Note added.');
  String get copiedVerseText => _t('copied_verse_text', 'Copied verse text.');
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
        _t(
          'reciter_applied_with_bitrate',
          '{reciter} selected ({bitrate} kbps).',
        ),
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
      'Translation settings are coming soon.');
  String get wordByWordSettingsComingSoon => _t(
        'word_by_word_settings_coming_soon',
        'Word by Word settings are coming soon.',
      );
  String get verseActionsUnavailable => _t(
        'verse_actions_unavailable',
        'Verse actions unavailable for this page data.',
      );

  static const Map<AppLanguage, Map<String, String>> _overrides =
      <AppLanguage, Map<String, String>>{
    AppLanguage.french: <String, String>{
      'close': 'Fermer',
      'language': 'Langue',
      'change_theme': 'Changer le thème',
      'theme_dark': 'Sombre',
      'read': 'Lire',
      'learn': 'Apprendre',
      'my_quran': 'Mon Coran',
      'quran_radio': 'Radio Coran',
      'reciters': 'Récitateurs',
      'reader': 'Lecteur',
      'bookmarks': 'Signets',
      'notes': 'Notes',
      'plan': 'Plan',
      'today': "Aujourd'hui",
      'settings': 'Paramètres',
      'about': 'À propos',
      'retry': 'Réessayer',
      'done': 'Fait',
      'copy': 'Copier',
      'share': 'Partager',
      'more': 'Plus',
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
      'word_by_word': 'Mot à mot',
      'script_style': "Style d'écriture",
      'show_tajweed_rules_while_reading':
          'Afficher les règles de tajwid pendant la lecture',
      'font_size': 'Taille de police',
      'selected_reciter': 'Récitateur sélectionné',
      'verse_actions_unavailable':
          "Actions de l'ayah indisponibles pour ces données de page.",
      'translation_unavailable': 'Traduction indisponible',
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
      'page_label': 'Page {page}',
      'juz_label': 'Juz {juz}',
      'hizb_label': 'Hizb {hizb}',
      'surah_label': 'Sourate {surah}',
      'ayah_label': 'Ayah {ayah}',
      'search_surah': 'Rechercher une sourate',
      'learn_title': "Plans d'apprentissage",
      'bookmarks_title': 'Signets',
      'failed_to_load_bookmarks': 'Échec du chargement des signets.',
      'no_bookmarks_yet': 'Aucun signet pour le moment.',
      'saved_label': 'Enregistré {timestamp}',
      'surah_ayah_list_label': 'Sourate {surah}, Ayah {ayah}',
      'go_to_verse': "Aller à l'ayah",
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
      'range_unavailable': 'Plage indisponible',
      'grade_good': 'Bon',
      'grade_medium': 'Moyen',
      'grade_hard': 'Difficile',
      'grade_very_hard': 'Très difficile',
      'grade_fail': 'Échec',
      'no_ayahs_for_surah': 'Aucun ayah trouvé pour la sourate {surah}.',
      'no_ayahs_for_page': 'Aucun ayah trouvé pour la page {page}.',
      'onboarding_questionnaire':
          "Questionnaire d'intégration ({count} questions)",
      'run_forecast': 'Lancer la prévision',
      'running': 'Exécution...',
      'suggested_plan_editable': 'Plan suggéré (modifiable)',
      'daily_minutes_by_weekday': 'Minutes quotidiennes par jour',
      'avg_new_minutes_per_ayah': 'Moyenne minutes nouvelles par ayah',
      'avg_review_minutes_per_ayah': 'Moyenne minutes révision par ayah',
      'require_page_metadata': 'Exiger les métadonnées de page',
      'activate': 'Activer',
      'activating': 'Activation...',
      'calibration_mode_optional': 'Mode calibration (optionnel)',
      'time_input': '1) Saisie du temps',
      'weekly_total': 'Total hebdomadaire',
      'per_weekday': 'Par jour',
      'weekly_minutes': 'Minutes hebdomadaires',
      'fluency': '2) Fluidité',
      'fluency_fluent': 'fluide',
      'fluency_developing': 'en progression',
      'fluency_support': 'support',
      'profile': '3) Profil',
      'profile_support': 'support',
      'profile_standard': 'standard',
      'profile_accelerated': 'accéléré',
      'force_revision_only': '4) Forcer révision seulement',
      'daily_new_item_caps': '5-6) Limites quotidiennes de nouveaux éléments',
      'max_new_pages_per_day': 'Max nouvelles pages par jour',
      'max_new_units_per_day': 'Max nouvelles unités par jour',
      'duration_minutes': 'Durée (minutes)',
      'ayah_count': "Nombre d'ayahs",
      'about_title': 'À propos',
      'open_hifz_plan': 'Ouvrir le plan de Hifz',
    },
    AppLanguage.portuguese: <String, String>{
      'close': 'Fechar',
      'language': 'Idioma',
      'change_theme': 'Mudar tema',
      'theme_dark': 'Escuro',
      'read': 'Ler',
      'learn': 'Aprender',
      'my_quran': 'Meu Alcorão',
      'quran_radio': 'Rádio Alcorão',
      'reciters': 'Recitadores',
      'reader': 'Leitor',
      'bookmarks': 'Favoritos',
      'notes': 'Notas',
      'plan': 'Plano',
      'today': 'Hoje',
      'settings': 'Configurações',
      'about': 'Sobre',
      'retry': 'Tentar novamente',
      'done': 'Feito',
      'copy': 'Copiar',
      'share': 'Compartilhar',
      'more': 'Mais',
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
      'word_by_word': 'Palavra por palavra',
      'tafsirs': 'Tafsirs',
      'lessons': 'Lições',
      'reflections': 'Reflexões',
      'font_size': 'Tamanho da fonte',
      'selected_reciter': 'Recitador selecionado',
      'translation_unavailable': 'Tradução indisponível',
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
      'page_label': 'Página {page}',
      'search_surah': 'Pesquisar Surah',
      'learn_title': 'Planos de aprendizado',
      'bookmarks_title': 'Favoritos',
      'failed_to_load_bookmarks': 'Falha ao carregar favoritos.',
      'no_bookmarks_yet': 'Ainda não há favoritos.',
      'saved_label': 'Salvo {timestamp}',
      'surah_ayah_list_label': 'Surah {surah}, Ayah {ayah}',
      'go_to_verse': 'Ir para versículo',
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
      'range_unavailable': 'Intervalo indisponível',
      'grade_good': 'Bom',
      'grade_medium': 'Médio',
      'grade_hard': 'Difícil',
      'grade_very_hard': 'Muito difícil',
      'grade_fail': 'Falha',
      'no_ayahs_for_surah': 'Nenhum ayah encontrado para a Surah {surah}.',
      'no_ayahs_for_page': 'Nenhum ayah encontrado para a Página {page}.',
      'onboarding_questionnaire': 'Questionário inicial ({count} perguntas)',
      'run_forecast': 'Executar previsão',
      'running': 'Executando...',
      'suggested_plan_editable': 'Plano sugerido (editável)',
      'daily_minutes_by_weekday': 'Minutos diários por dia da semana',
      'avg_new_minutes_per_ayah': 'Média de minutos novos por ayah',
      'avg_review_minutes_per_ayah': 'Média de minutos de revisão por ayah',
      'require_page_metadata': 'Exigir metadados de página',
      'activate': 'Ativar',
      'activating': 'Ativando...',
      'calibration_mode_optional': 'Modo de calibração (opcional)',
      'time_input': '1) Entrada de tempo',
      'weekly_total': 'Total semanal',
      'per_weekday': 'Por dia da semana',
      'weekly_minutes': 'Minutos semanais',
      'fluency': '2) Fluência',
      'fluency_fluent': 'fluente',
      'fluency_developing': 'em desenvolvimento',
      'fluency_support': 'suporte',
      'profile': '3) Perfil',
      'profile_support': 'suporte',
      'profile_standard': 'padrão',
      'profile_accelerated': 'acelerado',
      'force_revision_only': '4) Forçar somente revisão',
      'daily_new_item_caps': '5-6) Limites diários de novos itens',
      'max_new_pages_per_day': 'Máx. novas páginas por dia',
      'max_new_units_per_day': 'Máx. novas unidades por dia',
      'duration_minutes': 'Duração (minutos)',
      'ayah_count': 'Contagem de ayahs',
      'about_title': 'Sobre',
      'open_hifz_plan': 'Abrir Plano de Hifz',
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
      'quran_radio': 'راديو القرآن',
      'reciters': 'القراء',
      'reader': 'القارئ',
      'bookmarks': 'العلامات',
      'notes': 'الملاحظات',
      'plan': 'الخطة',
      'today': 'اليوم',
      'settings': 'الإعدادات',
      'about': 'حول',
      'retry': 'أعد المحاولة',
      'done': 'تم',
      'copy': 'نسخ',
      'share': 'مشاركة',
      'more': 'المزيد',
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
      'word_by_word': 'كلمة بكلمة',
      'tafsirs': 'تفاسير',
      'lessons': 'فوائد',
      'reflections': 'تدبرات',
      'bookmark_verse': 'حفظ الآية',
      'add_edit_note': 'إضافة/تعديل ملاحظة',
      'copy_text_uthmani': 'نسخ النص (عثماني)',
      'translation_unavailable': 'الترجمة غير متاحة',
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
      'failed_to_load_bookmarks': 'تعذر تحميل العلامات.',
      'no_bookmarks_yet': 'لا توجد علامات بعد.',
      'saved_label': 'تم الحفظ {timestamp}',
      'surah_ayah_list_label': 'سورة {surah}، آية {ayah}',
      'go_to_verse': 'الانتقال إلى الآية',
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
      'range_unavailable': 'النطاق غير متاح',
      'grade_good': 'جيد',
      'grade_medium': 'متوسط',
      'grade_hard': 'صعب',
      'grade_very_hard': 'صعب جدًا',
      'grade_fail': 'رسوب',
      'no_ayahs_for_surah': 'لا توجد آيات للسورة {surah}.',
      'no_ayahs_for_page': 'لا توجد آيات للصفحة {page}.',
      'onboarding_questionnaire': 'استبيان البداية ({count} أسئلة)',
      'run_forecast': 'تشغيل التنبؤ',
      'running': 'جارٍ التشغيل...',
      'suggested_plan_editable': 'الخطة المقترحة (قابلة للتعديل)',
      'daily_minutes_by_weekday': 'الدقائق اليومية حسب أيام الأسبوع',
      'avg_new_minutes_per_ayah': 'متوسط دقائق الجديد لكل آية',
      'avg_review_minutes_per_ayah': 'متوسط دقائق المراجعة لكل آية',
      'require_page_metadata': 'يتطلب بيانات الصفحة',
      'activate': 'تفعيل',
      'activating': 'جارٍ التفعيل...',
      'calibration_mode_optional': 'وضع المعايرة (اختياري)',
      'time_input': '1) إدخال الوقت',
      'weekly_total': 'الإجمالي الأسبوعي',
      'per_weekday': 'لكل يوم',
      'weekly_minutes': 'الدقائق الأسبوعية',
      'fluency': '2) الطلاقة',
      'fluency_fluent': 'متقن',
      'fluency_developing': 'قيد التطوير',
      'fluency_support': 'دعم',
      'profile': '3) الملف الشخصي',
      'profile_support': 'دعم',
      'profile_standard': 'قياسي',
      'profile_accelerated': 'متسارع',
      'force_revision_only': '4) فرض المراجعة فقط',
      'daily_new_item_caps': '5-6) حدود العناصر الجديدة اليومية',
      'max_new_pages_per_day': 'أقصى صفحات جديدة يوميًا',
      'max_new_units_per_day': 'أقصى وحدات جديدة يوميًا',
      'duration_minutes': 'المدة (دقائق)',
      'ayah_count': 'عدد الآيات',
      'about_title': 'حول',
      'open_hifz_plan': 'فتح خطة الحفظ',
      'basmala_translation': 'بسم الله الرحمن الرحيم',
    },
  };
}
