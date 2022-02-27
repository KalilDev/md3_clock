import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/navigation_manager/controller.dart';
import 'package:md3_clock/pages/preferences/controller.dart';
import 'package:md3_clock/widgets/weekday_picker.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/weekday.dart';
import '../../widgets/list_tile.dart';
import '../home/home.dart';

enum _MenuDestination {
  feedback,
  help,
}

extension on _MenuDestination {
  String get text {
    switch (this) {
      case _MenuDestination.feedback:
        return 'Enviar feedback';
      case _MenuDestination.help:
        return 'Ajuda';
    }
  }
}

class _Result<T> {
  final T value;

  _Result(this.value);
}

class _SelectionDialogListTile<T> extends StatelessWidget {
  const _SelectionDialogListTile({
    Key? key,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    required this.buildItemLabel,
  }) : super(key: key);
  final Widget title;
  final List<T> items;
  final T selectedItem;
  final ValueChanged<T> onSelected;
  final Widget Function(BuildContext context, T) buildItemLabel;

  Future<_Result<T>?> _showDialog(BuildContext context) =>
      showDialog<_Result<T>>(
        context: context,
        builder: (context) => _SelectionDialog<T>(
          title: title,
          items: items,
          buildItemLabel: buildItemLabel,
          selectedItem: selectedItem,
        ),
      );

  @override
  Widget build(BuildContext context) => MD3ListTile(
        title: title,
        subtitle: Builder(
          builder: (context) => buildItemLabel(context, selectedItem),
        ),
        onTap: () => _showDialog(context).then(
          (result) => result == null ? null : onSelected(result.value),
        ),
      );
}

class _SelectionDialog<T> extends StatelessWidget {
  const _SelectionDialog({
    Key? key,
    required this.title,
    required this.items,
    this.selectedItem,
    required this.buildItemLabel,
  }) : super(key: key);
  final Widget title;
  final List<T> items;
  final T? selectedItem;
  final Widget Function(BuildContext context, T) buildItemLabel;

  void _pop(BuildContext context, T item) =>
      Navigator.of(context).pop<_Result<T>>(_Result(item));

  Widget _buildItem(BuildContext context, T item) => MD3ListTile(
        padding: EdgeInsets.symmetric(vertical: 16),
        leading: Radio<T>(
          value: item,
          groupValue: selectedItem,
          onChanged: (_) => _pop(context, item),
        ),
        title: buildItemLabel(context, item),
        onTap: () => _pop(context, item),
      );

  @override
  Widget build(BuildContext context) => MD3BasicDialog(
        title: title,
        scrollable: true,
        content: ListBody(
          children: List.generate(
            items.length,
            (i) => _buildItem(
              context,
              items[i],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop<_Result<T>>,
            child: Text('Cancelar'),
          )
        ],
      );
}

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final ControllerHandle<PreferencesController> controller;

  void _onMenuDestination(BuildContext context, _MenuDestination destination) {
    final navigator =
        InheritedController.get<NavigationManagerController>(context).unwrap;
    switch (destination) {
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

  static const _kMinimumMargin = MD3SizeClassProperty.all(8.0);
  static const _kMaximumMargin = _kMinimumMargin;

  @override
  Widget build(BuildContext context) => MD3AdaptativeScaffold(
        body: MD3ScaffoldBody.noMargin(
          minimumMargin: _kMinimumMargin,
          maximumMargin: _kMaximumMargin,
          child: CustomScrollView(
            slivers: [
              MD3SliverAppBar(
                title: Text('Configurações'),
                actions: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => _openPopupMenuFrom(context),
                      icon: const Icon(Icons.more_vert),
                    ),
                  )
                ],
              ),
              Builder(
                builder: (context) => SliverPadding(
                  padding: InheritedMD3BodyMargin.of(context).padding,
                  sliver: _PreferencesSliverList(controller: controller.unwrap),
                ),
              ),
            ],
          ),
        ),
      );
}

extension on ClockStyle {
  String get text {
    switch (this) {
      case ClockStyle.digital:
        return 'Digital';
      case ClockStyle.analog:
        return 'Analógico';
    }
  }
}

class _StartOfTheWeekTile extends StatelessWidget {
  const _StartOfTheWeekTile({
    Key? key,
    required this.weekday,
    required this.onChanged,
  }) : super(key: key);
  final ValueListenable<Weekday> weekday;
  final ValueChanged<Weekday> onChanged;

  static const _kPossibleWeekdays = [
    Weekday.friday,
    Weekday.saturday,
    Weekday.sunday,
    Weekday.monday,
  ];

  @override
  Widget build(BuildContext context) => weekday
      .map(
        (weekday) => MD3MenuListTile<Weekday>(
          title: const Text('Começar a semana em'),
          initialValue: weekday,
          menuKind: MD3PopupMenuKind.selection,
          itemBuilder: (_) => _kPossibleWeekdays
              .map((e) => MD3SelectablePopupMenuItem(
                    value: e,
                    child: Text(e.uppercasedLongText),
                  ))
              .toList(),
          subtitle: Text(weekday.uppercasedLongText),
          onSelected: onChanged,
        ),
      )
      .build();
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    Key? key,
    required this.style,
    required this.onChanged,
  }) : super(key: key);
  final ValueListenable<ClockStyle> style;
  final ValueChanged<ClockStyle> onChanged;

  @override
  Widget build(BuildContext context) => style
      .map(
        (style) => MD3MenuListTile<ClockStyle>(
          title: const Text('Estilo'),
          initialValue: style,
          menuKind: MD3PopupMenuKind.selection,
          itemBuilder: (_) => ClockStyle.values
              .map((e) => MD3SelectablePopupMenuItem(
                    value: e,
                    child: Text(e.text),
                  ))
              .toList(),
          subtitle: Text(style.text),
          onSelected: onChanged,
        ),
      )
      .build();
}

extension on VolumeButtonsBehavior {
  String get text {
    switch (this) {
      case VolumeButtonsBehavior.volume:
        return 'Controlam o volume';
      case VolumeButtonsBehavior.snooze:
        return 'Ativam a soneca';
      case VolumeButtonsBehavior.stop:
        return 'Parar';
    }
  }
}

class _PreferencesSliverList extends StatelessWidget {
  const _PreferencesSliverList({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final PreferencesController controller;

  List<Widget> _clockSection(BuildContext context) {
    final clock = controller.clock.unwrap;
    return [
      const _SectionStartTitleAndSpacing(title: 'Relógio'),
      _StyleTile(
        style: clock.style,
        onChanged: clock.setStyle,
      ),
      MD3SwitchValueListenableListTile(
        title: Text('Exibir horário com segundos'),
        value: clock.showSeconds,
        onChanged: clock.setShowSeconds,
      ),
      MD3SwitchValueListenableListTile(
        title: Text('Relógio de casa automático'),
        subtitle: Text('Ao viajar para outro fuso horário, adicionar um '
            'relógio para casa.'),
        value: clock.autoHomeTimezoneClock,
        onChanged: clock.setAutoHomeTimezoneClock,
      ),
      _HomeTimezoneTile(
        controller: clock,
      ),
      MD3ListTile(
        title: Text('Alterar data e hora'),
        onTap: clock.requestShowChangeDateTime,
      ),
    ];
  }

  static final _kSilenceDurations = List.generate(
    7,
    (index) => index == 6
        ? null
        : Duration(
            minutes: index == 0 ? 1 : index * 5,
          ),
  );
  static final _kSnoozeDurations =
      List.generate(30, (index) => Duration(minutes: index + 1));

  List<Widget> _alarmsSection(BuildContext context) {
    final alarms = controller.alarms.unwrap;
    return [
      const _SectionStartTitleAndSpacing(title: 'Alarmes'),
      alarms.silenceAfter
          .map(
            (silenceAfter) => _SelectionDialogListTile<Duration?>(
              title: Text('Silenciar depois de'),
              items: _kSilenceDurations,
              selectedItem: silenceAfter,
              onSelected: alarms.setSilenceAfter,
              buildItemLabel: (context, duration) => Text(
                duration == null
                    ? 'Nunca'
                    : '${duration.inMinutes} minuto${duration.inMinutes > 1 ? 's' : ''}',
              ),
            ),
          )
          .build(),
      alarms.snoozeDuration
          .map(
            (snoozeDuration) => _SelectionDialogListTile<Duration>(
              title: Text('Duração da soneca'),
              items: _kSnoozeDurations,
              selectedItem: snoozeDuration,
              onSelected: alarms.setSnoozeDuration,
              buildItemLabel: (context, duration) => Text(
                '${duration.inMinutes} minuto${duration.inMinutes > 1 ? 's' : ''}',
              ),
            ),
          )
          .build(),
      _AlarmVolumeTile(
        value: alarms.volume,
        onChanged: alarms.setVolume,
      ),
      _VolumeIncreaseTile(
        value: alarms.volumeIncreaseDuration,
        onChanged: alarms.setVolumeIncreaseDuration,
      ),
      alarms.volumeButtonsBehavior
          .map(
            (volumeButtonsBehavior) => MD3MenuListTile<VolumeButtonsBehavior>(
              title: const Text('Botões de volume'),
              initialValue: volumeButtonsBehavior,
              menuKind: MD3PopupMenuKind.selection,
              itemBuilder: (_) => VolumeButtonsBehavior.values
                  .map((e) => MD3SelectablePopupMenuItem(
                        value: e,
                        child: Text(e.text),
                      ))
                  .toList(),
              subtitle: Text(volumeButtonsBehavior.text),
              onSelected: alarms.setVolumeButtonsBehavior,
            ),
          )
          .build(),
      _StartOfTheWeekTile(
        weekday: alarms.startOfTheWeek,
        onChanged: alarms.setStartOfTheWeek,
      ),
    ];
  }

  List<Widget> _timersSection(BuildContext context) {
    final timer = controller.timers.unwrap;
    return [
      const _SectionStartTitleAndSpacing(title: 'Timers'),
      _VolumeIncreaseTile(
        value: timer.volumeIncreaseDuration,
        onChanged: timer.setVolumeIncreaseDuration,
      ),
      MD3SwitchValueListenableListTile(
        title: Text('Vibração do timer'),
        value: timer.vibrate,
        onChanged: timer.setVibrate,
      ),
    ];
  }

  List<Widget> _screensaverSection(BuildContext context) {
    final screensaver = controller.screensaver.unwrap;
    return [
      const _SectionStartTitleAndSpacing(title: 'Protetor de tela'),
      _StyleTile(
        style: screensaver.style,
        onChanged: screensaver.setStyle,
      ),
      MD3SwitchValueListenableListTile(
        title: Text('Modo noturno'),
        subtitle: Text('Tela com iluminação mínima (para salas escuras)'),
        value: screensaver.nightMode,
        onChanged: screensaver.setNightMode,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Column(
          children: [
            ..._clockSection(context),
            const _SectionDivider(),
            ..._alarmsSection(context),
            const _SectionDivider(),
            ..._timersSection(context),
            const _SectionDivider(),
            ..._screensaverSection(context),
          ],
        ),
      );
}

class _VolumeIncreaseTile extends StatelessWidget {
  const _VolumeIncreaseTile({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);
  final ValueListenable<Duration?> value;
  final ValueChanged<Duration?> onChanged;

  static final _kGradualIncreaseDurations = List.generate(
      13, (index) => index == 0 ? null : Duration(seconds: index * 5));

  @override
  Widget build(BuildContext context) => value
      .map(
        (volumeIncreaseDuration) => _SelectionDialogListTile<Duration?>(
          title: Text('Aumentar gradualmente o volume'),
          items: _kGradualIncreaseDurations,
          selectedItem: volumeIncreaseDuration,
          onSelected: onChanged,
          buildItemLabel: (context, duration) => Text(
            duration == null ? 'Nunca' : '${duration.inSeconds} segundos',
          ),
        ),
      )
      .build();
}

class _AlarmVolumeTile extends StatelessWidget {
  const _AlarmVolumeTile({
    Key? key,
    required this.value,
    this.onChanged,
  }) : super(key: key);
  final ValueListenable<int> value;
  final ValueChanged<int>? onChanged;

  void _onChanged(double v) => onChanged!(v.toInt());

  @override
  Widget build(BuildContext context) => MD3ListTile(
        leading: Icon(Icons.alarm),
        title: Padding(
          padding: EdgeInsets.only(left: 24),
          child: Text('Volume do alarme'),
        ),
        disabled: onChanged == null,
        subtitle: SizedBox(
          height: 48,
          child: value
              .map(
                (value) => MD3Slider(
                  min: 0,
                  max: 6,
                  value: value.toDouble(),
                  onChanged: onChanged == null ? null : _onChanged,
                  divisions: 6,
                ),
              )
              .build(),
        ),
      );
}

class _HomeTimezoneTile extends StatelessWidget {
  const _HomeTimezoneTile({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final ClockPreferencesController controller;

  void _onTap() {
    print('TODO');
  }

  @override
  Widget build(BuildContext context) => controller.autoHomeTimezoneClock
      .map((autoHomeTimezoneClock) => MD3ListTile(
            title: Text('Fuso horário de casa'),
            onTap: _onTap,
            disabled: !autoHomeTimezoneClock,
          ))
      .build();
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Divider(
        height: 0,
        thickness: 0.0,
        indent: 0.0,
        endIndent: 0.0,
        color: context.colorScheme.outline,
      );
}

class _SectionStartTitleAndSpacing extends StatelessWidget {
  const _SectionStartTitleAndSpacing({
    Key? key,
    required this.title,
  }) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 16, left: 16, right: 16),
        child: SizedBox(
          height: 34,
          child: Align(
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle(
              style: context.textTheme.titleSmall.copyWith(
                color: context.colorScheme.primary,
              ),
              child: Text(title),
            ),
          ),
        ),
      );
}
