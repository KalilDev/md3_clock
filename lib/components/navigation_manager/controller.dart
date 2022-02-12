import 'package:flutter/foundation.dart';
import 'package:value_notifier/value_notifier.dart';

class NavigationManagerController
    extends ControllerBase<NavigationManagerController> {
  final ActionNotifier _didRequestNavigationToScreensaver = ActionNotifier();
  final ActionNotifier _didRequestNavigationToPreferences = ActionNotifier();
  final ActionNotifier _didRequestNavigationToSendFeedback = ActionNotifier();
  final ActionNotifier _didRequestNavigationToHelp = ActionNotifier();

  ValueListenable<void> get didRequestNavigationToScreensaver =>
      _didRequestNavigationToScreensaver.view();
  ValueListenable<void> get didRequestNavigationToPreferences =>
      _didRequestNavigationToPreferences.view();
  ValueListenable<void> get didRequestNavigationToSendFeedback =>
      _didRequestNavigationToSendFeedback.view();
  ValueListenable<void> get didRequestNavigationToHelp =>
      _didRequestNavigationToHelp.view();

  void requestNavigationToScreensaver() =>
      _didRequestNavigationToScreensaver.notify();
  void requestNavigationToPreferences() =>
      _didRequestNavigationToPreferences.notify();
  void requestNavigationToSendFeedback() =>
      _didRequestNavigationToSendFeedback.notify();
  void requestNavigationToHelp() => _didRequestNavigationToHelp.notify();
}
