library sn_bluetooth_ble_stomp_client;

import 'dart:convert';

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_authenticate_frame.dart';
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
      required this.password,
      Duration? actionDelay})
      : super(
            writeCharacteristic: writeCharacteristic,
            readCharacteristic: readCharacteristic,
            actionDelay: actionDelay);

  final String login;
  final String password;

  late String session;

  int _latestId = 0;
  int _latestRequestId = 0;

  String? latestDatum;

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

  /// Connect to the the server.
  void connect({required String host, String? acceptVersion = '1.2'}) {
    send(
        command: SnBluetoothBleStompClientFrameCommand.connect.value,
        headers: {
          'accept-version': acceptVersion!,
          'host': host,
          'login': login,
        },
        callback: () => _authenticate());
  }

  Future<void> _authenticate() async {
    /// Get the data.
    String readData = utf8.decode(await readCharacteristic.read());
    BluetoothBleStompClientFrame readFrame =
        BluetoothBleStompClientFrame.fromString(str: readData);

    /// Check the command. If it is CONNECTED, then continue.
    if (readFrame.command ==
        SnBluetoothBleStompClientFrameCommand.connected.value) {
      session = readFrame.headers['session']!;
      String authHash = readFrame.headers['auth-hash']!;
      String authHashParamSalt = readFrame.headers['auth-hash-param-salt']!;

      /// Encrypt using bcrypt.
      if (authHash == 'bcrypt') {
        /// Send an authenticate frame.
        sendFrame(
            frame: SnBluetoothBleStompClientAuthenticateFrame(
                password: password,
                salt: authHashParamSalt,
                login: login,
                date: DateTime.now().toUtc()),
            callback: () {});
        subscribe(destination: setupDestination);
      }
    }
    // sendFrame(frame: SnBluetoothBleStompClientAuthenticateFrame(password: password, salt: salt, login: login, date: date))
  }

  /// Subscribe to a destination topic with the given id.
  Future<void> subscribe(
      {required String destination,
      Function? callback,
      Duration? delay}) async {
    sendFrame(
        frame: SnBluetoothBleStompClientSubscribeFrame(
            destination: destination, id: _getId()),
        callback: callback,
        delay: delay);
  }

  /// Get the latest datum of the node.
  Future<void> getLatestDatum(Function? callback, Duration? delay) async {
    sendFrame(
        frame: SnBluetoothBleStompClientSendFrame(headers: {
          'destination': latestDatumDestination,
          'request-id': _getRequestId()
        }),
        callback: callback,
        delay: delay);
  }

  /// Get the status of internet access.
  Future<void> getInternetAccess(Function? callback, Duration? delay) async {
    sendFrame(
        frame: SnBluetoothBleStompClientSendFrame(
            headers: {'destination': pingDestination}),
        callback: callback,
        delay: delay);
  }
}
