import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/tajweed_tags_service.dart';

void main() {
  test('loads valid tajweed tags JSON and resolves verse lookup', () async {
    final service = TajweedTagsService(
      loadAssetText: (_) async =>
          '{"1:1":"<tajweed class=ham_wasl>ٱ</tajweed>"}',
    );

    await service.ensureLoaded();

    expect(service.hasAnyTags, isTrue);
    expect(
      service.getTajweedHtmlFor(1, 1),
      '<tajweed class=ham_wasl>ٱ</tajweed>',
    );
  });

  test('rejects invalid verse key format', () async {
    final service = TajweedTagsService(
      loadAssetText: (_) async => '{"invalid":"x"}',
    );

    await expectLater(
      service.ensureLoaded(),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects non-string values', () async {
    final service = TajweedTagsService(
      loadAssetText: (_) async => '{"1:1":1}',
    );

    await expectLater(
      service.ensureLoaded(),
      throwsA(isA<FormatException>()),
    );
  });

  test('empty map hasAnyTags false', () async {
    final service = TajweedTagsService(
      loadAssetText: (_) async => '{}',
    );

    await service.ensureLoaded();

    expect(service.hasAnyTags, isFalse);
    expect(service.getTajweedHtmlFor(1, 1), isNull);
  });
}
