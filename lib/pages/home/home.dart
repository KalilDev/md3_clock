import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/utils/chrono.dart';
import 'package:md3_clock/widgets/switcher.dart';
import 'package:value_notifier/value_notifier.dart';

import '../alarm/controller.dart';
import '../alarm/widget.dart';
import '../stopwatch/controller.dart';
import '../stopwatch/widget.dart';
import '../timer/controller.dart';
import '../timer/widget.dart';
import '../world_clock/controller.dart';
import '../world_clock/widget.dart';
import 'sleep.dart';

class _ClockPageSpec {
  const _ClockPageSpec({
    required this.item,
    required this.body,
    this.floatingActionButton,
  });
  final NavigationItem item;
  final Widget body;
  final Widget? floatingActionButton;
  String get title => item.labelText;
}

class ClockHomePageController extends IDisposableBase {
  final ICreateTickers _vsync;
  final ValueNotifier<int> _index = ValueNotifier(0);
  late final IDisposableValueListenable<_ClockPageSpec> currentPage =
      _index.view().map((index) => pages[index]);

  late final List<NavigationItem> _navigationItems =
      pages.map((e) => e.item).toList();

  late final IDisposableValueListenable<MD3NavigationSpec> spec =
      _index.view().map(
            (index) => MD3NavigationSpec(
              items: _navigationItems,
              onChanged: setIndex,
              selectedIndex: index,
            ),
          );

  final alarmPageController = AlarmPageController();
  final clockPageController = ClockPageController();
  late final timerPageController = TimerPageController(vsync: _vsync);
  late final stopwatchPageController = StopwatchPageController(_vsync.createTicker());
  late final List<_ClockPageSpec> pages = [
    _ClockPageSpec(
      item: NavigationItem(labelText: 'Alarme', icon: const Icon(Icons.alarm)),
      body: AlarmPage(controller: alarmPageController),
      floatingActionButton: AlarmPageFab(controller: alarmPageController),
    ),
    _ClockPageSpec(
      item: NavigationItem(
          labelText: 'Relógio', icon: const Icon(Icons.access_time)),
      body: ClockPage(controller: clockPageController),
      floatingActionButton: ClockPageFab(controller: clockPageController),
    ),
    _ClockPageSpec(
      item: NavigationItem(labelText: 'Timer', icon: const Icon(Icons.stop)),
      body: TimerPage(controller: timerPageController),
      floatingActionButton: TimerPageFab(controller: timerPageController),
    ),
    _ClockPageSpec(
      item: NavigationItem(
          labelText: 'Cronômetro', icon: const Icon(Icons.timer_outlined)),
      body: StopwatchPage(controller: stopwatchPageController),
      floatingActionButton:
          StopwatchPageFab(controller: stopwatchPageController),
    ),
    _ClockPageSpec(
      item: NavigationItem(
          labelText: 'Dormir', icon: const Icon(Icons.bed_rounded)),
      body: const SleepPage(),
    ),
  ];

  ClockHomePageController(this._vsync);

  void setIndex(int i) => _index.value = i;

  @override
  void dispose() {
    _index.dispose();
    currentPage.dispose();
    alarmPageController.dispose();
    super.dispose();
  }
}

class ClockHomePage extends StatefulWidget {
  const ClockHomePage({Key? key}) : super(key: key);

  @override
  State<ClockHomePage> createState() => _ClockHomePageState();
}

class _ClockHomePageState extends State<ClockHomePage> with SingleTickerProviderStateMixin {
  late final vsync = FlutterTickerFactory(vsync: this);
  late final controller = ClockHomePageController(vsync);
  late final _fabNotifier =
      controller.currentPage.view().map((page) => page.floatingActionButton);
  void initState() {
    super.initState();
    _fabNotifier.addListener(_fabChanged);
  }

  void _fabChanged() {
    setState(() {});
  }

  void dispose() {
    _fabNotifier.dispose();
    vsync.dispose();
    super.dispose();
  }

  Widget? _fab(BuildContext context) => _fabNotifier.value;

  void _onMenuDestination(BuildContext context, MenuDestination destination) {
    print('TODO');
  }

  void _openPopupMenuFrom(BuildContext context) => showMD3Menu<MenuDestination>(
        context: context,
        position: rectFromContext(context),
        items: MenuDestination.values
            .map(
              (e) => MD3PopupMenuItem<MenuDestination>(
                value: e,
                child: Text(e.text),
              ),
            )
            .toList(),
      ).then((value) => value != null
          ? _onMenuDestination(
              context,
              value,
            )
          : null);

  PreferredSizeWidget _appBar(BuildContext context) {
    return MD3SmallAppBar(
      title: controller.currentPage.buildView(
        builder: (context, page, _) => Text(page.title),
      ),
      // Apply the same margin as the scaffold body and remove the leading
      // placeholder, so that the appbar title is aligned with the body
      // elements.
      implyLeadingPlaceholder: false,
      titleSpacing: 24,
      /*MD3ScaffoldBody.marginFor(
        MediaQuery.of(context).size.width,
        context.sizeClass,
        minMargin: ClockNavigationDelegate.kBodyMinimumMargin,
        maxMargin: ClockNavigationDelegate.kBodyMaximumMargin,
      ),*/
      actions: [
        Builder(
          builder: (context) => IconButton(
            onPressed: () => _openPopupMenuFrom(context),
            icon: const Icon(Icons.more_vert),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) => MD3FloatingActionButtonTheme(
        data: MD3FloatingActionButtonThemeData(
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              const CircleBorder(),
            ),
          ),
        ),
        child: controller.spec.buildView(
          builder: (context, spec, _) => MD3NavigationScaffold(
            delegate: ClockNavigationDelegate(
              floatingActionButton: _fab(context),
              appBar: _appBar(context),
            ),
            spec: spec,
            body: controller.currentPage.buildView(
              builder: (context, page, _) => FadeThroughSwitcher(
                child: KeyedSubtree(
                  key: ObjectKey(page),
                  child: page.body,
                ),
              ),
            ),
          ),
        ),
      );
}

enum MenuDestination {
  screensaver,
  settings,
  feedback,
  help,
}

extension on MenuDestination {
  String get text {
    switch (this) {
      case MenuDestination.screensaver:
        return 'Protetor de tela';
      case MenuDestination.settings:
        return 'Configurações';
      case MenuDestination.feedback:
        return 'Enviar feedback';
      case MenuDestination.help:
        return 'Ajuda';
    }
  }
}

RelativeRect rectFromContext(BuildContext context) {
  final button = context.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(context)!.context.findRenderObject()! as RenderBox;
  return RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );
}
