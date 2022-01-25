import 'package:flutter/cupertino.dart';

bool isPortrait(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.portrait;
bool isLandscape(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.landscape;
bool isTiny(BuildContext context) =>
    MediaQuery.of(context).size.shortestSide < 360;
