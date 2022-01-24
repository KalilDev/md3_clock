class Lap {
  final int number;
  final Duration duration;
  final Duration endTime;

  const Lap(this.number, this.duration, this.endTime);
  static const Lap zero = Lap(0, Duration.zero, Duration.zero);
}
