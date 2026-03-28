import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/services/similar_verse_candidate_service.dart';
import '../l10n/app_strings.dart';

final similarVerseRepairProvider =
    FutureProvider.autoDispose.family<SimilarVerseRepairData?, int>((
  ref,
  unitId,
) {
  return ref.read(similarVerseCandidateServiceProvider).buildRescueData(unitId);
});

class SimilarVerseRepairScreen extends ConsumerWidget {
  const SimilarVerseRepairScreen({
    super.key,
    required this.unitId,
  });

  final int? unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(ref.watch(appPreferencesProvider).language);
    if (unitId == null || unitId! <= 0) {
      return KeyedSubtree(
        key: const ValueKey('similar_verse_repair_screen'),
        child: _buildPage(
          context: context,
          strings: strings,
          children: [
            _InvalidSimilarVerseRepairBody(strings: strings),
          ],
        ),
      );
    }
    final repairAsync = ref.watch(similarVerseRepairProvider(unitId!));

    return KeyedSubtree(
      key: const ValueKey('similar_verse_repair_screen'),
      child: repairAsync.when(
        loading: () => _buildPage(
          context: context,
          strings: strings,
          children: const [
            SizedBox(height: 24),
            Center(
              child: CircularProgressIndicator(
                key: ValueKey('similar_verse_repair_loading'),
              ),
            ),
          ),
        ),
        error: (_, __) => _buildPage(
          context: context,
          strings: strings,
          children: [
            const SizedBox(height: 8),
            Text(strings.failedToLoadSimilarVerseRescue),
          ],
        ),
        data: (data) {
          if (data == null) {
            return _buildPage(
              context: context,
              strings: strings,
              children: [
                _InvalidSimilarVerseRepairBody(strings: strings),
              ],
            );
          }
          return _buildPage(
            context: context,
            strings: strings,
            children: [
              Text(
                strings.similarVerseRescueBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildUnitCard(
                context: context,
                strings: strings,
                keyName: 'similar_verse_target_card',
                title: strings.similarVerseCurrentUnitTitle,
                unit: data.targetUnit,
                excerpt: data.targetExcerpt,
              ),
              const SizedBox(height: 16),
              if (data.hasConfidentCandidate) ...[
                Text(
                  strings.similarVerseCandidatesTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final candidate in data.candidates) ...[
                  _buildUnitCard(
                    context: context,
                    strings: strings,
                    keyName: 'similar_verse_candidate_${candidate.unit.id}',
                    title: _formatUnitHeader(candidate.unit, strings),
                    unit: candidate.unit,
                    excerpt: candidate.excerpt,
                    differenceCue: candidate.differenceCue == null
                        ? null
                        : _differenceCueText(
                            strings,
                            candidate.differenceCue!,
                          ),
                    showTitleAsHeader: false,
                    showNearbyPage: candidate.isNearbyPage,
                  ),
                  const SizedBox(height: 12),
                ],
              ] else
                Card(
                  key: const ValueKey('similar_verse_repair_no_candidate'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.similarVerseNoCandidateTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(strings.similarVerseNoCandidateBody),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required AppStrings strings,
    required List<Widget> children,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.similarVerseRescueTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard({
    required BuildContext context,
    required AppStrings strings,
    required String keyName,
    required String title,
    required MemUnitData unit,
    required String excerpt,
    String? differenceCue,
    bool showTitleAsHeader = true,
    bool showNearbyPage = false,
  }) {
    return Card(
      key: ValueKey(keyName),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (showTitleAsHeader) ...[
              const SizedBox(height: 8),
              Text(
                _formatUnitHeader(unit, strings),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
            const SizedBox(height: 4),
            Text(_formatRange(unit, strings)),
            if (showNearbyPage) ...[
              const SizedBox(height: 4),
              Text(strings.similarVerseNearbyPage),
            ],
            const SizedBox(height: 10),
            Text(excerpt),
            if (differenceCue != null) ...[
              const SizedBox(height: 10),
              Text(
                differenceCue,
                key: ValueKey('similar_verse_cue_${unit.id}'),
              ),
            ],
            if (_canOpenInReader(unit)) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: ValueKey('similar_verse_open_reader_${unit.id}'),
                onPressed: () {
                  context.go(_buildReaderRoute(unit));
                },
                child: Text(strings.openInReader),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canOpenInReader(MemUnitData unit) {
    return unit.pageMadina != null &&
        unit.startSurah != null &&
        unit.startAyah != null &&
        unit.endSurah != null &&
        unit.endAyah != null;
  }

  String _buildReaderRoute(MemUnitData unit) {
    final uri = Uri(
      path: '/reader',
      queryParameters: {
        'mode': 'page',
        'page': unit.pageMadina!.toString(),
        'targetSurah': unit.startSurah!.toString(),
        'targetAyah': unit.startAyah!.toString(),
        'highlightStartSurah': unit.startSurah!.toString(),
        'highlightStartAyah': unit.startAyah!.toString(),
        'highlightEndSurah': unit.endSurah!.toString(),
        'highlightEndAyah': unit.endAyah!.toString(),
      },
    );
    return uri.toString();
  }

  String _formatUnitHeader(MemUnitData unit, AppStrings strings) {
    final parts = <String>[unit.kind];
    if (unit.pageMadina != null) {
      parts.add(strings.pageLabel(unit.pageMadina!));
    }
    return parts.join(' • ');
  }

  String _formatRange(MemUnitData unit, AppStrings strings) {
    final startSurah = unit.startSurah;
    final startAyah = unit.startAyah;
    final endSurah = unit.endSurah;
    final endAyah = unit.endAyah;
    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      return strings.rangeUnavailable;
    }
    return '$startSurah:$startAyah - $endSurah:$endAyah';
  }

  String _differenceCueText(
    AppStrings strings,
    SimilarVerseDifferenceCue cue,
  ) {
    return switch (cue.kind) {
      SimilarVerseDifferenceCueKind.openingSplit =>
        strings.similarVerseDifferenceCueOpening(
          cue.currentToken,
          cue.candidateToken,
        ),
      SimilarVerseDifferenceCueKind.endingLeadIn =>
        strings.similarVerseDifferenceCueEnding(
          cue.currentToken,
          cue.candidateToken,
        ),
    };
  }
}

class _InvalidSimilarVerseRepairBody extends StatelessWidget {
  const _InvalidSimilarVerseRepairBody({
    required this.strings,
  });

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Text(
          strings.similarVerseRescueInvalidBody,
          key: const ValueKey('similar_verse_repair_invalid'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
