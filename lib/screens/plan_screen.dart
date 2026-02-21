import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/database_providers.dart';
import '../data/services/calibration_service.dart';
import '../data/services/forecast_simulation_service.dart';
import '../data/services/onboarding_defaults.dart';

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
        _errorMessage = 'Please enter valid positive values before activating.';
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
      _showSnackBar('Plan activated successfully.');
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to activate plan. Please try again.';
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
      _showSnackBar('Enter positive duration and ayah count.');
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
      _showSnackBar('Calibration sample added.');
    } catch (error) {
      _showSnackBar('Failed to add sample: $error');
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
            ? 'Calibration applied immediately.'
            : 'Calibration queued for tomorrow.',
      );
    } catch (error) {
      _showSnackBar('Calibration apply failed: $error');
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
        _forecastError = 'Forecast failed: $error';
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
      throw const FormatException(
        'Enter all q percentages (5,4,3,2,0) or leave all blank.',
      );
    }

    final parsed = <int, int>{};
    for (final entry in raw.entries) {
      final value = int.tryParse(entry.value);
      if (value == null) {
        throw FormatException('q${entry.key} must be an integer percentage.');
      }
      parsed[entry.key] = value;
    }

    final sum = parsed.values.fold<int>(0, (acc, value) => acc + value);
    if (sum != 100) {
      throw const FormatException('q percentages must sum to 100.');
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
              'Onboarding Questionnaire ($_maxQuestions questions)',
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
                      'Forecast (Deterministic Simulation)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const ValueKey('plan_forecast_run_button'),
                      onPressed: _isRunningForecast ? null : _runForecast,
                      child: Text(
                        _isRunningForecast ? 'Running...' : 'Run Forecast',
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
                          'Estimated completion: ${_formatDate(forecast.estimatedCompletionDate!)}',
                          key: const ValueKey('plan_forecast_completion_date'),
                        )
                      else
                        Text(
                          forecast.incompleteReason ??
                              'Completion estimate unavailable.',
                          key:
                              const ValueKey('plan_forecast_incomplete_reason'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Weekly minutes: ${_formatCurve(forecast.weeklyMinutesCurve)}',
                        key: const ValueKey('plan_forecast_weekly_minutes'),
                      ),
                      Text(
                        'Revision-only ratio: ${_formatCurve(forecast.revisionOnlyRatioCurve)}',
                        key: const ValueKey('plan_forecast_revision_ratio'),
                      ),
                      Text(
                        'Avg new pages/day: ${_formatCurve(forecast.avgNewPagesPerDayCurve)}',
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
                    _buildTimeQuestion(),
                    const SizedBox(height: 16),
                    _buildFluencyQuestion(),
                    const SizedBox(height: 16),
                    _buildProfileQuestion(),
                    const SizedBox(height: 16),
                    _buildForceRevisionQuestion(),
                    const SizedBox(height: 16),
                    _buildCapsQuestion(),
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
                      'Suggested Plan (Editable)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text('Daily minutes by weekday'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final key in onboardingWeekdayKeys)
                          Chip(
                            label: Text('$key: ${weekdayMinutes[key]}'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Derived daily default: $dailyDefault'),
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
                      decoration: const InputDecoration(
                        labelText: 'Avg new minutes per ayah',
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
                      decoration: const InputDecoration(
                        labelText: 'Avg review minutes per ayah',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      key: const ValueKey('plan_require_page_metadata'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require page metadata'),
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
                      child: Text(_isActivating ? 'Activating...' : 'Activate'),
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
                      'Calibration Mode (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildCalibrationLogGroup(
                      title: 'New memorization sample',
                      durationKey:
                          const ValueKey('plan_calibration_new_duration'),
                      ayahKey:
                          const ValueKey('plan_calibration_new_ayah_count'),
                      durationController: _newDurationController,
                      ayahController: _newAyahCountController,
                      buttonKey: const ValueKey('plan_calibration_add_new'),
                      buttonLabel: 'Add new sample',
                      onPressed: () => _addCalibrationSample(
                          CalibrationSampleKind.newMemorization),
                    ),
                    const SizedBox(height: 12),
                    _buildCalibrationLogGroup(
                      title: 'Review sample',
                      durationKey:
                          const ValueKey('plan_calibration_review_duration'),
                      ayahKey:
                          const ValueKey('plan_calibration_review_ayah_count'),
                      durationController: _reviewDurationController,
                      ayahController: _reviewAyahCountController,
                      buttonKey: const ValueKey('plan_calibration_add_review'),
                      buttonLabel: 'Add review sample',
                      onPressed: () =>
                          _addCalibrationSample(CalibrationSampleKind.review),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_isRefreshingCalibration)
                      const LinearProgressIndicator(),
                    Text(
                      'New samples: ${preview?.newSampleCount ?? 0}, '
                      'median: ${_formatMedian(preview?.medianNewMinutesPerAyah)}',
                      key: const ValueKey('plan_calibration_preview_new'),
                    ),
                    Text(
                      'Review samples: ${preview?.reviewSampleCount ?? 0}, '
                      'median: ${_formatMedian(preview?.medianReviewMinutesPerAyah)}',
                      key: const ValueKey('plan_calibration_preview_review'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Typical grade distribution (%)',
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
                    const Text('Apply timing'),
                    const SizedBox(height: 8),
                    SegmentedButton<_CalibrationTimingUi>(
                      key: const ValueKey('plan_calibration_timing'),
                      segments: const [
                        ButtonSegment<_CalibrationTimingUi>(
                          value: _CalibrationTimingUi.now,
                          label: Text('Apply now'),
                        ),
                        ButtonSegment<_CalibrationTimingUi>(
                          value: _CalibrationTimingUi.tomorrow,
                          label: Text('Apply from tomorrow'),
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
                            ? 'Applying...'
                            : 'Apply Calibration',
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

  Widget _buildTimeQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1) Time input',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<_TimeInputMode>(
          key: const ValueKey('plan_time_mode'),
          segments: const [
            ButtonSegment<_TimeInputMode>(
              value: _TimeInputMode.weekly,
              label: Text('Weekly total'),
            ),
            ButtonSegment<_TimeInputMode>(
              value: _TimeInputMode.weekday,
              label: Text('Per weekday'),
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
            decoration: const InputDecoration(
              labelText: 'Weekly minutes',
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

  Widget _buildFluencyQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2) Fluency',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final option in OnboardingFluency.values)
              ChoiceChip(
                key: ValueKey('plan_fluency_${option.name}'),
                label: Text(option.name),
                selected: _fluency == option,
                onSelected: (_) => _onFluencyChanged(option),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3) Profile',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const ValueKey('plan_profile'),
          value: _profile,
          items: const [
            DropdownMenuItem(value: 'support', child: Text('support')),
            DropdownMenuItem(value: 'standard', child: Text('standard')),
            DropdownMenuItem(value: 'accelerated', child: Text('accelerated')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _profile = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Profile',
          ),
        ),
      ],
    );
  }

  Widget _buildForceRevisionQuestion() {
    return SwitchListTile(
      key: const ValueKey('plan_force_revision_only'),
      contentPadding: EdgeInsets.zero,
      title: const Text('4) Force Revision Only'),
      value: _forceRevisionOnly,
      onChanged: (value) {
        setState(() {
          _forceRevisionOnly = value;
        });
      },
    );
  }

  Widget _buildCapsQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '5-6) Daily new-item caps',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('plan_max_new_pages'),
          controller: _maxNewPagesController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Max new pages per day',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('plan_max_new_units'),
          controller: _maxNewUnitsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Max new units per day',
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
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
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
                decoration: const InputDecoration(
                  labelText: 'Ayah count',
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
