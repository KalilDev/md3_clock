import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/alarm.dart';
import '../../model/weekday.dart';

class AlarmItemController extends ControllerBase<AlarmItemController> {
  final ValueNotifier<TimeOfDay> _time;
  final ValueNotifier<String> _marker;
  // TODO: null when default and on the view get it from somewhere.
  final ValueNotifier<Alarm> _alarm;
  final ValueNotifier<Weekdays> _weekdays;
  final ValueNotifier<bool> _active;
  final ValueNotifier<bool> _vibrate;
  final ValueNotifier<bool> _expanded;
  final ActionNotifier _didDelete = ActionNotifier();
  final ActionNotifier _didRequestScrollToTop = ActionNotifier();
  final DateTime itemCreationTime;

  ValueListenable<TimeOfDay> get time => _time.view();
  ValueListenable<String> get marker => _marker.view();
  ValueListenable<Alarm> get alarm => _alarm.view();
  ValueListenable<Weekdays> get weekdays => _weekdays.view();
  ValueListenable<bool> get active => _active.view();
  ValueListenable<bool> get vibrate => _vibrate.view();
  ValueListenable<bool> get expanded => _expanded.view();
  ValueListenable<void> get didDelete => _didDelete.view();
  ValueListenable<void> get didRequestScrollToTop =>
      _didRequestScrollToTop.view();

  AlarmItemController.from(
    TimeOfDay time,
    String marker,
    Alarm alarm,
    Weekdays weekdays,
    bool active,
    bool vibrate,
    bool expanded,
    this.itemCreationTime,
  )   : _time = ValueNotifier(time),
        _marker = ValueNotifier(marker),
        _alarm = ValueNotifier(alarm),
        _weekdays = ValueNotifier(weekdays),
        _active = ValueNotifier(active),
        _vibrate = ValueNotifier(vibrate),
        _expanded = ValueNotifier(expanded);

  AlarmItemController.create(
    TimeOfDay time,
    Alarm defaultAlarm,
  )   : assert(defaultAlarm.isDefault),
        _time = ValueNotifier(time),
        _marker = ValueNotifier(''),
        _alarm = ValueNotifier(defaultAlarm),
        _weekdays = ValueNotifier(Weekdays.empty()),
        _active = ValueNotifier(true),
        _vibrate = ValueNotifier(true),
        _expanded = ValueNotifier(true),
        itemCreationTime = DateTime.now();

  void delete() => _didDelete.notify();
  void toggleExpanded([bool requestScrollOnExpansion = true]) {
    _expanded.value = !_expanded.value;
    if (_expanded.value && requestScrollOnExpansion) {
      _didRequestScrollToTop.notify();
    }
  }

  void maybeExpand([bool requestScrollOnExpansion = true]) {
    if (_expanded.value) {
      return;
    }
    _expanded.value = true;
    if (requestScrollOnExpansion) {
      _didRequestScrollToTop.notify();
    }
  }

  void requestScrollToTop() => _didRequestScrollToTop.notify();
  void setTime(TimeOfDay time) => _time.value = time;
  void setActive(bool value) => _active.value = value;
  void toggleVibrate() => setVibrate(!_vibrate.value);
  void setVibrate(bool value) => _vibrate.value = value;
  void setMarker(String value) => _marker.value = value;
  void toggleWeekday(Weekday day) =>
      _weekdays.value = _weekdays.value.toggle(day);

  @override
  void dispose() {
    IDisposable.disposeAll([
      _time,
      _marker,
      _alarm,
      _weekdays,
      _active,
      _vibrate,
      _expanded,
      _didDelete,
      _didRequestScrollToTop,
    ]);
    super.dispose();
  }
}
