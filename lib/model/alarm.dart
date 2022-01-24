enum AlarmSource {
  sounds,
  spotify,
}

class Alarm {
  final String name;
  final bool isDefault;
  final AlarmSource source;

  const Alarm(this.name, this.isDefault, this.source);

  String get text => isDefault ? 'Padrão ($name)' : name;
}
