import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_preferences.dart';
import '../data/providers/database_providers.dart';
import '../data/services/calibration_service.dart';
import '../data/services/forecast_simulation_service.dart';
import '../data/services/onboarding_defaults.dart';
import '../data/services/scheduling/scheduling_preferences_codec.dart';
import '../data/services/scheduling/weekly_plan_generator.dart';
import '../data/time/local_day_time.dart';
import '../l10n/app_strings.dart';

enum _TimeInputMode { weekly, weekday }

enum _CalibrationTimingUi { now, tomorrow }

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  _TimeInputMode _timeInputMode = _TimeInputMode.weekly;
  GuidedPlanPreset _guidedPreset = GuidedPlanPreset.normal;
  bool _showAdvanced = false;
  final _weeklyMinutesController = TextEditingController(text: '315');
  late final Map<String, TextEditingController> _weekdayControllers = {
    for (final key in onboardingWeekdayKeys)
      key: TextEditingController(text: '45'),
  };
  OnboardingFluency _fluency = OnboardingFluency.developing;
  String _profile = 'standard';
  bool _forceRevisionOnly = true;
  final _maxNewPagesController = TextEditingController(text: '1');
  final _maxNewUnitsController = TextEditingController(text: '8');

  late final TextEditingController _avgNewMinutesController;
  late final TextEditingController _avgReviewMinutesController;
  bool _avgNewDirty = false;
  bool _avgReviewDirty = false;
  bool _requirePageMetadata = true;

  bool _isActivating = false;
  String? _errorMessage;

  final _newDurationController = TextEditingController();
  final _newAyahCountController = TextEditingController();
  final _reviewDurationController = TextEditingController();
  final _reviewAyahCountController = TextEditingController();
  final _gradeQ5Controller = TextEditingController();
  final _gradeQ4Controller = TextEditingController();
  final _gradeQ3Controller = TextEditingController();
  final _gradeQ2Controller = TextEditingController();
  final _gradeQ0Controller = TextEditingController();

  _CalibrationTimingUi _calibrationTiming = _CalibrationTimingUi.now;
  CalibrationPreview? _calibrationPreview;
  bool _isRefreshingCalibration = false;
  bool _isAddingSample = false;
  bool _isApplyingCalibration = false;

  bool _isRunningForecast = false;
  ForecastSimulationResult? _forecastResult;
  String? _forecastError;

  SchedulingPreferencesV1 _schedulingPreferences =
      SchedulingPreferencesV1.defaults;
  SchedulingOverridesV1 _schedulingOverrides = SchedulingOverridesV1.empty;
  WeeklyPlan? _weeklyPlan;
  bool _isLoadingScheduling = true;
  bool _isRefreshingWeeklyPlan = false;
  String? _weeklyPlanError;
  late final TextEditingController _minutesPerDayController;
  late final TextEditingController _minutesPerWeekController;

  AppStrings get _strings =>
      AppStrings.of(ref.read(appPreferencesProvider).language);

  @override
  void initState() {
    super.initState();
    final defaults = defaultsForFluency(_fluency);
    _avgNewMinutesController = TextEditingController(
      text: defaults.avgNew.toStringAsFixed(1),
    );
    _avgReviewMinutesController = TextEditingController(
      text: defaults.avgReview.toStringAsFixed(1),
    );
    _minutesPerDayController = TextEditingController(
      text: _schedulingPreferences.minutesPerDayDefault.toString(),
    );
    _minutesPerWeekController = TextEditingController(
      text: _schedulingPreferences.minutesPerWeekDefault.toString(),
    );
    Future<void>.microtask(_refreshCalibrationPreview);
    Future<void>.microtask(_loadSchedulingState);
  }

  @override
  void dispose() {
    _weeklyMinutesController.dispose();
    for (final controller in _weekdayControllers.values) {
      controller.dispose();
    }
    _maxNewPagesController.dispose();
    _maxNewUnitsController.dispose();
    _avgNewMinutesController.dispose();
    _avgReviewMinutesController.dispose();
    _minutesPerDayController.dispose();
    _minutesPerWeekController.dispose();

    _newDurationController.dispose();
    _newAyahCountController.dispose();
    _reviewDurationController.dispose();
    _reviewAyahCountController.dispose();
    _gradeQ5Controller.dispose();
    _gradeQ4Controller.dispose();
    _gradeQ3Controller.dispose();
    _gradeQ2Controller.dispose();
    _gradeQ0Controller.dispose();
    super.dispose();
  }

  Map<String, int> _currentWeekdayMinutes() {
    if (_timeInputMode == _TimeInputMode.weekly) {
      final weekly = int.tryParse(_weeklyMinutesController.text.trim()) ?? 0;
      return splitWeeklyMinutesEvenly(weekly.clamp(0, 1000000));
    }

    return <String, int>{
      for (final key in onboardingWeekdayKeys)
        key: int.tryParse(_weekdayControllers[key]!.text.trim()) ?? 0,
    };
  }

  int _totalWeeklyMinutes(Map<String, int> weekdayMinutes) {
    return weekdayMinutes.values.fold<int>(0, (sum, value) => sum + value);
  }

  Map<int, int> _weekdayMinutesForScheduling(Map<String, int> weekdayMinutes) {
    return <int, int>{
      DateTime.monday: weekdayMinutes['mon'] ?? 0,
      DateTime.tuesday: weekdayMinutes['tue'] ?? 0,
      DateTime.wednesday: weekdayMinutes['wed'] ?? 0,
      DateTime.thursday: weekdayMinutes['thu'] ?? 0,
      DateTime.friday: weekdayMinutes['fri'] ?? 0,
      DateTime.saturday: weekdayMinutes['sat'] ?? 0,
      DateTime.sunday: weekdayMinutes['sun'] ?? 0,
    };
  }

  Map<String, int> _weekdayMinutesFromScheduling(
    SchedulingPreferencesV1 preferences,
  ) {
    return <String, int>{
      'mon': preferences.minutesByWeekday[DateTime.monday] ??
          preferences.minutesPerDayDefault,
      'tue': preferences.minutesByWeekday[DateTime.tuesday] ??
          preferences.minutesPerDayDefault,
      'wed': preferences.minutesByWeekday[DateTime.wednesday] ??
          preferences.minutesPerDayDefault,
      'thu': preferences.minutesByWeekday[DateTime.thursday] ??
          preferences.minutesPerDayDefault,
      'fri': preferences.minutesByWeekday[DateTime.friday] ??
          preferences.minutesPerDayDefault,
      'sat': preferences.minutesByWeekday[DateTime.saturday] ??
          preferences.minutesPerDayDefault,
      'sun': preferences.minutesByWeekday[DateTime.sunday] ??
          preferences.minutesPerDayDefault,
    };
  }

  SchedulingPreferencesV1 _syncedSchedulingPreferencesFromCurrentInputs() {
    final weekdayMinutes = _currentWeekdayMinutes();
    final dailyDefault = deriveDailyDefault(weekdayMinutes);
    final weeklyTotal = _totalWeeklyMinutes(weekdayMinutes);
    return _schedulingPreferences.copyWith(
      minutesPerDayDefault: dailyDefault,
      minutesPerWeekDefault: weeklyTotal,
      minutesByWeekday: _weekdayMinutesForScheduling(weekdayMinutes),
    );
  }

  void _syncGuidedInputsIntoSchedulingPreferences() {
    final synced = _syncedSchedulingPreferencesFromCurrentInputs();
    setState(() {
      _schedulingPreferences = synced;
      _minutesPerDayController.text = synced.minutesPerDayDefault.toString();
      _minutesPerWeekController.text = synced.minutesPerWeekDefault.toString();
    });
    Future<void>.microtask(_refreshWeeklyPlan);
  }

  void _applyGuidedPreset(GuidedPlanPreset preset) {
    final defaults = defaultsForGuidedPlanPreset(preset);
    setState(() {
      _guidedPreset = preset;
      _profile = defaults.profile;
      _forceRevisionOnly = defaults.forceRevisionOnly;
      _maxNewPagesController.text = defaults.maxNewPagesPerDay.toString();
      _maxNewUnitsController.text = defaults.maxNewUnitsPerDay.toString();
    });
    Future<void>.microtask(_refreshWeeklyPlan);
  }

  OnboardingFluency _inferFluency({
    required double avgNew,
    required double avgReview,
  }) {
    var best = OnboardingFluency.developing;
    var bestDistance = double.infinity;
    for (final option in OnboardingFluency.values) {
      final defaults = defaultsForFluency(option);
      final distance =
          (defaults.avgNew - avgNew).abs() + (defaults.avgReview - avgReview).abs();
      if (distance < bestDistance) {
        best = option;
        bestDistance = distance;
      }
    }
    return best;
  }

  bool _matchesFluencyDefaults({
    required OnboardingFluency fluency,
    required double avgNew,
    required double avgReview,
  }) {
    final defaults = defaultsForFluency(fluency);
    return (defaults.avgNew - avgNew).abs() < 0.05 &&
        (defaults.avgReview - avgReview).abs() < 0.05;
  }

  void _onFluencyChanged(OnboardingFluency value) {
    setState(() {
      _fluency = value;
      final defaults = defaultsForFluency(value);
      if (!_avgNewDirty) {
        _avgNewMinutesController.text = defaults.avgNew.toStringAsFixed(1);
      }
      if (!_avgReviewDirty) {
        _avgReviewMinutesController.text =
            defaults.avgReview.toStringAsFixed(1);
      }
    });
  }

  Future<void> _activatePlan() async {
    setState(() {
      _errorMessage = null;
    });

    final weekdayMinutes = _currentWeekdayMinutes();
    final syncedSchedulingPreferences =
        _syncedSchedulingPreferencesFromCurrentInputs();
    final validMinutes = weekdayMinutes.values.every((value) => value > 0);
    final maxNewPages = int.tryParse(_maxNewPagesController.text.trim());
    final maxNewUnits = int.tryParse(_maxNewUnitsController.text.trim());
    final avgNew = double.tryParse(_avgNewMinutesController.text.trim());
    final avgReview = double.tryParse(_avgReviewMinutesController.text.trim());

    if (!validMinutes ||
        maxNewPages == null ||
        maxNewPages <= 0 ||
        maxNewUnits == null ||
        maxNewUnits <= 0 ||
        avgNew == null ||
        avgNew <= 0 ||
        avgReview == null ||
        avgReview <= 0) {
      setState(() {
        _errorMessage = _strings.enterValidPositiveValuesBeforeActivating;
      });
      return;
    }

    setState(() {
      _isActivating = true;
      _schedulingPreferences = syncedSchedulingPreferences;
    });

    try {
      final settingsRepo = ref.read(settingsRepoProvider);
      final progressRepo = ref.read(progressRepoProvider);
      final projectionEngine = ref.read(planningProjectionEngineProvider);

      final weekdayJson = encodeWeekdayMinutesJson(weekdayMinutes);
      final dailyDefault = deriveDailyDefault(weekdayMinutes);

      await settingsRepo.updateSettings(
        profile: _profile,
        forceRevisionOnly: _forceRevisionOnly ? 1 : 0,
        dailyMinutesDefault: dailyDefault,
        minutesByWeekdayJson: weekdayJson,
        maxNewPagesPerDay: maxNewPages,
        maxNewUnitsPerDay: maxNewUnits,
        avgNewMinutesPerAyah: avgNew,
        avgReviewMinutesPerAyah: avgReview,
        requirePageMetadata: _requirePageMetadata ? 1 : 0,
        schedulingPrefsJson:
            projectionEngine.encodePreferences(syncedSchedulingPreferences),
        schedulingOverridesJson:
            projectionEngine.encodeOverrides(_schedulingOverrides),
      );
      await progressRepo.getCursor();
      await _refreshWeeklyPlan();

      if (!mounted) {
        return;
      }
      _showSnackBar(_strings.planActivatedSuccessfully);
    } catch (_) {
      setState(() {
        _errorMessage = _strings.failedToActivatePlanTryAgain;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isActivating = false;
        });
      }
    }
  }

  Future<void> _refreshCalibrationPreview() async {
    if (_isRefreshingCalibration) {
      return;
    }
    setState(() {
      _isRefreshingCalibration = true;
    });
    try {
      final preview = await ref.read(calibrationServiceProvider).getPreview();
      if (!mounted) {
        return;
      }
      setState(() {
        _calibrationPreview = preview;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingCalibration = false;
        });
      }
    }
  }

  Future<void> _addCalibrationSample(CalibrationSampleKind kind) async {
    if (_isAddingSample) {
      return;
    }

    final durationController = kind == CalibrationSampleKind.newMemorization
        ? _newDurationController
        : _reviewDurationController;
    final ayahController = kind == CalibrationSampleKind.newMemorization
        ? _newAyahCountController
        : _reviewAyahCountController;

    final duration = double.tryParse(durationController.text.trim());
    final ayahCount = int.tryParse(ayahController.text.trim());

    if (duration == null ||
        duration <= 0 ||
        ayahCount == null ||
        ayahCount <= 0) {
      _showSnackBar(_strings.enterPositiveDurationAndAyahCount);
      return;
    }

    setState(() {
      _isAddingSample = true;
    });

    try {
      await ref.read(calibrationServiceProvider).logSample(
            kind: kind,
            durationMinutes: duration,
            ayahCount: ayahCount,
          );
      durationController.clear();
      ayahController.clear();
      await _refreshCalibrationPreview();
      _showSnackBar(_strings.calibrationSampleAdded);
    } catch (error) {
      _showSnackBar(_strings.failedToAddSample('$error'));
    } finally {
      if (mounted) {
        setState(() {
          _isAddingSample = false;
        });
      }
    }
  }

  Future<void> _applyCalibration() async {
    if (_isApplyingCalibration) {
      return;
    }

    setState(() {
      _isApplyingCalibration = true;
    });

    try {
      final distribution = _parseGradeDistributionOrNull();
      await ref.read(calibrationServiceProvider).applyCalibration(
            timing: _calibrationTiming == _CalibrationTimingUi.now
                ? CalibrationApplyTiming.immediate
                : CalibrationApplyTiming.tomorrow,
            gradeDistributionPercent: distribution,
          );
      await _refreshCalibrationPreview();
      _showSnackBar(
        _calibrationTiming == _CalibrationTimingUi.now
            ? _strings.calibrationAppliedImmediately
            : _strings.calibrationQueuedForTomorrow,
      );
    } catch (error) {
      _showSnackBar(_strings.calibrationApplyFailed('$error'));
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingCalibration = false;
        });
      }
    }
  }

  Future<void> _runForecast() async {
    if (_isRunningForecast) {
      return;
    }

    setState(() {
      _isRunningForecast = true;
      _forecastError = null;
    });

    try {
      final result =
          await ref.read(forecastSimulationServiceProvider).simulate();
      if (!mounted) {
        return;
      }
      setState(() {
        _forecastResult = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _forecastResult = null;
        _forecastError = _strings.forecastFailed('$error');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunningForecast = false;
        });
      }
    }
  }

  Future<void> _loadSchedulingState() async {
    setState(() {
      _isLoadingScheduling = true;
      _weeklyPlanError = null;
    });
    try {
      final settings = await ref.read(settingsRepoProvider).getSettings();
      final projectionEngine = ref.read(planningProjectionEngineProvider);
      final preferences = projectionEngine.preferencesFromSettings(settings);
      final overrides = projectionEngine.overridesFromSettings(settings);
      final weekdayMinutes = _weekdayMinutesFromScheduling(preferences);
      final weeklyTotal = _totalWeeklyMinutes(weekdayMinutes);
      final inferredFluency = _inferFluency(
        avgNew: settings.avgNewMinutesPerAyah,
        avgReview: settings.avgReviewMinutesPerAyah,
      );
      final guidedPreset = inferGuidedPlanPreset(
        profile: settings.profile,
        forceRevisionOnly: settings.forceRevisionOnly == 1,
        maxNewPagesPerDay: settings.maxNewPagesPerDay,
        maxNewUnitsPerDay: settings.maxNewUnitsPerDay,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _guidedPreset = guidedPreset;
        _profile = settings.profile;
        _forceRevisionOnly = settings.forceRevisionOnly == 1;
        _maxNewPagesController.text = settings.maxNewPagesPerDay.toString();
        _maxNewUnitsController.text = settings.maxNewUnitsPerDay.toString();
        _avgNewMinutesController.text =
            settings.avgNewMinutesPerAyah.toStringAsFixed(1);
        _avgReviewMinutesController.text =
            settings.avgReviewMinutesPerAyah.toStringAsFixed(1);
        _fluency = inferredFluency;
        _avgNewDirty = !_matchesFluencyDefaults(
          fluency: inferredFluency,
          avgNew: settings.avgNewMinutesPerAyah,
          avgReview: settings.avgReviewMinutesPerAyah,
        );
        _avgReviewDirty = _avgNewDirty;
        _requirePageMetadata = settings.requirePageMetadata == 1;
        _weeklyMinutesController.text = weeklyTotal.toString();
        for (final key in onboardingWeekdayKeys) {
          _weekdayControllers[key]!.text = (weekdayMinutes[key] ?? 0).toString();
        }
        _schedulingPreferences = preferences;
        _schedulingOverrides = overrides;
        _minutesPerDayController.text =
            preferences.minutesPerDayDefault.toString();
        _minutesPerWeekController.text =
            preferences.minutesPerWeekDefault.toString();
        _isLoadingScheduling = false;
      });
      await _refreshWeeklyPlan();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingScheduling = false;
        _weeklyPlanError = error.toString();
      });
    }
  }

  Future<void> _refreshWeeklyPlan() async {
    if (_isRefreshingWeeklyPlan) {
      return;
    }
    setState(() {
      _isRefreshingWeeklyPlan = true;
      _weeklyPlanError = null;
    });

    try {
      final settings = await ref.read(settingsRepoProvider).getSettings();
      final projectionEngine = ref.read(planningProjectionEngineProvider);
      final startDay = localDayIndex(DateTime.now().toLocal());
      final syncedPreferences = _syncedSchedulingPreferencesFromCurrentInputs();
      final effectiveSettings = settings.copyWith(
        profile: _profile,
        forceRevisionOnly: _forceRevisionOnly ? 1 : 0,
        dailyMinutesDefault: syncedPreferences.minutesPerDayDefault,
        minutesByWeekdayJson: Value(
          encodeWeekdayMinutesJson(_currentWeekdayMinutes()),
        ),
        schedulingPrefsJson: Value(
          projectionEngine.encodePreferences(syncedPreferences),
        ),
        schedulingOverridesJson: Value(
          projectionEngine.encodeOverrides(_schedulingOverrides),
        ),
      );
      final weeklyPlan = await projectionEngine.generateWeeklyPlan(
        startDay: startDay,
        horizonDays: 7,
        settings: effectiveSettings,
        scheduleRepo: ref.read(scheduleRepoProvider),
        quranRepo: ref.read(quranRepoProvider),
        preferences: syncedPreferences,
        overrides: _schedulingOverrides,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _schedulingPreferences = syncedPreferences;
        _weeklyPlan = weeklyPlan;
        _isRefreshingWeeklyPlan = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRefreshingWeeklyPlan = false;
        _weeklyPlanError = error.toString();
      });
    }
  }

  void _updateSchedulingPreferences(SchedulingPreferencesV1 next) {
    setState(() {
      _schedulingPreferences = next;
    });
    Future<void>.microtask(_refreshWeeklyPlan);
  }

  void _toggleStudyDay(int weekday) {
    final next = <int>{..._schedulingPreferences.enabledWeekdays};
    if (next.contains(weekday)) {
      next.remove(weekday);
    } else {
      next.add(weekday);
    }
    if (next.isEmpty) {
      next.add(weekday);
    }
    _updateSchedulingPreferences(
      _schedulingPreferences.copyWith(enabledWeekdays: next),
    );
  }

  void _toggleRevisionOnlyDay(int weekday) {
    final next = <int>{..._schedulingPreferences.revisionOnlyWeekdays};
    if (next.contains(weekday)) {
      next.remove(weekday);
    } else {
      next.add(weekday);
    }
    _updateSchedulingPreferences(
      _schedulingPreferences.copyWith(revisionOnlyWeekdays: next),
    );
  }

  Future<void> _pickSessionTime({required bool sessionA}) async {
    final initialMinute = sessionA
        ? _schedulingPreferences.sessionATimeMinute ?? 7 * 60
        : _schedulingPreferences.sessionBTimeMinute ?? 19 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinute ~/ 60,
        minute: initialMinute % 60,
      ),
    );
    if (picked == null) {
      return;
    }
    final minute = (picked.hour * 60) + picked.minute;
    _updateSchedulingPreferences(
      _schedulingPreferences.copyWith(
        sessionATimeMinute:
            sessionA ? minute : _schedulingPreferences.sessionATimeMinute,
        sessionBTimeMinute:
            sessionA ? _schedulingPreferences.sessionBTimeMinute : minute,
      ),
    );
  }

  List<TimeWindow> _windowsForWeekday(int weekday) {
    return List<TimeWindow>.from(
      _schedulingPreferences.windowsByWeekday[weekday] ?? const <TimeWindow>[],
    );
  }

  void _addWindowForWeekday(int weekday) {
    final windowsByWeekday = Map<int, List<TimeWindow>>.from(
        _schedulingPreferences.windowsByWeekday);
    final list = _windowsForWeekday(weekday);
    list.add(
      const TimeWindow(
        startMinute: 6 * 60,
        endMinute: 7 * 60,
      ),
    );
    windowsByWeekday[weekday] = list;
    _updateSchedulingPreferences(
      _schedulingPreferences.copyWith(windowsByWeekday: windowsByWeekday),
    );
  }

  void _removeWindowForWeekday(int weekday, int index) {
    final windowsByWeekday = Map<int, List<TimeWindow>>.from(
        _schedulingPreferences.windowsByWeekday);
    final list = _windowsForWeekday(weekday);
    if (index < 0 || index >= list.length) {
      return;
    }
    list.removeAt(index);
    if (list.isEmpty) {
      windowsByWeekday.remove(weekday);
    } else {
      windowsByWeekday[weekday] = list;
    }
    _updateSchedulingPreferences(
      _schedulingPreferences.copyWith(windowsByWeekday: windowsByWeekday),
    );
  }

  Future<void> _editWindowForWeekday(int weekday, int index) async {
    final windows = _windowsForWeekday(weekday);
    if (index < 0 || index >= windows.length) {
      return;
    }
    final target = windows[index];

    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: target.startMinute ~/ 60,
        minute: target.startMinute % 60,
      ),
    );
    if (start == null) {
      return;
    }
    if (!mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: target.endMinute ~/ 60,
        minute: target.endMinute % 60,
      ),
    );
    if (end == null) {
      return;
    }

    final nextWindow = TimeWindow(
      startMinute: (start.hour * 60) + start.minute,
      endMinute: (end.hour * 60) + end.minute,
    ).normalized();
    final windowsByWeekday = Map<int, List<TimeWindow>>.from(
        _schedulingPreferences.windowsByWeekday);
    final nextList = _windowsForWeekday(weekday);
    nextList[index] = nextWindow;
    windowsByWeekday[weekday] = nextList;

    _updateSchedulingPreferences(
      _schedulingPreferences.copyWith(windowsByWeekday: windowsByWeekday),
    );
  }

  void _setDaySkipOverride(int dayIndex, bool skip) {
    final current = _schedulingOverrides[dayIndex];
    final next = SchedulingDayOverrideV1(
      dayIndex: dayIndex,
      skipDay: skip,
      revisionOnly: current?.revisionOnly,
      overrideMinutes: current?.overrideMinutes,
      sessionATimeMinute: current?.sessionATimeMinute,
      sessionBTimeMinute: current?.sessionBTimeMinute,
    );

    setState(() {
      _schedulingOverrides = _schedulingOverrides.copyWithOverride(next);
    });
    Future<void>.microtask(_refreshWeeklyPlan);
  }

  Future<void> _setDaySessionOverrideTime({
    required int dayIndex,
    required bool sessionA,
  }) async {
    final current = _schedulingOverrides[dayIndex];
    final initialMinute = sessionA
        ? current?.sessionATimeMinute ??
            _schedulingPreferences.sessionATimeMinute ??
            7 * 60
        : current?.sessionBTimeMinute ??
            _schedulingPreferences.sessionBTimeMinute ??
            19 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinute ~/ 60,
        minute: initialMinute % 60,
      ),
    );
    if (picked == null) {
      return;
    }

    final minute = (picked.hour * 60) + picked.minute;
    final next = SchedulingDayOverrideV1(
      dayIndex: dayIndex,
      skipDay: current?.skipDay,
      revisionOnly: current?.revisionOnly,
      overrideMinutes: current?.overrideMinutes,
      sessionATimeMinute: sessionA ? minute : current?.sessionATimeMinute,
      sessionBTimeMinute: sessionA ? current?.sessionBTimeMinute : minute,
    );

    setState(() {
      _schedulingOverrides = _schedulingOverrides.copyWithOverride(next);
    });
    Future<void>.microtask(_refreshWeeklyPlan);
  }

  Map<int, int>? _parseGradeDistributionOrNull() {
    final raw = <int, String>{
      5: _gradeQ5Controller.text.trim(),
      4: _gradeQ4Controller.text.trim(),
      3: _gradeQ3Controller.text.trim(),
      2: _gradeQ2Controller.text.trim(),
      0: _gradeQ0Controller.text.trim(),
    };

    if (raw.values.every((value) => value.isEmpty)) {
      return null;
    }
    if (raw.values.any((value) => value.isEmpty)) {
      throw FormatException(_strings.enterAllQPercentagesOrBlank);
    }

    final parsed = <int, int>{};
    for (final entry in raw.entries) {
      final value = int.tryParse(entry.value);
      if (value == null) {
        throw FormatException(_strings.qMustBeIntegerPercentage(entry.key));
      }
      parsed[entry.key] = value;
    }

    final sum = parsed.values.fold<int>(0, (acc, value) => acc + value);
    if (sum != 100) {
      throw FormatException(_strings.qPercentagesMustSum100);
    }
    return parsed;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildGuidedSetupCard(AppStrings strings) {
    return Card(
      key: const ValueKey('plan_guided_setup_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPresetQuestion(strings),
            const SizedBox(height: 16),
            _buildTimeQuestion(strings),
            const SizedBox(height: 16),
            _buildFluencyQuestion(strings),
            const SizedBox(height: 12),
            Text(
              strings.planGuidedNote,
              key: const ValueKey('plan_guided_note'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetQuestion(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.planPresetQuestion,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPresetOption(
              strings: strings,
              preset: GuidedPlanPreset.easy,
              key: const ValueKey('plan_preset_easy'),
            ),
            _buildPresetOption(
              strings: strings,
              preset: GuidedPlanPreset.normal,
              key: const ValueKey('plan_preset_normal'),
            ),
            _buildPresetOption(
              strings: strings,
              preset: GuidedPlanPreset.intensive,
              key: const ValueKey('plan_preset_intensive'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetOption({
    required AppStrings strings,
    required GuidedPlanPreset preset,
    required Key key,
  }) {
    final selected = _guidedPreset == preset;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: OutlinedButton(
        key: key,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          backgroundColor:
              selected ? colorScheme.secondaryContainer : null,
          side: BorderSide(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        onPressed: () => _applyGuidedPreset(preset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localizedGuidedPresetLabel(preset, strings),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(_localizedGuidedPresetDescription(preset, strings)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummaryCard(
    AppStrings strings,
    Map<String, int> weekdayMinutes,
    int dailyDefault,
  ) {
    final weeklyTotal = _totalWeeklyMinutes(weekdayMinutes);
    final maxNewPages = int.tryParse(_maxNewPagesController.text.trim()) ?? 0;
    final maxNewUnits = int.tryParse(_maxNewUnitsController.text.trim()) ?? 0;

    return Card(
      key: const ValueKey('plan_summary_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.suggestedPlanEditable,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              label: strings.planSummaryPace,
              value: _localizedGuidedPresetLabel(_guidedPreset, strings),
              helper: _localizedGuidedPresetDescription(_guidedPreset, strings),
            ),
            const SizedBox(height: 10),
            _buildSummaryRow(
              label: strings.planSummaryTime,
              value: strings.planSummaryTimeValue(weeklyTotal, dailyDefault),
            ),
            const SizedBox(height: 10),
            _buildSummaryRow(
              label: strings.planSummaryNewLimit,
              value: strings.planSummaryNewLimitValue(
                maxNewPages,
                maxNewUnits,
              ),
            ),
            const SizedBox(height: 10),
            _buildSummaryRow(
              label: strings.planSummaryReviewPriority,
              value: _reviewPrioritySummary(strings),
            ),
            const SizedBox(height: 16),
            Text(strings.dailyMinutesByWeekday),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in onboardingWeekdayKeys)
                  Chip(
                    label: Text(
                      strings.weekdayMinutesChip(
                        key,
                        weekdayMinutes[key] ?? 0,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(strings.derivedDailyDefault(dailyDefault)),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('plan_activate_button'),
              onPressed: _isActivating ? null : _activatePlan,
              child: Text(
                _isActivating ? strings.activating : strings.activate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 2),
        Text(value),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(
            helper,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedGate(
    AppStrings strings,
    Map<String, int> weekdayMinutes,
    int dailyDefault,
  ) {
    return Card(
      key: const ValueKey('plan_advanced_gate'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.planAdvancedTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(strings.planAdvancedSubtitle),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('plan_advanced_toggle'),
              onPressed: () {
                setState(() {
                  _showAdvanced = !_showAdvanced;
                });
              },
              child: Text(
                _showAdvanced
                    ? strings.planHideAdvanced
                    : strings.planOpenAdvanced,
              ),
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              _buildAdvancedContent(strings, weekdayMinutes, dailyDefault),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedContent(
    AppStrings strings,
    Map<String, int> weekdayMinutes,
    int dailyDefault,
  ) {
    final preview = _calibrationPreview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFineTuneCard(strings, weekdayMinutes, dailyDefault),
        const SizedBox(height: 16),
        Card(
          key: const ValueKey('plan_scheduling_section'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoadingScheduling
                ? const LinearProgressIndicator()
                : _buildSchedulingSection(strings),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          key: const ValueKey('plan_weekly_calendar_section'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildWeeklyCalendarSection(strings),
          ),
        ),
        const SizedBox(height: 16),
        _buildForecastCard(strings),
        const SizedBox(height: 16),
        _buildCalibrationCard(strings, preview),
      ],
    );
  }

  Widget _buildFineTuneCard(
    AppStrings strings,
    Map<String, int> weekdayMinutes,
    int dailyDefault,
  ) {
    return Card(
      key: const ValueKey('plan_fine_tune_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.planFineTuneTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildProfileQuestion(strings),
            const SizedBox(height: 16),
            _buildForceRevisionQuestion(strings),
            const SizedBox(height: 16),
            _buildCapsQuestion(strings),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('plan_avg_new_minutes'),
              controller: _avgNewMinutesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9.]'),
                ),
              ],
              onChanged: (_) {
                setState(() {
                  _avgNewDirty = true;
                });
              },
              decoration: InputDecoration(
                labelText: strings.avgNewMinutesPerAyah,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('plan_avg_review_minutes'),
              controller: _avgReviewMinutesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9.]'),
                ),
              ],
              onChanged: (_) {
                setState(() {
                  _avgReviewDirty = true;
                });
              },
              decoration: InputDecoration(
                labelText: strings.avgReviewMinutesPerAyah,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const ValueKey('plan_require_page_metadata'),
              contentPadding: EdgeInsets.zero,
              title: Text(strings.requirePageMetadata),
              value: _requirePageMetadata,
              onChanged: (value) {
                setState(() {
                  _requirePageMetadata = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              strings.planSummaryTimeValue(
                _totalWeeklyMinutes(weekdayMinutes),
                dailyDefault,
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(AppStrings strings) {
    final forecast = _forecastResult;
    return Card(
      key: const ValueKey('plan_forecast_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.forecastDeterministicSimulation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('plan_forecast_run_button'),
              onPressed: _isRunningForecast ? null : _runForecast,
              child: Text(
                _isRunningForecast ? strings.running : strings.runForecast,
              ),
            ),
            if (_isRunningForecast) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_forecastError != null) ...[
              const SizedBox(height: 12),
              Text(
                _forecastError!,
                key: const ValueKey('plan_forecast_incomplete_reason'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (forecast != null) ...[
              const SizedBox(height: 12),
              if (forecast.estimatedCompletionDate != null)
                Text(
                  strings.estimatedCompletion(
                    _formatDate(forecast.estimatedCompletionDate!),
                  ),
                  key: const ValueKey('plan_forecast_completion_date'),
                )
              else
                Text(
                  forecast.incompleteReason ??
                      strings.completionEstimateUnavailable,
                  key: const ValueKey('plan_forecast_incomplete_reason'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                strings.weeklyMinutesCurve(
                  _formatCurve(forecast.weeklyMinutesCurve),
                ),
                key: const ValueKey('plan_forecast_weekly_minutes'),
              ),
              Text(
                strings.revisionOnlyRatioCurve(
                  _formatCurve(forecast.revisionOnlyRatioCurve),
                ),
                key: const ValueKey('plan_forecast_revision_ratio'),
              ),
              Text(
                strings.avgNewPagesPerDayCurve(
                  _formatCurve(forecast.avgNewPagesPerDayCurve),
                ),
                key: const ValueKey('plan_forecast_new_pages_per_day'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationCard(
    AppStrings strings,
    CalibrationPreview? preview,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.calibrationModeOptional,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildCalibrationLogGroup(
              title: strings.newMemorizationSample,
              durationKey: const ValueKey('plan_calibration_new_duration'),
              ayahKey: const ValueKey('plan_calibration_new_ayah_count'),
              durationController: _newDurationController,
              ayahController: _newAyahCountController,
              buttonKey: const ValueKey('plan_calibration_add_new'),
              buttonLabel: strings.addNewSample,
              onPressed: () => _addCalibrationSample(
                CalibrationSampleKind.newMemorization,
              ),
            ),
            const SizedBox(height: 12),
            _buildCalibrationLogGroup(
              title: strings.reviewSample,
              durationKey: const ValueKey('plan_calibration_review_duration'),
              ayahKey: const ValueKey('plan_calibration_review_ayah_count'),
              durationController: _reviewDurationController,
              ayahController: _reviewAyahCountController,
              buttonKey: const ValueKey('plan_calibration_add_review'),
              buttonLabel: strings.addReviewSample,
              onPressed: () => _addCalibrationSample(
                CalibrationSampleKind.review,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.preview,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_isRefreshingCalibration) const LinearProgressIndicator(),
            Text(
              strings.newSamplesPreview(
                preview?.newSampleCount ?? 0,
                _formatMedian(preview?.medianNewMinutesPerAyah),
              ),
              key: const ValueKey('plan_calibration_preview_new'),
            ),
            Text(
              strings.reviewSamplesPreview(
                preview?.reviewSampleCount ?? 0,
                _formatMedian(preview?.medianReviewMinutesPerAyah),
              ),
              key: const ValueKey('plan_calibration_preview_review'),
            ),
            const SizedBox(height: 16),
            Text(
              strings.typicalGradeDistributionPercent,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildGradeInput(5, _gradeQ5Controller),
                _buildGradeInput(4, _gradeQ4Controller),
                _buildGradeInput(3, _gradeQ3Controller),
                _buildGradeInput(2, _gradeQ2Controller),
                _buildGradeInput(0, _gradeQ0Controller),
              ],
            ),
            const SizedBox(height: 16),
            Text(strings.applyTiming),
            const SizedBox(height: 8),
            SegmentedButton<_CalibrationTimingUi>(
              key: const ValueKey('plan_calibration_timing'),
              segments: [
                ButtonSegment<_CalibrationTimingUi>(
                  value: _CalibrationTimingUi.now,
                  label: Text(strings.applyNow),
                ),
                ButtonSegment<_CalibrationTimingUi>(
                  value: _CalibrationTimingUi.tomorrow,
                  label: Text(strings.applyFromTomorrow),
                ),
              ],
              selected: {_calibrationTiming},
              onSelectionChanged: (selection) {
                setState(() {
                  _calibrationTiming = selection.first;
                });
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('plan_apply_calibration_button'),
              onPressed: _isApplyingCalibration ? null : _applyCalibration,
              child: Text(
                _isApplyingCalibration
                    ? strings.applying
                    : strings.applyCalibration,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizedGuidedPresetLabel(
    GuidedPlanPreset preset,
    AppStrings strings,
  ) {
    return switch (preset) {
      GuidedPlanPreset.easy => strings.planPresetEasy,
      GuidedPlanPreset.normal => strings.planPresetNormal,
      GuidedPlanPreset.intensive => strings.planPresetIntensive,
    };
  }

  String _localizedGuidedPresetDescription(
    GuidedPlanPreset preset,
    AppStrings strings,
  ) {
    return switch (preset) {
      GuidedPlanPreset.easy => strings.planPresetEasyDescription,
      GuidedPlanPreset.normal => strings.planPresetNormalDescription,
      GuidedPlanPreset.intensive => strings.planPresetIntensiveDescription,
    };
  }

  String _reviewPrioritySummary(AppStrings strings) {
    final inferredPreset = inferGuidedPlanPreset(
      profile: _profile,
      forceRevisionOnly: _forceRevisionOnly,
      maxNewPagesPerDay: int.tryParse(_maxNewPagesController.text.trim()) ?? 0,
      maxNewUnitsPerDay: int.tryParse(_maxNewUnitsController.text.trim()) ?? 0,
    );
    return switch (inferredPreset) {
      GuidedPlanPreset.easy => strings.planReviewPriorityEasy,
      GuidedPlanPreset.normal => strings.planReviewPriorityNormal,
      GuidedPlanPreset.intensive => strings.planReviewPriorityIntensive,
    };
  }

  Widget _buildSchedulingSection(AppStrings strings) {
    final twoSessions = _schedulingPreferences.sessionsPerDay == 2;
    final exactTimes = _schedulingPreferences.exactTimesEnabled;
    final advancedMode = _schedulingPreferences.advancedModeEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.automaticSchedulingTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const ValueKey('plan_scheduling_two_sessions'),
          contentPadding: EdgeInsets.zero,
          title: Text(strings.twoSessionsPerDay),
          value: twoSessions,
          onChanged: (value) {
            _updateSchedulingPreferences(
              _schedulingPreferences.copyWith(
                sessionsPerDay: value ? 2 : 1,
              ),
            );
          },
        ),
        SwitchListTile(
          key: const ValueKey('plan_scheduling_exact_times'),
          contentPadding: EdgeInsets.zero,
          title: Text(strings.setExactTimesQuestion),
          value: exactTimes,
          onChanged: (value) {
            _updateSchedulingPreferences(
              _schedulingPreferences.copyWith(
                exactTimesEnabled: value,
                timingStrategy:
                    value ? TimingStrategy.fixedTimes : TimingStrategy.untimed,
              ),
            );
          },
        ),
        if (exactTimes) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const ValueKey('plan_scheduling_session_a_time'),
                onPressed: () => _pickSessionTime(sessionA: true),
                child: Text(
                  strings.sessionTimeLabel(
                    'A',
                    _formatMinuteOfDay(
                        _schedulingPreferences.sessionATimeMinute),
                  ),
                ),
              ),
              OutlinedButton(
                key: const ValueKey('plan_scheduling_session_b_time'),
                onPressed: () => _pickSessionTime(sessionA: false),
                child: Text(
                  strings.sessionTimeLabel(
                    'B',
                    _formatMinuteOfDay(
                        _schedulingPreferences.sessionBTimeMinute),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(
          strings.studyDaysLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final weekday in const [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
              DateTime.sunday,
            ])
              FilterChip(
                key: ValueKey('plan_scheduling_study_day_$weekday'),
                label: Text(_weekdayLabel(weekday, strings)),
                selected:
                    _schedulingPreferences.enabledWeekdays.contains(weekday),
                onSelected: (_) => _toggleStudyDay(weekday),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const ValueKey('plan_scheduling_advanced_mode'),
          contentPadding: EdgeInsets.zero,
          title: Text(strings.advancedSchedulingMode),
          value: advancedMode,
          onChanged: (value) {
            _updateSchedulingPreferences(
              _schedulingPreferences.copyWith(
                advancedModeEnabled: value,
              ),
            );
          },
        ),
        if (advancedMode) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<AvailabilityModel>(
            key: const ValueKey('plan_scheduling_availability_model'),
            initialValue: _schedulingPreferences.availabilityModel,
            decoration: InputDecoration(
              labelText: strings.availabilityModelLabel,
            ),
            items: [
              DropdownMenuItem(
                value: AvailabilityModel.minutesPerDay,
                child: Text(strings.availabilityMinutesPerDay),
              ),
              DropdownMenuItem(
                value: AvailabilityModel.minutesPerWeek,
                child: Text(strings.availabilityMinutesPerWeek),
              ),
              DropdownMenuItem(
                value: AvailabilityModel.specificHours,
                child: Text(strings.availabilitySpecificHours),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              _updateSchedulingPreferences(
                _schedulingPreferences.copyWith(availabilityModel: value),
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('plan_scheduling_minutes_per_day'),
            controller: _minutesPerDayController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: strings.minutesPerDayLabel,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed == null) {
                return;
              }
              _updateSchedulingPreferences(
                _schedulingPreferences.copyWith(
                  minutesPerDayDefault: parsed,
                  minutesByWeekday: {
                    for (final weekday in const [
                      DateTime.monday,
                      DateTime.tuesday,
                      DateTime.wednesday,
                      DateTime.thursday,
                      DateTime.friday,
                      DateTime.saturday,
                      DateTime.sunday,
                    ])
                      weekday: parsed,
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('plan_scheduling_minutes_per_week'),
            controller: _minutesPerWeekController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: strings.minutesPerWeekLabel,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed == null) {
                return;
              }
              _updateSchedulingPreferences(
                _schedulingPreferences.copyWith(minutesPerWeekDefault: parsed),
              );
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<TimingStrategy>(
            key: const ValueKey('plan_scheduling_timing_strategy'),
            initialValue: _schedulingPreferences.timingStrategy,
            decoration: InputDecoration(
              labelText: strings.timingStrategyLabel,
            ),
            items: [
              DropdownMenuItem(
                value: TimingStrategy.untimed,
                child: Text(strings.timingStrategyUntimed),
              ),
              DropdownMenuItem(
                value: TimingStrategy.fixedTimes,
                child: Text(strings.timingStrategyFixed),
              ),
              DropdownMenuItem(
                value: TimingStrategy.autoPlacement,
                child: Text(strings.timingStrategyAuto),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              _updateSchedulingPreferences(
                _schedulingPreferences.copyWith(timingStrategy: value),
              );
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('plan_scheduling_flex_windows'),
            contentPadding: EdgeInsets.zero,
            title: Text(strings.flexOutsideWindowsLabel),
            value: _schedulingPreferences.flexOutsideWindows,
            onChanged: (value) {
              _updateSchedulingPreferences(
                _schedulingPreferences.copyWith(flexOutsideWindows: value),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            strings.revisionOnlyDaysLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final weekday in const [
                DateTime.monday,
                DateTime.tuesday,
                DateTime.wednesday,
                DateTime.thursday,
                DateTime.friday,
                DateTime.saturday,
                DateTime.sunday,
              ])
                FilterChip(
                  key: ValueKey('plan_scheduling_revision_day_$weekday'),
                  label: Text(_weekdayLabel(weekday, strings)),
                  selected: _schedulingPreferences.revisionOnlyWeekdays
                      .contains(weekday),
                  onSelected: (_) => _toggleRevisionOnlyDay(weekday),
                ),
            ],
          ),
          if (_schedulingPreferences.availabilityModel ==
              AvailabilityModel.specificHours) ...[
            const SizedBox(height: 12),
            Text(
              strings.specificHoursWindowsLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final weekday in const [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
              DateTime.sunday,
            ]) ...[
              _buildDayWindowsEditor(strings, weekday),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildDayWindowsEditor(AppStrings strings, int weekday) {
    final windows = _windowsForWeekday(weekday);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(_weekdayLabel(weekday, strings))),
            TextButton(
              key: ValueKey('plan_scheduling_add_window_$weekday'),
              onPressed: () => _addWindowForWeekday(weekday),
              child: Text(strings.addWindowLabel),
            ),
          ],
        ),
        if (windows.isEmpty)
          Text(strings.noWindowsConfigured)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < windows.length; i++)
                InputChip(
                  key: ValueKey('plan_scheduling_window_${weekday}_$i'),
                  label: Text(
                    '${_formatMinuteOfDay(windows[i].startMinute)}-${_formatMinuteOfDay(windows[i].endMinute)}',
                  ),
                  onPressed: () => _editWindowForWeekday(weekday, i),
                  onDeleted: () => _removeWindowForWeekday(weekday, i),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildWeeklyCalendarSection(AppStrings strings) {
    final plan = _weeklyPlan;
    if (_isRefreshingWeeklyPlan) {
      return const LinearProgressIndicator();
    }
    if (_weeklyPlanError != null) {
      return Text(
        _weeklyPlanError!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (plan == null || plan.days.isEmpty) {
      return Text(strings.noWeeklyPlanYet);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.weeklyCalendarTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < plan.days.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == plan.days.length - 1 ? 0 : 8),
            child: _buildWeeklyDayCard(strings, plan.days[i], i),
          ),
      ],
    );
  }

  Widget _buildWeeklyDayCard(
    AppStrings strings,
    WeeklyPlanDay day,
    int index,
  ) {
    final override = _schedulingOverrides[day.dayIndex];
    return DecoratedBox(
      key: ValueKey('plan_weekly_day_$index'),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayLabel(day, strings),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (!day.enabledStudyDay)
              Text(day.skipDay
                  ? strings.dayMarkedHoliday
                  : strings.dayNotEnabled)
            else if (day.sessions.isEmpty)
              Text(strings.noSessionsPlanned)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final session in day.sessions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        strings.weeklySessionLine(
                          session.sessionLabel,
                          session.focus == PlannedSessionFocus.reviewOnly
                              ? strings.reviewOnlyFocus
                              : strings.newAndReviewFocus,
                          session.plannedMinutes,
                          session.isTimed
                              ? _formatMinuteOfDay(session.startMinuteOfDay)
                              : strings.untimedSessionLabel,
                          _sessionStatusLabel(strings, session.status),
                        ),
                      ),
                    ),
                ],
              ),
            if (day.recoveryMode) ...[
              const SizedBox(height: 4),
              Text(
                strings.recoveryModeActive,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (_schedulingPreferences.advancedModeEnabled) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                key: ValueKey('plan_weekly_skip_day_${day.dayIndex}'),
                contentPadding: EdgeInsets.zero,
                title: Text(strings.skipDayLabel),
                value: override?.skipDay ?? false,
                onChanged: (value) => _setDaySkipOverride(day.dayIndex, value),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: ValueKey('plan_weekly_override_a_${day.dayIndex}'),
                    onPressed: () => _setDaySessionOverrideTime(
                      dayIndex: day.dayIndex,
                      sessionA: true,
                    ),
                    child: Text(strings.overrideSessionTime('A')),
                  ),
                  OutlinedButton(
                    key: ValueKey('plan_weekly_override_b_${day.dayIndex}'),
                    onPressed: () => _setDaySessionOverrideTime(
                      dayIndex: day.dayIndex,
                      sessionA: false,
                    ),
                    child: Text(strings.overrideSessionTime('B')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sessionStatusLabel(AppStrings strings, PlannedSessionStatus status) {
    return switch (status) {
      PlannedSessionStatus.pending => strings.sessionStatusPending,
      PlannedSessionStatus.completed => strings.sessionStatusCompleted,
      PlannedSessionStatus.missed => strings.sessionStatusMissed,
      PlannedSessionStatus.dueSoon => strings.sessionStatusDueSoon,
    };
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);
    final weekdayMinutes = _currentWeekdayMinutes();
    final dailyDefault = deriveDailyDefault(weekdayMinutes);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.planSetupTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(strings.planSetupSubtitle),
            const SizedBox(height: 16),
            _buildGuidedSetupCard(strings),
            const SizedBox(height: 16),
            _buildPlanSummaryCard(strings, weekdayMinutes, dailyDefault),
            const SizedBox(height: 16),
            _buildAdvancedGate(strings, weekdayMinutes, dailyDefault),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeQuestion(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.timeInput,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<_TimeInputMode>(
          key: const ValueKey('plan_time_mode'),
          segments: [
            ButtonSegment<_TimeInputMode>(
              value: _TimeInputMode.weekly,
              label: Text(strings.weeklyTotal),
            ),
            ButtonSegment<_TimeInputMode>(
              value: _TimeInputMode.weekday,
              label: Text(strings.perWeekday),
            ),
          ],
          selected: {_timeInputMode},
          onSelectionChanged: (selection) {
            setState(() {
              _timeInputMode = selection.first;
            });
            _syncGuidedInputsIntoSchedulingPreferences();
          },
        ),
        const SizedBox(height: 8),
        if (_timeInputMode == _TimeInputMode.weekly)
          TextField(
            key: const ValueKey('plan_weekly_minutes'),
            controller: _weeklyMinutesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _syncGuidedInputsIntoSchedulingPreferences(),
            decoration: InputDecoration(
              labelText: strings.weeklyMinutes,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in onboardingWeekdayKeys)
                SizedBox(
                  width: 120,
                  child: TextField(
                    key: ValueKey('plan_weekday_$key'),
                    controller: _weekdayControllers[key],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _syncGuidedInputsIntoSchedulingPreferences(),
                    decoration: InputDecoration(
                      labelText: key.toUpperCase(),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildFluencyQuestion(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.fluency,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final option in OnboardingFluency.values)
              ChoiceChip(
                key: ValueKey('plan_fluency_${option.name}'),
                label: Text(_localizedFluencyLabel(option, strings)),
                selected: _fluency == option,
                onSelected: (_) => _onFluencyChanged(option),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileQuestion(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.profile,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const ValueKey('plan_profile'),
          initialValue: _profile,
          items: [
            DropdownMenuItem(
                value: 'support', child: Text(strings.profileSupport)),
            DropdownMenuItem(
              value: 'standard',
              child: Text(strings.profileStandard),
            ),
            DropdownMenuItem(
              value: 'accelerated',
              child: Text(strings.profileAccelerated),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _profile = value;
            });
          },
          decoration: InputDecoration(
            labelText: strings.profile,
          ),
        ),
      ],
    );
  }

  Widget _buildForceRevisionQuestion(AppStrings strings) {
    return SwitchListTile(
      key: const ValueKey('plan_force_revision_only'),
      contentPadding: EdgeInsets.zero,
      title: Text(strings.forceRevisionOnly),
      value: _forceRevisionOnly,
      onChanged: (value) {
        setState(() {
          _forceRevisionOnly = value;
        });
      },
    );
  }

  Widget _buildCapsQuestion(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.dailyNewItemCaps,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('plan_max_new_pages'),
          controller: _maxNewPagesController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: strings.maxNewPagesPerDay,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('plan_max_new_units'),
          controller: _maxNewUnitsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: strings.maxNewUnitsPerDay,
          ),
        ),
      ],
    );
  }

  Widget _buildCalibrationLogGroup({
    required String title,
    required Key durationKey,
    required Key ayahKey,
    required TextEditingController durationController,
    required TextEditingController ayahController,
    required Key buttonKey,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: durationKey,
                controller: durationController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: _strings.durationMinutes,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: ayahKey,
                controller: ayahController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _strings.ayahCount,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: buttonKey,
          onPressed: _isAddingSample ? null : onPressed,
          child: Text(buttonLabel),
        ),
      ],
    );
  }

  Widget _buildGradeInput(int gradeQ, TextEditingController controller) {
    return SizedBox(
      width: 84,
      child: TextField(
        key: ValueKey('plan_grade_q$gradeQ'),
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'q$gradeQ',
        ),
      ),
    );
  }

  String _localizedFluencyLabel(OnboardingFluency fluency, AppStrings strings) {
    return switch (fluency) {
      OnboardingFluency.fluent => strings.fluencyFluent,
      OnboardingFluency.developing => strings.fluencyDeveloping,
      OnboardingFluency.support => strings.fluencySupport,
    };
  }

  String _formatMinuteOfDay(int? minuteOfDay) {
    if (minuteOfDay == null) {
      return '--:--';
    }
    final normalized = minuteOfDay.clamp(0, 1439);
    final hour = (normalized ~/ 60).toString().padLeft(2, '0');
    final minute = (normalized % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _weekdayLabel(int weekday, AppStrings strings) {
    return switch (weekday) {
      DateTime.monday => strings.weekdayShortMon,
      DateTime.tuesday => strings.weekdayShortTue,
      DateTime.wednesday => strings.weekdayShortWed,
      DateTime.thursday => strings.weekdayShortThu,
      DateTime.friday => strings.weekdayShortFri,
      DateTime.saturday => strings.weekdayShortSat,
      DateTime.sunday => strings.weekdayShortSun,
      _ => strings.weekdayShortMon,
    };
  }

  String _dayLabel(WeeklyPlanDay day, AppStrings strings) {
    final date = DateTime(1970, 1, 1).add(Duration(days: day.dayIndex));
    return '${_weekdayLabel(day.weekday, strings)} • ${_formatDate(date)}';
  }

  String _formatMedian(double? value) {
    if (value == null) {
      return '--';
    }
    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _formatCurve(List<double> values, {int maxPoints = 16}) {
    if (values.isEmpty) {
      return '[]';
    }

    final preview = values
        .take(maxPoints)
        .map((value) => value.toStringAsFixed(2))
        .join(', ');
    if (values.length > maxPoints) {
      return '[$preview, ...] (${values.length} weeks)';
    }
    return '[$preview]';
  }
}
