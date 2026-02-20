import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/database_providers.dart';
import '../data/services/onboarding_defaults.dart';

enum _TimeInputMode { weekly, weekday }

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
      key: TextEditingController(text: key == 'sun' ? '45' : '45'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan activated successfully.'),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final weekdayMinutes = _currentWeekdayMinutes();
    final dailyDefault = deriveDailyDefault(weekdayMinutes);

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
                    Text('Daily minutes by weekday'),
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
}
