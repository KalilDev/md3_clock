import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';

import '../pages/home/navigation_delegate.dart';

class FabScrim extends StatelessWidget {
  const FabScrim({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colorScheme.surface,
              context.colorScheme.surface.withOpacity(0),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: const [
              0,
              1,
            ],
          ),
        ),
        child: Padding(
          padding: FabSafeArea.fabPaddingFor(context),
        ),
      );
}

class FabSafeArea extends StatelessWidget {
  const FabSafeArea({Key? key, this.child}) : super(key: key);
  final Widget? child;

  static EdgeInsets fabPaddingFor(BuildContext context) => EdgeInsets.only(
        bottom:
            useVerticalFab(context) ? 0 : (useLargeFab(context) ? 96 : 56) + 16,
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: fabPaddingFor(context),
        child: child,
      );
}
