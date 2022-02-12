import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/navigation_manager/controller.dart';
import 'package:md3_clock/pages/preferences/controller.dart';
import 'package:md3_clock/widgets/weekday_picker.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/weekday.dart';
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
        (weekday) => _MenuListTile<Weekday>(
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
        (style) => _MenuListTile<ClockStyle>(
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
      _SwitchValueListenableListTile(
        title: Text('Exibir horário com segundos'),
        value: clock.showSeconds,
        onChanged: clock.setShowSeconds,
      ),
      _SwitchValueListenableListTile(
        title: Text('Relógio de casa automático'),
        subtitle: Text('Ao viajar para outro fuso horário, adicionar um '
            'relógio para casa.'),
        value: clock.autoHomeTimezoneClock,
        onChanged: clock.setAutoHomeTimezoneClock,
      ),
      _HomeTimezoneTile(
        controller: clock,
      ),
      _ListTile(
        title: Text('Alterar data e hora'),
        onTap: clock.requestShowChangeDateTime,
      ),
    ];
  }

  List<Widget> _alarmsSection(BuildContext context) {
    final alarms = controller.alarms.unwrap;
    return [
      const _SectionStartTitleAndSpacing(title: 'Alarmes'),
      _AlarmVolumeTile(
        value: alarms.volume,
        onChanged: alarms.setVolume,
      ),
      alarms.volumeButtonsBehavior
          .map(
            (volumeButtonsBehavior) => _MenuListTile<VolumeButtonsBehavior>(
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
      _SwitchValueListenableListTile(
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
      _SwitchValueListenableListTile(
        title: Text('Modo noturno'),
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
  Widget build(BuildContext context) => _ListTile(
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
      .map((autoHomeTimezoneClock) => _ListTile(
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

class _SwitchValueListenableListTile extends StatelessWidget {
  const _SwitchValueListenableListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.onChanged,
    this.onLongPress,
  }) : super(key: key);
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final ValueListenable<bool> value;
  final void Function(bool)? onChanged;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => value
      .map((value) => _SwitchListTile(
            title: title,
            subtitle: subtitle,
            leading: leading,
            value: value,
            onChanged: onChanged,
            onLongPress: onLongPress,
          ))
      .build();
}

class _MenuListTile<T> extends StatefulWidget {
  const _MenuListTile({
    Key? key,
    this.initialValue,
    required this.itemBuilder,
    this.onSelected,
    this.onCancel,
    required this.title,
    this.subtitle,
    this.menuKind,
  }) : super(key: key);
  final T? initialValue;
  final List<MD3PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final ValueChanged<T>? onSelected;
  final VoidCallback? onCancel;
  final Widget title;
  final Widget? subtitle;
  final MD3PopupMenuKind? menuKind;

  @override
  State<_MenuListTile<T>> createState() => _MenuListTileState<T>();
}

class _MenuListTileState<T> extends State<_MenuListTile<T>> {
  final GlobalKey titleKey = GlobalKey();
  void _onTap() {
    final selfRect = rectFromContext(context);
    final titleRect = rectFromContext(titleKey.currentContext!);
    // TODO:
    final targetRect = RelativeRect.fromLTRB(
      max(selfRect.left, titleRect.right + 16),
      selfRect.top,
      selfRect.right,
      selfRect.bottom,
    );

    showMD3Menu<T>(
            context: context,
            position: titleRect,
            items: widget.itemBuilder(context),
            initialValue: widget.initialValue,
            menuKind: widget.menuKind)
        .then(
      (e) => e is T ? widget.onSelected?.call(e) : widget.onCancel?.call(),
    );
  }

  @override
  Widget build(BuildContext context) => _ListTile(
        title: KeyedSubtree(
          key: titleKey,
          child: widget.title,
        ),
        subtitle: widget.subtitle,
        onTap: _onTap,
        disabled: widget.onSelected == null,
      );
}

class _SwitchListTile extends StatelessWidget {
  const _SwitchListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.onChanged,
    this.onLongPress,
  }) : super(key: key);
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool value;
  final void Function(bool)? onChanged;
  final VoidCallback? onLongPress;

  void _onTap() => onChanged?.call(!value);

  @override
  Widget build(BuildContext context) => _ListTile(
        title: title,
        subtitle: subtitle,
        onTap: _onTap,
        onLongPress: onLongPress,
        leading: leading,
        trailing: MD3Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        disabled: onChanged == null,
      );
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.disabled = false,
  }) : super(key: key);
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool disabled;

  static const _kTextStyleDuration = kThemeChangeDuration;

  Widget _text(
    BuildContext context,
    Color foreground,
    Color foregroundVariant,
  ) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: _kTextStyleDuration,
              style: context.textTheme.titleSmall.copyWith(
                color: foreground,
                height: 20 / 15.5,
                fontSize: 15.5,
              ),
              child: title,
            ),
            if (subtitle != null)
              AnimatedDefaultTextStyle(
                duration: _kTextStyleDuration,
                style: context.textTheme.bodyMedium.copyWith(
                  color: foregroundVariant,
                  height: 18 / 13.1,
                  fontSize: 13.1,
                ),
                child: subtitle!,
              )
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    const enabled = <MaterialState>{};
    const disabled = <MaterialState>{MaterialState.disabled};

    final states = this.disabled ? disabled : enabled;

    final foreground = MD3DisablableColor(context.colorScheme.onSurface);
    final foregroundVariant =
        MD3DisablableColor(context.colorScheme.onSurfaceVariant);

    final effectiveForeground = foreground.resolve(states);
    final effectiveForegroundVariant = foregroundVariant.resolve(states);

    return InkWell(
      onTap: this.disabled ? null : onTap,
      onLongPress: this.disabled ? null : onLongPress,
      mouseCursor: MaterialStateMouseCursor.clickable,
      overlayColor: MD3StateOverlayColor(
        context.colorScheme.onSurface,
        context.stateOverlayOpacity,
      ),
      child: IconTheme.merge(
        data: IconThemeData(
          opacity: effectiveForegroundVariant.opacity,
          color: effectiveForegroundVariant,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: _text(
                  context,
                  effectiveForeground,
                  effectiveForegroundVariant,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ]
            ],
          ),
        ),
      ),
    );
  }
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
