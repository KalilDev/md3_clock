import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:value_notifier/value_notifier.dart';

abstract class ITick implements IDisposable {
  void start({bool paused = false});
  void pause();
  void resume();
  void stop();
  ValueListenable<Duration> get elapsedTick;
  ValueListenable<Duration> get elapsedTotal;
}

abstract class ICreateTickers implements IDisposable {
  ITick createTicker();
}

class StreamTickerFactory extends IDisposableBase implements ICreateTickers {
  final Duration period;
  StreamTickerFactory({
    this.period = const Duration(milliseconds: 32),
  });

  @override
  ITick createTicker({
    Duration? period,
  }) =>
      StreamTicker(
        period: period ?? this.period,
      );
}

class FlutterTickerFactory extends IDisposableBase implements ICreateTickers {
  final EventNotifier<Duration> _didTick;
  late final Ticker _ticker;

  FlutterTickerFactory({
    required TickerProvider vsync,
  }) : _didTick = EventNotifier() {
    _ticker = vsync.createTicker(_onTick);
    _ticker.start();
  }

  @override
  ITick createTicker() => ValueListenableTicker(_didTick.viewNexts());

  @override
  void dispose() {
    _didTick.dispose();
    _ticker.dispose();
    super.dispose();
  }

  Duration _lastTick = Duration.zero;
  void _onTick(Duration totalTime) {
    final elapsed = totalTime - _lastTick;
    _didTick.add(elapsed);
    _lastTick = totalTime;
  }
}

class StreamTicker extends IDisposableBase implements ITick {
  final Duration period;
  final ValueNotifier<Duration> _elapsedTotal;
  final EventNotifier<Duration> _elapsedTick = EventNotifier();

  StreamTicker({
    this.period = const Duration(milliseconds: 32),
  }) : _elapsedTotal = ValueNotifier(Duration.zero);

  @override
  ValueListenable<Duration> get elapsedTotal => _elapsedTotal.view();
  @override
  ValueListenable<Duration> get elapsedTick => _elapsedTick.viewNexts();

  void _onBaseTick(DateTime tickTime) {
    Duration elapsed;
    // On debug mode, add an fixed tick time, as you (me) may be stepping
    // through the debugger, making the elapsed time be wayy longer than the
    // expected period
    if (kDebugMode) {
      elapsed = period;
    } else {
      elapsed = tickTime.difference(_lastTickTime!);
      _lastTickTime = tickTime;
    }
    _onElapsed(elapsed);
  }

  void _onElapsed(Duration duration) {
    _elapsedTotal.value += duration;
    _elapsedTick.add(duration);
  }

  @override
  void pause() {
    _lastTickTime = null;
    _baseTickerSubscription!.pause();
  }

  @override
  void resume() {
    _lastTickTime = DateTime.now();
    _baseTickerSubscription!.resume();
    print(' resumed base ticker');
  }

  @override
  void start({bool paused = false}) {
    if (_baseTickerSubscription != null) {
      _baseTickerSubscription!.cancel();
    }
    _lastTickTime = DateTime.now();
    _baseTickerSubscription = _baseTickerStream.listen(_onBaseTick);
    if (paused) {
      _baseTickerSubscription!.pause();
    }
    _elapsedTotal.value = Duration.zero;
  }

  @override
  void stop() {
    _lastTickTime = null;
    _baseTickerSubscription?.cancel();
    _baseTickerSubscription = null;
  }

  @override
  void dispose() {
    _lastTickTime = null;
    _baseTickerSubscription?.cancel();
    _baseTickerSubscription = null;
    IDisposable.disposeAll([
      _elapsedTotal,
      _elapsedTick,
    ]);
    super.dispose();
  }

  DateTime? _lastTickTime;
  late final _baseTickerStream =
      Stream<DateTime>.periodic(period, (_) => DateTime.now());
  StreamSubscription<DateTime>? _baseTickerSubscription;
}

enum TickerState {
  stopped,
  paused,
  running,
}

class TickerBase extends IDisposableBase implements ITick {
  final ValueNotifier<Duration> _elapsedTotal;
  final EventNotifier<Duration> _elapsedTick = EventNotifier();

  TickerBase() : _elapsedTotal = ValueNotifier(Duration.zero);

  @override
  ValueListenable<Duration> get elapsedTotal => _elapsedTotal.view();
  @override
  ValueListenable<Duration> get elapsedTick => _elapsedTick.viewNexts();

  TickerState _state = TickerState.stopped;

  void onTick(Duration duration) {
    if (_state != TickerState.running) {
      return;
    }
    _elapsedTotal.value += duration;
    _elapsedTick.add(duration);
  }

  @override
  void pause() {
    if (_state == TickerState.stopped) {
      return;
    }
    _state = TickerState.paused;
  }

  @override
  void resume() {
    if (_state == TickerState.stopped) {
      return;
    }
    _state = TickerState.running;
  }

  @override
  void start({bool paused = false}) {
    if (_state != TickerState.stopped) {
      return;
    }
    _state = paused ? TickerState.paused : TickerState.running;
  }

  @override
  void stop() {
    _state = TickerState.stopped;
  }

  @override
  void dispose() {
    IDisposable.disposeAll([
      _elapsedTotal,
      _elapsedTick,
    ]);
    super.dispose();
  }
}

class ValueListenableTicker extends TickerBase {
  late final IDisposable _didTickConnection;

  ValueListenableTicker(ValueListenable<Duration> didTick) {
    _didTickConnection = didTick.tap(onTick);
  }

  @override
  void dispose() {
    _didTickConnection.dispose();
    super.dispose();
  }
}
