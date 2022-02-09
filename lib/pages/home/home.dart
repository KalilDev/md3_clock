import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/current_time/controller.dart';
import 'package:md3_clock/model/city.dart';
import 'package:md3_clock/model/weekday.dart';
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

class ClockHomePageController extends ControllerBase<ClockHomePageController> {
  final ICreateTickers _vsync;
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

  final alarmPageController = AlarmPageController();
  late final clockPageController = ClockPageController(
    initialCities: [
      City(
        'Texas City',
        'TX',
        'EUA',
        const Duration(hours: -6),
      ),
    ],
    vsync: _vsync,
    nextAlarm: NextAlarmViewModel(
      Weekday.sunday,
      const TimeOfDay(
        hour: 00,
        minute: 00,
      ),
    ),
  );
  late final timerPageController = TimerPageController(vsync: _vsync);
  late final stopwatchPageController =
      StopwatchPageController(_vsync.createTicker());
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

  void setIndex(int i) => __index.value = i;

  @override
  void dispose() {
    IDisposable.disposeAll([
      __index,
      _vsync,
      alarmPageController,
      clockPageController,
      timerPageController,
      stopwatchPageController,
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
  late final controller = ClockHomePageController(vsync);
  final fabKey = GlobalKey();

  void dispose() {
    vsync.dispose();
    controller.dispose();
    super.dispose();
  }

  // TODO: the ownership of the fab is not correct. fix it.
  Widget _fab() => controller.currentPage
      .map((page) => page.floatingActionButton ?? SizedBox())
      .buildView(key: fabKey);

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
