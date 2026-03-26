import 'package:flutter/foundation.dart';

class AudioPlatformCapabilities {
  const AudioPlatformCapabilities({
    required this.supportsOfflineDownloads,
    required this.streamingOnly,
  });

  final bool supportsOfflineDownloads;
  final bool streamingOnly;
}

AudioPlatformCapabilities currentAudioPlatformCapabilities() {
  if (kIsWeb) {
    return const AudioPlatformCapabilities(
      supportsOfflineDownloads: false,
      streamingOnly: true,
    );
  }

  return const AudioPlatformCapabilities(
    supportsOfflineDownloads: true,
    streamingOnly: false,
  );
}
