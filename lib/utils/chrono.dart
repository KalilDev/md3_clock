import 'dart:async';

import 'package:flutter/foundation.dart';

Stream<Duration> createTickerStream(
    [Duration period = const Duration(milliseconds: 32)]) {
  DateTime? lastTickTime;
  final baseTickerStream =
      Stream<DateTime>.periodic(period, (_) => DateTime.now());
  StreamSubscription<DateTime>? baseTickerSubscription;
  StreamController<Duration> tickerStreamController = StreamController();
  void onBaseTick(DateTime tickTime) {
    Duration elapsed;
    // On debug mode, add an fixed tick time, as you (me) may be stepping
    // through the debugger, making the elapsed time be wayy longer than the
    // expected period
    if (kDebugMode) {
      elapsed = period;
    } else {
      elapsed = tickTime.difference(lastTickTime!);
      lastTickTime = tickTime;
    }
    tickerStreamController.add(elapsed);
  }

  tickerStreamController
    ..onListen = () {
      lastTickTime = DateTime.now();
      baseTickerSubscription = baseTickerStream.listen(onBaseTick);
    }
    ..onPause = () {
      lastTickTime = null;
      baseTickerSubscription!.pause();
    }
    ..onResume = () {
      lastTickTime = DateTime.now();
      baseTickerSubscription!.resume();
      print(' resumed base ticker');
    }
    ..onCancel = () => baseTickerSubscription!.cancel();
  return tickerStreamController.stream;
}
