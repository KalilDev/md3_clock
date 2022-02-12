enum SoundSource {
  sounds,
  spotify,
}

class AlarmSound {
  final String name;
  final bool isDefault;
  final SoundSource source;

  const AlarmSound(this.name, this.isDefault, this.source);

  String get text => isDefault ? 'Padrão ($name)' : name;
}

class Sound {
  final String name;
  final SoundSource source = SoundSource.sounds;

  Sound(this.name);
}
