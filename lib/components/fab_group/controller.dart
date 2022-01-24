import 'package:flutter/foundation.dart';
import 'package:value_notifier/value_notifier.dart';

enum CenterFABState {
  hidden,
  play,
  pause,
  stop,
}

class ProxyFABController implements IConnectToAnFABGroup {
  final ValueNotifier<IConnectToAnFABGroup?> _currentlyConnected =
      ValueNotifier(null);
  ValueListenable<IConnectToAnFABGroup> get currentlyConnected =>
      _currentlyConnected.view().cast();
  void setCurrentlyConnected(IConnectToAnFABGroup newConnected) =>
      _currentlyConnected.value = newConnected;
  void initProxy() {
    currentlyConnected.tap(_connect);
  }

  void _connect(IConnectToAnFABGroup connectable) {
    connectable;
  }

  ValueNotifier<CenterFABState?> _centerFabState = ValueNotifier(null);
  ValueListenable<CenterFABState> get centerFabState =>
      _centerFabState.view().cast();

  @override
  void onFabLeft() => currentlyConnected.value.onFabLeft();

  @override
  void onFabRight() => currentlyConnected.value.onFabRight();

  @override
  void onFabCenter() => currentlyConnected.value.onFabCenter();

  ValueNotifier<bool?> _showFabLeftIcon = ValueNotifier(null);
  ValueListenable<bool> get showFabLeftIcon => _showFabLeftIcon.view().cast();

  ValueNotifier<bool?> _showFabRightIcon = ValueNotifier(null);
  ValueListenable<bool> get showFabRightIcon => _showFabRightIcon.view().cast();
}

abstract class IConnectToAnFABGroup {
  ValueListenable<bool> get showFabLeftIcon;
  ValueListenable<bool> get showFabRightIcon;
  ValueListenable<CenterFABState> get centerFabState;

  void onFabLeft();
  void onFabRight();
  void onFabCenter();
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
      if (!excludeRight) ...[
        connectable.showFabRightIcon.tap(
          fabGroupController.setShowRightIcon,
          includeInitial: true,
        ),
        fabGroupController.didPressRight.listen(connectable.onFabRight),
      ],
      if (!excludeCenter) ...[
        connectable.centerFabState.tap(
          fabGroupController.setCenterState,
          includeInitial: true,
        ),
        fabGroupController.didPressCenter.listen(connectable.onFabCenter),
      ],
    ]);
  }
}

class FABGroupController extends IDisposableBase {
  final ValueNotifier<bool> _showLeftIcon;
  final ValueNotifier<bool> _showRightIcon;
  final ValueNotifier<CenterFABState> _centerState;
  final ActionNotifier _didPressCenter = ActionNotifier();
  final ActionNotifier _didPressRight = ActionNotifier();
  final ActionNotifier _didPressLeft = ActionNotifier();

  FABGroupController.from(
    bool showLeftIcon,
    bool showRightIcon,
    CenterFABState centerState,
  )   : _showLeftIcon = ValueNotifier(showLeftIcon),
        _showRightIcon = ValueNotifier(showRightIcon),
        _centerState = ValueNotifier(centerState);

  ValueListenable<bool> get showLeftIcon => _showLeftIcon.view();
  ValueListenable<bool> get showRightIcon => _showRightIcon.view();
  ValueListenable<CenterFABState> get centerState => _centerState.view();
  ValueListenable<void> get didPressCenter => _didPressCenter.view();
  ValueListenable<void> get didPressRight => _didPressRight.view();
  ValueListenable<void> get didPressLeft => _didPressLeft.view();

  void onCenter() => _didPressCenter.notify();
  void onRight() => _didPressRight.notify();
  void onLeft() => _didPressLeft.notify();

  void dispose() {
    IDisposable.disposeAll([
      _showLeftIcon,
      _showRightIcon,
      _centerState,
      _didPressCenter,
      _didPressRight,
      _didPressLeft,
    ]);
    super.dispose();
  }

  void setCenterState(CenterFABState state) => _centerState.value = state;
  void setShowLeftIcon(bool showLeftIcon) => _showLeftIcon.value = showLeftIcon;
  void setShowRightIcon(bool showRightIcon) =>
      _showRightIcon.value = showRightIcon;
}
