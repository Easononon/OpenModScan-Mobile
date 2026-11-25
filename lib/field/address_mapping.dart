import '../models/register_address_type.dart';

/// One address shown three ways, with the wire value computed in one place.
///
/// [displayAddress] is the number the existing read/write path already passes
/// into [RegisterAddressType.toModbusAddress] (type offset plus the user's
/// address-base entry). [pduAddress] is the zero-based address in the PDU.
/// [referenceAddress] is the classic 4xxxx/3xxxx/1xxxx/0xxxx label for that
/// same PDU. Nothing here rewrites a stored address on its own.
class MappedAddress {
  final RegisterAddressType type;
  final int addressBase;
  final int displayAddress;
  final int pduAddress;
  final int referenceAddress;

  const MappedAddress({
    required this.type,
    required this.addressBase,
    required this.displayAddress,
    required this.pduAddress,
    required this.referenceAddress,
  });

  factory MappedAddress.fromDisplayAddress({
    required RegisterAddressType type,
    required int displayAddress,
    required int addressBase,
  }) {
    final pdu = type.toModbusAddress(
      displayAddress,
      addressBase: addressBase,
    );
    final reference = type.toReferenceDisplay(
      type.toDisplayAddress(pdu, addressBase: addressBase),
    );
    return MappedAddress(
      type: type,
      addressBase: addressBase,
      displayAddress: displayAddress,
      pduAddress: pdu,
      referenceAddress: reference,
    );
  }

  /// User entry in the active address base (0 or 1), before the type offset.
  factory MappedAddress.fromUserEntry({
    required RegisterAddressType type,
    required int userAddress,
    required int addressBase,
  }) {
    return MappedAddress.fromDisplayAddress(
      type: type,
      displayAddress: userAddress + type.displayOffset,
      addressBase: addressBase,
    );
  }
}

/// Linear engineering scale. Identity (1, 0) leaves the formatted value as-is.
/// Non-numeric formats (hex, binary) are not rewritten.
String applyEngineeringScale(
  String formatted, {
  double scale = 1,
  double offset = 0,
}) {
  if (scale == 1 && offset == 0) return formatted;
  final parsed = double.tryParse(formatted);
  if (parsed == null) return formatted;
  final scaled = parsed * scale + offset;
  if (scaled == scaled.roundToDouble() && scaled.abs() < 1e15) {
    return scaled.round().toString();
  }
  return scaled.toString();
}
