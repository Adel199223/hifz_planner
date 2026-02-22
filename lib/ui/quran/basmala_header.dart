import 'package:flutter/material.dart';

class BasmalaHeader extends StatelessWidget {
  const BasmalaHeader({
    super.key = const ValueKey<String>('basmala_header'),
    this.preferredFontFamily,
  });

  static const String basmalaText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

  final String? preferredFontFamily;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: preferredFontFamily ?? 'UthmanicHafs',
              fontSize: 34,
              height: 1.6,
            ) ??
        TextStyle(
          fontFamily: preferredFontFamily ?? 'UthmanicHafs',
          fontSize: 34,
          height: 1.6,
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Text(
          basmalaText,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}
