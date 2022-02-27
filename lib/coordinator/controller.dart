import 'package:flutter/material.dart';
import 'package:md3_clock/coordinator/coordinator.dart';
import 'package:md3_clock/pages/preferences/controller.dart';
import 'package:md3_clock/pages/world_clock/controller.dart';
import 'package:value_notifier/value_notifier.dart';

import '../pages/alarm/controller.dart';

class _PreferencesAndAlarmsPage {
  final ControllerHandle<PreferencesController> prefsHandle;
  final ControllerHandle<AlarmPageController> alarmHandle;

  _PreferencesAndAlarmsPage(this.prefsHandle, this.alarmHandle);
}

class _PreferencesAndClockPage {
  final ControllerHandle<PreferencesController> prefsHandle;
  final ControllerHandle<ClockPageController> clockHandle;

  _PreferencesAndClockPage(this.prefsHandle, this.clockHandle);
}

class PreferencesCoordinatorComponent
    extends CoordinatorComponent<PreferencesCoordinatorComponent> {
  final EventNotifier<ControllerHandle<PreferencesController>>
      _preferencesController = EventNotifier();
  final EventNotifier<ControllerHandle<ClockPageController>>
      _clockPageController = EventNotifier();
  final EventNotifier<ControllerHandle<AlarmPageController>>
      _alarmPageController = EventNotifier();

  IDisposable _clockPageConnection = IDisposable.none();
  IDisposable _alarmPageConnection = IDisposable.none();

  void _onPreferencesAndClockPage(
    ControllerHandle<PreferencesController> prefsHandle,
    ControllerHandle<ClockPageController> clockHandle,
  ) {
    final clockPrefs = prefsHandle.unwrap.clock.unwrap;
    final clockPage = clockHandle.unwrap;
    print('connecting');
    _clockPageConnection.dispose();
    _clockPageConnection = IDisposable.merge([
      clockPrefs.showSeconds.connect(
        clockPage.setShowSeconds,
      ),
      clockPrefs.style.connect(
        clockPage.setClockStyle,
      ),
      clockPrefs.autoHomeTimezoneClock.connect(
        clockPage.setAutoHomeTimezoneClock,
      ),
      clockPrefs.homeTimezone.connect(
        clockPage.setHomeTimezone,
      ),
    ]);
  }

  void _onPreferencesAndAlarmPage(
    ControllerHandle<PreferencesController> prefsHandle,
    ControllerHandle<AlarmPageController> alarmHandle,
  ) {
    final alarmPrefs = prefsHandle.unwrap.alarms.unwrap;
    final alarmPage = alarmHandle.unwrap;
    print('connecting');
    _alarmPageConnection.dispose();
    _alarmPageConnection = IDisposable.merge([
      alarmPrefs.startOfTheWeek.connect(
        alarmPage.setStartOfTheWeek,
      ),
    ]);
  }

  @override
  void registerPreInit<Controller extends ControllerBase<Controller>>(
      ControllerHandle<Controller> controller) {
    print('register pre init $Controller');
    super.registerPreInit(controller);
    switch (Controller) {
      case PreferencesController:
        _preferencesController
            .add(controller as ControllerHandle<PreferencesController>);
        break;
      case ClockPageController:
        _clockPageController
            .add(controller as ControllerHandle<ClockPageController>);
        break;
      case AlarmPageController:
        _alarmPageController
            .add(controller as ControllerHandle<AlarmPageController>);
        break;
    }
  }

  @override
  void init() {
    super.init();
    _preferencesController.view().tap(print);
    _clockPageController.view().tap(print);
    _preferencesController
        .viewNexts()
        .bind(
          (prefsHandle) => _clockPageController.viewNexts().map((clockHandle) =>
              _PreferencesAndClockPage(prefsHandle, clockHandle)),
          canBindEagerly: false,
        )
        .tap((e) => _onPreferencesAndClockPage(e.prefsHandle, e.clockHandle));
    _preferencesController
        .viewNexts()
        .bind(
          (prefsHandle) => _alarmPageController.viewNexts().map((alarmHandle) =>
              _PreferencesAndAlarmsPage(prefsHandle, alarmHandle)),
          canBindEagerly: false,
        )
        .tap((e) => _onPreferencesAndAlarmPage(e.prefsHandle, e.alarmHandle));
    print('init');
  }

  void dispose() {
    IDisposable.disposeAll([
      _clockPageConnection,
    ]);
    IDisposable.disposeAll([
      _preferencesController,
      _clockPageController,
    ]);
    super.dispose();
  }
}
