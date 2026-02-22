import 'package:flutter_test/flutter_test.dart';

import '../../tooling/generate_tajweed_uthmani_tags_alquran_cloud.dart' as tool;

void main() {
  test('normalizeForCompare folds dagger alif form', () {
    expect(
      tool.normalizeForCompare('تَرْضَىٰهَا'),
      tool.normalizeForCompare('تَرْضَاهَا'),
    );
  });

  test('normalizeForCompare folds alif-wasl form', () {
    expect(
      tool.normalizeForCompare('ٱهْدِنَا'),
      tool.normalizeForCompare('اهْدِنَا'),
    );
  });

  test(
      'normalizeForCompare removes harakat, annotations, tatweel, format chars',
      () {
    expect(
      tool.normalizeForCompare('س\u200Cل\u200Dا\uFEFFم'),
      tool.normalizeForCompare('سلام'),
    );
    expect(
      tool.normalizeForCompare('ٱلْـحَمْدُ'),
      tool.normalizeForCompare('الحمد'),
    );
    expect(
      tool.normalizeForCompare('رَحْمَة\u06D6'),
      tool.normalizeForCompare('رحمة'),
    );
  });

  test('marker conversion maps [h:123[TEXT] to ham_wasl class', () {
    expect(
      tool.convertTajweedMarkersToHtml('[h:123[TEXT]'),
      '<tajweed class=ham_wasl>TEXT</tajweed>',
    );
  });
}
