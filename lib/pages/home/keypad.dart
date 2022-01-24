import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:value_notifier/value_notifier.dart';

class TimeKeypadResult {
  final int _value;
  const TimeKeypadResult._(this._value);

  static const int kMaxValue = 999999;

  factory TimeKeypadResult.from(
    int hours,
    int minutes,
    int seconds,
  ) =>
      TimeKeypadResult._(
        (hours * 10000) + (minutes * 100) + (seconds),
      );

  bool get isEmpty => _value == 0;
  static const TimeKeypadResult zero = TimeKeypadResult._(0);
  TimeKeypadResult clear() => zero;
  TimeKeypadResult append(int digit) {
    assert(digit >= 0 && digit < 10);
    final newValue = (_value * 10) + digit;
    if (newValue > kMaxValue) {
      return this;
    }
    return TimeKeypadResult._(newValue);
  }

  TimeKeypadResult appendZeroZero() => append(0).append(0);
  TimeKeypadResult delete() => TimeKeypadResult._(_value ~/ 10);
  int get hours => _value ~/ 10000;
  int get minutes => (_value ~/ 100) - (hours * 100);
  int get seconds => _value - (minutes * 100) - (hours * 10000);

  Duration toDuration() => Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      );
}

class TimeKeypadController extends IDisposableBase {
  TimeKeypadController.zero() : _result = ValueNotifier(TimeKeypadResult.zero);
  TimeKeypadController.from(
    int hours,
    int minutes,
    int seconds,
  ) : _result = ValueNotifier(TimeKeypadResult.from(hours, minutes, seconds));
  final ValueNotifier<TimeKeypadResult> _result;

  ValueListenable<TimeKeypadResult> get result => _result.view();
  ValueListenable<bool> get isResultEmpty =>
      _result.view().map((r) => r.isEmpty);

  void onClear() => _result.value = _result.value.clear();
  void onDelete() => _result.value = _result.value.delete();
  void onDigit(int digit) => _result.value = _result.value.append(digit);
  void onZeroZero() => _result.value = _result.value.appendZeroZero();

  void dispose() {
    IDisposable.disposeObj(_result);
    super.dispose();
  }
}

class _TimeKeypad extends StatelessWidget {
  const _TimeKeypad({
    Key? key,
    required this.onDigit,
    required this.onZeroZero,
    required this.onDelete,
    required this.onClear,
  }) : super(key: key);
  final ValueChanged<int> onDigit;
  final VoidCallback onZeroZero;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  static const _kHorizontalSpacing = 36.0;
  static const _kVerticalSpacing = 4.0;
  static const _h = SizedBox(width: _kHorizontalSpacing);
  static const _v = SizedBox(height: _kVerticalSpacing);

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
              textStyle: MaterialStateProperty.all(
                context.textTheme.headlineLarge,
              ),
              foregroundColor: MaterialStateProperty.all(
                fabColorScheme == MD3FABColorScheme.surface
                    ? context.colorScheme.onSurface
                    : null,
              ),
            ),
            onLongPress: onLongPress,
            fabColorScheme: fabColorScheme,
            onPressed: onPressed,
            isLowered: true,
            child: child,
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
        fabColorScheme: MD3FABColorScheme.primary,
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

class TimeKeypad extends StatelessWidget {
  const TimeKeypad({Key? key, required this.controller}) : super(key: key);
  final TimeKeypadController controller;

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

  static const _h = SizedBox(width: 16);

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
  Widget _buildKeypad(BuildContext context) => _TimeKeypad(
        onDigit: controller.onDigit,
        onZeroZero: controller.onZeroZero,
        onDelete: controller.onDelete,
        onClear: controller.onClear,
      );
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Spacer(),
          controller.result.buildView(
              builder: (context, result, _) => _buildVisor(context, result)),
          Spacer(),
          Flexible(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                bottom: 16.0,
              ),
              child: _buildKeypad(context),
            ),
          ),
        ],
      );
}
