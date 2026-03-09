import 'dart:async';

import '../database/app_database.dart';
import '../repositories/bookmark_repo.dart';
import '../repositories/note_repo.dart';
import '../repositories/quran_repo.dart';

class MyQuranBookmarkPreview {
  const MyQuranBookmarkPreview({
    required this.bookmark,
    this.ayah,
  });

  final BookmarkData bookmark;
  final AyahData? ayah;
}

class MyQuranNotePreview {
  const MyQuranNotePreview({
    required this.note,
    this.ayah,
  });

  final NoteData note;
  final AyahData? ayah;
}

class MyQuranSavedItemsSnapshot {
  const MyQuranSavedItemsSnapshot({
    required this.bookmarkCount,
    required this.noteCount,
    this.latestBookmark,
    this.latestNote,
  });

  final int bookmarkCount;
  final int noteCount;
  final MyQuranBookmarkPreview? latestBookmark;
  final MyQuranNotePreview? latestNote;
}

class MyQuranSnapshotService {
  const MyQuranSnapshotService(
    this._bookmarkRepo,
    this._noteRepo,
    this._quranRepo,
  );

  final BookmarkRepo _bookmarkRepo;
  final NoteRepo _noteRepo;
  final QuranRepo _quranRepo;

  Stream<MyQuranSavedItemsSnapshot> watchSavedItems() {
    final bookmarkStream = _bookmarkRepo.watchBookmarks();
    final noteStream = _noteRepo.watchAllNotes();

    return Stream.multi((controller) {
      List<BookmarkData>? bookmarks;
      List<NoteData>? notes;
      var generation = 0;

      Future<void> emitSnapshot() async {
        if (bookmarks == null || notes == null) {
          return;
        }
        final currentGeneration = ++generation;
        final latestBookmark = bookmarks!.isEmpty ? null : bookmarks!.first;
        final latestNote = notes!.isEmpty ? null : notes!.first;
        final latestBookmarkAyah = latestBookmark == null
            ? null
            : await _quranRepo.getAyah(
                latestBookmark.surah,
                latestBookmark.ayah,
              );
        final latestNoteAyah = latestNote == null
            ? null
            : await _quranRepo.getAyah(latestNote.surah, latestNote.ayah);

        if (currentGeneration != generation) {
          return;
        }

        controller.add(
          MyQuranSavedItemsSnapshot(
            bookmarkCount: bookmarks!.length,
            noteCount: notes!.length,
            latestBookmark: latestBookmark == null
                ? null
                : MyQuranBookmarkPreview(
                    bookmark: latestBookmark,
                    ayah: latestBookmarkAyah,
                  ),
            latestNote: latestNote == null
                ? null
                : MyQuranNotePreview(note: latestNote, ayah: latestNoteAyah),
          ),
        );
      }

      final bookmarkSubscription = bookmarkStream.listen((value) {
        bookmarks = value;
        unawaited(emitSnapshot());
      }, onError: controller.addError);
      final noteSubscription = noteStream.listen((value) {
        notes = value;
        unawaited(emitSnapshot());
      }, onError: controller.addError);

      controller.onCancel = () async {
        await bookmarkSubscription.cancel();
        await noteSubscription.cancel();
      };
    });
  }
}
