import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/companion_repo.dart';
import 'package:hifz_planner/data/repositories/mem_unit_repo.dart';
import 'package:hifz_planner/data/repositories/progress_repo.dart';
import 'package:hifz_planner/data/repositories/quran_repo.dart';
import 'package:hifz_planner/data/repositories/review_log_repo.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/services/adaptive_queue_policy.dart';
import 'package:hifz_planner/data/services/daily_planner.dart';
import 'package:hifz_planner/data/services/new_unit_generator.dart';
import 'package:hifz_planner/data/services/review_completion_service.dart';
import 'package:hifz_planner/data/services/scheduling/planning_projection_engine.dart';

void main() {
  late AppDatabase db;
  late QuranRepo quranRepo;
  late MemUnitRepo memUnitRepo;
  late CompanionRepo companionRepo;
  late ScheduleRepo scheduleRepo;
  late SettingsRepo settingsRepo;
  late ProgressRepo progressRepo;
  late NewUnitGenerator newUnitGenerator;
  late ReviewCompletionService reviewCompletionService;
  late DailyPlanner dailyPlanner;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    quranRepo = QuranRepo(db);
    memUnitRepo = MemUnitRepo(db);
    companionRepo = CompanionRepo(db);
    scheduleRepo = ScheduleRepo(db);
    settingsRepo = SettingsRepo(db);
    progressRepo = ProgressRepo(db);
    newUnitGenerator = NewUnitGenerator(quranRepo, memUnitRepo, scheduleRepo);
    reviewCompletionService = ReviewCompletionService(
      db,
      ReviewLogRepo(db),
      scheduleRepo,
      companionRepo,
    );
    dailyPlanner = DailyPlanner(
      db,
      settingsRepo,
      progressRepo,
      scheduleRepo,
      quranRepo,
      companionRepo,
      newUnitGenerator,
      PlanningProjectionEngine(),
    );

    await _seedAyahs(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('uses mon..sun weekday override when present', () async {
    final monday = _findDayForWeekday(DateTime.monday);
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      minutesByWeekdayJson: '{"mon":4}',
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: monday,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: monday);

    expect(plan.plannedReviews.length, 4);
    expect(plan.minutesPlannedReviews, 4.0);
  });

  test('falls back to daily_minutes_default when weekday json is invalid',
      () async {
    final monday = _findDayForWeekday(DateTime.monday);
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      minutesByWeekdayJson: '{bad-json',
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: monday,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: monday);

    expect(plan.plannedReviews.length, 5);
  });

  test('review budget ratio follows support/standard/accelerated constants',
      () async {
    const todayDay = 100;
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: todayDay,
      count: 10,
    );

    await _configureSettings(
      settingsRepo,
      profile: 'support',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    final supportPlan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(supportPlan.plannedReviews.length, 9);

    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    final standardPlan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(standardPlan.plannedReviews.length, 8);

    await _configureSettings(
      settingsRepo,
      profile: 'accelerated',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    final acceleratedPlan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(acceleratedPlan.plannedReviews.length, 10);
  });

  test(
      'sorts due rows by overdue desc, lifecycle tier, reps asc, lapse_count desc',
      () async {
    const todayDay = 10;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 100,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-a',
      dueDay: 8,
      reps: 2,
      lapseCount: 0,
    );
    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-b',
      dueDay: 9,
      reps: 0,
      lapseCount: 0,
    );
    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-c',
      dueDay: 9,
      reps: 0,
      lapseCount: 0,
    );
    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-d',
      dueDay: 9,
      reps: 0,
      lapseCount: 3,
    );
    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-e',
      dueDay: 9,
      reps: 0,
      lapseCount: 1,
    );

    final uB = await _unitIdForKey(db, 'u-b');
    final uC = await _unitIdForKey(db, 'u-c');
    final uD = await _unitIdForKey(db, 'u-d');
    final uE = await _unitIdForKey(db, 'u-e');
    await _seedLifecycleState(
      companionRepo,
      unitId: uB,
      lifecycleTier: 'maintained',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: uC,
      lifecycleTier: 'ready',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: uD,
      lifecycleTier: 'stable',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: uE,
      lifecycleTier: 'stable',
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(
      plan.plannedReviews.map((row) => row.unit.unitKey).toList(),
      ['u-a', 'u-c', 'u-d', 'u-e', 'u-b'],
    );
    expect(
      plan.plannedReviews.map((row) => row.lifecycleTier).toList(),
      ['emerging', 'ready', 'stable', 'stable', 'maintained'],
    );
  });

  test(
      'weak retention sorts ahead of stronger units when due pressure is close',
      () async {
    const todayDay = 10;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 100,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final strongUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-strong',
      dueDay: 9,
      reps: 0,
      lapseCount: 0,
    );
    final weakUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-weak',
      dueDay: 9,
      reps: 0,
      lapseCount: 0,
    );

    await _seedLifecycleState(
      companionRepo,
      unitId: strongUnitId,
      lifecycleTier: 'stable',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: weakUnitId,
      lifecycleTier: 'stable',
    );

    await _seedStepProficiency(
      companionRepo,
      unitId: strongUnitId,
      ayah: 1,
      proficiencyEma: 0.94,
      attemptsCount: 8,
      passesCount: 8,
      lastEvaluatorConfidence: 0.96,
    );
    await _seedStepProficiency(
      companionRepo,
      unitId: weakUnitId,
      ayah: 1,
      proficiencyEma: 0.28,
      attemptsCount: 6,
      passesCount: 1,
      lastEvaluatorConfidence: 0.42,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(
      plan.plannedReviews.take(2).map((row) => row.unit.unitKey).toList(),
      ['u-weak', 'u-strong'],
    );
    expect(
      plan.plannedReviews.first.reinforcementWeight,
      greaterThan(plan.plannedReviews[1].reinforcementWeight),
    );
  });

  test(
      'classifies reviews into lock-in, weak spot, recent review, and maintenance',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 100,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final lockInUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'bucket-lockin',
      dueDay: todayDay - 1,
      reps: 0,
      intervalDays: 0,
      lapseCount: 0,
    );
    final weakSpotUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'bucket-weak',
      dueDay: todayDay - 1,
      reps: 3,
      intervalDays: 10,
      lapseCount: 0,
      lastReviewDay: todayDay - 10,
      lastGradeQ: 4,
    );
    final recentUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'bucket-recent',
      dueDay: todayDay - 1,
      reps: 3,
      intervalDays: 5,
      lapseCount: 0,
      lastReviewDay: todayDay - 2,
      lastGradeQ: 4,
    );
    final maintenanceUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'bucket-maintenance',
      dueDay: todayDay - 1,
      reps: 4,
      intervalDays: 14,
      lapseCount: 0,
      lastReviewDay: todayDay - 12,
      lastGradeQ: 4,
    );

    await _seedLifecycleState(
      companionRepo,
      unitId: lockInUnitId,
      lifecycleTier: 'ready',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: weakSpotUnitId,
      lifecycleTier: 'stable',
      weakSpotScore: 0.60,
      recentStruggleCount: 2,
      lastErrorType: 'hesitation',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: recentUnitId,
      lifecycleTier: 'stable',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: maintenanceUnitId,
      lifecycleTier: 'maintained',
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(
      plan.plannedReviews.map((row) => row.unit.unitKey).take(4).toList(),
      <String>[
        'bucket-lockin',
        'bucket-weak',
        'bucket-recent',
        'bucket-maintenance',
      ],
    );
    expect(
      plan.plannedReviews.map((row) => row.bucket).take(4).toList(),
      <AdaptiveQueueBucket>[
        AdaptiveQueueBucket.lockIn,
        AdaptiveQueueBucket.weakSpot,
        AdaptiveQueueBucket.recentReview,
        AdaptiveQueueBucket.maintenance,
      ],
    );
    expect(
      plan.plannedReviews.map((row) => row.reason).take(4).toList(),
      <AdaptiveReviewReason>[
        AdaptiveReviewReason.needsLockIn,
        AdaptiveReviewReason.shakyRecently,
        AdaptiveReviewReason.recentCheckIn,
        AdaptiveReviewReason.maintenanceDue,
      ],
    );
    expect(
      plan.plannedReviews[1].lastErrorType,
      AdaptiveLastErrorType.hesitation,
    );
  });

  test('mature schedule-only units without lifecycle do not fall into lock-in',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 100,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final unitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'legacy-mature-no-lifecycle',
      dueDay: todayDay - 1,
      reps: 3,
      intervalDays: 10,
      lapseCount: 0,
      lastReviewDay: todayDay - 10,
      lastGradeQ: 4,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);
    final row =
        plan.plannedReviews.singleWhere((item) => item.unit.id == unitId);

    expect(row.lifecycleTier, 'stable');
    expect(row.bucket, isNot(AdaptiveQueueBucket.lockIn));
    expect(row.bucket, AdaptiveQueueBucket.maintenance);
  });

  test('fake-ready legacy rows without stage4 history do not fall into lock-in',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 100,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final unitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'legacy-fake-ready-no-history',
      dueDay: todayDay - 1,
      reps: 3,
      intervalDays: 10,
      lapseCount: 0,
      lastReviewDay: todayDay - 10,
      lastGradeQ: 4,
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      stage4Status: 'none',
      stage4LastCompletedDay: null,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);
    final row =
        plan.plannedReviews.singleWhere((item) => item.unit.id == unitId);

    expect(row.lifecycleTier, 'stable');
    expect(row.bucket, isNot(AdaptiveQueueBucket.lockIn));
    expect(row.bucket, AdaptiveQueueBucket.maintenance);
  });

  test('true new no-lifecycle units still classify as lock-in', () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 100,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final unitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'true-new-no-lifecycle',
      dueDay: todayDay - 1,
      reps: 0,
      intervalDays: 0,
      lapseCount: 0,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);
    final row =
        plan.plannedReviews.singleWhere((item) => item.unit.id == unitId);

    expect(row.lifecycleTier, 'emerging');
    expect(row.bucket, AdaptiveQueueBucket.lockIn);
  });

  test('recovery mode expands review capacity and suspends new when overloaded',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 4,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: todayDay,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.plannedReviews.length, 4);
    expect(plan.revisionOnly, isTrue);
    expect(plan.recoveryMode, isTrue);
  });

  test('sets revisionOnly=true and skips new units on forced overload',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 1,
      dailyMinutesDefault: 4,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: todayDay,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.revisionOnly, isTrue);
    expect(plan.plannedNewUnits, isEmpty);
    expect(plan.minutesPlannedNew, 0);
  });

  test('when not forced, overload still allows new-unit generation', () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 6,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: todayDay,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.revisionOnly, isFalse);
    expect(plan.plannedReviews.length, 4);
    expect(plan.plannedNewUnits, isNotEmpty);
    expect(plan.minutesPlannedNew, greaterThan(0));
  });

  test('weak retention increases review pressure and reduces new allocation',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final dueUnitIds = <int>[];
    for (var i = 0; i < 5; i++) {
      dueUnitIds.add(
        await _seedDueUnit(
          memUnitRepo,
          db,
          unitKey: 'weak-pressure-$i',
          dueDay: todayDay - 1,
          reps: 0,
          lapseCount: 0,
          startAyah: i + 1,
          endAyah: i + 1,
        ),
      );
    }

    final baselinePlan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(baselinePlan.plannedNewUnits, isNotEmpty);
    expect(baselinePlan.minutesPlannedNew, greaterThan(0));
    expect(baselinePlan.newAvailability, TodayNewAvailability.available);

    for (var i = 0; i < dueUnitIds.length; i++) {
      await _seedStepProficiency(
        companionRepo,
        unitId: dueUnitIds[i],
        ayah: i + 1,
        proficiencyEma: 0.22,
        attemptsCount: 5,
        passesCount: 1,
        lastEvaluatorConfidence: 0.40,
      );
    }

    final weakPlan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(weakPlan.reviewPressure, greaterThan(baselinePlan.reviewPressure));
    expect(
        weakPlan.minutesPlannedNew, lessThan(baselinePlan.minutesPlannedNew));
    expect(
      weakPlan.plannedNewUnits.length,
      lessThanOrEqualTo(baselinePlan.plannedNewUnits.length),
    );
    if (weakPlan.plannedNewUnits.isNotEmpty) {
      expect(weakPlan.newAvailability, TodayNewAvailability.available);
    }
  });

  test('durable weak spots add adaptive debt and reduce new allocation',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final dueUnitIds = <int>[];
    for (var i = 0; i < 4; i++) {
      dueUnitIds.add(
        await _seedDueUnit(
          memUnitRepo,
          db,
          unitKey: 'adaptive-debt-$i',
          dueDay: todayDay - 1,
          reps: 3,
          intervalDays: 10,
          lapseCount: 0,
          startAyah: i + 1,
          endAyah: i + 1,
          lastReviewDay: todayDay - 8,
          lastGradeQ: 4,
        ),
      );
      await _seedLifecycleState(
        companionRepo,
        unitId: dueUnitIds.last,
        lifecycleTier: 'stable',
      );
    }

    final baselinePlan = await dailyPlanner.planToday(todayDay: todayDay);

    for (final unitId in dueUnitIds) {
      await _seedLifecycleState(
        companionRepo,
        unitId: unitId,
        lifecycleTier: 'stable',
        weakSpotScore: 0.55,
        recentStruggleCount: 2,
        lastErrorType: 'hesitation',
      );
    }

    final weakSpotPlan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(
      weakSpotPlan.reviewPressure,
      greaterThan(baselinePlan.reviewPressure),
    );
    expect(
      weakSpotPlan.minutesPlannedNew,
      lessThanOrEqualTo(baselinePlan.minutesPlannedNew),
    );
    expect(
      weakSpotPlan.plannedReviews.every(
        (row) => row.bucket == AdaptiveQueueBucket.weakSpot,
      ),
      isTrue,
    );
  });

  test('metadata guard blocks new units when cursor ayah page metadata missing',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 1,
    );

    await (db.update(db.ayah)
          ..where((tbl) => tbl.surah.equals(1) & tbl.ayah.equals(1)))
        .write(const AyahCompanion(pageMadina: Value(null)));

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.plannedNewUnits, isEmpty);
    expect(plan.minutesPlannedNew, 0);
    expect(plan.notice, TodayPlanNotice.finishSetup);
    expect(plan.newAvailability, TodayNewAvailability.blockedSetup);
  });

  test(
      'weak spot ordering surfaces similar confusion, repeated wrong recall, and fresh weak lock-in before hesitation',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 60,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedAyahs(db);

    final hesitationUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'weak-hesitation',
      dueDay: todayDay - 1,
      reps: 3,
      lapseCount: 0,
      lastGradeQ: 4,
      lastReviewDay: todayDay - 4,
      intervalDays: 4,
      startAyah: 50,
      endAyah: 50,
    );
    final similarConfusionUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'weak-similar',
      dueDay: todayDay - 1,
      reps: 3,
      lapseCount: 0,
      lastGradeQ: 4,
      lastReviewDay: todayDay - 4,
      intervalDays: 4,
      startAyah: 51,
      endAyah: 51,
    );
    final repeatedWrongRecallUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'weak-wrong-repeat',
      dueDay: todayDay - 1,
      reps: 3,
      lapseCount: 0,
      lastGradeQ: 4,
      lastReviewDay: todayDay - 4,
      intervalDays: 4,
      startAyah: 52,
      endAyah: 52,
    );
    final weakLockInUnitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'weak-lock-in',
      dueDay: todayDay - 1,
      reps: 2,
      lapseCount: 0,
      lastGradeQ: 4,
      lastReviewDay: todayDay - 1,
      intervalDays: 3,
      startAyah: 53,
      endAyah: 53,
    );

    await _seedLifecycleState(
      companionRepo,
      unitId: hesitationUnitId,
      lifecycleTier: 'stable',
      weakSpotScore: 0.55,
      recentStruggleCount: 1,
      lastErrorType: 'hesitation',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: similarConfusionUnitId,
      lifecycleTier: 'stable',
      weakSpotScore: 0.55,
      recentStruggleCount: 1,
      lastErrorType: 'similar_confusion',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: repeatedWrongRecallUnitId,
      lifecycleTier: 'stable',
      weakSpotScore: 0.55,
      recentStruggleCount: 2,
      lastErrorType: 'wrong_recall',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: weakLockInUnitId,
      lifecycleTier: 'stable',
      weakSpotScore: 0.55,
      recentStruggleCount: 1,
      lastErrorType: 'weak_lock_in',
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);
    final weakSpotRows = plan.plannedReviews
        .where((row) => row.bucket == AdaptiveQueueBucket.weakSpot)
        .toList();

    expect(
      weakSpotRows.map((row) => row.unit.unitKey).toList(),
      <String>[
        'weak-similar',
        'weak-wrong-repeat',
        'weak-lock-in',
        'weak-hesitation',
      ],
    );
    expect(
      weakSpotRows.map((row) => row.lastErrorType).toList(),
      <AdaptiveLastErrorType?>[
        AdaptiveLastErrorType.similarConfusion,
        AdaptiveLastErrorType.wrongRecall,
        AdaptiveLastErrorType.weakLockIn,
        AdaptiveLastErrorType.hesitation,
      ],
    );
  });

  test('metadata guard blocks when next-20 page coverage is below 90%',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 1,
    );

    for (final ayah in [2, 3, 4]) {
      await (db.update(db.ayah)
            ..where((tbl) => tbl.surah.equals(1) & tbl.ayah.equals(ayah)))
          .write(const AyahCompanion(pageMadina: Value(null)));
    }

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.plannedNewUnits, isEmpty);
    expect(plan.minutesPlannedNew, 0);
    expect(plan.notice, TodayPlanNotice.finishSetup);
    expect(plan.newAvailability, TodayNewAvailability.blockedSetup);
  });

  test('mandatory Stage-4 due blocks new generation unless override', () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    final unitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'stage4-due-unit',
      dueDay: todayDay - 1,
      reps: 1,
      lapseCount: 0,
    );

    await companionRepo.upsertLifecycleState(
      unitId: unitId,
      lifecycleTier: const Value('ready'),
      stage4Status: const Value('pending'),
      stage4NextDayDueDay: const Value(todayDay),
      stage4UnresolvedTargetsJson: const Value('[0]'),
      updatedAtDay: todayDay,
      updatedAtSeconds: 300,
    );

    final blockedPlan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(blockedPlan.stage4BlocksNewByDefault, isTrue);
    expect(blockedPlan.plannedStage4Due, isNotEmpty);
    expect(blockedPlan.plannedStage4Due.first.unit.id, unitId);
    expect(blockedPlan.plannedStage4Due.first.mandatory, isTrue);
    expect(blockedPlan.plannedNewUnits, isEmpty);

    final overridePlan = await dailyPlanner.planToday(
      todayDay: todayDay,
      allowStage4Override: true,
    );
    expect(overridePlan.stage4BlocksNewByDefault, isFalse);
    expect(overridePlan.plannedStage4Due, isNotEmpty);
    expect(overridePlan.plannedNewUnits, isNotEmpty);
  });

  test('quality snapshot counts maintained after review promotion', () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    final unitId = await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'maintained-after-review',
      dueDay: todayDay - 1,
      reps: 2,
      lapseCount: 0,
    );
    await companionRepo.upsertLifecycleState(
      unitId: unitId,
      lifecycleTier: const Value('stable'),
      stage4Status: const Value('passed'),
      updatedAtDay: todayDay - 1,
      updatedAtSeconds: 200,
    );

    final promotion = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 5,
      completedDay: todayDay,
      completedSeconds: 400,
    );
    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(promotion.promotedToMaintained, isTrue);
    expect(
      promotion.lifecycleTransition,
      ReviewLifecycleTransition.promotedToMaintained,
    );
    expect(plan.stage4QualitySnapshot.maintainedCount, 1);
    expect(plan.stage4QualitySnapshot.stableCount, 0);
  });

  test(
      'non-materializing planToday previews zero-unit days without side effects',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 1,
      maxNewUnitsPerDay: 1,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final cursorBefore = await progressRepo.getCursor();
    final plan = await dailyPlanner.planToday(
      todayDay: todayDay,
      materializeNewUnits: false,
    );
    final cursorAfter = await progressRepo.getCursor();

    expect(plan.plannedNewUnits, isEmpty);
    expect(plan.minutesPlannedNew, 0);
    expect(await memUnitRepo.hasAnyUnits(), isFalse);
    expect(cursorAfter.nextSurah, cursorBefore.nextSurah);
    expect(cursorAfter.nextAyah, cursorBefore.nextAyah);
  });

  test(
      'createStarterUnitForToday creates one production unit and advances cursor',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 0,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(plan.plannedNewUnits, isEmpty);

    final result = await dailyPlanner.createStarterUnitForToday(
      todayDay: todayDay,
      plan: plan,
    );

    expect(result.status, StarterUnitCreationStatus.created);
    expect(result.createdUnit, isNotNull);
    expect(result.createdUnit!.unitKey, 'page_segment:p1:s1a1-s1a5');
    expect(result.minutesPlannedNew, 5);

    final cursor = await progressRepo.getCursor();
    expect(cursor.nextSurah, 1);
    expect(cursor.nextAyah, 6);

    final schedule = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(result.createdUnit!.id)))
        .getSingle();
    expect(schedule.dueDay, todayDay);
    expect(await memUnitRepo.hasAnyUnits(), isTrue);
  });

  test(
      'createStarterUnitForToday returns blockedByMetadata when setup is blocked',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 0,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 1,
    );

    await (db.update(db.ayah)
          ..where((tbl) => tbl.surah.equals(1) & tbl.ayah.equals(1)))
        .write(const AyahCompanion(pageMadina: Value(null)));

    final plan = await dailyPlanner.planToday(todayDay: todayDay);
    final result = await dailyPlanner.createStarterUnitForToday(
      todayDay: todayDay,
      plan: plan,
    );

    expect(result.status, StarterUnitCreationStatus.blockedByMetadata);
    expect(result.createdUnit, isNull);
  });

  test(
      'createStarterUnitForToday returns alreadyInitialized when any unit exists',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 0,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    await memUnitRepo.create(
      MemUnitCompanion.insert(
        kind: 'page_segment',
        unitKey: 'existing-unit',
        createdAtDay: todayDay,
        updatedAtDay: todayDay,
      ),
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);
    final result = await dailyPlanner.createStarterUnitForToday(
      todayDay: todayDay,
      plan: plan,
    );

    expect(result.status, StarterUnitCreationStatus.alreadyInitialized);
    expect(result.createdUnit, isNull);
  });

  test('createStarterUnitForToday returns unavailable past the end of data',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 0,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await progressRepo.updateCursor(nextSurah: 99, nextAyah: 1);

    final plan = await dailyPlanner.planToday(todayDay: todayDay);
    final result = await dailyPlanner.createStarterUnitForToday(
      todayDay: todayDay,
      plan: plan,
    );

    expect(result.status, StarterUnitCreationStatus.unavailable);
    expect(result.createdUnit, isNull);
  });
}

Future<void> _configureSettings(
  SettingsRepo settingsRepo, {
  required String profile,
  required int forceRevisionOnly,
  required int dailyMinutesDefault,
  String? minutesByWeekdayJson,
  required int maxNewPagesPerDay,
  required int maxNewUnitsPerDay,
  required double avgNewMinutesPerAyah,
  required double avgReviewMinutesPerAyah,
  required int requirePageMetadata,
}) async {
  await settingsRepo.updateSettings(
    profile: profile,
    forceRevisionOnly: forceRevisionOnly,
    dailyMinutesDefault: dailyMinutesDefault,
    minutesByWeekdayJson: minutesByWeekdayJson,
    maxNewPagesPerDay: maxNewPagesPerDay,
    maxNewUnitsPerDay: maxNewUnitsPerDay,
    avgNewMinutesPerAyah: avgNewMinutesPerAyah,
    avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
    requirePageMetadata: requirePageMetadata,
  );
}

Future<void> _seedDueUnits(
  MemUnitRepo memUnitRepo,
  AppDatabase db, {
  required int todayDay,
  required int count,
}) async {
  for (var i = 0; i < count; i++) {
    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'due-$i',
      dueDay: todayDay - 1,
      reps: i % 3,
      lapseCount: i % 2,
      startAyah: i + 1,
      endAyah: i + 1,
    );
  }
}

Future<int> _seedDueUnit(
  MemUnitRepo memUnitRepo,
  AppDatabase db, {
  required String unitKey,
  required int dueDay,
  required int reps,
  int? intervalDays,
  required int lapseCount,
  int startAyah = 1,
  int endAyah = 1,
  int? lastReviewDay,
  int? lastGradeQ,
}) async {
  final unitId = await memUnitRepo.create(
    MemUnitCompanion.insert(
      kind: 'ayah_range',
      unitKey: unitKey,
      startSurah: const Value(1),
      startAyah: Value(startAyah),
      endSurah: const Value(1),
      endAyah: Value(endAyah),
      createdAtDay: 100,
      updatedAtDay: 100,
    ),
  );

  await db.into(db.scheduleState).insert(
        ScheduleStateCompanion.insert(
          unitId: Value(unitId),
          ef: 2.5,
          reps: reps,
          intervalDays: intervalDays ?? (reps == 0 ? 0 : 1),
          dueDay: dueDay,
          lastReviewDay: Value(lastReviewDay),
          lastGradeQ: Value(lastGradeQ),
          lapseCount: lapseCount,
        ),
      );
  return unitId;
}

Future<void> _seedLifecycleState(
  CompanionRepo companionRepo, {
  required int unitId,
  required String lifecycleTier,
  double weakSpotScore = 0.0,
  int recentStruggleCount = 0,
  String? lastErrorType,
  String stage4Status = 'passed',
  int? stage4LastCompletedDay = 100,
}) async {
  await companionRepo.upsertLifecycleState(
    unitId: unitId,
    lifecycleTier: Value(lifecycleTier),
    stage4Status: Value(stage4Status),
    stage4LastCompletedDay: Value(stage4LastCompletedDay),
    updatedAtDay: 100,
    updatedAtSeconds: 100,
  );
  await companionRepo.writeAdaptiveState(
    unitId: unitId,
    weakSpotScore: weakSpotScore,
    recentStruggleCount: recentStruggleCount,
    lastErrorType: lastErrorType,
    updatedAtDay: 100,
    updatedAtSeconds: 100,
    seedLifecycleTier: lifecycleTier,
  );
}

Future<void> _seedStepProficiency(
  CompanionRepo companionRepo, {
  required int unitId,
  required int ayah,
  required double proficiencyEma,
  required int attemptsCount,
  required int passesCount,
  required double lastEvaluatorConfidence,
}) async {
  final sessionId = await companionRepo.startChainSession(
    unitId: unitId,
    targetVerseCount: 1,
    createdAtDay: 100,
    startedAtSeconds: 0,
  );
  return companionRepo.upsertStepProficiency(
    unitId: unitId,
    surah: 1,
    ayah: ayah,
    proficiencyEma: proficiencyEma,
    lastHintLevel: 'h0',
    lastEvaluatorConfidence: lastEvaluatorConfidence,
    lastLatencyToStartMs: 600,
    attemptsCount: attemptsCount,
    passesCount: passesCount,
    lastUpdatedDay: 100,
    lastSessionId: sessionId,
  );
}

Future<int> _unitIdForKey(AppDatabase db, String unitKey) async {
  final unit = await (db.select(db.memUnit)
        ..where((tbl) => tbl.unitKey.equals(unitKey))
        ..limit(1))
      .getSingle();
  return unit.id;
}

Future<void> _seedAyahs(AppDatabase db) async {
  final rows = <AyahCompanion>[];
  for (var ayah = 1; ayah <= 25; ayah++) {
    final page = ((ayah - 1) ~/ 5) + 1;
    rows.add(
      AyahCompanion.insert(
        surah: 1,
        ayah: ayah,
        textUthmani: 'ayah-$ayah',
        pageMadina: Value(page),
      ),
    );
  }
  await db.batch((batch) {
    batch.insertAll(db.ayah, rows);
  });
}

int _findDayForWeekday(int weekday) {
  for (var day = 0; day < 14; day++) {
    final date = DateTime(1970, 1, 1).add(Duration(days: day));
    if (date.weekday == weekday) {
      return day;
    }
  }
  throw StateError('Weekday $weekday not found in search window');
}
