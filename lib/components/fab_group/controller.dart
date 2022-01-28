import 'package:flutter/foundation.dart';
import 'package:value_notifier/value_notifier.dart';

enum CenterFABState {
  hidden,
  play,
  pause,
  stop,
}

mixin ProxyFABControllerMixin implements IConnectToAnFABGroup {
  final ValueNotifier<IConnectToAnFABGroup?> _currentlyConnected =
      ValueNotifier(null);
  final ValueNotifier<bool?> _showFabLeftIcon = ValueNotifier(null);
  final ValueNotifier<CenterFABState?> _centerFabState = ValueNotifier(null);
  final ValueNotifier<bool?> _showFabRightIcon = ValueNotifier(null);

  ValueListenable<IConnectToAnFABGroup> get currentlyConnected =>
      _currentlyConnected.view().cast();

  @override
  ValueListenable<bool> get showFabLeftIcon => _showFabLeftIcon.view().cast();
  @override
  ValueListenable<bool> get showFabRightIcon => _showFabRightIcon.view().cast();
  @override
  ValueListenable<CenterFABState> get centerFabState =>
      _centerFabState.view().cast();

  void setCurrentlyConnected(IConnectToAnFABGroup newConnected) =>
      _currentlyConnected.value = newConnected;
  @override
  void onFabLeft() => currentlyConnected.value.onFabLeft();
  @override
  void onFabCenter() => currentlyConnected.value.onFabCenter();
  @override
  void onFabRight() => currentlyConnected.value.onFabRight();

  @protected
  void initProxy() {
    currentlyConnected.tap(setCurrentlyConnected);
  }

  @protected
  void disposeProxy() {
    IDisposable.disposeAll([
      _currentlyConnected,
      _showFabLeftIcon,
      _centerFabState,
      _showFabRightIcon,
    ]);
  }
}

abstract class IConnectToAnFABGroup {
  ValueListenable<bool> get showFabLeftIcon;
  ValueListenable<CenterFABState> get centerFabState;
  ValueListenable<bool> get showFabRightIcon;

  void onFabLeft();
  void onFabCenter();
  void onFabRight();
}

mixin FABGroupConnectionManagerMixin {
  FABGroupController get fabGroupController;
  IDisposable? fabGroupConnection;
  bool get isFabGroupConnected => fabGroupConnection != null;

  void disposeFabConnection() {
    fabGroupConnection?.dispose();
    fabGroupConnection = null;
  }

  void connectFabTo(
    IConnectToAnFABGroup connectable, {
    bool excludeLeft = false,
    bool excludeCenter = false,
    bool excludeRight = false,
  }) {
    disposeFabConnection();
    fabGroupConnection = IDisposable.merge([
      if (!excludeLeft) ...[
        connectable.showFabLeftIcon.tap(
          fabGroupController.setShowLeftIcon,
          includeInitial: true,
        ),
        fabGroupController.didPressLeft.listen(connectable.onFabLeft),
      ],
      if (!excludeCenter) ...[
        connectable.centerFabState.tap(
          fabGroupController.setCenterState,
          includeInitial: true,
        ),
        fabGroupController.didPressCenter.listen(connectable.onFabCenter),
      ],
      if (!excludeRight) ...[
        connectable.showFabRightIcon.tap(
          fabGroupController.setShowRightIcon,
          includeInitial: true,
        ),
        fabGroupController.didPressRight.listen(connectable.onFabRight),
      ],
    ]);
  }
}

class FABGroupController extends ControllerBase {
  final ValueNotifier<bool> _showLeftIcon;
  final ValueNotifier<CenterFABState> _centerState;
  final ValueNotifier<bool> _showRightIcon;
  final ActionNotifier _didPressLeft = ActionNotifier();
  final ActionNotifier _didPressCenter = ActionNotifier();
  final ActionNotifier _didPressRight = ActionNotifier();

  FABGroupController.hidden()
      : _showLeftIcon = ValueNotifier(false),
        _centerState = ValueNotifier(CenterFABState.hidden),
        _showRightIcon = ValueNotifier(false);

  FABGroupController.from({
    required bool showLeftIcon,
    required CenterFABState centerState,
    required bool showRightIcon,
  })  : _showLeftIcon = ValueNotifier(showLeftIcon),
        _centerState = ValueNotifier(centerState),
        _showRightIcon = ValueNotifier(showRightIcon);

  ValueListenable<bool> get showLeftIcon => _showLeftIcon.view();
  ValueListenable<CenterFABState> get centerState => _centerState.view();
  ValueListenable<bool> get showRightIcon => _showRightIcon.view();
  ValueListenable<void> get didPressLeft => _didPressLeft.view();
  ValueListenable<void> get didPressCenter => _didPressCenter.view();
  ValueListenable<void> get didPressRight => _didPressRight.view();

  void onLeft() => _didPressLeft.notify();
  void onCenter() => _didPressCenter.notify();
  void onRight() => _didPressRight.notify();
  void setShowLeftIcon(bool showLeftIcon) => _showLeftIcon.value = showLeftIcon;
  void setCenterState(CenterFABState state) => _centerState.value = state;
  void setShowRightIcon(bool showRightIcon) =>
      _showRightIcon.value = showRightIcon;

  @override
  void dispose() {
    IDisposable.disposeAll([
      _showLeftIcon,
      _centerState,
      _showRightIcon,
      _didPressLeft,
      _didPressCenter,
      _didPressRight,
    ]);
    super.dispose();
  }
}
