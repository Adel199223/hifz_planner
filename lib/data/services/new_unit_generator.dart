import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/mem_unit_repo.dart';
import '../repositories/quran_repo.dart';
import '../repositories/schedule_repo.dart';
import '../repositories/settings_repo.dart';

class NewUnitGenerationResult {
  const NewUnitGenerationResult({
    required this.createdUnits,
    required this.minutesPlannedNew,
    required this.nextSurah,
    required this.nextAyah,
    required this.cursorAtEnd,
  });

  final List<MemUnitData> createdUnits;
  final double minutesPlannedNew;
  final int nextSurah;
  final int nextAyah;
  final bool cursorAtEnd;
}

class NewUnitGenerator {
  NewUnitGenerator(
    this._quranRepo,
    this._memUnitRepo,
    this._scheduleRepo,
  );

  final QuranRepo _quranRepo;
  final MemUnitRepo _memUnitRepo;
  final ScheduleRepo _scheduleRepo;

  Future<NewUnitGenerationResult> generate({
    required int todayDay,
    required MemProgressData cursor,
    required double remainingMinutes,
    required AppSettingsData settings,
    required double initialEf,
  }) async {
    if (remainingMinutes <= 0 ||
        settings.maxNewUnitsPerDay <= 0 ||
        settings.maxNewPagesPerDay <= 0 ||
        settings.avgNewMinutesPerAyah <= 0) {
      return NewUnitGenerationResult(
        createdUnits: const <MemUnitData>[],
        minutesPlannedNew: 0,
        nextSurah: cursor.nextSurah,
        nextAyah: cursor.nextAyah,
        cursorAtEnd: false,
      );
    }

    var currentSurah = cursor.nextSurah;
    var currentAyah = cursor.nextAyah;
    var minutesPlanned = 0.0;
    var cursorAtEnd = false;
    final createdUnits = <MemUnitData>[];
    final touchedPages = <int>{};

    while (createdUnits.length < settings.maxNewUnitsPerDay) {
      final minutesLeft = remainingMinutes - minutesPlanned;
      final maxAyahsByTime =
          (minutesLeft / settings.avgNewMinutesPerAyah).floor();
      if (maxAyahsByTime < 1) {
        break;
      }

      final window = await _quranRepo.getAyahsFromCursor(
        startSurah: currentSurah,
        startAyah: currentAyah,
        limit: maxAyahsByTime,
      );
      if (window.isEmpty) {
        cursorAtEnd = true;
        final lastAyah = await _quranRepo.getLastAyah();
        if (lastAyah != null) {
          currentSurah = lastAyah.surah;
          currentAyah = lastAyah.ayah;
        }
        break;
      }

      final anchor = window.first;
      final anchorPage = anchor.pageMadina;
      final normalizedPage = anchorPage ?? -1;
      final isNewPage = !touchedPages.contains(normalizedPage);
      if (isNewPage && touchedPages.length >= settings.maxNewPagesPerDay) {
        break;
      }

      final unitAyahs = _takeUnitAyahs(window, anchorPage);
      final ayahCount = unitAyahs.length;
      final estimatedMinutes = ayahCount * settings.avgNewMinutesPerAyah;
      if (estimatedMinutes > minutesLeft + 1e-9) {
        break;
      }

      final start = unitAyahs.first;
      final end = unitAyahs.last;
      final unitKey = _buildUnitKey(
        pageMadina: anchorPage,
        startSurah: start.surah,
        startAyah: start.ayah,
        endSurah: end.surah,
        endAyah: end.ayah,
      );

      final unitId = await _memUnitRepo.create(
        MemUnitCompanion.insert(
          kind: 'page_segment',
          pageMadina:
              anchorPage == null ? const Value.absent() : Value(anchorPage),
          startSurah: Value(start.surah),
          startAyah: Value(start.ayah),
          endSurah: Value(end.surah),
          endAyah: Value(end.ayah),
          unitKey: unitKey,
          createdAtDay: todayDay,
          updatedAtDay: todayDay,
        ),
      );

      await _scheduleRepo.upsertInitialStateForNewUnit(
        unitId: unitId,
        dueDay: todayDay,
        ef: initialEf,
        reps: 0,
        intervalDays: 0,
      );

      final created = await _memUnitRepo.get(unitId);
      if (created != null) {
        createdUnits.add(created);
      }
      touchedPages.add(normalizedPage);
      minutesPlanned += estimatedMinutes;

      final nextAyahs = await _quranRepo.getAyahsFromCursor(
        startSurah: end.surah,
        startAyah: end.ayah + 1,
        limit: 1,
      );
      if (nextAyahs.isEmpty) {
        cursorAtEnd = true;
        final lastAyah = await _quranRepo.getLastAyah();
        if (lastAyah != null) {
          currentSurah = lastAyah.surah;
          currentAyah = lastAyah.ayah;
        }
        break;
      }

      currentSurah = nextAyahs.first.surah;
      currentAyah = nextAyahs.first.ayah;
    }

    return NewUnitGenerationResult(
      createdUnits: createdUnits,
      minutesPlannedNew: minutesPlanned,
      nextSurah: currentSurah,
      nextAyah: currentAyah,
      cursorAtEnd: cursorAtEnd,
    );
  }

  Future<NewUnitGenerationResult> generateOneUnit({
    required int todayDay,
    required MemProgressData cursor,
    required AppSettingsData settings,
    required double initialEf,
  }) async {
    if (settings.avgNewMinutesPerAyah <= 0) {
      return NewUnitGenerationResult(
        createdUnits: const <MemUnitData>[],
        minutesPlannedNew: 0,
        nextSurah: cursor.nextSurah,
        nextAyah: cursor.nextAyah,
        cursorAtEnd: false,
      );
    }

    final anchorWindow = await _quranRepo.getAyahsFromCursor(
      startSurah: cursor.nextSurah,
      startAyah: cursor.nextAyah,
      limit: 1,
    );
    if (anchorWindow.isEmpty) {
      final exhaustedCursor = await _resolveExhaustedCursor(
        fallbackSurah: cursor.nextSurah,
        fallbackAyah: cursor.nextAyah,
      );
      return NewUnitGenerationResult(
        createdUnits: const <MemUnitData>[],
        minutesPlannedNew: 0,
        nextSurah: exhaustedCursor.nextSurah,
        nextAyah: exhaustedCursor.nextAyah,
        cursorAtEnd: exhaustedCursor.cursorAtEnd,
      );
    }

    final anchor = anchorWindow.first;
    final unitAyahs = await _loadSingleUnitAyahs(
      anchor: anchor,
      settings: settings,
    );
    if (unitAyahs.isEmpty) {
      return NewUnitGenerationResult(
        createdUnits: const <MemUnitData>[],
        minutesPlannedNew: 0,
        nextSurah: anchor.surah,
        nextAyah: anchor.ayah,
        cursorAtEnd: false,
      );
    }

    final createdUnit = await _createUnitFromAyahs(
      unitAyahs: unitAyahs,
      todayDay: todayDay,
      initialEf: initialEf,
    );
    final end = unitAyahs.last;
    final nextCursor = await _resolveNextCursor(
      endSurah: end.surah,
      endAyah: end.ayah,
    );

    return NewUnitGenerationResult(
      createdUnits: <MemUnitData>[createdUnit],
      minutesPlannedNew: unitAyahs.length * settings.avgNewMinutesPerAyah,
      nextSurah: nextCursor.nextSurah,
      nextAyah: nextCursor.nextAyah,
      cursorAtEnd: nextCursor.cursorAtEnd,
    );
  }

  List<AyahData> _takeUnitAyahs(List<AyahData> window, int? anchorPage) {
    if (window.isEmpty) {
      return const <AyahData>[];
    }
    if (anchorPage == null) {
      return window;
    }

    final unitAyahs = <AyahData>[];
    for (final ayah in window) {
      if (ayah.pageMadina != anchorPage) {
        break;
      }
      unitAyahs.add(ayah);
    }
    return unitAyahs.isEmpty ? <AyahData>[window.first] : unitAyahs;
  }

  String _buildUnitKey({
    required int? pageMadina,
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
  }) {
    final pageToken = pageMadina ?? 0;
    return 'page_segment:p$pageToken:s${startSurah}a$startAyah-s${endSurah}a$endAyah';
  }

  Future<List<AyahData>> _loadSingleUnitAyahs({
    required AyahData anchor,
    required AppSettingsData settings,
  }) async {
    final anchorPage = anchor.pageMadina;
    if (anchorPage != null) {
      final pageAyahs = await _quranRepo.getAyahsByPage(anchorPage);
      final unitAyahs = pageAyahs
          .where(
            (ayah) =>
                ayah.surah > anchor.surah ||
                (ayah.surah == anchor.surah && ayah.ayah >= anchor.ayah),
          )
          .toList(growable: false);
      return unitAyahs.isEmpty ? <AyahData>[anchor] : unitAyahs;
    }

    final windowLimit = math.max(
      1,
      (settings.dailyMinutesDefault / settings.avgNewMinutesPerAyah).floor(),
    );
    return _quranRepo.getAyahsFromCursor(
      startSurah: anchor.surah,
      startAyah: anchor.ayah,
      limit: windowLimit,
    );
  }

  Future<MemUnitData> _createUnitFromAyahs({
    required List<AyahData> unitAyahs,
    required int todayDay,
    required double initialEf,
  }) async {
    final start = unitAyahs.first;
    final end = unitAyahs.last;
    final pageMadina = start.pageMadina;
    final unitId = await _memUnitRepo.create(
      MemUnitCompanion.insert(
        kind: 'page_segment',
        pageMadina:
            pageMadina == null ? const Value.absent() : Value(pageMadina),
        startSurah: Value(start.surah),
        startAyah: Value(start.ayah),
        endSurah: Value(end.surah),
        endAyah: Value(end.ayah),
        unitKey: _buildUnitKey(
          pageMadina: pageMadina,
          startSurah: start.surah,
          startAyah: start.ayah,
          endSurah: end.surah,
          endAyah: end.ayah,
        ),
        createdAtDay: todayDay,
        updatedAtDay: todayDay,
      ),
    );

    await _scheduleRepo.upsertInitialStateForNewUnit(
      unitId: unitId,
      dueDay: todayDay,
      ef: initialEf,
      reps: 0,
      intervalDays: 0,
    );

    final createdUnit = await _memUnitRepo.get(unitId);
    if (createdUnit == null) {
      throw StateError('Failed to load newly created unit $unitId.');
    }
    return createdUnit;
  }

  Future<_NextCursorResult> _resolveNextCursor({
    required int endSurah,
    required int endAyah,
  }) async {
    final nextAyahs = await _quranRepo.getAyahsFromCursor(
      startSurah: endSurah,
      startAyah: endAyah + 1,
      limit: 1,
    );
    if (nextAyahs.isNotEmpty) {
      return _NextCursorResult(
        nextSurah: nextAyahs.first.surah,
        nextAyah: nextAyahs.first.ayah,
        cursorAtEnd: false,
      );
    }

    return _resolveExhaustedCursor(
      fallbackSurah: endSurah,
      fallbackAyah: endAyah,
    );
  }

  Future<_NextCursorResult> _resolveExhaustedCursor({
    required int fallbackSurah,
    required int fallbackAyah,
  }) async {
    final lastAyah = await _quranRepo.getLastAyah();
    return _NextCursorResult(
      nextSurah: lastAyah?.surah ?? fallbackSurah,
      nextAyah: lastAyah?.ayah ?? fallbackAyah,
      cursorAtEnd: true,
    );
  }
}

class _NextCursorResult {
  const _NextCursorResult({
    required this.nextSurah,
    required this.nextAyah,
    required this.cursorAtEnd,
  });

  final int nextSurah;
  final int nextAyah;
  final bool cursorAtEnd;
}
