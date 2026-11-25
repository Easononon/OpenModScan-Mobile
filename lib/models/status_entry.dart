class StatusEntry {
  final int address;
  final int? displayAddress;
  final bool value;
  final bool? previousValue;
  final String comment;
  final String? timestamp;
  final String? date;

  /// True when the value came from labelled demonstration fixtures, not a read.
  final bool demonstration;

  /// True only after this point was returned by a read in this session.
  final bool observed;

  const StatusEntry({
    required this.address,
    this.displayAddress,
    required this.value,
    this.previousValue,
    required this.comment,
    this.timestamp,
    this.date,
    this.demonstration = false,
    this.observed = false,
  });

  /// Coil state that was actually read. Unread defaults and demo fixtures are
  /// not reported as a known previous value.
  String? get knownCoilState {
    if (!observed || demonstration) return null;
    return value ? 'ON' : 'OFF';
  }

  StatusEntry copyWith({bool? value}) => StatusEntry(
    address: address,
    displayAddress: displayAddress,
    value: value ?? this.value,
    previousValue: previousValue,
    comment: comment,
    timestamp: timestamp,
    date: date,
    demonstration: demonstration,
    observed: observed,
  );
}
