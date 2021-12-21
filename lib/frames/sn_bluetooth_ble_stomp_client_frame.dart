import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_frame_command.dart';

/// A SolarNetwork specific STOMP client frame.
class SnBluetoothBleStompClientFrame extends BluetoothBleStompClientFrame {
  SnBluetoothBleStompClientFrame(
      {required String command,
      required Map<String, String> headers,
      required String body})
      : super(command: command, headers: headers, body: body);

  SnBluetoothBleStompClientFrame.fromBytes(
      {required List<int> bytes,
      Set<String> validCommands =
          validSnBluetoothBleStompClientFrameCommandValues})
      : super.fromBytes(bytes: bytes, validCommands: validCommands);

  /// Check for an authenticated error frame.
  static bool isAuthenticatedError(
      {required BluetoothBleStompClientFrame frame}) {
    if (frame.command == SnBluetoothBleStompClientFrameCommand.error.value) {
      if (frame.headers['message'] ==
          'Must start with CONNECT or STOMP frame.') {
        return true;
      }
    }
    return false;
  }
}
