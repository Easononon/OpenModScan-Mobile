import '../models/device_info.dart';
import 'field_transport.dart';

extension ProtocolWireFraming on ProtocolType {
  /// Phone-side TCP socket is used for both implemented modes.
  bool get usesPhoneTcpSocket => switch (this) {
    ProtocolType.modbusTcp => true,
    ProtocolType.modbusRtuIp => true,
  };

  ModbusWireFraming get wireFraming => switch (this) {
    ProtocolType.modbusTcp => ModbusWireFraming.mbap,
    ProtocolType.modbusRtuIp => ModbusWireFraming.rtuWithCrcOverTcp,
  };

  /// This app does not claim the gateway rewrites MBAP into RTU or the reverse.
  bool get assumesGatewayTranslatesFraming => false;

  /// RTU-over-TCP shares the RS485 bus behind the gateway with any other master.
  bool get warnsAboutSecondMaster => this == ProtocolType.modbusRtuIp;
}
