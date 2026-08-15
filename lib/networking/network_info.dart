import 'dart:io';

import '../../core/constants.dart';

class LocalNetworkInfo {
  const LocalNetworkInfo();

  Future<List<String>> ipv4Addresses() async {
    final addresses = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.isLoopback) {
            continue;
          }
          addresses.add(addr.address);
        }
      }
    } catch (_) {
      // Platform may deny interface listing; the host can still type an IP.
    }
    addresses.sort(_preferLan);
    return addresses;
  }

  Future<String?> primaryIpv4() async {
    final all = await ipv4Addresses();
    return all.isEmpty ? null : all.first;
  }

  int get port => NetworkConstants.serverPort;

  static int _preferLan(String a, String b) =>
      _score(b).compareTo(_score(a)) == 0 ? a.compareTo(b) : _score(b).compareTo(_score(a));

  static int _score(String ip) {
    if (ip.startsWith('192.168.')) {
      return 3;
    }
    if (ip.startsWith('10.')) {
      return 2;
    }
    if (ip.startsWith('172.')) {
      return 1;
    }
    return 0;
  }
}

class HostAddress {
  const HostAddress({required this.host, required this.port});

  final String host;
  final int port;

  String get display => '$host:$port';
  Uri get websocketUri => Uri.parse('ws://$host:$port');

  static HostAddress? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    var value = trimmed;
    if (value.startsWith('ws://')) {
      value = value.substring(5);
    }
    if (value.startsWith('http://')) {
      value = value.substring(7);
    }
    value = value.split('/').first;

    String host;
    var port = NetworkConstants.serverPort;
    if (value.contains(':')) {
      final parts = value.split(':');
      host = parts.first;
      port = int.tryParse(parts.last) ?? NetworkConstants.serverPort;
    } else if (_isShortLan(value)) {
      host = '192.168.$value';
    } else {
      host = value;
    }

    if (!_looksLikeIp(host) && !_looksLikeHostname(host)) {
      return null;
    }
    return HostAddress(host: host, port: port);
  }

  static bool _isShortLan(String value) {
    final parts = value.split('.');
    if (parts.length != 2) {
      return false;
    }
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    return a != null && b != null && a >= 0 && a <= 255 && b >= 0 && b <= 255;
  }

  static bool _looksLikeIp(String host) {
    final parts = host.split('.');
    if (parts.length != 4) {
      return false;
    }
    return parts.every((p) {
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 255;
    });
  }

  static bool _looksLikeHostname(String host) {
    return host.isNotEmpty && !host.contains(' ');
  }
}
