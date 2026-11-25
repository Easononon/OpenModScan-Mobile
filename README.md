# OpenModScan Mobile

[![Flutter CI](https://github.com/sanny32/OpenModScan-Mobile/actions/workflows/flutter.yml/badge.svg)](https://github.com/sanny32/OpenModScan-Mobile/actions/workflows/flutter.yml)
[![Release](https://github.com/sanny32/OpenModScan-Mobile/actions/workflows/release.yml/badge.svg)](https://github.com/sanny32/OpenModScan-Mobile/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Mobile version of the OpenModScan Modbus master/client utility.

This fork is a Chinese, Android-first field edition. It keeps the upstream MIT license and attribution to Alexandr Ananev (`LICENSE`, About screen). It is not a hardware validation report: protocol checks below use a local simulated Modbus endpoint.

## Field edition

The phone joins a portable gateway over Wi-Fi. The gateway's RS485 or Ethernet port is configured on the gateway itself. This app does not speak a vendor management API.

- **Modbus TCP** puts an MBAP header on the phone's TCP socket and does not add a CRC.
- **RTU over TCP** puts a raw RTU frame, including the CRC, on that same kind of TCP socket. The app does not assume a gateway converts one into the other.
- Baud, parity, stop bits and the RS485 port label are wiring notes. They are not applied to an unknown gateway.
- USB OTG RS485 and Bluetooth are shown as unavailable. They are not implemented.
- Scanning is manual and capped at 256 hosts, 4 ports and 4096 probes. A known gateway is entered by IP and port.
- Opening a TCP socket is not treated as a verified Modbus response. The status stays "TCP open, Modbus not verified" until a success or exception response is decoded.
- Writes are off by default. Each write is confirmed with endpoint, unit ID, function, PDU address, reference label, the previous value when one was actually read, and the new value. Unit ID 0 is rejected below the buttons as well as in the form.
- Addresses keep the zero-based PDU and the 0xxxx/1xxxx/3xxxx/4xxxx label visible. Data type, signedness, byte order, word order and an optional display scale are stored with the point. The scale does not rewrite the frame.
- The UI is Chinese when the phone language is Chinese, with English and Russian still available. Light and dark themes use high-contrast text for outdoor use.
- Demonstration fixtures, when the demo flag is on, are labelled and are not shown as live values.

## Screenshots

<img src=".github/assets/screen_devices_light.png" alt="Devices screen, light theme" width="240"> <img src=".github/assets/screen_devices_dark.png" alt="Devices screen, dark theme" width="240"> <img src=".github/assets/screen_registers_light.png" alt="Registers screen, light theme" width="240">
## Features

- Save Modbus devices and register lists.
- Connect to Modbus TCP and Modbus RTU/IP devices.
- Read holding registers, input registers, coils, and discrete inputs.
- Write holding registers and coils only after writes are explicitly enabled, with a confirmation for each write.
- Discover Modbus TCP and Modbus RTU/IP devices on the local network.
- Inspect captured Modbus traffic with decoded frame details.
- Export and import app settings and saved devices as a JSON backup.
- Supports Chinese, English and Russian UI localization. Chinese follows the phone language.

## Protocol Support

| Protocol | Notes |
| --- | --- |
| Modbus TCP | MBAP framing on a TCP socket. No CRC. |
| Modbus RTU/IP | Raw RTU frame with CRC on a TCP socket. The gateway is not assumed to translate this to MBAP. |

## Getting Started

[Install Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.12.0`), then fetch dependencies:

```sh
flutter pub get
```

Run the app:

```sh
flutter run
```

Build release artifacts for a target platform:

<img src="https://cdn.simpleicons.org/android/3DDC84" alt="Android" width="16" height="16"> Android APK:

```sh
flutter build apk
```

<img src="https://cdn.simpleicons.org/apple/666666" alt="Apple" width="16" height="16"> iOS:

```sh
flutter build ios
```

> [!NOTE]
> iOS builds require Xcode and a configured Apple signing environment.

## Quality Checks

Run static analysis:

```sh
flutter analyze
```

Run tests:

```sh
flutter test
```

Run tests with coverage:

```sh
flutter test --coverage
```

The CI workflow enforces at least 80% line coverage from `coverage/lcov.info`.
Coverage output is a local artifact and is ignored by git.

Run integration tests (requires a connected device or running emulator):

macOS / Linux:

```sh
scripts/integration_test.sh
```

Windows (PowerShell):

```powershell
.\scripts\integration_test.ps1
```

Windows (cmd.exe):

```bat
scripts\integration_test.bat
```

The demo scenarios (`app_smoke_test.dart`, `register_write_test.dart`) need the
demo fixtures, so they must run with `--dart-define=OMODSCAN_DEMO_DATA=true` —
the script sets this for you. The seeded scenarios (`device_crud_test.dart`,
`settings_test.dart`) own their state and pass with or without the flag.

## What the automated checks cover

`flutter test` includes a local simulated Modbus TCP server and a simulated RTU-over-TCP server. Those tests check framing selection, reads, writes, timeouts and the rule that a TCP accept is not a verified Modbus response. They do not exercise a real RS485 transceiver, a real gateway, USB OTG or Bluetooth.

## Notes

- Writes are disabled until Settings → Allow writes is turned on. Unit ID 0 writes are refused in the client, not only in the form.
- Multiple-register writes fall back to sequential single-register writes when
  a device rejects function code 16 with an illegal-function exception.
- Traffic file logging writes `modbus-traffic.log` in the app documents
  directory when enabled.

## License

Released under the [MIT License](LICENSE).
