/// How the phone reaches a Modbus device.
///
/// Only [FieldTransport.wifiTcp] is implemented. USB OTG RS485 and Bluetooth
/// are extension seams for a later version: they are visible so the limitation
/// is explicit, and nothing in the app pretends to open them.
enum FieldTransport {
  wifiTcp(available: true),
  usbOtgRs485(available: false),
  bluetooth(available: false);

  final bool available;

  const FieldTransport({required this.available});

  static const List<FieldTransport> displayed = [
    FieldTransport.wifiTcp,
    FieldTransport.usbOtgRs485,
    FieldTransport.bluetooth,
  ];
}

/// What the phone actually puts on the TCP socket.
///
/// A portable RS485/Ethernet gateway is not assumed to translate between these.
/// The user picks the framing the gateway is known to speak.
enum ModbusWireFraming {
  /// Modbus TCP MBAP header, no CRC.
  mbap,

  /// Raw Modbus RTU frame, including the CRC, carried on a TCP socket.
  rtuWithCrcOverTcp,
}

/// Serial settings recorded for the gateway's RS485 side.
///
/// These are wiring notes only. This app does not apply them: the gateway is
/// not a known product and has no management API selected yet.
class SerialWiringNote {
  static const parities = ['none', 'even', 'odd'];

  final int? baudRate;
  final String parity;
  final int stopBits;
  final String portLabel;

  const SerialWiringNote({
    this.baudRate,
    this.parity = 'none',
    this.stopBits = 1,
    this.portLabel = '',
  });

  bool get hasRecordedDetail =>
      baudRate != null ||
      portLabel.trim().isNotEmpty ||
      parity != 'none' ||
      stopBits != 1;

  SerialWiringNote copyWith({
    int? baudRate,
    bool clearBaudRate = false,
    String? parity,
    int? stopBits,
    String? portLabel,
  }) {
    return SerialWiringNote(
      baudRate: clearBaudRate ? null : baudRate ?? this.baudRate,
      parity: parity ?? this.parity,
      stopBits: stopBits ?? this.stopBits,
      portLabel: portLabel ?? this.portLabel,
    );
  }

  Map<String, dynamic> toJson() => {
    'serialBaud': baudRate,
    'serialParity': parity,
    'serialStopBits': stopBits,
    'serialPortLabel': portLabel,
  };

  factory SerialWiringNote.fromJson(Map<String, dynamic> json) {
    final baud = json['serialBaud'];
    final parity = json['serialParity'];
    final stop = json['serialStopBits'];
    final label = json['serialPortLabel'];
    return SerialWiringNote(
      baudRate: baud is int && baud > 0 ? baud : null,
      parity: parities.contains(parity) ? parity as String : 'none',
      stopBits: stop == 2 ? 2 : 1,
      portLabel: label is String ? label : '',
    );
  }
}
