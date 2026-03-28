import 'package:flutter/material.dart';

import '../data/services/adaptive_queue_policy.dart';
import '../l10n/app_strings.dart';

enum ReviewErrorTagSheetAction {
  cancel,
  skip,
  tagged,
}

class ReviewErrorTagSheetResult {
  const ReviewErrorTagSheetResult._(this.action, [this.taggedErrorType]);

  const ReviewErrorTagSheetResult.cancel()
      : this._(ReviewErrorTagSheetAction.cancel);

  const ReviewErrorTagSheetResult.skip()
      : this._(ReviewErrorTagSheetAction.skip);

  const ReviewErrorTagSheetResult.tagged(AdaptiveLastErrorType taggedErrorType)
      : this._(ReviewErrorTagSheetAction.tagged, taggedErrorType);

  final ReviewErrorTagSheetAction action;
  final AdaptiveLastErrorType? taggedErrorType;
}

Future<ReviewErrorTagSheetResult> showReviewErrorTagSheet({
  required BuildContext context,
  required AppStrings strings,
}) async {
  final result = await showModalBottomSheet<ReviewErrorTagSheetResult>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            key: const ValueKey('review_error_tag_sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.reviewErrorTagTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(strings.reviewErrorTagBody),
              const SizedBox(height: 12),
              ListTile(
                key: const ValueKey('review_error_tag_option_hesitation'),
                leading: const Icon(Icons.pause_circle_outline),
                title: Text(strings.reviewErrorTagHesitation),
                onTap: () => Navigator.of(context).pop(
                  const ReviewErrorTagSheetResult.tagged(
                    AdaptiveLastErrorType.hesitation,
                  ),
                ),
              ),
              ListTile(
                key:
                    const ValueKey('review_error_tag_option_similar_confusion'),
                leading: const Icon(Icons.compare_arrows_outlined),
                title: Text(strings.reviewErrorTagSimilarConfusion),
                onTap: () => Navigator.of(context).pop(
                  const ReviewErrorTagSheetResult.tagged(
                    AdaptiveLastErrorType.similarConfusion,
                  ),
                ),
              ),
              ListTile(
                key: const ValueKey('review_error_tag_option_weak_lock_in'),
                leading: const Icon(Icons.lock_clock_outlined),
                title: Text(strings.reviewErrorTagWeakLockIn),
                onTap: () => Navigator.of(context).pop(
                  const ReviewErrorTagSheetResult.tagged(
                    AdaptiveLastErrorType.weakLockIn,
                  ),
                ),
              ),
              ListTile(
                key: const ValueKey('review_error_tag_option_wrong_recall'),
                leading: const Icon(Icons.refresh_outlined),
                title: Text(strings.reviewErrorTagWrongRecall),
                onTap: () => Navigator.of(context).pop(
                  const ReviewErrorTagSheetResult.tagged(
                    AdaptiveLastErrorType.wrongRecall,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('review_error_tag_skip'),
                  onPressed: () => Navigator.of(context).pop(
                    const ReviewErrorTagSheetResult.skip(),
                  ),
                  child: Text(strings.reviewErrorTagSkip),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? const ReviewErrorTagSheetResult.cancel();
}
