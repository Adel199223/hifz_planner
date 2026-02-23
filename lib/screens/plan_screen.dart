import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_preferences.dart';
import '../data/providers/database_providers.dart';
import '../data/services/calibration_service.dart';
import '../data/services/forecast_simulation_service.dart';
import '../data/services/onboarding_defaults.dart';
import '../l10n/app_strings.dart';

enum _TimeInputMode { weekly, weekday }

enum _CalibrationTimingUi { now, tomorrow }

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  static const _maxQuestions = 6;

  _TimeInputMode _timeInputMode = _TimeInputMode.weekly;
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
    Future<void>.microtask(_refreshCalibrationPreview);
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
    });

    try {
      final settingsRepo = ref.read(settingsRepoProvider);
      final progressRepo = ref.read(progressRepoProvider);

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
      );
      await progressRepo.getCursor();

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

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);
    final weekdayMinutes = _currentWeekdayMinutes();
    final dailyDefault = deriveDailyDefault(weekdayMinutes);
    final preview = _calibrationPreview;
    final forecast = _forecastResult;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.onboardingQuestionnaire(_maxQuestions),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
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
                        _isRunningForecast
                            ? strings.running
                            : strings.runForecast,
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
                          key:
                              const ValueKey('plan_forecast_incomplete_reason'),
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
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeQuestion(strings),
                    const SizedBox(height: 16),
                    _buildFluencyQuestion(strings),
                    const SizedBox(height: 16),
                    _buildProfileQuestion(strings),
                    const SizedBox(height: 16),
                    _buildForceRevisionQuestion(strings),
                    const SizedBox(height: 16),
                    _buildCapsQuestion(strings),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
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
            ),
            const SizedBox(height: 16),
            Card(
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
                      durationKey:
                          const ValueKey('plan_calibration_new_duration'),
                      ayahKey:
                          const ValueKey('plan_calibration_new_ayah_count'),
                      durationController: _newDurationController,
                      ayahController: _newAyahCountController,
                      buttonKey: const ValueKey('plan_calibration_add_new'),
                      buttonLabel: strings.addNewSample,
                      onPressed: () => _addCalibrationSample(
                          CalibrationSampleKind.newMemorization),
                    ),
                    const SizedBox(height: 12),
                    _buildCalibrationLogGroup(
                      title: strings.reviewSample,
                      durationKey:
                          const ValueKey('plan_calibration_review_duration'),
                      ayahKey:
                          const ValueKey('plan_calibration_review_ayah_count'),
                      durationController: _reviewDurationController,
                      ayahController: _reviewAyahCountController,
                      buttonKey: const ValueKey('plan_calibration_add_review'),
                      buttonLabel: strings.addReviewSample,
                      onPressed: () =>
                          _addCalibrationSample(CalibrationSampleKind.review),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.preview,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_isRefreshingCalibration)
                      const LinearProgressIndicator(),
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
                      onPressed:
                          _isApplyingCalibration ? null : _applyCalibration,
                      child: Text(
                        _isApplyingCalibration
                            ? strings.applying
                            : strings.applyCalibration,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          },
        ),
        const SizedBox(height: 8),
        if (_timeInputMode == _TimeInputMode.weekly)
          TextField(
            key: const ValueKey('plan_weekly_minutes'),
            controller: _weeklyMinutesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
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
                    onChanged: (_) => setState(() {}),
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
          value: _profile,
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
