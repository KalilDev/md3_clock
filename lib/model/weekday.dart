import 'dart:collection';

enum Weekday {
  saturday,
  sunday,
  monday,
  tuesday,
  wednsday,
  thursday,
  friday,
}

class Weekdays {
  final Set<Weekday> active;

  Weekdays(Set<Weekday> active) : active = UnmodifiableSetView(active);
  factory Weekdays.empty() => Weekdays({});

  Weekdays add(Weekday day) => Weekdays(active.toSet()..add(day));
  Weekdays remove(Weekday day) => Weekdays(active.toSet()..remove(day));
  Weekdays toggle(Weekday day) {
    final newActive = active.toSet();
    if (active.contains(day)) {
      newActive.remove(day);
    } else {
      newActive.add(day);
    }
    return Weekdays(newActive);
  }

  bool isActive(Weekday day) => active.contains(day);
}
