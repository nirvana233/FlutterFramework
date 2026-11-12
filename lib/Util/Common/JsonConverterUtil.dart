bool? boolOrNullFromJson(Object? value) {
  return value is bool ? value : null;
}

bool boolFromJson(Object? value) {
  return nullableBoolFromJson(value) ?? false;
}

bool? nullableBoolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}
