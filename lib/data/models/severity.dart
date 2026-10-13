enum Severity {
  critical,
  high,
  medium,
  low,
  info;

  static Severity? tryParse(Object? value) => value is String ? Severity.values.asNameMap()[value] : null;
}
