library sn_bluetooth_ble_stomp_client;

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_frame_command.dart';

/// A skeleton class used for send frames.
class SnBluetoothBleStompClientSendFrame extends BluetoothBleStompClientFrame {
  SnBluetoothBleStompClientSendFrame(
      {required Map<String, String> headers, String? body})
      : super(
            command: SnBluetoothBleStompClientFrameCommand.send.value,
            headers: headers,
            body: body);
}
