import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_preferences.dart';
import '../services/my_quran_snapshot_service.dart';
import 'database_providers.dart';

class MyQuranDashboardSnapshot {
  const MyQuranDashboardSnapshot({
    required this.lastReaderLocation,
    required this.bookmarkCount,
    required this.noteCount,
    required this.reciterDisplayName,
    required this.speed,
    required this.repeatCount,
  });

  final ReaderLastLocation? lastReaderLocation;
  final int bookmarkCount;
  final int noteCount;
  final String reciterDisplayName;
  final double speed;
  final int repeatCount;
}

final myQuranSnapshotServiceProvider = Provider<MyQuranSnapshotService>((ref) {
  final bookmarkRepo = ref.watch(bookmarkRepoProvider);
  final noteRepo = ref.watch(noteRepoProvider);
  return MyQuranSnapshotService(bookmarkRepo, noteRepo);
});

final myQuranSavedItemsSnapshotProvider =
    StreamProvider<MyQuranSavedItemsSnapshot>((ref) {
  final service = ref.watch(myQuranSnapshotServiceProvider);
  return service.watchSavedItems();
});

final myQuranDashboardSnapshotProvider =
    Provider<AsyncValue<MyQuranDashboardSnapshot>>((ref) {
  final savedItemsAsync = ref.watch(myQuranSavedItemsSnapshotProvider);
  final appPreferences = ref.watch(appPreferencesProvider);
  final audioPreferences = ref.watch(ayahAudioPreferencesProvider);

  return savedItemsAsync.whenData(
    (savedItems) => MyQuranDashboardSnapshot(
      lastReaderLocation: appPreferences.readerLastLocation,
      bookmarkCount: savedItems.bookmarkCount,
      noteCount: savedItems.noteCount,
      reciterDisplayName: audioPreferences.reciterDisplayName,
      speed: audioPreferences.speed,
      repeatCount: audioPreferences.repeatCount,
    ),
  );
});
