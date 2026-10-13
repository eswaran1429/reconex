import 'package:reconex/core/network/paginated.dart';

// Tolerant readers for loosely-typed API payloads (dashboard, live-scan rows).

Json asMap(Object? value) => value is Map ? Json.from(value) : {};

List<dynamic> asList(Object? value) => value is List ? value : const [];

int asInt(Object? value) => value is num ? value.toInt() : 0;

/// Readable text for strings, numbers, or certificate-style objects like `{ CN, O }`.
String asText(Object? value) {
  if (value == null) return '—';
  if (value is Map) return (value['CN'] ?? value['O'] ?? value.values.join(', ')).toString();
  return value.toString();
}
