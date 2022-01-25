import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:value_notifier/value_notifier.dart';

import 'controller.dart';

class _TimeKeypad extends StatelessWidget {
  const _TimeKeypad({
    Key? key,
    required this.onDigit,
    required this.onZeroZero,
    required this.onDelete,
    required this.onClear,
    required this.isPortrait,
  }) : super(key: key);
  final ValueChanged<int> onDigit;
  final VoidCallback onZeroZero;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final bool isPortrait;

  static const _kHorizontalSpacing = 36.0;
  static const _kVerticalSpacing = 4.0;
  Widget get _h => SizedBox(width: isPortrait ? _kHorizontalSpacing : 4.0);
  Widget get _v => SizedBox(height: isPortrait ? _kVerticalSpacing : 8.0);

  Widget _button(
    BuildContext context, {
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
    MD3FABColorScheme fabColorScheme = MD3FABColorScheme.surface,
    required Widget child,
  }) =>
      Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: MD3FloatingActionButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.resolveWith(
                (states) => states.contains(MaterialState.pressed)
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24))
                    : null,
              ),
              padding: MaterialStateProperty.all(
                const EdgeInsets.all(2.0),
              ),
              textStyle: MaterialStateProperty.all(
                context.textTheme.headlineLarge,
              ),
              foregroundColor: MaterialStateProperty.all(
                fabColorScheme == MD3FABColorScheme.surface
                    ? context.colorScheme.onSurface
                    : null,
              ),
              elevation: MaterialStateProperty.all(
                  fabColorScheme == MD3FABColorScheme.secondary ? 0.0 : null),
            ),
            onLongPress: onLongPress,
            fabColorScheme: fabColorScheme,
            onPressed: onPressed,
            isLowered: true,
            child: FittedBox(
              fit: BoxFit.contain,
              child: child,
            ),
          ),
        ),
      );
  Widget _d(BuildContext context, int digit) => _button(
        context,
        onPressed: () => onDigit(digit),
        child: Text(
          digit.toString(),
        ),
      );
  Widget _zz(BuildContext context) => _button(
        context,
        onPressed: onZeroZero,
        child: const Text('00'),
      );
  Widget _del(BuildContext context) => _button(
        context,
        onPressed: onDelete,
        onLongPress: onClear,
        fabColorScheme: MD3FABColorScheme.secondary,
        child: Icon(Icons.backspace_outlined),
      );
  Widget _row(List<Widget> children) => Flexible(
        child: Row(
          children: children,
        ),
      );
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(
            [_d(context, 1), _h, _d(context, 2), _h, _d(context, 3)],
          ),
          _v,
          _row(
            [_d(context, 4), _h, _d(context, 5), _h, _d(context, 6)],
          ),
          _v,
          _row(
            [_d(context, 7), _h, _d(context, 8), _h, _d(context, 9)],
          ),
          _v,
          _row(
            [_zz(context), _h, _d(context, 0), _h, _del(context)],
          ),
        ],
      );
}

class TimeKeypadVisor extends StatelessWidget {
  const TimeKeypadVisor({Key? key, required this.result}) : super(key: key);
  final ValueListenable<TimeKeypadResult> result;

  static const _h = SizedBox(width: 16);
  Widget _displayText(BuildContext context, String text) => Text(
        text,
        style: context.textTheme.displayLarge,
      );
  Widget _auxText(BuildContext context, String text) => Text(
        text,
        style: context.textTheme.headlineMedium,
      );

  Widget _textFor(BuildContext context, int number, String abbr) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          _displayText(context, _valueToString(number)),
          _auxText(context, abbr),
        ],
      );
  Widget _buildVisor(BuildContext context, TimeKeypadResult result) =>
      AnimatedDefaultTextStyle(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _textFor(context, result.hours, 'h'),
            _h,
            _textFor(context, result.minutes, 'm'),
            _h,
            _textFor(context, result.seconds, 's'),
          ],
        ),
        style: TextStyle(
          color: result.isEmpty
              ? context.colorScheme.onSurfaceVariant
              : context.colorScheme.primary,
        ),
        duration: Duration(milliseconds: 300),
      );
  static String _valueToString(int value) => value.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) => result.buildView(
        builder: (context, result, _) => _buildVisor(context, result),
      );
}

class TimeKeypad extends StatelessWidget {
  const TimeKeypad({
    Key? key,
    required this.controller,
    this.isPortrait = false,
  }) : super(key: key);
  final TimeKeypadController controller;
  final bool isPortrait;

  @override
  Widget build(BuildContext context) => _TimeKeypad(
        onDigit: controller.onDigit,
        onZeroZero: controller.onZeroZero,
        onDelete: controller.onDelete,
        onClear: controller.onClear,
        isPortrait: isPortrait,
      );
}

class TimeKeypadAndVisor extends StatelessWidget {
  const TimeKeypadAndVisor({
    Key? key,
    required this.controller,
    this.isLandscape = false,
  }) : super(key: key);
  final TimeKeypadController controller;
  final bool isLandscape;

  Widget _buildPortrait(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Spacer(),
          TimeKeypadVisor(result: controller.result),
          Spacer(),
          Flexible(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                bottom: 16.0,
              ),
              child: TimeKeypad(
                controller: controller,
              ),
            ),
          ),
        ],
      );

  Widget _buildLandscape(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.contain,
              child: TimeKeypadVisor(result: controller.result),
            ),
          ),
          Expanded(
            flex: 2,
            child: TimeKeypad(
              controller: controller,
              isPortrait: false,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape
          ? _buildLandscape(context)
          : _buildPortrait(context);
}
