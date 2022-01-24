import 'package:flutter/foundation.dart';
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
