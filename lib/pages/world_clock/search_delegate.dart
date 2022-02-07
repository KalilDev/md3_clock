import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/widgets/switcher.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/city.dart';
import '../../widgets/search.dart';
import 'controller.dart';
import 'search_delegate_controller.dart';

class CitySearchDelegate extends MD3SearchDelegate<City> {
  final WorldClockSearchController controller =
      WorldClockSearchController('', DummyQueryFetcher())..init();
  String get searchFieldLabel => 'Pesquisar uma cidade';
  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            onPressed: () => query = '',
            icon: const Icon(Icons.clear),
          ),
      ];
  @override
  set query(String value) {
    controller.setQuery(value);
    super.query = value;
  }

  @override
  Widget? buildLeading(BuildContext context) => const BackButton();

  Widget _buildCity(BuildContext context, City city) => ListTile(
        title: Text(city.titleString),
        trailing: Text(TimeOfDay.fromDateTime(city.now).toString()),
        onTap: () => Navigator.of(context).pop(city),
      );

  Widget buildScaffold(
    BuildContext context,
    Widget textField,
    Widget? body,
  ) =>
      MD3AdaptativeScaffold(
        appBar: buildAppbar(context, textField),
        body: MD3ScaffoldBody.noMargin(
          child: SharedAxisSwitcher(
            type: SharedAxisTransitionType.scaled,
            child: body ?? const SizedBox.expand(),
          ),
        ),
      );

  @override
  Widget buildResults(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) => Padding(
                padding: InheritedMD3BodyMargin.of(context).padding,
                child: controller.queryResult.buildView(
                  builder: (context, results, _) => results.isEmpty
                      ? _EmptySearchBody(controller: controller)
                      : ListView.builder(
                          itemBuilder: (context, i) =>
                              _buildCity(context, results[i]),
                          itemCount: results.length,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: controller.isLoading
                .map((isLoading) =>
                    isLoading ? LinearProgressIndicator() : SizedBox())
                .build(),
          ),
        ],
      );

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);

  @override
  PreferredSizeWidget buildAppbar(BuildContext context, Widget textField) =>
      MD3SmallAppBar(
        leading: buildLeading(context),
        actions: buildActions(context),
        title: TextField(
          onChanged: (e) => controller.setQuery(e),
        ),
        bottom: _BottomDecoration(),
      );
}

class _EmptySearchBody extends StatelessWidget {
  const _EmptySearchBody({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final WorldClockSearchController controller;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 124,
              color: context.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            Text(
              'Pesquisar uma cidade',
              style: context.textTheme.bodyLarge.copyWith(
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            )
          ],
        ),
      );
}

class _BottomDecoration extends StatelessWidget implements PreferredSizeWidget {
  const _BottomDecoration({
    Key? key,
    // one device pixel
    this.size = 0.0,
  }) : super(key: key);
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BottomDecorationPainter(
          color: context.colorScheme.outline,
          size: size,
        ),
        size: preferredSize,
      );

  @override
  Size get preferredSize => Size.fromHeight(size);
}

class _BottomDecorationPainter extends CustomPainter {
  final Color color;
  final double size;

  _BottomDecorationPainter({
    required this.color,
    required this.size,
  });
  @override
  void paint(Canvas canvas, Size size) {
    print(size);
    paintBorder(
      canvas,
      Offset.zero & size,
      bottom: BorderSide(
        color: color,
        width: this.size,
      ),
    );
  }

  @override
  bool shouldRepaint(_BottomDecorationPainter oldDelegate) =>
      color != oldDelegate.color || size != oldDelegate.size;
}
