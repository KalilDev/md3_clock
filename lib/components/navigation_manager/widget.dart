import 'package:flutter/material.dart';
import 'package:md3_clock/components/navigation_manager/controller.dart';
import 'package:value_notifier/value_notifier.dart';

class NavigationManager extends StatelessWidget {
  const NavigationManager({
    Key? key,
    required this.controller,
    required this.navigatorKey,
    required this.child,
  }) : super(key: key);
  final ControllerHandle<NavigationManagerController> controller;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller.unwrap;
    void navigateToScreensaver(void _) {}
    void navigateToPreferences(void _) {
      navigatorKey.currentState!.pushNamed('/preferences');
    }

    void navigateToSendFeedback(void _) {}
    void navigateToHelp(void _) {}
    return EventListener(
      event: controller.didRequestNavigationToScreensaver,
      onEvent: navigateToScreensaver,
      child: EventListener(
        event: controller.didRequestNavigationToPreferences,
        onEvent: navigateToPreferences,
        child: EventListener(
          event: controller.didRequestNavigationToSendFeedback,
          onEvent: navigateToSendFeedback,
          child: EventListener(
            event: controller.didRequestNavigationToHelp,
            onEvent: navigateToHelp,
            child: child,
          ),
        ),
      ),
    );
  }
}
