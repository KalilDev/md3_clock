import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/model/weekday.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/widgets/duration.dart';
import 'package:md3_clock/widgets/icon/generated_resources.dart';
import 'package:md3_clock/widgets/icon/widget.dart';
import 'package:md3_clock/widgets/list_tile.dart';
import 'package:md3_clock/widgets/onboarding/generated_resource.dart';
import 'package:md3_clock/widgets/onboarding/widget.dart';
import 'package:md3_clock/widgets/weekday_picker.dart';
import 'package:value_notifier/value_notifier.dart';
import 'package:vector_drawable/vector_drawable.dart';

class SleepPage extends StatelessWidget {
  const SleepPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          primary: true,
          child: Padding(
            padding: InheritedMD3BodyMargin.of(context).padding +
                EdgeInsets.symmetric(
                  vertical: 8.0,
                ),
            child: ListBody(
              children: [
                Text(
                  'Defina uma hora de dormir consistente para ter uma noite de sono melhor',
                  style: context.textTheme.titleLarge.copyWith(
                    color: context.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Mantenha um horário regular para dormir, desconecte-se do smartphone e ouça sons relaxantes',
                  style: context.textTheme.bodyMedium.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: AutoRepeatingAnimatedVector(
                      vector: avd_bedtime_onboarding_graphic.body,
                    ),
                  ),
                ),
                Center(
                  child: FilledButton(
                      onPressed: () => Navigator.of(context)
                          .push<WakeupTimeDialogResult>(
                            MaterialPageRoute(
                              builder: (context) => WakeupTimeDialog(),
                            ),
                          )
                          .then(print),
                      child: Text('Iniciar')),
                )
              ],
            ),
          ),
        ),
      );
}

class _CustomDialog extends StatelessWidget {
  const _CustomDialog({
    Key? key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  }) : super(key: key);
  final Widget icon;
  final Widget title;
  final Widget body;
  final Widget actions;

  @override
  Widget build(BuildContext context) => MD3AdaptativeScaffold(
        body: MD3ScaffoldBody.noMargin(
          child: Builder(
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: InheritedMD3BodyMargin.of(context).padding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 56),
                      IconTheme(
                        data: IconThemeData(
                            color: context.colorScheme.onSurface, opacity: 1),
                        child: icon,
                      ),
                      SizedBox(
                        height: 18,
                      ),
                      DefaultTextStyle(
                        style: context.textTheme.titleLarge.copyWith(
                          color: context.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        child: title,
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 26,
                ),
                Flexible(
                  child: SingleChildScrollView(child: body),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: InheritedMD3BodyMargin.of(context).padding,
                  child: actions,
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
}

class WakeupTimeDialog extends StatefulWidget {
  const WakeupTimeDialog({Key? key}) : super(key: key);

  @override
  State<WakeupTimeDialog> createState() => _WakeupTimeDialogState();
}

class WakeupTimeDialogResult {
  final TimeOfDay wakingTime;
  final Weekdays weekdays;
  final bool sunriseAlarm;
  final bool vibrate;
  final SleepTimeDialogResult sleepResult;

  WakeupTimeDialogResult(
    this.wakingTime,
    this.weekdays,
    this.sunriseAlarm,
    this.vibrate,
    this.sleepResult,
  );
}

Duration differenceBetweenTimes(TimeOfDay a, TimeOfDay b) =>
    Duration(
      hours: a.hour,
      minutes: a.minute,
    ) -
    Duration(
      hours: b.hour,
      minutes: b.minute,
    );
String timeDiffString(TimeOfDay a, TimeOfDay b) {
  var diff = differenceBetweenTimes(a, b);
  diff = (diff.isNegative
      ? differenceBetweenTimes(a, b)
      : -differenceBetweenTimes(b, a));

  final hour = diff.inHours % Duration.hoursPerDay;
  final min = diff.inMinutes % Duration.minutesPerHour;
  final short = hour != 0 && min != 0;
  final hourSuffix = short ? 'h' : 'horas';
  final minSuffix = short ? 'min' : 'minutos';
  final hourString = hour == 0 ? '' : '$hour $hourSuffix';
  final minString = min == 0 ? '' : '$min $minSuffix';
  return hourString.isEmpty ? minString : '$hourString $minString';
}

class _WakeupTimeDialogState extends State<WakeupTimeDialog> {
  late TimeOfDay wakingTime = TimeOfDay(hour: 7, minute: 0);
  void _setWakingTime(TimeOfDay time) => setState(() => wakingTime = time);

  late Weekdays weekdays = Weekdays(Weekday.values.toSet());
  void _setWeekday(Weekday day) =>
      setState(() => weekdays = weekdays.toggle(day));

  late bool sunriseAlarm = true;
  void _setSunriseAlarm(bool val) => setState(() => sunriseAlarm = val);

  late bool vibrate = true;
  void _setVibrate(bool val) => setState(() => vibrate = val);

  ListBody _buildBody(BuildContext context) => ListBody(
        children: [
          SizedBox(
            height: 22,
          ),
          Padding(
            padding: InheritedMD3BodyMargin.of(context).padding,
            child: _TimePicker(
              value: wakingTime,
              onChange: _setWakingTime,
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: InheritedMD3BodyMargin.of(context).padding,
            child: WeekdaysPicker(
              value: weekdays,
              onTap: _setWeekday,
              isActive: true,
            ),
          ),
          Divider(
            indent: 0,
            endIndent: 0,
          ),
          MD3CheckboxListTile(
            leading: Icon(Icons.wb_sunny_outlined),
            title: Text('Alarme Nascer do sol'),
            subtitle: Text('Ilumina a tela lentamente antes do alarme'),
            value: sunriseAlarm,
            onChanged: (v) => _setSunriseAlarm(v!),
          ),
          SizedBox(height: 8),
          MD3ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Som'),
            subtitle: Text('Padrão (Cesium)'),
          ),
          SizedBox(height: 8),
          MD3CheckboxListTile(
            leading: Icon(Icons.vibration),
            title: Text('Vibrar'),
            value: vibrate,
            onChanged: (v) => _setVibrate(v!),
          ),
        ],
      );

  void _pushSkipToNext(BuildContext context) => Navigator.of(context)
      .push<SleepTimeDialogResult>(
        MaterialPageRoute(
          builder: (context) => SleepTimeDialog(
            wakingTime: const TimeOfDay(hour: 7, minute: 0),
          ),
        ),
      )
      .then(
        (value) => value == null
            ? null
            : Navigator.of(context).pop<WakeupTimeDialogResult>(
                WakeupTimeDialogResult(
                  const TimeOfDay(hour: 7, minute: 0),
                  Weekdays(Weekday.values.toSet()),
                  true,
                  true,
                  value,
                ),
              ),
      );

  void _pushNext(BuildContext context) => Navigator.of(context)
      .push<SleepTimeDialogResult>(
        MaterialPageRoute(
          builder: (context) => SleepTimeDialog(
            wakingTime: wakingTime,
          ),
        ),
      )
      .then(
        (value) => value == null
            ? null
            : Navigator.of(context).pop<WakeupTimeDialogResult>(
                WakeupTimeDialogResult(
                  wakingTime,
                  weekdays,
                  sunriseAlarm,
                  vibrate,
                  value,
                ),
              ),
      );

  @override
  Widget build(BuildContext context) => _CustomDialog(
        icon: Icon(Icons.alarm),
        title: Text(
          'Definir o horário frequente para acordar',
          style: context.textTheme.titleLarge.copyWith(
            color: context.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        body: Builder(
          builder: _buildBody,
        ),
        actions: Row(
          children: [
            OutlinedButton(
              onPressed: () => _pushSkipToNext(context),
              child: Text('Pular'),
            ),
            Spacer(),
            FilledButton(
              onPressed: () => _pushNext(context),
              child: Text('Próxima'),
            ),
          ],
        ),
      );
}

TimeOfDay timeOfDayAfter(
  TimeOfDay time,
  Duration duration,
) {
  final inMinutes = time.hour * TimeOfDay.minutesPerHour + time.minute;
  const minutesPerDay = TimeOfDay.minutesPerHour * TimeOfDay.hoursPerDay;
  // add an day so that we can handle durations between -1day to +1day
  final inMinutesAdded =
      minutesPerDay + inMinutes + (duration.inMinutes % minutesPerDay);
  return TimeOfDay(
    hour: (inMinutesAdded ~/ TimeOfDay.minutesPerHour) % TimeOfDay.hoursPerDay,
    minute: inMinutesAdded % TimeOfDay.minutesPerHour,
  );
}

class SleepTimeDialog extends StatefulWidget {
  const SleepTimeDialog({
    Key? key,
    required this.wakingTime,
  }) : super(key: key);
  final TimeOfDay wakingTime;

  @override
  State<SleepTimeDialog> createState() => _SleepTimeDialogState();
}

class SleepTimeDialogResult {
  final TimeOfDay wakingTime;
  final Weekdays weekdays;
  final Duration? notificationReminder;

  SleepTimeDialogResult(
    this.wakingTime,
    this.weekdays,
    this.notificationReminder,
  );
}

class _SleepTimeDialogState extends State<SleepTimeDialog> {
  late TimeOfDay sleepingTime = timeOfDayAfter(
    widget.wakingTime,
    Duration(hours: -8),
  );
  void _setSleepingTime(TimeOfDay time) => setState(() => sleepingTime = time);

  late Weekdays weekdays = Weekdays(Weekday.values.toSet());
  void _setWeekday(Weekday day) =>
      setState(() => weekdays = weekdays.toggle(day));

  late Duration? notificationReminder = Duration(minutes: 15);
  void _setNotificationReminder(Duration? reminder) =>
      setState(() => notificationReminder = reminder);

  void popWithDefaults(BuildContext context) =>
      Navigator.of(context).pop<SleepTimeDialogResult>(
        SleepTimeDialogResult(
          timeOfDayAfter(
            widget.wakingTime,
            Duration(hours: -8),
          ),
          Weekdays(Weekday.values.toSet()),
          Duration(minutes: 15),
        ),
      );
  void popWithResult(BuildContext context) =>
      Navigator.of(context).pop<SleepTimeDialogResult>(
        SleepTimeDialogResult(
          sleepingTime,
          weekdays,
          notificationReminder,
        ),
      );

  ListBody _buildBody(BuildContext context) => ListBody(
        children: [
          Padding(
            padding: InheritedMD3BodyMargin.of(context).padding,
            child: _TimePicker(
              value: sleepingTime,
              onChange: _setSleepingTime,
            ),
          ),
          SizedBox(height: 9),
          Text(
            timeDiffString(widget.wakingTime, sleepingTime),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: InheritedMD3BodyMargin.of(context).padding,
            child: WeekdaysPicker(
              value: weekdays,
              onTap: _setWeekday,
              isActive: true,
            ),
          ),
          Divider(
            indent: 0,
            endIndent: 0,
          ),
          _SelectionDialogListTile<Duration?>(
            leading: Icon(Icons.notification_important_outlined),
            selectedItem: notificationReminder,
            onSelected: _setNotificationReminder,
            title: Text('Notificação de lembrete'),
            items: [
              Duration(minutes: 15),
              Duration(minutes: 30),
              Duration(minutes: 45),
              Duration(minutes: 60),
              null,
            ],
            buildItemLabel: (context, item) => Text(
              item == null
                  ? 'Desativado'
                  : (item.inHours == 0
                          ? '${item.inMinutes} min'
                          : '${item.inHours} hora') +
                      ' antes da hora de dormir',
            ),
          ),
          SizedBox(height: 8),
          const MD3ListTile(
            title: Text(''),
            subtitle: Text(''),
          ),
          SizedBox(height: 8),
          const MD3ListTile(
            title: Text(''),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => _CustomDialog(
        icon: VectorIcon(
          icon: avd_tab_bedtime_white_24dp.body.drawable.resource!.body,
        ),
        title: Text(
          'Definir hora de dormir e silenciar o dispositivo',
        ),
        body: Builder(
          builder: _buildBody,
        ),
        actions: Row(
          children: [
            OutlinedButton(
              onPressed: () => popWithDefaults(context),
              child: Text('Pular'),
            ),
            Spacer(),
            FilledButton(
              onPressed: () => popWithResult(context),
              child: Text('Concluído'),
            ),
          ],
        ),
      );
}

class _Result<T> {
  final T value;

  _Result(this.value);
}

class _SelectionDialogListTile<T> extends StatelessWidget {
  const _SelectionDialogListTile({
    Key? key,
    this.leading,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    required this.buildItemLabel,
  }) : super(key: key);
  final Widget? leading;
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
        leading: leading,
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

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    Key? key,
    required this.value,
    required this.onChange,
  }) : super(key: key);
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChange;

  Widget _buildButton(
    BuildContext context, {
    required Widget icon,
    required VoidCallback onPressed,
  }) =>
      Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        color: context.elevation.level2.overlaidColor(
          context.colorScheme.surface,
          MD3ElevationLevel.surfaceTint(context.colorScheme),
        ),
        child: SizedBox.square(
          dimension: 48,
          child: IconButton(
            onPressed: onPressed,
            icon: icon,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(
                context,
                icon: Icon(Icons.remove),
                onPressed: () {
                  final inMinutes =
                      value.hour * TimeOfDay.minutesPerHour + value.minute;
                  final inMinutesAdded =
                      TimeOfDay.hoursPerDay * TimeOfDay.minutesPerHour +
                          inMinutes -
                          15;
                  final nextVal = TimeOfDay(
                    hour: (inMinutesAdded ~/ TimeOfDay.minutesPerHour) %
                        TimeOfDay.hoursPerDay,
                    minute: inMinutesAdded % TimeOfDay.minutesPerHour,
                  );
                  onChange(nextVal);
                },
              ),
              SizedBox(width: 24),
              InkWell(
                child: TimeOfDayWidget(
                  timeOfDay: value,
                  padHours: true,
                  numberStyle: context.textTheme.displayLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  showTimePicker(
                    context: context,
                    initialTime: value,
                  ).then(
                    (nextValue) =>
                        nextValue == null ? null : onChange(nextValue),
                  );
                },
              ),
              SizedBox(width: 24),
              _buildButton(
                context,
                icon: Icon(Icons.add),
                onPressed: () {
                  final inMinutes =
                      value.hour * TimeOfDay.minutesPerHour + value.minute;
                  final inMinutesAdded = inMinutes + 15;
                  final nextVal = TimeOfDay(
                    hour: (inMinutesAdded ~/ TimeOfDay.minutesPerHour) %
                        TimeOfDay.hoursPerDay,
                    minute: inMinutesAdded % TimeOfDay.minutesPerHour,
                  );
                  onChange(nextVal);
                },
              ),
            ],
          ),
        ),
      );
}
