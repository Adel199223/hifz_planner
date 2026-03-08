import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/time/local_day_time.dart';
import '../l10n/app_strings.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  late final Future<_LearnPracticeTargets> _practiceTargetsFuture;

  @override
  void initState() {
    super.initState();
    _practiceTargetsFuture = _loadPracticeTargets();
  }

  Future<_LearnPracticeTargets> _loadPracticeTargets() async {
    final todayDay = localDayIndex(DateTime.now().toLocal());
    try {
      final db = ref.read(appDatabaseProvider);
      final scheduleRepo = ref.read(scheduleRepoProvider);
      final companionRepo = ref.read(companionRepoProvider);

      final dueReviews = await scheduleRepo.getDueUnits(todayDay);
      dueReviews.sort((a, b) {
        final dueCompare = a.schedule.dueDay.compareTo(b.schedule.dueDay);
        if (dueCompare != 0) {
          return dueCompare;
        }
        return a.unit.id.compareTo(b.unit.id);
      });

      final stage4LifecycleRows = await companionRepo.getDueLifecycleStates(
        todayDay: todayDay,
      );
      stage4LifecycleRows.sort((a, b) {
        final aDueDay = _stage4DueDay(a, todayDay);
        final bDueDay = _stage4DueDay(b, todayDay);
        final dueCompare = aDueDay.compareTo(bDueDay);
        if (dueCompare != 0) {
          return dueCompare;
        }
        return a.unitId.compareTo(b.unitId);
      });

      final scheduleStates = await db.select(db.scheduleState).get();
      final newCandidateIds = scheduleStates
          .where((row) => row.dueDay == todayDay && row.reps == 0)
          .map((row) => row.unitId)
          .toList()
        ..sort();

      final reviewUnitId = dueReviews.isEmpty ? null : dueReviews.first.unit.id;
      final stage4Row =
          stage4LifecycleRows.isEmpty ? null : stage4LifecycleRows.first;
      final newUnitId = newCandidateIds.isEmpty ? null : newCandidateIds.first;

      return _LearnPracticeTargets(
        newPracticeRoute: newUnitId == null
            ? '/today'
            : '/companion/chain?unitId=$newUnitId&mode=new',
        reviewPracticeRoute: reviewUnitId == null
            ? '/today'
            : '/companion/chain?unitId=$reviewUnitId&mode=review',
        delayedCheckRoute:
            stage4Row == null ? '/today' : _stage4PracticeRoute(stage4Row),
        newPracticeDirect: newUnitId != null,
        reviewPracticeDirect: reviewUnitId != null,
        delayedCheckDirect: stage4Row != null,
      );
    } catch (_) {
      return _LearnPracticeTargets.fallback();
    }
  }

  int _stage4DueDay(CompanionLifecycleStateData row, int todayDay) {
    final retryDay = row.stage4RetryDueDay;
    if (retryDay != null && retryDay <= todayDay) {
      return retryDay;
    }
    final nextDay = row.stage4NextDayDueDay;
    if (nextDay != null && nextDay <= todayDay) {
      return nextDay;
    }
    final preSleepDay = row.stage4PreSleepDueDay;
    if (preSleepDay != null && preSleepDay <= todayDay) {
      return preSleepDay;
    }
    return todayDay;
  }

  String _stage4PracticeRoute(CompanionLifecycleStateData row) {
    final status = row.stage4Status;
    final strengtheningRoute = row.stage4StrengtheningRoute;
    final needsStrengthening = status == 'failed' ||
        status == 'needs_reinforcement' ||
        strengtheningRoute != null;
    if (needsStrengthening) {
      return '/companion/chain?unitId=${row.unitId}&mode=new';
    }
    return '/companion/chain?unitId=${row.unitId}&mode=stage4';
  }

  Widget _buildPracticeEntry({
    required BuildContext context,
    required Key key,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required String route,
    required bool primary,
  }) {
    final button = primary
        ? FilledButton(
            key: key,
            onPressed: () {
              context.go(route);
            },
            child: Text(buttonLabel),
          )
        : OutlinedButton(
            key: key,
            onPressed: () {
              context.go(route);
            },
            child: Text(buttonLabel),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 12),
            button,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);

    return SafeArea(
      key: const ValueKey('learn_screen_root'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.learnTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.learnSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FutureBuilder<_LearnPracticeTargets>(
              future: _practiceTargetsFuture,
              builder: (context, snapshot) {
                final practiceTargets =
                    snapshot.data ?? _LearnPracticeTargets.fallback();
                final usesFallback = practiceTargets.usesTodayFallback;
                return Card(
                  key: const ValueKey('learn_practice_card'),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.record_voice_over_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.learnPracticeFromMemoryTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(strings.learnPracticeFromMemorySubtitle),
                        const SizedBox(height: 16),
                        _buildPracticeEntry(
                          context: context,
                          key: const ValueKey('learn_practice_new_button'),
                          title: strings.startNewPractice,
                          subtitle: strings.learnPracticeNewSubtitle,
                          buttonLabel: strings.startNewPractice,
                          route: practiceTargets.newPracticeRoute,
                          primary: true,
                        ),
                        const SizedBox(height: 12),
                        _buildPracticeEntry(
                          context: context,
                          key: const ValueKey('learn_practice_review_button'),
                          title: strings.continueReviewPractice,
                          subtitle: strings.learnPracticeReviewSubtitle,
                          buttonLabel: strings.continueReviewPractice,
                          route: practiceTargets.reviewPracticeRoute,
                          primary: false,
                        ),
                        const SizedBox(height: 12),
                        _buildPracticeEntry(
                          context: context,
                          key: const ValueKey('learn_practice_stage4_button'),
                          title: strings.doDelayedCheck,
                          subtitle: strings.learnPracticeDelayedCheckSubtitle,
                          buttonLabel: strings.doDelayedCheck,
                          route: practiceTargets.delayedCheckRoute,
                          primary: false,
                        ),
                        if (usesFallback) ...[
                          const SizedBox(height: 12),
                          Text(
                            strings.learnPracticeFromMemorySubtitle,
                            key: const ValueKey('learn_practice_fallback_note'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              key: const ValueKey('learn_hifz_plan_card'),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          strings.hifzPlanTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(strings.hifzPlanSubtitle),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('learn_hifz_plan_open'),
                      onPressed: () {
                        context.go('/plan');
                      },
                      child: Text(strings.openHifzPlan),
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
}

class _LearnPracticeTargets {
  const _LearnPracticeTargets({
    required this.newPracticeRoute,
    required this.reviewPracticeRoute,
    required this.delayedCheckRoute,
    required this.newPracticeDirect,
    required this.reviewPracticeDirect,
    required this.delayedCheckDirect,
  });

  factory _LearnPracticeTargets.fallback() {
    return const _LearnPracticeTargets(
      newPracticeRoute: '/today',
      reviewPracticeRoute: '/today',
      delayedCheckRoute: '/today',
      newPracticeDirect: false,
      reviewPracticeDirect: false,
      delayedCheckDirect: false,
    );
  }

  final String newPracticeRoute;
  final String reviewPracticeRoute;
  final String delayedCheckRoute;
  final bool newPracticeDirect;
  final bool reviewPracticeDirect;
  final bool delayedCheckDirect;

  bool get usesTodayFallback =>
      !newPracticeDirect || !reviewPracticeDirect || !delayedCheckDirect;
}
