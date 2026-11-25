import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omodscan_mobile/features/devices/devices_controller.dart';
import 'package:omodscan_mobile/features/devices/devices_screen.dart';
import 'package:omodscan_mobile/features/settings/settings_controller.dart';
import 'package:omodscan_mobile/features/settings/settings_screen.dart';
import 'package:omodscan_mobile/l10n/l10n.dart';
import 'package:omodscan_mobile/models/app_settings.dart';
import 'package:omodscan_mobile/models/device_info.dart';
import 'package:omodscan_mobile/services/device_repository.dart';
import 'package:omodscan_mobile/services/device_scanner.dart';
import 'package:omodscan_mobile/theme/app_theme.dart';

import 'helpers.dart';

/// Renders the Chinese field screens when FIELD_UI_OUT is set.
///
///   FIELD_UI_OUT=/tmp/field-ui flutter test test/field_ui_capture_test.dart
void main() {
  testWidgets('capture Chinese field screens', (tester) async {
    final out = Platform.environment['FIELD_UI_OUT'];
    if (out == null || out.isEmpty) return;

    await resetAppTestState(
      devices: [
        DeviceInfo(
          id: 'gw',
          name: '车间网关',
          host: '192.168.8.10',
          port: 502,
          protocol: ProtocolType.modbusRtuIp,
          unitId: 1,
        ),
      ],
    );
    await AppSettings.instance.setLanguage('Chinese');
    final controller = DevicesController(
      DeviceRepository.instance,
      PollingConnectionRuntime(),
      DeviceScanner(
        networkInterfacesProvider: () async => const [],
      ),
      AppSettings.instance,
    );
    addTearDown(controller.dispose);

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pump(Widget home, ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(child: home),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await pump(
      DevicesScreen(controller: controller, onOpenDevice: (_) {}),
      AppTheme.lightTheme,
    );
    await _save(tester, '$out/devices-light.png');

    await tester.tap(find.byKey(const ValueKey('connect-portable-gateway')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await _save(tester, '$out/gateway-form-light.png');

    await pump(
      DevicesScreen(controller: controller, onOpenDevice: (_) {}),
      AppTheme.darkTheme,
    );
    await _save(tester, '$out/devices-dark.png');

    await pump(
      SettingsScreen(controller: SettingsController(AppSettings.instance)),
      AppTheme.lightTheme,
    );
    await _save(tester, '$out/settings-light.png');
  });
}

Future<void> _save(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}
