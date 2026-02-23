import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/ayah_reciter_catalog_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads reciters from API payload and sorts by english name', () async {
    late Uri requestUri;
    final client = MockClient((request) async {
      requestUri = request.url;
      return http.Response(
        jsonEncode({
          'code': 200,
          'status': 'OK',
          'data': [
            {
              'identifier': 'ar.zeta',
              'englishName': 'Zeta Reader',
              'name': 'Zeta',
              'language': 'ar',
              'format': 'audio',
              'type': 'versebyverse',
            },
            {
              'identifier': 'ar.alpha',
              'englishName': 'Alpha Reader',
              'name': 'Alpha',
              'language': 'ar',
              'format': 'audio',
              'type': 'versebyverse',
            },
            {
              'identifier': 'ar.skip',
              'englishName': 'Skip Reader',
              'name': 'Skip',
              'language': 'ar',
              'format': 'audio',
              'type': 'translation',
            },
          ],
        }),
        200,
      );
    });
    final service = AlQuranCloudAyahReciterCatalogService(client: client);

    final reciters = await service.loadReciters();

    expect(requestUri.host, 'api.alquran.cloud');
    expect(requestUri.path, '/v1/edition');
    expect(reciters.length, 2);
    expect(reciters.first.edition, 'ar.alpha');
    expect(reciters.last.edition, 'ar.zeta');
    expect(reciters.every((entry) => entry.isFallback == false), isTrue);
  });

  test('falls back when API response is empty', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'code': 200,
          'status': 'OK',
          'data': <Object>[],
        }),
        200,
      );
    });
    final service = AlQuranCloudAyahReciterCatalogService(client: client);

    final reciters = await service.loadReciters();

    expect(reciters, isNotEmpty);
    expect(reciters.any((entry) => entry.edition == 'ar.alafasy'), isTrue);
    expect(reciters.every((entry) => entry.isFallback), isTrue);
  });

  test('falls back on transport failure', () async {
    final client = MockClient((request) async {
      throw http.ClientException('network down');
    });
    final service = AlQuranCloudAyahReciterCatalogService(client: client);

    final reciters = await service.loadReciters();

    expect(reciters, isNotEmpty);
    expect(reciters.any((entry) => entry.edition == 'ar.alafasy'), isTrue);
  });
}
