import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:value_notifier/value_notifier.dart';

import '../pages/home/home.dart';

class MD3SwitchValueListenableListTile extends StatelessWidget {
  const MD3SwitchValueListenableListTile({
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
      .map((value) => MD3SwitchListTile(
            title: title,
            subtitle: subtitle,
            leading: leading,
            value: value,
            onChanged: onChanged,
            onLongPress: onLongPress,
          ))
      .build();
}

class MD3CheckboxValueListenableListTile extends StatelessWidget {
  const MD3CheckboxValueListenableListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.tristate = false,
    this.onChanged,
    this.onLongPress,
  }) : super(key: key);
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final ValueListenable<bool?> value;
  final bool tristate;
  final void Function(bool?)? onChanged;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => value
      .map((value) => MD3CheckboxListTile(
            title: title,
            subtitle: subtitle,
            leading: leading,
            value: value,
            tristate: tristate,
            onChanged: onChanged,
            onLongPress: onLongPress,
          ))
      .build();
}

class MD3MenuListTile<T> extends StatefulWidget {
  const MD3MenuListTile({
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
  State<MD3MenuListTile<T>> createState() => _MD3MenuListTileState<T>();
}

class _MD3MenuListTileState<T> extends State<MD3MenuListTile<T>> {
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
  Widget build(BuildContext context) => MD3ListTile(
        title: KeyedSubtree(
          key: titleKey,
          child: widget.title,
        ),
        subtitle: widget.subtitle,
        onTap: _onTap,
        disabled: widget.onSelected == null,
      );
}

class MD3SwitchListTile extends StatelessWidget {
  const MD3SwitchListTile({
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
  Widget build(BuildContext context) => MD3ListTile(
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

class MD3CheckboxListTile extends StatelessWidget {
  const MD3CheckboxListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.tristate = false,
    this.onChanged,
    this.onLongPress,
  }) : super(key: key);
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool? value;
  final bool tristate;
  final void Function(bool?)? onChanged;
  final VoidCallback? onLongPress;

  void _onTap() => onChanged?.call(!value!);

  @override
  Widget build(BuildContext context) => MD3ListTile(
        title: title,
        subtitle: subtitle,
        onTap: value == null ? null : _onTap,
        onLongPress: onLongPress,
        leading: leading,
        trailing: Checkbox(
          value: value,
          tristate: tristate,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        disabled: onChanged == null,
      );
}

class MD3ListTile extends StatelessWidget {
  const MD3ListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.disabled = false,
  }) : super(key: key);
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool disabled;

  static const _kTextStyleDuration = kThemeChangeDuration;

  Widget _text(
    BuildContext context,
    Color foreground,
    Color foregroundVariant,
  ) =>
      Column(
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
    final effectivePadding =
        padding?.resolve(Directionality.of(context)) ?? EdgeInsets.all(16.0);

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
          padding: EdgeInsets.only(
            left: effectivePadding.left,
            right: effectivePadding.right,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: effectivePadding.top,
                    bottom: effectivePadding.bottom,
                  ),
                  child: _text(
                    context,
                    effectiveForeground,
                    effectiveForegroundVariant,
                  ),
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
