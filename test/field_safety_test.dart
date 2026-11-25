import 'package:flutter_test/flutter_test.dart';
import 'package:omodscan_mobile/field/address_mapping.dart';
import 'package:omodscan_mobile/field/field_transport.dart';
import 'package:omodscan_mobile/field/protocol_framing.dart';
import 'package:omodscan_mobile/field/scan_bounds.dart';
import 'package:omodscan_mobile/field/write_guard.dart';
import 'package:omodscan_mobile/field/write_plan.dart';
import 'package:omodscan_mobile/models/app_settings.dart';
import 'package:omodscan_mobile/models/device_info.dart';
import 'package:omodscan_mobile/models/modbus_scan.dart';
import 'package:omodscan_mobile/models/register_address_type.dart';
import 'package:omodscan_mobile/models/register_list.dart';
import 'package:omodscan_mobile/runtime/runtime_ports.dart';
import 'package:omodscan_mobile/services/connection_manager.dart';
import 'package:omodscan_mobile/services/device_scanner.dart';
import 'package:omodscan_mobile/services/modbus_client.dart';
import 'package:omodscan_mobile/services/modbus_discovery_probe.dart';
import 'package:omodscan_mobile/services/settings_store.dart';
import 'package:omodscan_mobile/utils/modbus_format.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'modbus_tcp_test_server.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.resetToDefaults();
  });

  test('fresh settings are read-only and confirm writes', () async {
    final settings = AppSettings.withStore(FakeSettingsStore());
    await settings.load();

    expect(settings.writeEnabled, isFalse);
    expect(settings.confirmBeforeWrite, isTrue);
    expect(AppSettings.languageOptions, contains('Chinese'));
  });

  test('device wiring notes persist and unavailable transports do not stick', () async {
    final device = DeviceInfo(
      id: 'gw-1',
      name: '便携网关',
      host: '192.168.8.10',
      port: 502,
      protocol: ProtocolType.modbusRtuIp,
      unitId: 1,
      serialWiring: const SerialWiringNote(
        baudRate: 9600,
        parity: 'even',
        stopBits: 1,
        portLabel: 'A/B',
      ),
      transport: FieldTransport.wifiTcp,
    );

    final restored = DeviceInfo.fromJson(device.toJson());

    expect(restored.serialWiring.baudRate, 9600);
    expect(restored.serialWiring.parity, 'even');
    expect(restored.serialWiring.portLabel, 'A/B');
    expect(restored.serialWiring.hasRecordedDetail, isTrue);
    expect(restored.transport, FieldTransport.wifiTcp);
    expect(FieldTransport.usbOtgRs485.available, isFalse);
    expect(FieldTransport.bluetooth.available, isFalse);

    final forced = DeviceInfo.fromJson({
      ...device.toJson(),
      'transport': 'usbOtgRs485',
    });
    expect(forced.transport, FieldTransport.wifiTcp);
  });

  test('protocol selection picks MBAP or RTU-with-CRC and not a gateway API', () {
    expect(
      ProtocolType.modbusTcp.wireFraming,
      ModbusWireFraming.mbap,
    );
    expect(
      ProtocolType.modbusRtuIp.wireFraming,
      ModbusWireFraming.rtuWithCrcOverTcp,
    );
    expect(ProtocolType.modbusTcp.usesPhoneTcpSocket, isTrue);
    expect(ProtocolType.modbusRtuIp.usesPhoneTcpSocket, isTrue);
    expect(ProtocolType.modbusTcp.assumesGatewayTranslatesFraming, isFalse);
    expect(ProtocolType.modbusRtuIp.assumesGatewayTranslatesFraming, isFalse);
    expect(ProtocolType.modbusRtuIp.warnsAboutSecondMaster, isTrue);
    expect(ProtocolType.modbusTcp.warnsAboutSecondMaster, isFalse);
  });

  test('address mapping keeps PDU and reference label distinct', () {
    final zeroBased = MappedAddress.fromUserEntry(
      type: RegisterAddressType.holdingRegisters,
      userAddress: 0,
      addressBase: 0,
    );
    expect(zeroBased.pduAddress, 0);
    expect(zeroBased.referenceAddress, 40000);

    final oneBased = MappedAddress.fromUserEntry(
      type: RegisterAddressType.holdingRegisters,
      userAddress: 1,
      addressBase: 1,
    );
    expect(oneBased.pduAddress, 0);
    expect(oneBased.referenceAddress, 40001);
    expect(oneBased.displayAddress, 40001);

    final coil = MappedAddress.fromUserEntry(
      type: RegisterAddressType.coils,
      userAddress: 1,
      addressBase: 1,
    );
    expect(coil.pduAddress, 0);
    expect(coil.referenceAddress, 1);
  });

  test('engineering scale changes display only', () {
    expect(
      computeDisplayValue(0, 'Int16', {0: 10}, scale: 0.1, offset: 2),
      '3',
    );
    expect(
      computeDisplayValue(0, 'Hex', {0: 0x10}, scale: 2, offset: 1),
      '0x0010',
    );
    final stored = RegisterConfig(address: 0, scale: 0.1, offset: 2);
    final loaded = RegisterConfig.fromJson(stored.toJson());
    expect(loaded.scale, 0.1);
    expect(loaded.offset, 2);
  });

  test('write plan names the endpoint, function and both addresses', () {
    final device = DeviceInfo(
      name: 'GW',
      host: '10.0.0.8',
      port: 502,
      protocol: ProtocolType.modbusTcp,
      unitId: 3,
    );
    final plan = WritePlan.holding(
      device: device,
      displayAddress: 40001,
      addressBase: 1,
      wordCount: 1,
      newValue: '12',
      knownOldValue: '4',
    );

    expect(plan.endpoint, '10.0.0.8:502');
    expect(plan.unitId, 3);
    expect(plan.functionCode, 0x06);
    expect(plan.pduAddress, 0);
    expect(plan.referenceAddress, 40001);
    expect(plan.knownOldValue, '4');
    expect(plan.newValue, '12');

    final unknown = WritePlan.coil(
      device: device,
      displayAddress: 1,
      addressBase: 1,
      newValue: 'ON',
    );
    expect(unknown.functionCode, 0x05);
    expect(unknown.oldValueKnown, isFalse);
    expect(unknown.pduAddress, 0);
  });

  test('write guard blocks disabled writes and unit 0 before the socket', () {
    expect(
      () => enforceWriteAllowed(writeEnabled: false, unitId: 1),
      throwsA(
        isA<WriteDenied>().having(
          (error) => error.reason,
          'reason',
          WriteDenyReason.writesDisabled,
        ),
      ),
    );
    expect(
      () => enforceWriteAllowed(writeEnabled: true, unitId: 0),
      throwsA(
        isA<WriteDenied>().having(
          (error) => error.reason,
          'reason',
          WriteDenyReason.broadcastUnit,
        ),
      ),
    );
    enforceWriteAllowed(writeEnabled: true, unitId: 1);
  });

  test('TCP accept is not a verified Modbus response', () async {
    final server = await ModbusTcpTestServer.start(holdingRegisters: {0: 7});
    addTearDown(server.close);
    final client = ModbusClient(
      DeviceInfo(
        name: 'sim',
        host: server.host,
        port: server.port,
        protocol: ProtocolType.modbusTcp,
        unitId: 1,
        timeout: 400,
      ),
    );
    addTearDown(client.disconnect);

    await client.connect();
    expect(client.isConnected, isTrue);
    expect(client.isModbusVerified, isFalse);

    expect(await client.readHoldingRegisters(0, 1), [7]);
    expect(client.isModbusVerified, isTrue);
  });

  test('simulated exception still counts as a Modbus response', () async {
    final server = await ModbusTcpTestServer.start(
      exceptionByFunction: {0x03: 0x02},
    );
    addTearDown(server.close);
    final client = ModbusClient(
      DeviceInfo(
        name: 'sim',
        host: server.host,
        port: server.port,
        protocol: ProtocolType.modbusTcp,
        unitId: 1,
      ),
    );
    addTearDown(client.disconnect);
    await client.connect();

    await expectLater(
      client.readHoldingRegisters(0, 1),
      throwsA(isA<ModbusClientException>()),
    );
    expect(client.isModbusVerified, isTrue);
  });

  test('unit 0 write is refused by the client', () async {
    final server = await ModbusTcpTestServer.start();
    addTearDown(server.close);
    final client = ModbusClient(
      DeviceInfo(
        name: 'broadcast',
        host: server.host,
        port: server.port,
        protocol: ProtocolType.modbusTcp,
        unitId: 0,
      ),
    );
    addTearDown(client.disconnect);
    await client.connect();

    expect(
      () => client.writeHoldingRegister(0, 1),
      throwsA(isA<WriteDenied>()),
    );
    expect(server.singleRegisterWrites, isEmpty);
  });

  test('connection manager refuses writes while the default lock is on', () async {
    await resetAppTestState();
    final server = await ModbusTcpTestServer.start();
    addTearDown(server.close);
    final manager = ConnectionManager.instance;
    await manager.resetForTesting();
    addTearDown(manager.resetForTesting);
    final device = DeviceInfo(
      id: 'locked',
      name: 'locked',
      host: server.host,
      port: server.port,
      protocol: ProtocolType.modbusTcp,
      unitId: 1,
    );
    await manager.connect(device);

    expect(
      () => manager.writeCoil(device, address: 0, value: true),
      throwsA(isA<WriteDenied>()),
    );
    expect(server.coilWrites, isEmpty);
  });

  test('oversized scan does not open probes', () async {
    final probe = _CountingProbe();
    final scanner = DeviceScanner(probe: probe);

    await scanner.startScan(
      const DeviceScanRequest(
        subnetCidr: '10.1.0.0/16',
        portStart: 502,
        portEnd: 502,
        unitIdStart: 1,
        unitIdEnd: 1,
      ),
    );

    expect(probe.calls, 0);
    expect(scanner.state.name, 'idle');
    expect(scanner.scanRejection, isNotNull);
    expect(ScanBounds.hostCountFor(cidr: '10.1.0.0/16', prefix: 24), 65534);
    expect(
      ScanBounds.violation(
        hostCount: 254,
        portStart: 502,
        portEnd: 502,
        unitStart: 1,
        unitEnd: 10,
      ),
      isNull,
    );
  });
}

class FakeSettingsStore implements SettingsStore {
  final Map<String, Object?> values = {};

  @override
  Future<void> load() async {}

  @override
  String? getString(String key) => values[key] as String?;

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> setInt(String key, int value) async => values[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
}

class _CountingProbe implements ModbusDiscoveryProbe {
  var calls = 0;

  @override
  Future<List<int>> probeEndpoint({
    required String host,
    required int port,
    required ProtocolType protocol,
    required Iterable<int> unitIds,
    required ModbusScanRequestType requestType,
    required int requestAddress,
    required Duration connectTimeout,
    required Duration responseTimeout,
    bool Function()? isCancelled,
  }) async {
    calls++;
    return const [];
  }
}
