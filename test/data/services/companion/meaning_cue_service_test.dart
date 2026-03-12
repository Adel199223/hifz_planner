import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/companion/meaning_cue_service.dart';
import 'package:hifz_planner/data/services/qurancom_api.dart';

void main() {
  test('prefers the requested translation resource and cleans HTML', () async {
    final service = CompanionMeaningCueService(_FakeQuranComApi(
      verseData: const MushafVerseData(
        verseKey: '1:1',
        words: <MushafWord>[],
        translations: <MushafVerseTranslation>[
          MushafVerseTranslation(
            resourceId: 31,
            resourceName: 'French Source',
            text: '<p>Louange a Allah.</p>',
          ),
          MushafVerseTranslation(
            resourceId: 85,
            resourceName: 'English Source',
            text: '<p>All praise is for Allah, Lord of all worlds.</p>',
          ),
        ],
      ),
    ));

    final cue = await service.getCueForVerse(
      page: 1,
      mushafId: 19,
      verseKey: '1:1',
      translationResourceId: 85,
    );

    expect(cue, isNotNull);
    expect(cue!.text, 'All praise is for Allah, Lord of all worlds.');
    expect(cue.sourceLabel, 'English Source');
  });

  test('falls back to the first non-empty translation when preferred is absent',
      () {
    final service = CompanionMeaningCueService(QuranComApi());
    final cue = service.cueFromVerseData(
      const MushafVerseData(
        verseKey: '1:2',
        words: <MushafWord>[],
        translations: <MushafVerseTranslation>[
          MushafVerseTranslation(
            resourceId: 43,
            resourceName: 'Portuguese Source',
            text: 'Louvado seja Allah, Senhor do Universo.',
          ),
          MushafVerseTranslation(
            resourceId: 85,
            resourceName: 'English Source',
            text: '',
          ),
        ],
      ),
      translationResourceId: 31,
    );

    expect(cue, isNotNull);
    expect(cue!.text, 'Louvado seja Allah, Senhor do Universo.');
    expect(cue.sourceLabel, 'Portuguese Source');
  });

  test('returns null when no usable translation text exists', () {
    final service = CompanionMeaningCueService(QuranComApi());
    final cue = service.cueFromVerseData(
      const MushafVerseData(
        verseKey: '1:3',
        words: <MushafWord>[],
        translations: <MushafVerseTranslation>[
          MushafVerseTranslation(
            resourceId: 85,
            resourceName: 'English Source',
            text: '   ',
          ),
        ],
      ),
      translationResourceId: 85,
    );

    expect(cue, isNull);
  });
}

class _FakeQuranComApi extends QuranComApi {
  _FakeQuranComApi({required this.verseData}) : super();

  final MushafVerseData verseData;

  @override
  Future<MushafVerseData> getVerseDataByPage({
    required int page,
    required int mushafId,
    required String verseKey,
    int? translationResourceId,
  }) async {
    return verseData;
  }
}
