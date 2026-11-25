/// Why a write was refused before any bytes were sent.
enum WriteDenyReason { writesDisabled, broadcastUnit }

class WriteDenied implements Exception {
  final WriteDenyReason reason;

  const WriteDenied(this.reason);

  @override
  String toString() => switch (reason) {
    WriteDenyReason.writesDisabled => 'Writes are disabled.',
    WriteDenyReason.broadcastUnit =>
      'Refusing Modbus broadcast write to unit ID 0.',
  };
}

/// Enforced below the widgets. A hidden button is not the protection.
void enforceWriteAllowed({required bool writeEnabled, required int unitId}) {
  if (!writeEnabled) {
    throw const WriteDenied(WriteDenyReason.writesDisabled);
  }
  if (unitId == 0) {
    throw const WriteDenied(WriteDenyReason.broadcastUnit);
  }
}

/// Unit ID 0 is the Modbus broadcast address. Writes to it are never sent.
void enforceNoBroadcastWrite(int unitId) {
  if (unitId == 0) {
    throw const WriteDenied(WriteDenyReason.broadcastUnit);
  }
}
