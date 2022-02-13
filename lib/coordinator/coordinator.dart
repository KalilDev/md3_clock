import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:value_notifier/value_notifier.dart';

extension CoordinatorContextE on BuildContext {
  Controller createController<Controller extends ControllerBase<Controller>>(
          Controller Function(BuildContext) factory) =>
      coordinator.unwrap.createController(() => factory(this));

  ControllerHandle<Coordinator> get coordinator =>
      InheritedController.get<Coordinator>(this);
}

class Coordinator extends ControllerBase<Coordinator> {
  final UnmodifiableListView<CoordinatorComponent> _parentComponents;
  final UnmodifiableListView<CoordinatorComponent> _ownedComponents;

  Coordinator.empty()
      : _parentComponents = UnmodifiableListView(const []),
        _ownedComponents = UnmodifiableListView(const []);

  Coordinator(Iterable<CoordinatorComponent> initial)
      : _parentComponents = UnmodifiableListView(const []),
        _ownedComponents = UnmodifiableListView(initial.toList());

  Coordinator._with(
    Iterable<CoordinatorComponent> parentComponents,
    Iterable<CoordinatorComponent> ownedComponents,
  )   : _parentComponents = UnmodifiableListView(parentComponents.toList()),
        _ownedComponents = UnmodifiableListView(ownedComponents.toList());

  void init() {
    super.init();
    for (final component in _ownedComponents) {
      component._registerSelfTo(this);
      component.init();
    }
  }

  void dispose() {
    IDisposable.disposeAll(_ownedComponents);
    super.dispose();
  }

  Coordinator install(CoordinatorComponent component) =>
      installAll([component]);

  Coordinator installAll(Iterable<CoordinatorComponent> components) =>
      Coordinator._with(_allComponents, components);

  Iterable<CoordinatorComponent> get _allComponents =>
      _parentComponents.followedBy(_ownedComponents);

  void
      _registerControllerPreInit<Controller extends ControllerBase<Controller>>(
    Controller controller,
  ) {
    final handle = controller.handle;
    for (final component in _allComponents) {
      component.registerPreInit(handle);
    }
  }

  void _registerControllerPostInit<
      Controller extends ControllerBase<Controller>>(
    Controller controller,
  ) {
    final handle = controller.handle;
    for (final component in _allComponents) {
      component.registerPostInit(handle);
    }
  }

  Controller createController<Controller extends ControllerBase<Controller>>(
    Controller Function() factory,
  ) =>
      ControllerBase.create<Controller>(
        factory,
        registerPreInit: _registerControllerPreInit,
        register: _registerControllerPostInit,
      );
}

abstract class CoordinatorComponent<Self extends CoordinatorComponent<Self>>
    extends SubcontrollerBase<Coordinator, Self> {
  // Needed because we need the Self type argument.
  void _registerSelfTo(Coordinator parentCoordinator) {
    parentCoordinator.registerSubcontroller<Self>(this as Self);
  }

  @mustCallSuper
  void registerPreInit<Controller extends ControllerBase<Controller>>(
    ControllerHandle<Controller> controller,
  ) {}
  @mustCallSuper
  void registerPostInit<Controller extends ControllerBase<Controller>>(
    ControllerHandle<Controller> controller,
  ) {}
}
