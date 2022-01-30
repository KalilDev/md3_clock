enum Month {
  jan,
  feb,
  mar,
  apr,
  may,
  jun,
  jul,
  aug,
  sep,
  nov,
  dec,
}

class Date {
  final int day;
  final Month month;

  Date(this.day, this.month);
  factory Date.fromDateTime(DateTime time) => Date(
        time.day,
        Month.values[time.month - 1],
      );
  int get hashCode => Object.hashAll([
        day,
        month,
      ]);
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is Date) {
      return true && day == other.day && month == other.month;
    }
    return false;
  }
}
