import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/qurancom_chapters_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses chapters payload and returns translated names', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('chapters_parse_test');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final client = MockClient((request) async {
      expect(request.url.host, 'api.quran.com');
      expect(request.url.path, '/api/v4/chapters');
      expect(request.url.queryParameters['language'], 'en');
      return _jsonResponse(
        {
          'chapters': [
            {
              'id': 1,
              'name_simple': 'Al-Fatihah',
              'name_arabic': 'الفاتحة',
              'translated_name': {
                'name': 'The Opener',
                'language_name': 'english',
              },
            },
          ],
        },
      );
    });

    final service = QuranComChaptersService(
      httpClient: client,
      getSupportDirectory: () async => tempDir,
      requestTimeout: const Duration(milliseconds: 300),
    );

    final chapters = await service.getChapters(languageCode: 'en');
    expect(chapters.length, 1);
    expect(chapters.first.id, 1);
    expect(chapters.first.nameSimple, 'Al-Fatihah');
    expect(chapters.first.nameArabic, 'الفاتحة');
    expect(chapters.first.translatedName, 'The Opener');
  });

  test('falls back to cached chapters when network request fails', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('chapters_cache_test');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final successClient = MockClient((request) async {
      return _jsonResponse(
        {
          'chapters': [
            {
              'id': 1,
              'name_simple': 'Al-Fatihah',
              'name_arabic': 'الفاتحة',
              'translated_name': {
                'name': 'The Opener',
                'language_name': 'english',
              },
            },
          ],
        },
      );
    });
    final cachedService = QuranComChaptersService(
      httpClient: successClient,
      getSupportDirectory: () async => tempDir,
      requestTimeout: const Duration(milliseconds: 300),
    );
    final firstLoad = await cachedService.getChapters(languageCode: 'en');
    expect(firstLoad, isNotEmpty);

    final failingClient = MockClient((request) async {
      throw http.ClientException('network down');
    });
    final fallbackService = QuranComChaptersService(
      httpClient: failingClient,
      getSupportDirectory: () async => tempDir,
      requestTimeout: const Duration(milliseconds: 300),
    );
    final cachedLoad = await fallbackService.getChapters(languageCode: 'en');
    expect(cachedLoad, isNotEmpty);
    expect(cachedLoad.first.translatedName, 'The Opener');
  });

  test('returns empty list when no cache is available and request fails',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('chapters_empty_test');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final failingClient = MockClient((request) async {
      throw http.ClientException('network down');
    });
    final service = QuranComChaptersService(
      httpClient: failingClient,
      getSupportDirectory: () async => tempDir,
      requestTimeout: const Duration(milliseconds: 300),
    );

    final chapters = await service.getChapters(languageCode: 'en');
    expect(chapters, isEmpty);
  });
}

http.Response _jsonResponse(Map<String, Object?> payload) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(payload)),
    200,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}
