import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:value_notifier/value_notifier.dart';

import '../../model/city.dart';

abstract class IFetchCityQueries {
  Future<List<City>> fetchQuery(String query);
}

class DummyQueryFetcher extends IFetchCityQueries {
  static const values = [
    City(
      'Texas City',
      'TX',
      'EUA',
      const Duration(hours: -6),
    ),
    City(
      'Frankfurt',
      'TX',
      'Alemanha',
      const Duration(hours: 1),
    ),
    City(
      'Florianopolis',
      'SC',
      'Brasil',
      const Duration(hours: -2),
    ),
  ];

  @override
  Future<List<City>> fetchQuery(String query) =>
      Future.delayed(const Duration(seconds: 10)).then((_) =>
          values.take(Random().nextInt(values.length + 1)).toList()..shuffle());
}

class WorldClockSearchController
    extends ControllerBase<WorldClockSearchController> {
  final ValueNotifier<String> _queryString;
  final IFetchCityQueries queryFetcher;
  final ProxyValueListenable<AsyncSnapshot<List<City>>> _connectedQueryFetch =
      ProxyValueListenable(SingleValueListenable(AsyncSnapshot.nothing()));

  // late final because debouncing causes an side effecct
  late final ValueListenable<String> _debouncedQueryString = _queryString
      .view()
      .tap(print)
      .debounce(
        wait: const Duration(milliseconds: 300),
        maxWait: const Duration(seconds: 2),
        leading: true,
      )
      .tap(print)
      .unique();

  WorldClockSearchController(String initialQuery, this.queryFetcher)
      : _queryString = ValueNotifier(initialQuery);

  ValueListenable<String> get debouncedQueryString =>
      _debouncedQueryString.view();

  ValueListenable<bool> get isLoading =>
      _connectedQueryFetch.view().map((snap) {
        switch (snap.connectionState) {
          case ConnectionState.waiting:
          case ConnectionState.active:
            return true;
          case ConnectionState.none:
          case ConnectionState.done:
            return false;
        }
      });

  // late final because whereKeepingPrevious creates an side effect.
  // Contains the data of the connected query, if it has data, and the data of
  // the previous query if it doesnt have data, with an empty result
  // representing both no queries and an empty query.
  late final ValueListenable<List<City>> _queryResult = _connectedQueryFetch
      .view()
      .map((snap) => snap.hasData ? snap.requireData : null)
      .whereKeepingPrevious((data) => data != null, initial: () => const [])
      .castNotNull();

  ValueListenable<List<City>> get queryResult => _queryResult.view();

  void setQuery(String query) => _queryString.value = query;

  void init() {
    super.init();
    debouncedQueryString.tap(_fetchQuery, includeInitial: true);
  }

  void _fetchQuery(String query) {
    if (query.isEmpty) {
      _connectedQueryFetch.base =
          SingleValueListenable(AsyncSnapshot.nothing());
      return;
    }
    _connectedQueryFetch.base =
        queryFetcher.fetchQuery(query).toValueListenable();
  }
}
