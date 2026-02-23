import 'dart:async';

import 'package:http/http.dart' as http;

import 'ayah_audio_source.dart';

abstract class AyahAudioStreamResolver {
  Future<int?> resolvePlayableBitrate({
    required String edition,
    required int preferredBitrate,
  });
}

class AlQuranCloudAyahAudioStreamResolver implements AyahAudioStreamResolver {
  AlQuranCloudAyahAudioStreamResolver({
    required http.Client client,
    Duration probeTimeout = const Duration(seconds: 8),
  })  : _client = client,
        _probeTimeout = probeTimeout;

  final http.Client _client;
  final Duration _probeTimeout;

  @override
  Future<int?> resolvePlayableBitrate({
    required String edition,
    required int preferredBitrate,
  }) async {
    final candidateBitrates = <int>[];
    void addCandidate(int bitrate) {
      if (bitrate > 0 && !candidateBitrates.contains(bitrate)) {
        candidateBitrates.add(bitrate);
      }
    }

    addCandidate(preferredBitrate);
    addCandidate(128);
    addCandidate(64);
    addCandidate(32);

    for (final bitrate in candidateBitrates) {
      final playable = await _probePlayable(
        edition: edition,
        bitrate: bitrate,
      );
      if (playable) {
        return bitrate;
      }
    }

    return null;
  }

  Future<bool> _probePlayable({
    required String edition,
    required int bitrate,
  }) async {
    final probeUri = AlQuranCloudAyahAudioSource(
      edition: edition,
      bitrate: bitrate,
    ).urlForAyah(1, 1);

    try {
      final response = await _client.get(
        probeUri,
        headers: const <String, String>{
          'Range': 'bytes=0-0',
        },
      ).timeout(_probeTimeout);

      return response.statusCode == 200 || response.statusCode == 206;
    } catch (_) {
      return false;
    }
  }
}
