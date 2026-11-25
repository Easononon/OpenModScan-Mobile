/// Socket progress is not the same thing as a Modbus conversation.
enum ModbusLinkPhase {
  /// No TCP socket.
  closed,

  /// TCP connected. No Modbus response has been decoded yet.
  tcpOpen,

  /// A Modbus response was decoded (success or exception).
  modbusVerified,
}
