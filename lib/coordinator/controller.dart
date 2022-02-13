import 'package:flutter/material.dart';
import 'package:md3_clock/coordinator/coordinator.dart';
import 'package:md3_clock/pages/preferences/controller.dart';
import 'package:md3_clock/pages/world_clock/controller.dart';
import 'package:value_notifier/value_notifier.dart';

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

  IDisposable _clockPageConnection = IDisposable.none();

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
