import 'package:flutter/material.dart';

import '../../data/services/quran_wording.dart';
import '../../data/services/qurancom_api.dart';

typedef QuranWordKeyBuilder = Key Function(int wordIndex, MushafWord word);
typedef QuranWordIdentityBuilder = String Function(
  int wordIndex,
  MushafWord word,
);
typedef QuranWordHoverCallback = void Function(
  String? wordIdentity,
  MushafWord? word,
);

class QuranWordWrap extends StatefulWidget {
  const QuranWordWrap({
    super.key,
    required this.words,
    required this.qcfFamilyName,
    required this.translationUnavailableText,
    this.showWordHover = true,
    this.showTooltips = true,
    this.suppressEndMarkers = false,
    this.preserveQcfTextColorOnHover = false,
    this.baseStyle,
    this.wordSpacing = 4,
    this.wordRunSpacing = 8,
    this.wordTextKeyBuilder,
    this.wordTooltipKeyBuilder,
    this.wordIdentityBuilder,
    this.onHoverWordChanged,
  });

  final List<MushafWord> words;
  final String qcfFamilyName;
  final String translationUnavailableText;
  final bool showWordHover;
  final bool showTooltips;
  final bool suppressEndMarkers;
  final bool preserveQcfTextColorOnHover;
  final TextStyle? baseStyle;
  final double wordSpacing;
  final double wordRunSpacing;
  final QuranWordKeyBuilder? wordTextKeyBuilder;
  final QuranWordKeyBuilder? wordTooltipKeyBuilder;
  final QuranWordIdentityBuilder? wordIdentityBuilder;
  final QuranWordHoverCallback? onHoverWordChanged;

  @override
  State<QuranWordWrap> createState() => _QuranWordWrapState();
}

class _QuranWordWrapState extends State<QuranWordWrap> {
  String? _hoveredWordIdentity;

  @override
  Widget build(BuildContext context) {
    final baseStyle = (widget.baseStyle ??
            Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 34,
                  height: 1.65,
                )) ??
        const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 34,
          height: 1.65,
        );
    final qcfStyle = baseStyle.copyWith(fontFamily: widget.qcfFamilyName);
    final fallbackStyle = baseStyle.copyWith(fontFamily: 'UthmanicHafs');

    return Wrap(
      textDirection: TextDirection.rtl,
      spacing: widget.wordSpacing,
      runSpacing: widget.wordRunSpacing,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var wordIndex = 0; wordIndex < widget.words.length; wordIndex++)
          _buildWord(
            context: context,
            word: widget.words[wordIndex],
            wordIndex: wordIndex,
            qcfStyle: qcfStyle,
            fallbackStyle: fallbackStyle,
          ),
      ],
    );
  }

  Widget _buildWord({
    required BuildContext context,
    required MushafWord word,
    required int wordIndex,
    required TextStyle qcfStyle,
    required TextStyle fallbackStyle,
  }) {
    if (widget.suppressEndMarkers && isEndMarkerWord(word)) {
      return const SizedBox.shrink();
    }

    final displayText = wordDisplayText(word);
    if (displayText.isEmpty) {
      return const SizedBox.shrink();
    }

    final wordIdentity = widget.wordIdentityBuilder?.call(wordIndex, word) ??
        'word:${word.position ?? wordIndex}';
    final isHovered = _hoveredWordIdentity == wordIdentity;
    final colorScheme = Theme.of(context).colorScheme;
    final isQcfWord = (word.codeV2 ?? '').trim().isNotEmpty;
    final baseStyle = isQcfWord ? qcfStyle : fallbackStyle;
    final shouldPreserveTextColor =
        widget.preserveQcfTextColorOnHover && isQcfWord;
    final resolvedStyle =
        isHovered && widget.showWordHover && !shouldPreserveTextColor
            ? baseStyle.copyWith(color: colorScheme.secondary)
            : baseStyle;
    final highlightColor = isHovered && widget.showWordHover
        ? colorScheme.primary.withValues(alpha: 0.22)
        : null;

    Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
      decoration: highlightColor == null
          ? null
          : BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(6),
            ),
      child: Text(
        displayText,
        key: widget.wordTextKeyBuilder?.call(wordIndex, word),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        softWrap: false,
        textScaler: const TextScaler.linear(1.0),
        style: resolvedStyle,
      ),
    );

    if (widget.showTooltips && !isEndMarkerWord(word)) {
      child = Tooltip(
        key: widget.wordTooltipKeyBuilder?.call(wordIndex, word),
        message: wordTooltipMessage(
          word,
          fallback: widget.translationUnavailableText,
        ),
        waitDuration: Duration.zero,
        child: child,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (widget.showWordHover) {
          setState(() {
            _hoveredWordIdentity = wordIdentity;
          });
        }
        widget.onHoverWordChanged?.call(wordIdentity, word);
      },
      onExit: (_) {
        if (widget.showWordHover && _hoveredWordIdentity == wordIdentity) {
          setState(() {
            _hoveredWordIdentity = null;
          });
        }
        widget.onHoverWordChanged?.call(null, null);
      },
      child: child,
    );
  }
}
