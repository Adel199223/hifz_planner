import 'dart:convert';

import 'package:http/http.dart' as http;

class AyahReciterOption {
  const AyahReciterOption({
    required this.edition,
    required this.englishName,
    required this.nativeName,
    required this.languageCode,
    required this.isFallback,
  });

  final String edition;
  final String englishName;
  final String nativeName;
  final String languageCode;
  final bool isFallback;
}

abstract class AyahReciterCatalogService {
  Future<List<AyahReciterOption>> loadReciters();
}

class AlQuranCloudAyahReciterCatalogService
    implements AyahReciterCatalogService {
  AlQuranCloudAyahReciterCatalogService({
    required http.Client client,
  }) : _client = client;

  static final Uri _editionsUri = Uri.https(
    'api.alquran.cloud',
    '/v1/edition',
    <String, String>{
      'format': 'audio',
      'type': 'versebyverse',
      'language': 'ar',
    },
  );

  final http.Client _client;

  @override
  Future<List<AyahReciterOption>> loadReciters() async {
    try {
      final response = await _client.get(_editionsUri);
      if (response.statusCode != 200) {
        return _fallbackReciters;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _fallbackReciters;
      }
      final data = decoded['data'];
      if (data is! List) {
        return _fallbackReciters;
      }

      final reciters = <AyahReciterOption>[];
      for (final raw in data) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }
        final identifier = (raw['identifier'] ?? '').toString().trim();
        final englishName = (raw['englishName'] ?? '').toString().trim();
        final nativeName = (raw['name'] ?? '').toString().trim();
        final languageCode = (raw['language'] ?? '').toString().trim();
        final format = (raw['format'] ?? '').toString().trim().toLowerCase();
        final type = (raw['type'] ?? '').toString().trim().toLowerCase();

        if (identifier.isEmpty || englishName.isEmpty) {
          continue;
        }
        if (format != 'audio' || type != 'versebyverse') {
          continue;
        }

        reciters.add(
          AyahReciterOption(
            edition: identifier,
            englishName: englishName,
            nativeName: nativeName.isEmpty ? englishName : nativeName,
            languageCode: languageCode.isEmpty ? 'ar' : languageCode,
            isFallback: false,
          ),
        );
      }

      if (reciters.isEmpty) {
        return _fallbackReciters;
      }

      reciters.sort((a, b) => a.englishName.compareTo(b.englishName));
      return reciters;
    } catch (_) {
      return _fallbackReciters;
    }
  }
}

const List<AyahReciterOption> _fallbackReciters = <AyahReciterOption>[
  AyahReciterOption(
    edition: 'ar.abdullahbasfar',
    englishName: 'Abdullah Basfar',
    nativeName: 'عبد الله بصفر',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.abdurrahmaansudais',
    englishName: 'Abdurrahmaan As-Sudais',
    nativeName: 'عبدالرحمن السديس',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.abdulsamad',
    englishName: 'Abdul Samad',
    nativeName: 'عبدالباسط عبدالصمد',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.shaatree',
    englishName: 'Abu Bakr Ash-Shaatree',
    nativeName: 'أبو بكر الشاطري',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.ahmedajamy',
    englishName: 'Ahmed ibn Ali al-Ajamy',
    nativeName: 'أحمد بن علي العجمي',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.alafasy',
    englishName: 'Alafasy',
    nativeName: 'مشاري العفاسي',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.hanirifai',
    englishName: 'Hani Rifai',
    nativeName: 'هاني الرفاعي',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.husary',
    englishName: 'Husary',
    nativeName: 'محمود خليل الحصري',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.husarymujawwad',
    englishName: 'Husary (Mujawwad)',
    nativeName: 'محمود خليل الحصري (المجود)',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.hudhaify',
    englishName: 'Hudhaify',
    nativeName: 'علي بن عبدالرحمن الحذيفي',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.mahermuaiqly',
    englishName: 'Maher Al Muaiqly',
    nativeName: 'ماهر المعيقلي',
    languageCode: 'ar',
    isFallback: true,
  ),
  AyahReciterOption(
    edition: 'ar.saoodshuraym',
    englishName: 'Saood bin Ibraaheem Ash-Shuraym',
    nativeName: 'سعود الشريم',
    languageCode: 'ar',
    isFallback: true,
  ),
];
