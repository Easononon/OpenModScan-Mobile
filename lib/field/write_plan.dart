import '../models/device_info.dart';
import '../models/register_address_type.dart';
import 'address_mapping.dart';

/// Everything a write confirmation must show. [knownOldValue] is null when
/// this session has not actually read the point.
class WritePlan {
  final String endpoint;
  final int unitId;
  final int functionCode;
  final String functionName;
  final RegisterAddressType addressType;
  final int pduAddress;
  final int referenceAddress;
  final int quantity;
  final String? knownOldValue;
  final String newValue;

  const WritePlan({
    required this.endpoint,
    required this.unitId,
    required this.functionCode,
    required this.functionName,
    required this.addressType,
    required this.pduAddress,
    required this.referenceAddress,
    required this.quantity,
    required this.knownOldValue,
    required this.newValue,
  });

  bool get oldValueKnown => knownOldValue != null;

  factory WritePlan.holding({
    required DeviceInfo device,
    required int displayAddress,
    required int addressBase,
    required int wordCount,
    required String newValue,
    String? knownOldValue,
  }) {
    final mapped = MappedAddress.fromDisplayAddress(
      type: RegisterAddressType.holdingRegisters,
      displayAddress: displayAddress,
      addressBase: addressBase,
    );
    final functionCode = wordCount <= 1 ? 0x06 : 0x10;
    return WritePlan(
      endpoint: device.address,
      unitId: device.unitId,
      functionCode: functionCode,
      functionName: functionCode == 0x06
          ? '06 Write Single Register'
          : '16 Write Multiple Registers',
      addressType: mapped.type,
      pduAddress: mapped.pduAddress,
      referenceAddress: mapped.referenceAddress,
      quantity: wordCount,
      knownOldValue: _clean(knownOldValue),
      newValue: newValue,
    );
  }

  factory WritePlan.coil({
    required DeviceInfo device,
    required int displayAddress,
    required int addressBase,
    required String newValue,
    String? knownOldValue,
  }) {
    final mapped = MappedAddress.fromDisplayAddress(
      type: RegisterAddressType.coils,
      displayAddress: displayAddress,
      addressBase: addressBase,
    );
    return WritePlan(
      endpoint: device.address,
      unitId: device.unitId,
      functionCode: 0x05,
      functionName: '05 Write Single Coil',
      addressType: mapped.type,
      pduAddress: mapped.pduAddress,
      referenceAddress: mapped.referenceAddress,
      quantity: 1,
      knownOldValue: _clean(knownOldValue),
      newValue: newValue,
    );
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
