library sn_bluetooth_ble_stomp_client;

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client.dart';
import 'package:flutter_blue/flutter_blue.dart';

class SnBluetoothBleStompClient extends BluetoothBleStompClient {
  static const String setupDestination = '/setup/**';
  static const String latestDatumDestination = '/setup/datum/latest';
  static const String internetAccessDestination = '/setup/internet/access';
  static const String pingDestination = '/setup/network/ping';

  SnBluetoothBleStompClient(
      {required BluetoothCharacteristic writeCharacteristic,
      required BluetoothCharacteristic readCharacteristic})
      : super(
            writeCharacteristic: writeCharacteristic,
            readCharacteristic: readCharacteristic);
}
