// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/widgets/switcher.dart';

/// Shows a full screen search page and returns the search result selected by
/// the user when the page is closed.
///
/// The search page consists of an app bar with a search field and a body which
/// can either show suggested search queries or the search results.
///
/// The appearance of the search page is determined by the provided
/// `delegate`. The initial query string is given by `query`, which defaults
/// to the empty string. When `query` is set to null, `delegate.query` will
/// be used as the initial query.
///
/// This method returns the selected search result, which can be set in the
/// [MD3MD3SearchDelegate.close] call. If the search page is closed with the system
/// back button, it returns null.
///
/// A given [MD3MD3SearchDelegate] can only be associated with one active [showSearch]
/// call. Call [MD3MD3SearchDelegate.close] before re-using the same delegate instance
/// for another [showSearch] call.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// search page to the [Navigator] furthest from or nearest to the given
/// `context`. By default, `useRootNavigator` is `false` and the search page
/// route created by this method is pushed to the nearest navigator to the
/// given `context`. It can not be `null`.
///
/// The transition to the search page triggered by this method looks best if the
/// screen triggering the transition contains an [AppBar] at the top and the
/// transition is called from an [IconButton] that's part of [AppBar.actions].
/// The animation provided by [MD3MD3SearchDelegate.transitionAnimation] can be used
/// to trigger additional animations in the underlying page while the search
/// page fades in or out. This is commonly used to animate an [AnimatedIcon] in
/// the [AppBar.leading] position e.g. from the hamburger menu to the back arrow
/// used to exit the search page.
///
/// ## Handling emojis and other complex characters
/// {@macro flutter.widgets.EditableText.onChanged}
///
/// See also:
///
///  * [MD3MD3SearchDelegate] to define the content of the search page.
Future<T?> showMD3Search<T>({
  required BuildContext context,
  required MD3SearchDelegate<T> delegate,
  String? query = '',
  bool useRootNavigator = false,
}) {
  assert(delegate != null);
  assert(context != null);
  assert(useRootNavigator != null);
  delegate.query = query ?? delegate.query;
  delegate._currentBody = _SearchBody.suggestions;
  return Navigator.of(context, rootNavigator: useRootNavigator)
      .push(_MD3SearchPageRoute<T>(
    delegate: delegate,
  ));
}

/// Delegate for [showSearch] to define the content of the search page.
///
/// The search page always shows an [AppBar] at the top where users can
/// enter their search queries. The buttons shown before and after the search
/// query text field can be customized via [MD3SearchDelegate.buildLeading]
/// and [MD3SearchDelegate.buildActions]. Additionally, a widget can be placed
/// across the bottom of the [AppBar] via [MD3SearchDelegate.buildBottom].
///
/// The body below the [AppBar] can either show suggested queries (returned by
/// [MD3SearchDelegate.buildSuggestions]) or - once the user submits a search  - the
/// results of the search as returned by [MD3SearchDelegate.buildResults].
///
/// [MD3SearchDelegate.query] always contains the current query entered by the user
/// and should be used to build the suggestions and results.
///
/// The results can be brought on screen by calling [MD3SearchDelegate.showResults]
/// and you can go back to showing the suggestions by calling
/// [MD3SearchDelegate.showSuggestions].
///
/// Once the user has selected a search result, [MD3SearchDelegate.close] should be
/// called to remove the search page from the top of the navigation stack and
/// to notify the caller of [showSearch] about the selected search result.
///
/// A given [MD3SearchDelegate] can only be associated with one active [showSearch]
/// call. Call [MD3SearchDelegate.close] before re-using the same delegate instance
/// for another [showSearch] call.
///
/// ## Handling emojis and other complex characters
/// {@macro flutter.widgets.EditableText.onChanged}
abstract class MD3SearchDelegate<T> {
  /// Constructor to be called by subclasses which may specify
  /// [searchFieldLabel], either [searchFieldStyle] or [searchFieldDecorationTheme],
  /// [keyboardType] and/or [textInputAction]. Only one of [searchFieldLabel]
  /// and [searchFieldDecorationTheme] may be non-null.
  ///
  /// {@tool snippet}
  /// ```dart
  /// class CustomSearchHintDelegate extends MD3SearchDelegate<String> {
  ///   CustomSearchHintDelegate({
  ///     required String hintText,
  ///   }) : super(
  ///     searchFieldLabel: hintText,
  ///     keyboardType: TextInputType.text,
  ///     textInputAction: TextInputAction.search,
  ///   );
  ///
  ///   @override
  ///   Widget buildLeading(BuildContext context) => const Text('leading');
  ///
  ///   @override
  ///   PreferredSizeWidget buildBottom(BuildContext context) {
  ///     return const PreferredSize(
  ///        preferredSize: Size.fromHeight(56.0),
  ///        child: Text('bottom'));
  ///   }
  ///
  ///   @override
  ///   Widget buildSuggestions(BuildContext context) => const Text('suggestions');
  ///
  ///   @override
  ///   Widget buildResults(BuildContext context) => const Text('results');
  ///
  ///   @override
  ///   List<Widget> buildActions(BuildContext context) => <Widget>[];
  /// }
  /// ```
  /// {@end-tool}
  MD3SearchDelegate() {
    assert(searchFieldStyle == null || searchFieldDecorationTheme == null);
  }

  /// Suggestions shown in the body of the search page while the user types a
  /// query into the search field.
  ///
  /// The delegate method is called whenever the content of [query] changes.
  /// The suggestions should be based on the current [query] string. If the query
  /// string is empty, it is good practice to show suggested queries based on
  /// past queries or the current context.
  ///
  /// Usually, this method will return a [ListView] with one [ListTile] per
  /// suggestion. When [ListTile.onTap] is called, [query] should be updated
  /// with the corresponding suggestion and the results page should be shown
  /// by calling [showResults].
  Widget buildSuggestions(BuildContext context);

  /// The results shown after the user submits a search from the search page.
  ///
  /// The current value of [query] can be used to determine what the user
  /// searched for.
  ///
  /// This method might be applied more than once to the same query.
  /// If your [buildResults] method is computationally expensive, you may want
  /// to cache the search results for one or more queries.
  ///
  /// Typically, this method returns a [ListView] with the search results.
  /// When the user taps on a particular search result, [close] should be called
  /// with the selected result as argument. This will close the search page and
  /// communicate the result back to the initial caller of [showSearch].
  Widget buildResults(BuildContext context);

  PreferredSizeWidget buildAppbar(BuildContext context, Widget textField);

  Widget buildScaffold(
    BuildContext context,
    Widget textField,
    Widget? body,
  ) =>
      MD3AdaptativeScaffold(
        appBar: buildAppbar(context, textField),
        body: SharedAxisSwitcher(
          type: SharedAxisTransitionType.scaled,
          child: body ?? const SizedBox.expand(),
        ),
      );

  /// The current query string shown in the [AppBar].
  ///
  /// The user manipulates this string via the keyboard.
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] this
  /// string should be updated to that suggestion via the setter.
  String get query => _queryTextController.text;

  /// Changes the current query string.
  ///
  /// Setting the query string programmatically moves the cursor to the end of the text field.
  set query(String value) {
    assert(query != null);
    _queryTextController.text = value;
    _queryTextController.selection = TextSelection.fromPosition(
        TextPosition(offset: _queryTextController.text.length));
  }

  /// Transition from the suggestions returned by [buildSuggestions] to the
  /// [query] results returned by [buildResults].
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] the
  /// screen should typically transition to the page showing the search
  /// results for the suggested query. This transition can be triggered
  /// by calling this method.
  ///
  /// See also:
  ///
  ///  * [showSuggestions] to show the search suggestions again.
  void showResults(BuildContext context) {
    _focusNode?.unfocus();
    _currentBody = _SearchBody.results;
  }

  /// Transition from showing the results returned by [buildResults] to showing
  /// the suggestions returned by [buildSuggestions].
  ///
  /// Calling this method will also put the input focus back into the search
  /// field of the [AppBar].
  ///
  /// If the results are currently shown this method can be used to go back
  /// to showing the search suggestions.
  ///
  /// See also:
  ///
  ///  * [showResults] to show the search results.
  void showSuggestions(BuildContext context) {
    assert(_focusNode != null,
        '_focusNode must be set by route before showSuggestions is called.');
    _focusNode!.requestFocus();
    _currentBody = _SearchBody.suggestions;
  }

  /// Closes the search page and returns to the underlying route.
  ///
  /// The value provided for `result` is used as the return value of the call
  /// to [showSearch] that launched the search initially.
  void close(BuildContext context, T result) {
    _currentBody = null;
    _focusNode?.unfocus();
    Navigator.of(context)
      ..popUntil((Route<dynamic> route) => route == _route)
      ..pop(result);
  }

  /// The hint text that is shown in the search field when it is empty.
  ///
  /// If this value is set to null, the value of
  /// `MaterialLocalizations.of(context).searchFieldLabel` will be used instead.
  String? get searchFieldLabel => null;

  /// The style of the [searchFieldLabel].
  ///
  /// If this value is set to null, the value of the ambient [Theme]'s
  /// [InputDecorationTheme.hintStyle] will be used instead.
  ///
  /// Only one of [searchFieldStyle] or [searchFieldDecorationTheme] can
  /// be non-null.
  TextStyle? get searchFieldStyle => null;

  /// The [InputDecorationTheme] used to configure the search field's visuals.
  ///
  /// Only one of [searchFieldStyle] or [searchFieldDecorationTheme] can
  /// be non-null.
  InputDecorationTheme? get searchFieldDecorationTheme => null;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to the default value specified in [TextField].
  TextInputType? get keyboardType => null;

  /// The text input action configuring the soft keyboard to a particular action
  /// button.
  ///
  /// Defaults to [TextInputAction.search].
  TextInputAction get textInputAction => TextInputAction.search;

  /// [Animation] triggered when the search pages fades in or out.
  ///
  /// This animation is commonly used to animate [AnimatedIcon]s of
  /// [IconButton]s returned by [buildLeading] or [buildActions]. It can also be
  /// used to animate [IconButton]s contained within the route below the search
  /// page.
  Animation<double> get transitionAnimation => _proxyAnimation;

  // The focus node to use for manipulating focus on the search page. This is
  // managed, owned, and set by the _MD3SearchPageRoute using this delegate.
  FocusNode? _focusNode;

  final TextEditingController _queryTextController = TextEditingController();

  final ProxyAnimation _proxyAnimation =
      ProxyAnimation(kAlwaysDismissedAnimation);

  final ValueNotifier<_SearchBody?> _currentBodyNotifier =
      ValueNotifier<_SearchBody?>(null);

  _SearchBody? get _currentBody => _currentBodyNotifier.value;
  set _currentBody(_SearchBody? value) {
    _currentBodyNotifier.value = value;
  }

  _MD3SearchPageRoute<T>? _route;
}

/// Describes the body that is currently shown under the [AppBar] in the
/// search page.
enum _SearchBody {
  /// Suggested queries are shown in the body.
  ///
  /// The suggested queries are generated by [MD3SearchDelegate.buildSuggestions].
  suggestions,

  /// Search results are currently shown in the body.
  ///
  /// The search results are generated by [MD3SearchDelegate.buildResults].
  results,
}

class _MD3SearchPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _MD3SearchPageRoute({
    required this.delegate,
  }) : assert(delegate != null) {
    assert(
      delegate._route == null,
      'The ${delegate.runtimeType} instance is currently used by another active '
      'search. Please close that search by calling close() on the MD3SearchDelegate '
      'before opening another search with the same delegate instance.',
    );
    delegate._route = this;
  }

  final MD3SearchDelegate<T> delegate;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => false;

  @override
  Animation<double> createAnimation() {
    final Animation<double> animation = super.createAnimation();
    delegate._proxyAnimation.parent = animation;
    return animation;
  }

  @override
  Widget buildContent(
    BuildContext context,
  ) {
    return _SearchPage<T>(
      delegate: delegate,
      animation: animation!,
    );
  }

  @override
  void didComplete(T? result) {
    super.didComplete(result);
    assert(delegate._route == this);
    delegate._route = null;
    delegate._currentBody = null;
  }
}

class _SearchPage<T> extends StatefulWidget {
  const _SearchPage({
    required this.delegate,
    required this.animation,
  });

  final MD3SearchDelegate<T> delegate;
  final Animation<double> animation;

  @override
  State<StatefulWidget> createState() => _SearchPageState<T>();
}

class _SearchPageState<T> extends State<_SearchPage<T>> {
  // This node is owned, but not hosted by, the search page. Hosting is done by
  // the text field.
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.delegate._queryTextController.addListener(_onQueryChanged);
    widget.animation.addStatusListener(_onAnimationStatusChanged);
    widget.delegate._currentBodyNotifier.addListener(_onSearchBodyChanged);
    focusNode.addListener(_onFocusChanged);
    widget.delegate._focusNode = focusNode;
  }

  @override
  void dispose() {
    super.dispose();
    widget.delegate._queryTextController.removeListener(_onQueryChanged);
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    widget.delegate._currentBodyNotifier.removeListener(_onSearchBodyChanged);
    widget.delegate._focusNode = null;
    focusNode.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    if (widget.delegate._currentBody == _SearchBody.suggestions) {
      focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(_SearchPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delegate != oldWidget.delegate) {
      oldWidget.delegate._queryTextController.removeListener(_onQueryChanged);
      widget.delegate._queryTextController.addListener(_onQueryChanged);
      oldWidget.delegate._currentBodyNotifier
          .removeListener(_onSearchBodyChanged);
      widget.delegate._currentBodyNotifier.addListener(_onSearchBodyChanged);
      oldWidget.delegate._focusNode = null;
      widget.delegate._focusNode = focusNode;
    }
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus &&
        widget.delegate._currentBody != _SearchBody.suggestions) {
      widget.delegate.showSuggestions(context);
    }
  }

  void _onQueryChanged() {
    setState(() {
      // rebuild ourselves because query changed.
    });
  }

  void _onSearchBodyChanged() {
    setState(() {
      // rebuild ourselves because search body changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final ThemeData theme = Theme.of(context);
    final String searchFieldLabel = widget.delegate.searchFieldLabel ??
        MaterialLocalizations.of(context).searchFieldLabel;
    Widget? body;
    switch (widget.delegate._currentBody) {
      case _SearchBody.suggestions:
        body = KeyedSubtree(
          key: const ValueKey<_SearchBody>(_SearchBody.suggestions),
          child: widget.delegate.buildSuggestions(context),
        );
        break;
      case _SearchBody.results:
        body = KeyedSubtree(
          key: const ValueKey<_SearchBody>(_SearchBody.results),
          child: widget.delegate.buildResults(context),
        );
        break;
      case null:
        break;
    }

    late final String routeName;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        routeName = '';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        routeName = searchFieldLabel;
    }

    final textFieldStyle = context.textTheme.bodyLarge.copyWith(
      color: context.colorScheme.onSurface,
    );

    final textField = TextField(
      controller: widget.delegate._queryTextController,
      focusNode: focusNode,
      style: textFieldStyle,
      textInputAction: widget.delegate.textInputAction,
      keyboardType: widget.delegate.keyboardType,
      onSubmitted: (String _) {
        widget.delegate.showResults(context);
      },
      decoration: InputDecoration(
        hintText: searchFieldLabel,
        border: InputBorder.none,
        hintStyle: textFieldStyle,
      ),
    );

    return Semantics(
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: routeName,
      child: widget.delegate.buildScaffold(
        context,
        textField,
        body,
      ),
    );
  }
}
