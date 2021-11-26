library sn_bluetooth_ble_stomp_client;

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_frame_command.dart';

/// Create a subscribe frame to subscribe to a given topic.
class SnBluetoothBleStompClientSubscribeFrame
    extends BluetoothBleStompClientFrame {

  SnBluetoothBleStompClientSubscribeFrame(
      {required this.destination, required this.id})
      : super(
      command: SnBluetoothBleStompClientFrameCommand.subscribe.value,
      headers: {'id': id, 'destination': destination});

  final String destination;
  final String id;
}
