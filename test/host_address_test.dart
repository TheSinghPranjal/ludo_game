import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/networking/network_info.dart';

void main() {
  test('parses full IP, port, and 192.168 shorthand', () {
    expect(HostAddress.tryParse('192.168.43.1')?.host, '192.168.43.1');
    expect(HostAddress.tryParse('192.168.43.1:4040')?.port, 4040);
    expect(HostAddress.tryParse('43.1')?.host, '192.168.43.1');
    expect(HostAddress.tryParse('ws://10.0.0.5:4040')?.host, '10.0.0.5');
    expect(HostAddress.tryParse(''), isNull);
    expect(HostAddress.tryParse('not an ip'), isNull);
  });
}
