import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/current_time/controller.dart';
import 'package:md3_clock/components/navigation_manager/controller.dart';
import 'package:md3_clock/coordinator/coordinator.dart';
import 'package:md3_clock/model/city.dart';
import 'package:md3_clock/model/weekday.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/pages/preferences/controller.dart';
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

class ClockHomePageController extends ControllerBase<ClockHomePageController> {
  final ValueNotifier<int> __index = ValueNotifier(0);
  late final List<NavigationItem> _navigationItems =
      pages.map((e) => e.item).toList();

  ValueListenable<int> get _index => __index.view();
  ValueListenable<_ClockPageSpec> get currentPage =>
      _index.map((index) => pages[index]);

  ValueListenable<MD3NavigationSpec> get spec => _index.map(
        (index) => MD3NavigationSpec(
          items: _navigationItems,
          onChanged: setIndex,
          selectedIndex: index,
        ),
      );

  final AlarmPageController _alarmPageController;
  final ClockPageController _clockPageController;
  final TimerPageController _timerPageController;
  final StopwatchPageController _stopwatchPageController;

  late final List<_ClockPageSpec> pages = [
    _ClockPageSpec(
      item: NavigationItem(labelText: 'Alarme', icon: const Icon(Icons.alarm)),
      body: AlarmPage(controller: _alarmPageController),
      floatingActionButton: AlarmPageFab(controller: _alarmPageController),
    ),
    _ClockPageSpec(
      item: NavigationItem(
          labelText: 'Relógio', icon: const Icon(Icons.access_time)),
      body: ClockPage(controller: _clockPageController),
      floatingActionButton: ClockPageFab(controller: _clockPageController),
    ),
    _ClockPageSpec(
      item: NavigationItem(labelText: 'Timer', icon: const Icon(Icons.stop)),
      body: TimerPage(controller: _timerPageController.handle),
      floatingActionButton:
          TimerPageFab(controller: _timerPageController.handle),
    ),
    _ClockPageSpec(
      item: NavigationItem(
          labelText: 'Cronômetro', icon: const Icon(Icons.timer_outlined)),
      body: StopwatchPage(controller: _stopwatchPageController),
      floatingActionButton:
          StopwatchPageFab(controller: _stopwatchPageController),
    ),
    _ClockPageSpec(
      item: NavigationItem(
          labelText: 'Dormir', icon: const Icon(Icons.bed_rounded)),
      body: const SleepPage(),
    ),
  ];

  ClockHomePageController({
    required ICreateTickers vsync,
    required ControllerHandle<Coordinator> coordinator,
  })  : _alarmPageController =
            coordinator.unwrap.createController(() => AlarmPageController()),
        _clockPageController = coordinator.unwrap.createController(
          () => ClockPageController(
            initialCities: [
              const City(
                'Texas City',
                'TX',
                'EUA',
                Duration(hours: -6),
              ),
            ],
            vsync: vsync,
            nextAlarm: NextAlarmViewModel(
              Weekday.sunday,
              const TimeOfDay(
                hour: 00,
                minute: 00,
              ),
            ),
            autoHomeTimezoneClock: true,
            clockStyle: ClockStyle.analog,
            homeTimezone: null,
            showSeconds: false,
          ),
        ),
        _timerPageController = coordinator.unwrap.createController(
          () => TimerPageController(vsync: vsync),
        ),
        _stopwatchPageController = coordinator.unwrap.createController(
          () => StopwatchPageController(vsync.createTicker()),
        );

  void setIndex(int i) => __index.value = i;

  @override
  void dispose() {
    IDisposable.disposeAll([
      __index,
      _alarmPageController,
      _clockPageController,
      _timerPageController,
      _stopwatchPageController,
    ]);
    super.dispose();
  }
}

class ClockHomePage extends StatefulWidget {
  const ClockHomePage({Key? key}) : super(key: key);

  @override
  State<ClockHomePage> createState() => _ClockHomePageState();
}

class _ClockHomePageState extends State<ClockHomePage>
    with SingleTickerProviderStateMixin {
  late final vsync = FlutterTickerFactory(vsync: this);
  late final ClockHomePageController controller;
  bool didInitController = false;

  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!didInitController) {
      controller = context.createController(
        (_) => ClockHomePageController(
          vsync: vsync,
          coordinator: context.coordinator,
        ),
      );
      didInitController = true;
    }
  }

  // TODO: using an global key results in it being used twice on the tree for some reason?
  final fabKey = UniqueKey();
  final _bodyKey = GlobalKey();

  void dispose() {
    vsync.dispose();
    controller.dispose();
    super.dispose();
  }

  // TODO: the ownership of the fab is not correct. fix it.
  Widget _fab() => controller.currentPage
      .map((page) => page.floatingActionButton ?? SizedBox())
      .buildView(key: fabKey);

  void _onMenuDestination(BuildContext context, _MenuDestination destination) {
    final navigator =
        InheritedController.get<NavigationManagerController>(context).unwrap;
    switch (destination) {
      case _MenuDestination.screensaver:
        navigator.requestNavigationToScreensaver();
        break;
      case _MenuDestination.preferences:
        navigator.requestNavigationToPreferences();
        break;
      case _MenuDestination.feedback:
        navigator.requestNavigationToSendFeedback();
        break;
      case _MenuDestination.help:
        navigator.requestNavigationToHelp();
        break;
    }
  }

  void _openPopupMenuFrom(BuildContext context) =>
      showMD3Menu<_MenuDestination>(
        context: context,
        position: rectFromContext(context),
        items: _MenuDestination.values
            .map(
              (e) => MD3PopupMenuItem<_MenuDestination>(
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

  PreferredSizeWidget _appBar() => MD3SmallAppBar(
        title: controller.currentPage.build(
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

  late final navigationDelegate = ClockNavigationDelegate(
    floatingActionButton: _fab(),
    appBar: _appBar(),
  );

  @override
  Widget build(BuildContext context) => MD3FloatingActionButtonTheme(
        data: MD3FloatingActionButtonThemeData(
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              const CircleBorder(),
            ),
          ),
        ),
        child: controller.spec.build(
          builder: (context, spec, _) => MD3NavigationScaffold(
            delegate: navigationDelegate,
            spec: spec,
            body: controller.currentPage.build(
              key: _bodyKey,
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

enum _MenuDestination {
  screensaver,
  preferences,
  feedback,
  help,
}

extension on _MenuDestination {
  String get text {
    switch (this) {
      case _MenuDestination.screensaver:
        return 'Protetor de tela';
      case _MenuDestination.preferences:
        return 'Configurações';
      case _MenuDestination.feedback:
        return 'Enviar feedback';
      case _MenuDestination.help:
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
