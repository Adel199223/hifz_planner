import 'dart:io';

import 'package:just_audio_media_kit/just_audio_media_kit.dart';

void ensurePlatformAudioInitialized() {
  final isWindows = Platform.isWindows;
  final isLinux = Platform.isLinux;
  if (!isWindows && !isLinux) {
    return;
  }
  JustAudioMediaKit.ensureInitialized(
    windows: isWindows,
    linux: isLinux,
  );
}
