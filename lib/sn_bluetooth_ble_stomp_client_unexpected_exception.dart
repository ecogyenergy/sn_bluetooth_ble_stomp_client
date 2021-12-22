library sn_bluetooth_ble_stomp_client;

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';

/// An exception raised when the server is waiting to start.
class SnBluetoothBleStompClientUnexpectedException implements Exception {
  SnBluetoothBleStompClientUnexpectedException(
      {this.message = 'Unexpected frame.', required this.frame});

  final String? message;
  final BluetoothBleStompClientFrame frame;
}
