import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/model/weekday.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/alarm.dart';
import '../../widgets/weekday_picker.dart';
import 'controller.dart';

class _ActivatableDefaultTextStyle extends StatelessWidget {
  const _ActivatableDefaultTextStyle({
    Key? key,
    required this.activeTextStyle,
    required this.inactiveTextStyle,
    required this.isActive,
    required this.child,
  }) : super(key: key);

  final TextStyle activeTextStyle;
  final TextStyle inactiveTextStyle;
  final ValueListenable<bool> isActive;
  final Widget child;

  @override
  Widget build(BuildContext context) => isActive.buildView(
        builder: (context, isActive, child) => AnimatedDefaultTextStyle(
          child: child!,
          style: isActive ? activeTextStyle : inactiveTextStyle,
          duration: const Duration(milliseconds: 300),
        ),
        child: child,
      );
}

class _AlarmItemBasicSection extends StatelessWidget {
  const _AlarmItemBasicSection({Key? key, required this.controller})
      : super(key: key);
  final AlarmItemController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlarmItemTimeText(controller: controller),
        SizedBox(
          height: kMinInteractiveDimension,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: _kExtraLeftPadding),
              _ActivatableDefaultTextStyle(
                isActive: controller.active,
                activeTextStyle: context.textTheme.bodyMedium.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.normal,
                ),
                inactiveTextStyle: context.textTheme.bodyMedium.copyWith(
                  color: context.colorScheme.outline,
                  fontWeight: FontWeight.normal,
                ),
                child: controller.scheduleString.buildView(
                  builder: (context, scheduleString, _) => Text(scheduleString),
                ),
              ),
              const Spacer(),
              controller.active.buildView(
                builder: (context, isActive, _) => MD3Switch(
                  value: isActive,
                  onChanged: (v) => controller.setActive(v),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _AlarmItemTimeText extends StatelessWidget {
  const _AlarmItemTimeText({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final AlarmItemController controller;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        controller.maybeExpand();
        showTimePicker(
          context: context,
          initialTime: controller.time.value,
        ).then(
          (time) => time == null ? null : controller.setTime(time),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
        child: _ActivatableDefaultTextStyle(
          activeTextStyle: context.textTheme.displayMedium.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          inactiveTextStyle: context.textTheme.displayMedium.copyWith(
            color: context.colorScheme.outline,
            fontWeight: FontWeight.normal,
          ),
          isActive: controller.active,
          child: controller.timeString.buildView(
            builder: (context, timeString, _) => Text(timeString),
          ),
        ),
      ),
    );
  }
}

const _kExtraLeftPadding = 4.0;
const _kListTileIconSize = 24.0;

class _ListTile extends StatelessWidget {
  const _ListTile({
    Key? key,
    this.leading,
    required this.title,
    this.trailing,
    this.isActive,
    this.contentPadding,
    this.onTap,
    this.dense = true,
  }) : super(key: key);
  final Widget? leading;
  final Widget title;
  final Widget? trailing;
  final ValueListenable<bool>? isActive;
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback? onTap;
  final bool dense;

  Widget _buildTile(BuildContext context, bool isActive) {
    final titleStyle = context.textTheme.titleSmall.copyWith(
      fontWeight: FontWeight.normal,
      color: isActive
          ? context.colorScheme.onSurface
          : context.colorScheme.outline,
    );
    final iconTheme = IconThemeData(
      opacity: 1,
      color: context.colorScheme.onSurface,
      size: _kListTileIconSize,
    );
    return ListTile(
      leading: leading == null
          ? null
          : IconTheme(
              data: iconTheme,
              child: leading!,
            ),
      minLeadingWidth: 36,
      horizontalTitleGap: 4,
      title: DefaultTextStyle.merge(
        style: titleStyle,
        child: title,
      ),
      contentPadding:
          contentPadding ?? const EdgeInsets.only(left: _kExtraLeftPadding),
      trailing: trailing,
      dense: dense,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) => isActive == null
      ? _buildTile(context, true)
      : isActive!.buildView(
          builder: (context, isActive, _) => _buildTile(context, isActive),
        );
}

class _WeekdaysAndActive {
  final bool isActive;
  final Weekdays weekdays;

  _WeekdaysAndActive(this.isActive, this.weekdays);
}

class _AlarmItemHiddenSection extends StatelessWidget {
  const _AlarmItemHiddenSection({Key? key, required this.controller})
      : super(key: key);
  final AlarmItemController controller;

  void showAlarmDialog(BuildContext context) {
    print('TODO');
  }

  Widget _buildWeekdaysPicker(
    BuildContext context,
    Weekdays weekdays,
    bool isActive,
  ) =>
      Padding(
        padding: const EdgeInsets.only(
          left: _kExtraLeftPadding,
          right: 56 / 3,
        ),
        child: WeekdaysPicker(
          value: weekdays,
          onTap: controller.toggleWeekday,
          isActive: isActive,
        ),
      );

  @override
  Widget build(BuildContext context) => _ExpansionAnimation(
        isExpanded: controller.expanded,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            controller.active
                .bind(
                  (active) => controller.weekdays
                      .map((weekdays) => _WeekdaysAndActive(active, weekdays)),
                )
                .buildView(
                  builder: (context, weekdaysAndActive, _) =>
                      _buildWeekdaysPicker(
                    context,
                    weekdaysAndActive.weekdays,
                    weekdaysAndActive.isActive,
                  ),
                ),
            const SizedBox(height: 8),
            controller.alarm.buildView(
              builder: (context, alarm, _) => _ListTile(
                leading: Icon(
                  alarm.source == AlarmSource.sounds ? Icons.alarm : Icons.stop,
                ),
                title: Text(alarm.text),
                onTap: () => showAlarmDialog(context),
              ),
            ),
            _ListTile(
              leading: const Icon(Icons.vibration),
              title: const Text('Vibrar'),
              onTap: controller.toggleVibrate,
              trailing: controller.vibrate.buildView(
                builder: (context, vibrate, _) => Checkbox(
                  value: vibrate,
                  onChanged: (v) => controller.setVibrate(v!),
                ),
              ),
            ),
            IntrinsicWidth(
              child: _ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Excluir'),
                contentPadding: const EdgeInsets.only(
                  left: _kExtraLeftPadding,
                  right: 8,
                ),
                onTap: controller.delete,
              ),
            ),
          ],
        ),
      );
}

class _ExpansionAnimation extends StatelessWidget {
  const _ExpansionAnimation({
    Key? key,
    required this.isExpanded,
    required this.child,
  }) : super(key: key);
  final ValueListenable<bool> isExpanded;
  final Widget child;

  @override
  Widget build(BuildContext context) => isExpanded.buildView(
        builder: (
          context,
          expanded,
          child,
        ) =>
            TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(end: expanded ? 1.0 : 0.0),
          curve: const Interval(2 / 3, 1.0, curve: Curves.easeOut),
          builder: (context, opacity, child) => Opacity(
            opacity: opacity,
            child: child,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: KeyedSubtree(
              key: ObjectKey(expanded),
              child: expanded ? child! : const SizedBox(width: double.infinity),
            ),
          ),
        ),
        child: child,
      );
}

class _MarkerAndIsExpanded {
  final String marker;
  final bool isExpanded;

  _MarkerAndIsExpanded(this.marker, this.isExpanded);
}

class _MarkerDialog extends StatefulWidget {
  const _MarkerDialog({
    Key? key,
    required this.initialMarker,
  }) : super(key: key);
  final String initialMarker;

  @override
  __MarkerDialogState createState() => __MarkerDialogState();
}

class __MarkerDialogState extends State<_MarkerDialog> {
  late final _controller = TextEditingController(text: widget.initialMarker);
  late final _titleString =
      widget.initialMarker.isEmpty ? 'Adicionar marcador' : 'Alterar marcador';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = Navigator.of(context).pop<String>;
    return MD3BasicDialog(
      title: Text(_titleString),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Marcador',
        ),
        onSubmitted: pop,
      ),
      actions: [
        TextButton(
          onPressed: pop,
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => pop(_controller.text),
          child: const Text('Ok'),
        ),
      ],
    );
  }
}

class _AlarmItemMarker extends StatelessWidget {
  const _AlarmItemMarker({Key? key, required this.controller})
      : super(key: key);
  final AlarmItemController controller;

  void _showDialog(
    BuildContext context,
    String marker,
  ) {
    showDialog(
      context: context,
      builder: (context) => _MarkerDialog(
        initialMarker: marker,
      ),
    ).then(
      (value) => value == null ? null : controller.setMarker(value),
    );
  }

  Widget _markerTile(
    BuildContext context,
    String marker,
  ) {
    final titleStyle = TextStyle(
      color: marker.isEmpty
          ? context.colorScheme.outline
          : context.colorScheme.onSurface,
    );
    final text = marker.isEmpty ? 'Adicionar marcador' : marker;
    return Padding(
      padding: const EdgeInsets.only(right: 48.0),
      child: _ListTile(
        dense: true,
        leading: const Icon(Icons.label_outline),
        onTap: () => _showDialog(context, marker),
        title: Text(
          text,
          style: titleStyle,
        ),
      ),
    );
  }

  Widget _buildMarker(BuildContext context, String marker, bool isExpanded) {
    if (!isExpanded) {
      return marker.isEmpty
          ? const SizedBox(
              width: double.infinity,
            )
          : ListTile(
              contentPadding: const EdgeInsets.only(left: _kExtraLeftPadding),
              dense: true,
              title: Text(
                marker,
                style: context.textTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.normal,
                  color: context.colorScheme.onSurface,
                ),
              ),
            );
    } else {
      return _markerTile(context, marker);
    }
  }

  Widget _buildMarkerTransition(
    BuildContext context,
    String marker, {
    required Widget child,
  }) =>
      marker.isNotEmpty
          ? AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 400,
              ),
              switchInCurve: const Interval(2 / 3, 1),
              switchOutCurve: const Interval(0, 1 / 3),
              child: child,
            )
          : _ExpansionAnimation(
              isExpanded: controller.expanded,
              child: child,
            );

  Widget _buildChild(BuildContext context, bool isExpanded, String marker) =>
      _buildMarkerTransition(
        context,
        marker,
        child: _buildMarker(
          context,
          marker,
          isExpanded,
        ),
      );

  @override
  Widget build(BuildContext context) => controller.expanded
      .bind(
        (isExpanded) => controller.marker.map(
          (marker) => _MarkerAndIsExpanded(
            marker,
            isExpanded,
          ),
        ),
      )
      .buildView(
        builder: (context, markerAndIsExpanded, _) => _buildChild(
          context,
          markerAndIsExpanded.isExpanded,
          markerAndIsExpanded.marker,
        ),
      );
}

void focusScrollviewOnContext(BuildContext context) {
  final scrollController = Scrollable.of(context);
  if (scrollController == null) {
    return;
  }
  final contextRenderBox = context.findRenderObject()!;
  final scrollPosition = scrollController.position;
  scrollPosition.ensureVisible(
    contextRenderBox,
    alignment: 0,
    duration: const Duration(milliseconds: 300),
  );
}

const _kAnimationDuration = const Duration(milliseconds: 300);

class _ExpandableHeight extends StatelessWidget {
  const _ExpandableHeight({
    Key? key,
    required this.isExpanded,
    required this.hidden,
    required this.expanded,
    this.child,
  }) : super(key: key);
  final ValueListenable<bool> isExpanded;
  final double hidden;
  final double expanded;
  final Widget? child;

  @override
  Widget build(BuildContext context) => isExpanded.buildView(
        builder: (context, isExpanded, child) => TweenAnimationBuilder<double>(
          tween: Tween(end: isExpanded ? expanded : hidden),
          duration: _kAnimationDuration,
          builder: (context, height, child) => SizedBox(
            height: height,
            child: child,
          ),
          child: child,
        ),
        child: child,
      );
}

class AlarmItemCard extends StatelessWidget {
  const AlarmItemCard({Key? key, required this.controller}) : super(key: key);
  final AlarmItemController controller;

  @override
  Widget build(BuildContext context) {
    return FilledCard(
      onPressed: controller.toggleExpanded,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AlarmItemMarker(controller: controller),
              _AlarmItemBasicSection(controller: controller),
              _AlarmItemHiddenSection(controller: controller),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _AlarmItemExpansionButton(controller: controller),
          ),
        ],
      ),
    );
  }
}

extension on AlarmItemController {
  IDisposableValueListenable<String> get timeString => time.map(
        (time) =>
            time.hour.toString().padLeft(2, '0') +
            ':' +
            time.minute.toString().padLeft(2, '0'),
      );
  IDisposableValueListenable<String> get scheduleString => weekdays.bind(
        (weekdays) => active.map(
          (active) => weekdays.text(active),
        ),
      );
}

class _RotationAnimation extends StatelessWidget {
  const _RotationAnimation({
    Key? key,
    required this.isRotated,
    this.initialAngle = pi / 2,
    required this.child,
  }) : super(key: key);
  final ValueListenable<bool> isRotated;
  final double initialAngle;
  final Widget child;

  @override
  Widget build(BuildContext context) => isRotated.buildView(
        builder: (context, isRotated, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: isRotated ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, rotation, child) => Transform.rotate(
            angle: (rotation * pi) + initialAngle,
            child: child,
          ),
          child: child,
        ),
      );
}

class _AlarmItemExpansionButton extends StatelessWidget {
  const _AlarmItemExpansionButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final AlarmItemController controller;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: controller.toggleExpanded,
        icon: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.surfaceVariant,
          ),
          child: _RotationAnimation(
            isRotated: controller.expanded.map((expanded) => !expanded),
            child: const Icon(
              Icons.chevron_left,
              size: 18,
            ),
          ),
        ),
      );
}

extension on Weekdays {
  String text(bool isActive) {
    if (active.isEmpty) {
      return isActive ? 'Hoje' : 'Não programado';
    }
    final orderedSelected =
        Weekday.values.where((e) => active.contains(e)).toList();
    if (orderedSelected.length == 1) {
      return orderedSelected.single.longText;
    }
    if (orderedSelected.length == Weekday.values.length) {
      return 'Todos os dias';
    }
    return orderedSelected.map((e) => e.text).join(', ');
  }
}

extension on Weekday {
  String get text {
    switch (this) {
      case Weekday.saturday:
        return 'sáb';
      case Weekday.sunday:
        return 'dom';
      case Weekday.monday:
        return 'seg';
      case Weekday.tuesday:
        return 'ter';
      case Weekday.wednsday:
        return 'qua';
      case Weekday.thursday:
        return 'qui';
      case Weekday.friday:
        return 'sex';
    }
  }

  String get letter {
    switch (this) {
      case Weekday.saturday:
        return 'S';
      case Weekday.sunday:
        return 'D';
      case Weekday.monday:
        return 'S';
      case Weekday.tuesday:
        return 'T';
      case Weekday.wednsday:
        return 'Q';
      case Weekday.thursday:
        return 'Q';
      case Weekday.friday:
        return 'S';
    }
  }

  String get longText {
    switch (this) {
      case Weekday.saturday:
        return 'sábado';
      case Weekday.sunday:
        return 'domingo';
      case Weekday.monday:
        return 'segunda-feira';
      case Weekday.tuesday:
        return 'terça-feira';
      case Weekday.wednsday:
        return 'quarta-feira';
      case Weekday.thursday:
        return 'quinta-feira';
      case Weekday.friday:
        return 'sexta-feira';
    }
  }
}
