class City {
  final String name;
  final String? stateName;
  final String countryName;

  final Duration timeZoneOffset;

  const City(
    this.name,
    this.stateName,
    this.countryName,
    this.timeZoneOffset,
  );
  DateTime get now => DateTime.now().add(timeZoneOffset);
  String get titleString =>
      '$name,${stateName != null ? ' $stateName,' : ''} $countryName';
}
