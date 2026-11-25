import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

class ConnectionStatusChip extends StatelessWidget {
  final bool connected;

  /// When false while [connected] is true, the TCP socket is open but no
  /// Modbus response has been decoded. Null keeps the previous connected label
  /// for callers that do not track the distinction.
  final bool? modbusVerified;
  final String? label;
  final Color? color;

  const ConnectionStatusChip({
    super.key,
    required this.connected,
    this.modbusVerified,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final tcpOnly = connected && modbusVerified == false;
    final statusColor =
        color ??
        (tcpOnly
            ? appColors.warningColor
            : connected
            ? appColors.connectedColor
            : appColors.disconnectedColor);
    final statusLabel =
        label ??
        (tcpOnly
            ? l10n.linkTcpOpen
            : connected
            ? l10n.statusConnected
            : l10n.statusDisconnected);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall!.copyWith(color: statusColor),
          ),
        ),
      ],
    );
  }
}
