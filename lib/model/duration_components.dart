class DurationComponents {
  final bool isNegative;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final int miliseconds;
  final int microseconds;

  const DurationComponents.raw(
    this.isNegative,
    this.days,
    this.hours,
    this.minutes,
    this.seconds,
    this.miliseconds,
    this.microseconds,
  );

  const DurationComponents({
    this.isNegative = false,
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
    this.miliseconds = 0,
    this.microseconds = 0,
  });

  factory DurationComponents.fromDuration(Duration d) {
    final isNegative = d.isNegative;
    d = isNegative ? -d : d;
    final days = d.inDays;
    final hours = d.inHours - (d.inDays * Duration.hoursPerDay);
    final minutes = d.inMinutes - (d.inHours * Duration.minutesPerHour);
    final seconds = d.inSeconds - (d.inMinutes * Duration.secondsPerMinute);
    final miliseconds =
        d.inMilliseconds - (d.inSeconds * Duration.millisecondsPerSecond);
    final microseconds = d.inMicroseconds -
        (d.inMilliseconds * Duration.microsecondsPerMillisecond);
    return DurationComponents.raw(
      isNegative,
      days,
      hours,
      minutes,
      seconds,
      miliseconds,
      microseconds,
    );
  }

  Duration toDuration() => Duration(
        days: days,
        minutes: minutes,
        seconds: seconds,
        milliseconds: miliseconds,
        microseconds: microseconds,
      );
}
