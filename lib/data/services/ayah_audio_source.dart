const List<int> _ayahCountsPerSurah = <int>[
  7,
  286,
  200,
  176,
  120,
  165,
  206,
  75,
  129,
  109,
  123,
  111,
  43,
  52,
  99,
  128,
  111,
  110,
  98,
  135,
  112,
  78,
  118,
  64,
  77,
  227,
  93,
  88,
  69,
  60,
  34,
  30,
  73,
  54,
  45,
  83,
  182,
  88,
  75,
  85,
  54,
  53,
  89,
  59,
  37,
  35,
  38,
  29,
  18,
  45,
  60,
  49,
  62,
  55,
  78,
  96,
  29,
  22,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  28,
  28,
  20,
  56,
  40,
  31,
  50,
  40,
  46,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  30,
  20,
  15,
  21,
  11,
  8,
  8,
  19,
  5,
  8,
  8,
  11,
  11,
  8,
  3,
  9,
  5,
  4,
  7,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];

int ayahCountForSurah(int surah) {
  if (surah < 1 || surah > _ayahCountsPerSurah.length) {
    throw RangeError.range(surah, 1, _ayahCountsPerSurah.length, 'surah');
  }
  return _ayahCountsPerSurah[surah - 1];
}

int globalAyahIndex(int surah, int ayah) {
  final ayahCount = ayahCountForSurah(surah);
  if (ayah < 1 || ayah > ayahCount) {
    throw RangeError.range(ayah, 1, ayahCount, 'ayah');
  }

  var index = ayah;
  for (var i = 0; i < surah - 1; i++) {
    index += _ayahCountsPerSurah[i];
  }
  return index;
}

abstract class AyahAudioSource {
  String get edition;
  int get bitrate;
  Uri urlForAyah(int surah, int ayah);
}

class AlQuranCloudAyahAudioSource implements AyahAudioSource {
  AlQuranCloudAyahAudioSource({
    this.edition = 'ar.alafasy',
    this.bitrate = 128,
    this.globalAyahIndexFn = globalAyahIndex,
  });

  @override
  final String edition;
  @override
  final int bitrate;
  final int Function(int surah, int ayah) globalAyahIndexFn;

  @override
  Uri urlForAyah(int surah, int ayah) {
    final number = globalAyahIndexFn(surah, ayah);
    return Uri.https(
      'cdn.islamic.network',
      '/quran/audio/$bitrate/$edition/$number.mp3',
    );
  }
}
