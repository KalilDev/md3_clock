import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:md3_clock/components/navigation_manager/controller.dart';
import 'package:md3_clock/pages/preferences/controller.dart';
import 'package:value_notifier/value_notifier.dart';

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

  @override
  Widget build(BuildContext context) => MD3AdaptativeScaffold(
        body: MD3ScaffoldBody.noMargin(
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
              SliverFillRemaining(
                child: Placeholder(),
              )
            ],
          ),
        ),
      );
}

class _PreferencesSliverList extends StatelessWidget {
  const _PreferencesSliverList({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final PreferencesController controller;

  @override
  Widget build(BuildContext context) =>
      SliverList(delegate: SliverChildListDelegate([]));
}
