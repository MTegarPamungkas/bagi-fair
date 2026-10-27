/// Enum helpers shared by the entities that map to Postgres text columns.
///
/// PostgREST stores enum-ish values in `snake_case` (`member_joined`), while
/// Dart enums are camelCase (`memberJoined`). Parsing both shapes keeps rows
/// created by the app, by SQL RPCs, and by older seeds readable, and writing
/// snake_case keeps new rows consistent with the server.
library;

T parseEnum<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final needle = raw?.toString().replaceAll('_', '').toLowerCase();
  if (needle == null || needle.isEmpty) return fallback;
  for (final value in values) {
    if (value.name.toLowerCase() == needle) return value;
  }
  return fallback;
}

String enumToSnake(Enum value) {
  return value.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match[0]!.toLowerCase()}',
  );
}
