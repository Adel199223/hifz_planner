import 'package:flutter/material.dart';

import '../tajweed/tajweed_colors.dart';
import '../tajweed/tajweed_markup.dart';

class ArabicAyahText extends StatelessWidget {
  const ArabicAyahText({
    super.key,
    required this.text,
    this.tajweedHtml,
    this.tajweedEnabled = true,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final String? tajweedHtml;
  final bool tajweedEnabled;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final baseStyle = (style ??
            Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'UthmanicHafs',
                  height: 1.8,
                  fontSize: 26,
                )) ??
        const TextStyle(
          fontFamily: 'UthmanicHafs',
          height: 1.8,
          fontSize: 26,
        );

    if (!tajweedEnabled || tajweedHtml == null) {
      return Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
        style: baseStyle,
      );
    }

    final fallbackColor = baseStyle.color ?? Theme.of(context).colorScheme.onSurface;
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      text: TextSpan(
        style: baseStyle,
        children: buildTajweedSpans(
          tajweedHtml: tajweedHtml!,
          baseStyle: baseStyle,
          classColors: tajweedClassColors,
          fallbackColor: fallbackColor,
        ),
      ),
    );
  }
}
