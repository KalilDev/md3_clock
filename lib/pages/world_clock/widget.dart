import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/city.dart';
import '../../widgets/search.dart';
import 'controller.dart';
import 'search_delegate.dart';

class ClockPage extends StatelessWidget {
  const ClockPage({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final ClockPageController controller;

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

class ClockPageFab extends StatelessWidget {
  const ClockPageFab({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final ClockPageController controller;

  @override
  Widget build(BuildContext context) {
    const child = Icon(Icons.add);
    void onPressed() {
      showMD3Search<City>(
        context: context,
        delegate: CitySearchDelegate(),
      ).then((city) {
        print('todo');
      });
    }

    if (useLargeFab(context)) {
      return MD3FloatingActionButton.large(onPressed: onPressed, child: child);
    }
    return MD3FloatingActionButton(onPressed: onPressed, child: child);
  }
}
