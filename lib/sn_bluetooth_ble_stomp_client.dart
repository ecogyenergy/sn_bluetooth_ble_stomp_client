library sn_bluetooth_ble_stomp_client;

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

  SnBluetoothBleStompClient({
    required BluetoothCharacteristic writeCharacteristic,
    required BluetoothCharacteristic readCharacteristic,
    Duration? actionDelay,
    int? consecutiveAttempts,
    required this.login,
    required this.password,
    required this.host,
  }) : super(
            writeCharacteristic: writeCharacteristic,
            readCharacteristic: readCharacteristic,
            actionDelay: actionDelay,
            consecutiveAttempts: consecutiveAttempts);

  final String login;
  final String password;
  final String host;

  late String session;
  int _latestId = 0;
  int _latestRequestId = 0;

  bool authenticated = false;

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
  Future<void> connect(
      {String? acceptVersion = '1.2', Duration? delay, int? attempts}) async {
    await send(
        command: SnBluetoothBleStompClientFrameCommand.connect.value,
        headers: {
          'accept-version': acceptVersion!,
          'host': host,
          'login': login,
        },
        delay: delay,
        attempts: attempts);

    /// Evaluate the response.
    BluetoothBleStompClientFrame response =
        BluetoothBleStompClientFrame.fromBytes(bytes: await read());
    switch (response.command) {

      /// If a CONNECTED command is sent back, then attempt to authenticate.
      case 'CONNECTED':
        session = response.headers['session']!;

        String authHashParamSalt = response.headers['auth-hash-param-salt']!;
        await _authenticate(
            salt: authHashParamSalt, date: DateTime.now().toUtc());
    }
  }

  /// Authenticate to the server.
  Future<void> _authenticate(
      {required String salt,
      required DateTime date,
      Duration? delay,
      int? attempts}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientAuthenticateFrame(
            password: password, salt: salt, login: login, date: date),
        delay: delay,
        attempts: attempts);

    /// If the next read is a null, then assume that authentication was
    /// successful.
    if (await nullRead() == true) {
      authenticated = true;
      await subscribe(destination: '/setup/**');
    }
  }

  /// Subscribe to a destination topic with the given id.
  Future<void> subscribe(
      {required String destination, Duration? delay, int? attempts}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientSubscribeFrame(
            destination: destination, id: _getId()),
        delay: delay,
        attempts: attempts);
  }

  /// Get the latest datum of the node.
  Future<void> getLatestDatum({Duration? delay, int? attempts}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientSendFrame(headers: {
          'destination': latestDatumDestination,
          'request-id': _getRequestId()
        }),
        delay: delay,
        attempts: attempts);
  }

  /// Get the status of internet access.
  Future<void> getInternetAccess({Duration? delay, int? attempts}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientSendFrame(
            headers: {'destination': pingDestination}),
        delay: delay,
        attempts: attempts);
  }
}
