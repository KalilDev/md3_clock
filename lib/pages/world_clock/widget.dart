import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/current_time/controller.dart';
import 'package:md3_clock/components/current_time/widget.dart';
import 'package:md3_clock/components/sorted_animated_list/widget.dart';
import 'package:md3_clock/model/duration_components.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:md3_clock/utils/layout.dart';
import 'package:md3_clock/utils/theme.dart';
import 'package:md3_clock/widgets/duration.dart';
import 'package:md3_clock/widgets/fab_safe_area.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/city.dart';
import '../../widgets/search.dart';
import 'controller.dart';
import 'search_delegate.dart';

class _DimissedCityCard extends StatelessWidget {
  const _DimissedCityCard({
    Key? key,
    required this.startToEnd,
  }) : super(key: key);
  final bool startToEnd;

  @override
  Widget build(BuildContext context) => ColoredCard(
        /// TODO: Fix colored card on contexts with [FilledCardTheme]
        style: ColoredCard.styleFrom(
          backgroundColor: context.colorScheme.errorContainer,
          foregroundColor: context.colorScheme.onErrorContainer,
          stateLayerOpacity: context.stateOverlayOpacity,
        ),
        color: context.colorScheme.errorScheme,
        child: SizedBox(
          height: _CityCard.kHeight,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment:
                  startToEnd ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Icon(Icons.delete_outlined),
              ],
            ),
          ),
        ),
      );
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    Key? key,
    required this.model,
    required this.onDelete,
  }) : super(key: key);
  final CityViewModel model;
  final ValueChanged<DismissDirection> onDelete;

  static const kHeight = 96.0;

  static String _offsetToString(Duration offset) {
    final components = DurationComponents.fromDuration(offset);
    return '${offset.isNegative ? '-' : '+'}'
            '${components.hours}h' +
        (components.minutes == 0
            ? ''
            : '${components.minutes.toString().padLeft(2, '0')}min');
  }

  Widget _cityNameAndOffset(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.city.name,
            style: context.textTheme.bodyLarge.copyWith(
              color: context.colorScheme.onSurface,
            ),
          ),
          Text(
            _offsetToString(model.timeZoneOffsetLocal),
            style: context.textTheme.bodyMedium.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          )
        ],
      );

  Widget _timeAtCity(BuildContext context) => DefaultTextStyle.merge(
        style: TextStyle(color: context.colorScheme.onSurface),
        child: TimeOfDayWidget(
          timeOfDay: model.currentOffsetTime,
          numberStyle: context.textTheme.displaySmall,
          separatorStyle: context.textTheme.headlineLarge,
        ),
      );

  Widget _buildInnerCard(BuildContext context) => FilledCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _cityNameAndOffset(context),
            const Spacer(),
            _timeAtCity(context),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: CardStyle.kMaxCardSpacing / 4,
        ),
        child: _DismissibleFilledCard(
          key: ObjectKey(model.city),
          onDismissed: onDelete,
          child: Container(
            height: kHeight,
            color: context.colorScheme.errorContainer,
            child: _buildInnerCard(context),
          ),
          background: const _DimissedCityCard(
            startToEnd: true,
          ),
          secondaryBackground: const _DimissedCityCard(
            startToEnd: false,
          ),
        ),
      );
}

class _ClockPortraitBody extends StatelessWidget {
  const _ClockPortraitBody({Key? key, required this.controller})
      : super(key: key);
  final ClockPageController controller;

  void _onItemDelete(CityViewModel city) {
    controller.onRemoveCity(city);
  }

  Widget _buildClockCard(
    BuildContext context,
    CityViewModel cityClock,
    Animation<double> animation,
  ) =>
      _ListEntranceTransition(
        animation: animation,
        child: _CityCard(
          model: cityClock,
          onDelete: (_) => _onItemDelete(cityClock),
        ),
      );

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CurrentTime(
                  controller: controller.currentTimeController,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                vertical: CardStyle.kMaxCardSpacing / 2),
            sliver: SliverSortedAnimatedList<CityViewModel>(
              controller: controller.clocksList,
              itemBuilder: _buildClockCard,
              removalDuration: Duration.zero,
            ),
          ),
          SliverPadding(padding: FabSafeArea.fabPaddingFor(context)),
        ],
      );
}

class _ClockLandscapeBody extends StatelessWidget {
  const _ClockLandscapeBody({Key? key, required this.controller})
      : super(key: key);
  final ClockPageController controller;
  void _onItemDelete(CityViewModel city) {
    controller.onRemoveCity(city);
  }

  Widget _buildClockCard(
    BuildContext context,
    CityViewModel cityClock,
    Animation<double> animation,
  ) =>
      _ListEntranceTransition(
        animation: animation,
        child: _CityCard(
          model: cityClock,
          onDelete: (_) => _onItemDelete(cityClock),
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            flex: 4,
            child: CurrentTime(
              controller: controller.currentTimeController,
              layout: CurrentTimeLayout.expandedCenterAligned,
            ),
          ),
          Expanded(
            flex: 3,
            child: SortedAnimatedList(
              padding: const EdgeInsets.symmetric(
                  vertical: CardStyle.kMaxCardSpacing / 2),
              controller: controller.clocksList,
              itemBuilder: _buildClockCard,
              removalDuration: Duration.zero,
            ),
          ),
        ],
      );
}

class ClockPage extends StatelessWidget {
  const ClockPage({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final ClockPageController controller;

  Widget _cardTheme(
    BuildContext context, {
    required Widget child,
  }) =>
      FilledCardTheme(
        data: FilledCardThemeData(
          style: CardStyle(
              clipBehavior: Clip.antiAlias,
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
              ),
              backgroundColor: MD3ElevationTintableColor(
                context.colorScheme.surface,
                MD3ElevationLevel.surfaceTint(context.colorScheme),
                MaterialStateProperty.all(context.elevation.level2),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    26,
                  ),
                ),
              )),
        ),
        child: child,
      );

  Widget _buildBody(BuildContext context) => isPortrait(context)
      ? _ClockPortraitBody(controller: controller)
      : _ClockLandscapeBody(controller: controller);

  @override
  Widget build(BuildContext context) => _cardTheme(
        context,
        child: _buildBody(context),
      );
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
      ).then((city) => city == null
          ? null
          : controller.onAddCity(
              city,
            ));
    }

    if (useLargeFab(context)) {
      return MD3FloatingActionButton.large(
        colorScheme: primarySchemeOf(context),
        onPressed: onPressed,
        child: IconTheme.merge(
          data: const IconThemeData(size: 24),
          child: child,
        ),
      );
    }
    return MD3FloatingActionButton(
      colorScheme: primarySchemeOf(context),
      onPressed: onPressed,
      child: child,
    );
  }
}

class _DismissibleFilledCard extends StatelessWidget {
  const _DismissibleFilledCard({
    required Key key,
    required this.child,
    this.background,
    this.secondaryBackground,
    this.onDismissed,
  }) : super(key: key);
  final Widget child;
  final Widget? background;
  final Widget? secondaryBackground;
  final ValueChanged<DismissDirection>? onDismissed;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = FilledCardTheme.of(context).style ?? const CardStyle();
    // TODO: Unfuck. This is an workaround so that the background color
    // does not leak in a subpixel margin
    final workaroundShape = MaterialStateProperty.resolveWith(
      (states) {
        final defaultShape = defaultStyle.shape!.resolve(states);
        if (defaultShape is RoundedRectangleBorder) {
          return RoundedRectangleBorder(
            borderRadius:
                defaultShape.borderRadius.subtract(BorderRadius.circular(2)),
            side: defaultShape.side,
          );
        }
        return defaultShape;
      },
    );
    return FilledCard(
      style: CardStyle(
        padding: MaterialStateProperty.all(EdgeInsets.zero),
        clipBehavior: Clip.antiAlias,
      ),
      child: FilledCardTheme(
        data: FilledCardThemeData(
          style: defaultStyle.copyWith(
            elevation: MaterialStateProperty.all(context.elevation.level0),
            shape: workaroundShape,
          ),
        ),
        child: Dismissible(
          key: key!,
          background: background,
          secondaryBackground: secondaryBackground,
          onDismissed: onDismissed,
          child: child,
        ),
      ),
    );
  }
}

class _ListEntranceTransition extends StatelessWidget {
  const _ListEntranceTransition({
    Key? key,
    required this.animation,
    required this.child,
  }) : super(key: key);
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Interval(2 / 3, 1),
          ),
          child: child,
        ),
      );
}
