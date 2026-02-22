import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/qurancom_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory supportDir;

  setUp(() async {
    supportDir = await Directory.systemTemp.createTemp('qurancom_api_test_');
  });

  tearDown(() async {
    if (await supportDir.exists()) {
      await supportDir.delete(recursive: true);
    }
  });

  test('getPage parses backward-compatible cached meta', () async {
    var networkCalls = 0;
    final api = QuranComApi(
      httpClient: MockClient((request) async {
        networkCalls += 1;
        return http.Response('{}', HttpStatus.badRequest);
      }),
      getSupportDirectory: () async => supportDir,
    );

    final cacheDir = Directory(
      '${supportDir.path}${Platform.pathSeparator}qurancom_pages',
    );
    await cacheDir.create(recursive: true);
    final legacyCache = File(
      '${cacheDir.path}${Platform.pathSeparator}page_1_m1.json',
    );
    await legacyCache.writeAsString(
      jsonEncode(
        <String, dynamic>{
          'meta': <String, dynamic>{
            'first_chapter_id': 1,
            'first_verse_number': 1,
            'first_verse_key': '1:1',
          },
          'words': <Map<String, dynamic>>[
            <String, dynamic>{
              'verse_key': '1:1',
              'code_v2': 'A',
              'text_qpc_hafs': 'A',
              'char_type_name': 'word',
              'line_number': 1,
              'position': 1,
              'page_number': 1,
            },
          ],
          'verses': <Map<String, dynamic>>[
            <String, dynamic>{
              'verse_key': '1:1',
              'code_v2': 'A',
              'words': <Map<String, dynamic>>[
                <String, dynamic>{
                  'verse_key': '1:1',
                  'code_v2': 'A',
                  'text_qpc_hafs': 'A',
                  'char_type_name': 'word',
                  'line_number': 1,
                  'position': 1,
                  'page_number': 1,
                },
              ],
            },
          ],
        },
      ),
    );

    final page = await api.getPage(page: 1, mushafId: 1);

    expect(networkCalls, 0);
    expect(page.meta.firstChapterId, 1);
    expect(page.meta.firstVerseKey, '1:1');
    expect(page.meta.pageNumber, isNull);
    expect(page.meta.juzNumber, isNull);
    expect(page.meta.hizbNumber, isNull);
  });

  test('getPage persists upgraded meta fields from network payload', () async {
    final api = QuranComApi(
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v4/verses/by_page/1');
        return http.Response(
          jsonEncode(
            <String, dynamic>{
              'verses': <Map<String, dynamic>>[
                <String, dynamic>{
                  'verse_key': '1:1',
                  'chapter_id': 1,
                  'verse_number': 1,
                  'page_number': 1,
                  'juz_number': 1,
                  'hizb_number': 1,
                  'rub_el_hizb_number': 1,
                  'code_v2': 'A',
                  'words': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'verse_key': '1:1',
                      'code_v2': 'A',
                      'text_qpc_hafs': 'A',
                      'char_type_name': 'word',
                      'line_number': 1,
                      'position': 1,
                      'page_number': 1,
                      'translation': <String, dynamic>{'text': 'Example'},
                      'transliteration': <String, dynamic>{'text': 'Sample'},
                    },
                  ],
                },
              ],
            },
          ),
          HttpStatus.ok,
        );
      }),
      getSupportDirectory: () async => supportDir,
    );

    final pageData = await api.getPage(page: 1, mushafId: 1);
    expect(pageData.meta.pageNumber, 1);
    expect(pageData.meta.juzNumber, 1);
    expect(pageData.meta.hizbNumber, 1);
    expect(pageData.meta.rubElHizbNumber, 1);

    final cacheFile = File(
      '${supportDir.path}${Platform.pathSeparator}qurancom_pages${Platform.pathSeparator}page_1_m1.json',
    );
    final cachedJson =
        jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
    final cachedMeta = cachedJson['meta'] as Map<String, dynamic>;
    expect(cachedMeta['page_number'], 1);
    expect(cachedMeta['juz_number'], 1);
    expect(cachedMeta['hizb_number'], 1);
    expect(cachedMeta['rub_el_hizb_number'], 1);
  });

  test('getJuzIndex dedupes in-flight fetches and reuses cache', () async {
    var byJuzRequestCount = 0;
    final api = QuranComApi(
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/verses/by_juz/')) {
          byJuzRequestCount += 1;
          final juzNumber = int.parse(path.split('/').last);
          return http.Response(
            jsonEncode(
              <String, dynamic>{
                'verses': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'verse_key': '2:$juzNumber',
                    'chapter_id': 2,
                    'verse_number': juzNumber,
                    'page_number': juzNumber,
                    'juz_number': juzNumber,
                    'hizb_number': juzNumber,
                    'rub_el_hizb_number': juzNumber,
                  },
                ],
              },
            ),
            HttpStatus.ok,
          );
        }
        return http.Response('{}', HttpStatus.badRequest);
      }),
      getSupportDirectory: () async => supportDir,
    );

    final results = await Future.wait([
      api.getJuzIndex(mushafId: 1),
      api.getJuzIndex(mushafId: 1),
    ]);

    expect(results[0].length, 30);
    expect(results[1].length, 30);
    expect(byJuzRequestCount, 30);

    final cachedCall = await api.getJuzIndex(mushafId: 1);
    expect(cachedCall.length, 30);
    expect(byJuzRequestCount, 30);
  });

  test('getJuzIndex throws QuranComApiException on fetch failure', () async {
    final api = QuranComApi(
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/verses/by_juz/7')) {
          return http.Response('failed', HttpStatus.internalServerError);
        }
        if (path.contains('/verses/by_juz/')) {
          final juzNumber = int.parse(path.split('/').last);
          return http.Response(
            jsonEncode(
              <String, dynamic>{
                'verses': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'verse_key': '2:$juzNumber',
                    'chapter_id': 2,
                    'verse_number': juzNumber,
                    'page_number': juzNumber,
                    'juz_number': juzNumber,
                    'hizb_number': juzNumber,
                    'rub_el_hizb_number': juzNumber,
                  },
                ],
              },
            ),
            HttpStatus.ok,
          );
        }
        return http.Response('{}', HttpStatus.badRequest);
      }),
      getSupportDirectory: () async => supportDir,
      retries: 0,
    );

    expect(
      () => api.getJuzIndex(mushafId: 1),
      throwsA(isA<QuranComApiException>()),
    );
  });
}
