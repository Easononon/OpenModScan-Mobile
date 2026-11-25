import '../services/network_scan_subnet.dart';

/// Local discovery limits. A scan is a user action, and it stays inside one
/// small subnet so it is not fired across a plant network.
class ScanBounds {
  static const maxHosts = 256;
  static const maxPorts = 4;
  static const maxProbes = 4096;

  static int hostCountFor({String? cidr, required int prefix}) {
    final parsed = cidr == null || cidr.trim().isEmpty
        ? null
        : Ipv4Subnet.tryParse(cidr);
    final bits = parsed?.prefix ?? prefix;
    if (bits < 0 || bits > 32) return 0;
    final size = 1 << (32 - bits);
    if (size <= 2) return 0;
    return size - 2;
  }

  /// Null when the request is inside the limits.
  static String? violation({
    required int hostCount,
    required int portStart,
    required int portEnd,
    required int unitStart,
    required int unitEnd,
  }) {
    final ports = (portEnd - portStart).abs() + 1;
    final units = (unitEnd - unitStart).abs() + 1;
    if (hostCount <= 0) return null;
    if (hostCount > maxHosts) {
      return 'Scan refused: $hostCount hosts exceeds the limit of $maxHosts. '
          'Enter a /24 or smaller subnet, or type the gateway IP directly.';
    }
    if (ports > maxPorts) {
      return 'Scan refused: $ports ports exceeds the limit of $maxPorts.';
    }
    final probes = hostCount * ports * units;
    if (probes > maxProbes) {
      return 'Scan refused: $probes probes exceeds the limit of $maxProbes. '
          'Narrow the subnet, ports or unit IDs.';
    }
    return null;
  }
}
