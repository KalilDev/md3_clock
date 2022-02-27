import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:md3_clock/model/alarm.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/weekday.dart';

enum ClockStyle {
  digital,
  analog,
}

enum VolumeButtonsBehavior {
  volume,
  snooze,
  stop,
}

class Timezone {
  final String tz;

  Timezone(this.tz);
}

class ClockPreferencesController extends SubcontrollerBase<
    PreferencesController, ClockPreferencesController> {
  final ValueNotifier<ClockStyle> _style;
  final ValueNotifier<bool> _showSeconds;
  final ValueNotifier<bool> _autoHomeTimezoneClock;
  final ValueNotifier<Timezone?> _homeTimezone;

  final ActionNotifier _didRequestShowChangeDateTime = ActionNotifier();

  ClockPreferencesController({
    required ClockStyle style,
    required bool showSeconds,
    required bool autoHomeTimezoneClock,
    required Timezone? homeTimezone,
  })  : _style = ValueNotifier(style),
        _showSeconds = ValueNotifier(showSeconds),
        _autoHomeTimezoneClock = ValueNotifier(autoHomeTimezoneClock),
        _homeTimezone = ValueNotifier(homeTimezone);

  factory ClockPreferencesController.defaults() => ClockPreferencesController(
        style: ClockStyle.digital,
        showSeconds: false,
        autoHomeTimezoneClock: true,
        homeTimezone: null,
      );

  ValueListenable<ClockStyle> get style => _style.view();
  ValueListenable<bool> get showSeconds => _showSeconds.view();
  ValueListenable<bool> get autoHomeTimezoneClock =>
      _autoHomeTimezoneClock.view();
  ValueListenable<Timezone?> get homeTimezone => _homeTimezone.view();
  ValueListenable<void> get didRequestShowChangeDateTime =>
      _didRequestShowChangeDateTime.view();

  late final setStyle = _style.setter;
  late final setShowSeconds = _showSeconds.setter;
  late final setAutoHomeTimezoneClock = _autoHomeTimezoneClock.setter;
  late final requestShowChangeDateTime = _didRequestShowChangeDateTime.notify;
  late final setHomeTimezone = _homeTimezone.setter;
}

class AlarmsPreferencesController extends SubcontrollerBase<
    PreferencesController, AlarmsPreferencesController> {
  final ValueNotifier<Duration?> _silenceAfter;
  final ValueNotifier<Duration> _snoozeDuration;
  // 0 to 6
  final ValueNotifier<int> _volume;
  final ValueNotifier<Duration?> _volumeIncreaseDuration;
  final ValueNotifier<VolumeButtonsBehavior> _volumeButtonsBehavior;
  final ValueNotifier<Weekday> _startOfTheWeek;

  AlarmsPreferencesController({
    required Duration? silenceAfter,
    required Duration snoozeDuration,
    required int volume,
    required Duration? volumeIncreaseDuration,
    required VolumeButtonsBehavior volumeButtonsBehavior,
    required Weekday startOfTheWeek,
  })  : _silenceAfter = ValueNotifier(silenceAfter),
        _snoozeDuration = ValueNotifier(snoozeDuration),
        _volume = ValueNotifier(volume),
        _volumeIncreaseDuration = ValueNotifier(volumeIncreaseDuration),
        _volumeButtonsBehavior = ValueNotifier(volumeButtonsBehavior),
        _startOfTheWeek = ValueNotifier(startOfTheWeek);

  factory AlarmsPreferencesController.defaults() => AlarmsPreferencesController(
        silenceAfter: const Duration(minutes: 10),
        snoozeDuration: const Duration(minutes: 5),
        volume: 6,
        volumeIncreaseDuration: null,
        volumeButtonsBehavior: VolumeButtonsBehavior.volume,
        startOfTheWeek: Weekday.saturday,
      );

  ValueListenable<Duration?> get silenceAfter => _silenceAfter.view();
  ValueListenable<Duration> get snoozeDuration => _snoozeDuration.view();
  // 0 to 6
  ValueListenable<int> get volume => _volume.view();
  ValueListenable<Duration?> get volumeIncreaseDuration =>
      _volumeIncreaseDuration.view();
  ValueListenable<VolumeButtonsBehavior> get volumeButtonsBehavior =>
      _volumeButtonsBehavior.view();
  ValueListenable<Weekday> get startOfTheWeek => _startOfTheWeek.view();

  late final setSilenceAfter = _silenceAfter.setter;
  late final setSnoozeDuration = _snoozeDuration.setter;
  late final setVolume = _volume.setter;
  late final setVolumeIncreaseDuration = _volumeIncreaseDuration.setter;
  late final setStartOfTheWeek = _startOfTheWeek.setter;
  late final setVolumeButtonsBehavior = _volumeButtonsBehavior.setter;
}

class TimersPreferencesController extends SubcontrollerBase<
    PreferencesController, TimersPreferencesController> {
  final ValueNotifier<Sound?> _sound;
  final ValueNotifier<Duration?> _volumeIncreaseDuration;
  final ValueNotifier<bool> _vibrate;

  TimersPreferencesController({
    required Sound? sound,
    required Duration? volumeIncreaseDuration,
    required bool vibrate,
  })  : _sound = ValueNotifier(sound),
        _volumeIncreaseDuration = ValueNotifier(volumeIncreaseDuration),
        _vibrate = ValueNotifier(vibrate);

  factory TimersPreferencesController.defaults() => TimersPreferencesController(
        sound: null,
        volumeIncreaseDuration: null,
        vibrate: false,
      );

  ValueListenable<Sound?> get sound => _sound.view();
  ValueListenable<Duration?> get volumeIncreaseDuration =>
      _volumeIncreaseDuration.view();
  ValueListenable<bool> get vibrate => _vibrate.view();

  late final setVolumeIncreaseDuration = _volumeIncreaseDuration.setter;
  late final setVibrate = _vibrate.setter;
}

class ScreensaverPreferencesController extends SubcontrollerBase<
    PreferencesController, ScreensaverPreferencesController> {
  final ValueNotifier<ClockStyle> _style;
  final ValueNotifier<bool> _nightMode;

  ScreensaverPreferencesController({
    required ClockStyle style,
    required bool nightMode,
  })  : _style = ValueNotifier(style),
        _nightMode = ValueNotifier(nightMode);

  factory ScreensaverPreferencesController.defaults() =>
      ScreensaverPreferencesController(
        style: ClockStyle.digital,
        nightMode: true,
      );

  ValueListenable<ClockStyle> get style => _style.view();
  ValueListenable<bool> get nightMode => _nightMode.view();

  late final setStyle = _style.setter;
  late final setNightMode = _nightMode.setter;
}

class PreferencesController extends ControllerBase<PreferencesController> {
  late final ClockPreferencesController _clockPreferencesController;
  late final AlarmsPreferencesController _alarmsPreferencesController;
  late final TimersPreferencesController _timersPreferencesController;
  late final ScreensaverPreferencesController _screensaverPreferencesController;

  ControllerHandle<ClockPreferencesController> get clock =>
      _clockPreferencesController.handle;
  ControllerHandle<AlarmsPreferencesController> get alarms =>
      _alarmsPreferencesController.handle;
  ControllerHandle<TimersPreferencesController> get timers =>
      _timersPreferencesController.handle;
  ControllerHandle<ScreensaverPreferencesController> get screensaver =>
      _screensaverPreferencesController.handle;

  @override
  void init() {
    super.init();
    _clockPreferencesController = addSubcontroller(
        ControllerBase.create(() => ClockPreferencesController.defaults()));
    _alarmsPreferencesController = addSubcontroller(
        ControllerBase.create(() => AlarmsPreferencesController.defaults()));
    _timersPreferencesController = addSubcontroller(
        ControllerBase.create(() => TimersPreferencesController.defaults()));
    _screensaverPreferencesController = addSubcontroller(ControllerBase.create(
        () => ScreensaverPreferencesController.defaults()));
  }

  @override
  void dispose() {
    IDisposable.disposeAll([
      _clockPreferencesController,
      _alarmsPreferencesController,
      _timersPreferencesController,
      _screensaverPreferencesController,
    ]);
    super.dispose();
  }
}
