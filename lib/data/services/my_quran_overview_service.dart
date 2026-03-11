import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/bookmark_repo.dart';
import '../repositories/companion_repo.dart';
import '../repositories/note_repo.dart';
import '../repositories/progress_repo.dart';
import '../repositories/quran_repo.dart';

class MyQuranOverview {
  const MyQuranOverview({
    required this.totalMemorizationUnits,
    required this.dueReviewCount,
    required this.stage4DueCount,
    required this.bookmarkCount,
    required this.noteCount,
    required this.cursor,
    required this.recentBookmarks,
    required this.recentNotes,
  });

  final int totalMemorizationUnits;
  final int dueReviewCount;
  final int stage4DueCount;
  final int bookmarkCount;
  final int noteCount;
  final MyQuranCursorTarget cursor;
  final List<MyQuranBookmarkPreview> recentBookmarks;
  final List<MyQuranNotePreview> recentNotes;
}

class MyQuranCursorTarget {
  const MyQuranCursorTarget({
    required this.surah,
    required this.ayah,
    required this.pageMadina,
  });

  final int surah;
  final int ayah;
  final int? pageMadina;
}

class MyQuranBookmarkPreview {
  const MyQuranBookmarkPreview({
    required this.bookmark,
    required this.pageMadina,
  });

  final BookmarkData bookmark;
  final int? pageMadina;
}

class MyQuranNotePreview {
  const MyQuranNotePreview({
    required this.note,
    required this.pageMadina,
  });

  final NoteData note;
  final int? pageMadina;
}

class MyQuranOverviewService {
  MyQuranOverviewService(
    this._db,
    this._bookmarkRepo,
    this._noteRepo,
    this._progressRepo,
    this._quranRepo,
    this._companionRepo,
  );

  final AppDatabase _db;
  final BookmarkRepo _bookmarkRepo;
  final NoteRepo _noteRepo;
  final ProgressRepo _progressRepo;
  final QuranRepo _quranRepo;
  final CompanionRepo _companionRepo;

  Future<MyQuranOverview> loadOverview({
    required int todayDay,
  }) {
    return _db.transaction(() async {
      final bookmarkRows = await _bookmarkRepo.getBookmarks();
      final noteRows = await _noteRepo.getAllNotes();
      final cursor = await _progressRepo.getCursor();
      final cursorAyah = await _quranRepo.getAyah(
        cursor.nextSurah,
        cursor.nextAyah,
      );
      final recentBookmarks = await _buildRecentBookmarks(bookmarkRows);
      final recentNotes = await _buildRecentNotes(noteRows);

      return MyQuranOverview(
        totalMemorizationUnits: await _countRows('mem_unit'),
        dueReviewCount: await _countDueReviews(todayDay),
        stage4DueCount:
            (await _companionRepo.getDueLifecycleStates(todayDay: todayDay))
                .length,
        bookmarkCount: bookmarkRows.length,
        noteCount: noteRows.length,
        cursor: MyQuranCursorTarget(
          surah: cursor.nextSurah,
          ayah: cursor.nextAyah,
          pageMadina: cursorAyah?.pageMadina,
        ),
        recentBookmarks: recentBookmarks,
        recentNotes: recentNotes,
      );
    });
  }

  Future<List<MyQuranBookmarkPreview>> _buildRecentBookmarks(
    List<BookmarkData> rows,
  ) async {
    final previews = <MyQuranBookmarkPreview>[];
    for (final bookmark in rows.take(3)) {
      final ayah = await _quranRepo.getAyah(bookmark.surah, bookmark.ayah);
      previews.add(
        MyQuranBookmarkPreview(
          bookmark: bookmark,
          pageMadina: ayah?.pageMadina,
        ),
      );
    }
    return previews;
  }

  Future<List<MyQuranNotePreview>> _buildRecentNotes(
    List<NoteData> rows,
  ) async {
    final previews = <MyQuranNotePreview>[];
    for (final note in rows.take(3)) {
      final ayah = await _quranRepo.getAyah(note.surah, note.ayah);
      previews.add(
        MyQuranNotePreview(
          note: note,
          pageMadina: ayah?.pageMadina,
        ),
      );
    }
    return previews;
  }

  Future<int> _countRows(String tableName) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS row_count FROM $tableName',
        )
        .getSingle();
    return row.read<int>('row_count');
  }

  Future<int> _countDueReviews(int todayDay) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS row_count '
      'FROM schedule_state '
      'WHERE due_day <= ? AND is_suspended = 0',
      variables: <Variable<Object>>[
        Variable<int>(todayDay),
      ],
    ).getSingle();
    return row.read<int>('row_count');
  }
}
