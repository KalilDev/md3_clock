import 'package:flutter/material.dart';
import 'package:md3_clock/widgets/prototype_text/raw.dart';

class PrototypeText extends StatelessWidget {
  const PrototypeText({
    Key? key,
    required this.reference,
    required this.target,
    this.style,
    this.initialCharacterSet,
    this.characterAlignment = 0.0,
    this.textDirection,
    this.textScaleFactor,
    this.locale,
    this.strutStyle,
    this.textHeightBehavior,
  }) : super(key: key);
  final String reference;
  final String target;
  final TextStyle? style;
  final Set<String>? initialCharacterSet;
  final double characterAlignment;
  final TextDirection? textDirection;
  final double? textScaleFactor;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextHeightBehavior? textHeightBehavior;

  static const debugDontUsePrototypeText = false;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = style;
    if (style == null || style!.inherit)
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    if (MediaQuery.boldTextOverride(context))
      effectiveTextStyle = effectiveTextStyle!
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    if (debugDontUsePrototypeText) {
      return Text(
        target,
        style: effectiveTextStyle?.copyWith(inherit: false),
        textDirection:
            textDirection, // RichText uses Directionality.of to obtain a default if this is null.
        textScaleFactor: textScaleFactor ??
            MediaQuery.maybeOf(context)?.textScaleFactor ??
            1.0,
        locale:
            locale, // RichText uses Localizations.localeOf to obtain a default if this is null
        strutStyle: strutStyle,
        textHeightBehavior: textHeightBehavior ??
            defaultTextStyle.textHeightBehavior ??
            DefaultTextHeightBehavior.of(context),
      );
    }
    return RawPrototypeText(
      reference: reference,
      target: target,
      textStyle: effectiveTextStyle,
      initialCharacterSet: initialCharacterSet,
      characterAlignment: characterAlignment,
      textDirection:
          textDirection, // RichText uses Directionality.of to obtain a default if this is null.
      textScaleFactor: textScaleFactor ??
          MediaQuery.maybeOf(context)?.textScaleFactor ??
          1.0,
      locale:
          locale, // RichText uses Localizations.localeOf to obtain a default if this is null
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior ??
          defaultTextStyle.textHeightBehavior ??
          DefaultTextHeightBehavior.of(context),
    );
  }
}
