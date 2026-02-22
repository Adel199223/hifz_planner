import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum QcfFontVariant {
  v2,
  v4tajweed,
}

class QcfFontSelection {
  const QcfFontSelection({
    required this.familyName,
    required this.requestedVariant,
    required this.effectiveVariant,
  });

  final String familyName;
  final QcfFontVariant requestedVariant;
  final QcfFontVariant effectiveVariant;

  bool get usedFallback => requestedVariant != effectiveVariant;
}

class QcfFontManager {
  QcfFontManager({
    http.Client? httpClient,
    Future<Directory> Function()? getSupportDirectory,
  })  : _httpClient = httpClient ?? http.Client(),
        _getSupportDirectory =
            getSupportDirectory ?? getApplicationSupportDirectory;

  static const String _v2BaseUrl =
      'https://verses.quran.foundation/fonts/quran/hafs/v2/ttf';
  static const String _v4TajweedBaseUrl =
      'https://verses.quran.foundation/fonts/quran/hafs/v4/colrv1/ttf';

  final http.Client _httpClient;
  final Future<Directory> Function() _getSupportDirectory;

  final Map<String, Future<String>> _pendingFamilyLoads =
      <String, Future<String>>{};
  final Set<String> _loadedFamilies = <String>{};
  final Set<int> _loggedV4Failures = <int>{};

  Future<QcfFontSelection> ensurePageFont({
    required int page,
    required QcfFontVariant variant,
  }) async {
    if (page < 1 || page > 604) {
      throw ArgumentError.value(page, 'page', 'Expected 1..604.');
    }

    if (variant == QcfFontVariant.v2) {
      final familyName = await _ensureFamilyLoaded(
        page: page,
        variant: QcfFontVariant.v2,
      );
      return QcfFontSelection(
        familyName: familyName,
        requestedVariant: variant,
        effectiveVariant: QcfFontVariant.v2,
      );
    }

    try {
      final familyName = await _ensureFamilyLoaded(
        page: page,
        variant: QcfFontVariant.v4tajweed,
      );
      return QcfFontSelection(
        familyName: familyName,
        requestedVariant: variant,
        effectiveVariant: QcfFontVariant.v4tajweed,
      );
    } catch (error) {
      if (_loggedV4Failures.add(page)) {
        debugPrint(
          'QCF v4tajweed font failed for page $page. Falling back to v2. '
          'Error: $error',
        );
      }
      final familyName = await _ensureFamilyLoaded(
        page: page,
        variant: QcfFontVariant.v2,
      );
      return QcfFontSelection(
        familyName: familyName,
        requestedVariant: variant,
        effectiveVariant: QcfFontVariant.v2,
      );
    }
  }

  Future<String> _ensureFamilyLoaded({
    required int page,
    required QcfFontVariant variant,
  }) {
    final familyName = _familyFor(page: page, variant: variant);
    if (_loadedFamilies.contains(familyName)) {
      return Future<String>.value(familyName);
    }

    final loadKey = '$familyName|load';
    final existingLoad = _pendingFamilyLoads[loadKey];
    if (existingLoad != null) {
      return existingLoad;
    }

    final loadFuture = _loadFamily(
      page: page,
      variant: variant,
      familyName: familyName,
    );
    _pendingFamilyLoads[loadKey] = loadFuture;
    return loadFuture.whenComplete(() {
      _pendingFamilyLoads.remove(loadKey);
    });
  }

  Future<String> _loadFamily({
    required int page,
    required QcfFontVariant variant,
    required String familyName,
  }) async {
    final file = await _resolveFontFile(page: page, variant: variant);
    if (!await file.exists()) {
      await _downloadFontFile(file: file, page: page, variant: variant);
    }

    final bytes = await file.readAsBytes();
    final loader = FontLoader(familyName)
      ..addFont(
        Future<ByteData>.value(
          ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    await loader.load();
    _loadedFamilies.add(familyName);
    return familyName;
  }

  Future<File> _resolveFontFile({
    required int page,
    required QcfFontVariant variant,
  }) async {
    final supportDir = await _getSupportDirectory();
    final folderName = switch (variant) {
      QcfFontVariant.v2 => 'qcf_v2',
      QcfFontVariant.v4tajweed => 'qcf_v4tajweed',
    };
    final dir = Directory(
      _joinPath(_joinPath(supportDir.path, 'fonts'), folderName),
    );
    await dir.create(recursive: true);
    return File(_joinPath(dir.path, 'p$page.ttf'));
  }

  Future<void> _downloadFontFile({
    required File file,
    required int page,
    required QcfFontVariant variant,
  }) async {
    final base = switch (variant) {
      QcfFontVariant.v2 => _v2BaseUrl,
      QcfFontVariant.v4tajweed => _v4TajweedBaseUrl,
    };
    final uri = Uri.parse('$base/p$page.ttf');

    final response = await _httpClient.get(uri);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Failed to download QCF font ($variant page $page): '
        '${response.statusCode}.',
        uri: uri,
      );
    }

    final tempPath =
        '${file.path}.tmp_${DateTime.now().microsecondsSinceEpoch}';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(response.bodyBytes, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  String _familyFor({
    required int page,
    required QcfFontVariant variant,
  }) {
    return switch (variant) {
      QcfFontVariant.v2 => 'qcf_v2_p$page',
      QcfFontVariant.v4tajweed => 'qcf_v4tajweed_p$page',
    };
  }
}

String _joinPath(String base, String leaf) {
  if (base.endsWith(Platform.pathSeparator)) {
    return '$base$leaf';
  }
  return '$base${Platform.pathSeparator}$leaf';
}
