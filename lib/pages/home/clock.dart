import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/pages/home/navigation_delegate.dart';
import 'package:value_notifier/value_notifier.dart';

class ClockPageController extends IDisposableBase {}

class ClockPage extends StatelessWidget {
  const ClockPage({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final ClockPageController controller;

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

class City {
  final String name;
  final String? stateName;
  final String countryName;

  final Duration timeZoneOffset;

  City(
    this.name,
    this.stateName,
    this.countryName,
    this.timeZoneOffset,
  );
  DateTime get now => DateTime.now().add(timeZoneOffset);
  String get titleString =>
      '$name,${stateName != null ? ' $stateName,' : ''} $countryName';
}

class CitySearchDelegate extends SearchDelegate<City> {
  CitySearchDelegate() : super(searchFieldLabel: 'Pesquisar uma cidade');
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
    super.query = value;
    if (value.isEmpty) {
      return;
    }
  }

  @override
  Widget? buildLeading(BuildContext context) => const BackButton();

  ValueNotifier<List<City>> queryResults = ValueNotifier([]);

  Widget _buildCity(BuildContext context, City city) => ListTile(
        title: Text(city.titleString),
        trailing: Text(TimeOfDay.fromDateTime(city.now).toString()),
        onTap: () => Navigator.of(context).pop(city),
      );
  @override
  ThemeData appBarTheme(BuildContext context) => context.theme.copyWith(
        appBarTheme: const AppBarTheme(
          elevation: 0,
        ),
      );

  @override
  Widget buildResults(BuildContext context) => queryResults.buildView(
        builder: (context, results, _) => results.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search,
                      size: 80,
                      color:
                          context.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Pesquisar uma cidade',
                      style: context.textTheme.bodyMedium.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.6),
                      ),
                    )
                  ],
                ),
              )
            : ListView.builder(
                itemBuilder: (context, i) => _buildCity(context, results[i]),
                itemCount: results.length,
              ),
      );

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
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
      showSearch<City>(
        context: context,
        delegate: CitySearchDelegate(),
      ).then((city) {
        print('todo');
      });
    }

    if (useLargeFab(context)) {
      return MD3FloatingActionButton.large(onPressed: onPressed, child: child);
    }
    return MD3FloatingActionButton(onPressed: onPressed, child: child);
  }
}
