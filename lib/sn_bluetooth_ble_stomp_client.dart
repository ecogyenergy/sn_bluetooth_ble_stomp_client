library sn_bluetooth_ble_stomp_client;

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_send_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_subscribe_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_frame_command.dart';

class SnBluetoothBleStompClient extends BluetoothBleStompClient {
  static const String setupDestination = '/setup/**';
  static const String latestDatumDestination = '/setup/datum/latest';
  static const String internetAccessDestination = '/setup/internet/access';
  static const String pingDestination = '/setup/network/ping';

  SnBluetoothBleStompClient(
      {required BluetoothCharacteristic writeCharacteristic,
      required BluetoothCharacteristic readCharacteristic,
      required this.login,
      required this.password})
      : super(
            writeCharacteristic: writeCharacteristic,
            readCharacteristic: readCharacteristic);

  final String login;
  final String password;

  late String session;

  bool isAuthenticated = false;
  int _latestId = 0;
  int _latestRequestId = 0;

  String? latestDatum;
  bool isConnected = false;

  /// Connect to the the server.
  void connect({required String host, String? acceptVersion = '1.2'}) {
    send(
        command: SnBluetoothBleStompClientFrameCommand.connect.value,
        headers: {
          'accept-version': acceptVersion!,
          'host': host,
          'login': login,
        });
  }

  /// Subscribe to a destination topic with the given id.
  void subscribe({required String destination}) {
    sendFrame(SnBluetoothBleStompClientSubscribeFrame(
        destination: destination, id: _getId()));
  }

  /// Get the latest ID and increment it.
  String _getId() {
    String id = _latestId.toString();
    _latestId += 1;
    return id;
  }

  /// Get the latest request ID and increment it.
  String _getRequestId() {
    String requestId = _latestRequestId.toString();
    _latestRequestId += 1;
    return requestId;
  }

  /// Get the latest datum of the node.
  void getLatestDatum() {
    sendFrame(SnBluetoothBleStompClientSendFrame(headers: {
      'destination': latestDatumDestination,
      'request-id': _getRequestId()
    }));
  }

  /// Get the status of internet access.
  void getInternetAccess() {
    sendFrame(SnBluetoothBleStompClientSendFrame(
        headers: {'destination': pingDestination}));
  }
}
