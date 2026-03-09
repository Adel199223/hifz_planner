import 'dart:async';

import '../database/app_database.dart';
import '../repositories/bookmark_repo.dart';
import '../repositories/note_repo.dart';

class MyQuranSavedItemsSnapshot {
  const MyQuranSavedItemsSnapshot({
    required this.bookmarkCount,
    required this.noteCount,
    this.latestBookmark,
    this.latestNote,
  });

  final int bookmarkCount;
  final int noteCount;
  final BookmarkData? latestBookmark;
  final NoteData? latestNote;
}

class MyQuranSnapshotService {
  const MyQuranSnapshotService(this._bookmarkRepo, this._noteRepo);

  final BookmarkRepo _bookmarkRepo;
  final NoteRepo _noteRepo;

  Stream<MyQuranSavedItemsSnapshot> watchSavedItems() {
    final bookmarkStream = _bookmarkRepo.watchBookmarks();
    final noteStream = _noteRepo.watchAllNotes();

    return Stream.multi((controller) {
      List<BookmarkData>? bookmarks;
      List<NoteData>? notes;

      void emitSnapshot() {
        if (bookmarks == null || notes == null) {
          return;
        }
        controller.add(
          MyQuranSavedItemsSnapshot(
            bookmarkCount: bookmarks!.length,
            noteCount: notes!.length,
            latestBookmark: bookmarks!.isEmpty ? null : bookmarks!.first,
            latestNote: notes!.isEmpty ? null : notes!.first,
          ),
        );
      }

      final bookmarkSubscription = bookmarkStream.listen((value) {
        bookmarks = value;
        emitSnapshot();
      }, onError: controller.addError);
      final noteSubscription = noteStream.listen((value) {
        notes = value;
        emitSnapshot();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await bookmarkSubscription.cancel();
        await noteSubscription.cancel();
      };
    });
  }
}
