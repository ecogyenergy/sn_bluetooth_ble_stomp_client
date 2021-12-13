library sn_bluetooth_ble_stomp_client;

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_response_exception.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_authenticate_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_send_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_subscribe_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_frame_command.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_message_status.dart';

/// A simple SolarNetwork specific BLE STOMP client that uses
/// bluetooth_ble_stomp_client.
class SnBluetoothBleStompClient extends BluetoothBleStompClient {
  static const String setupDestination = '/setup/**';
  static const String latestDatumDestination = '/setup/datum/latest';
  static const String internetAccessDestination = '/setup/internet/access';
  static const String pingDestination = '/setup/network/ping';

  SnBluetoothBleStompClient({
    required QualifiedCharacteristic readCharacteristic,
    required QualifiedCharacteristic writeCharacteristic,
    Duration? actionDelay = const Duration(seconds: 1),
    required this.login,
    required this.password,
    required this.host,
  }) : super(
            writeCharacteristic: writeCharacteristic,
            readCharacteristic: readCharacteristic,
            actionDelay: actionDelay);

  final String login;
  final String password;
  final String host;

  late String session;
  int _latestId = 0;
  int _latestRequestId = 0;

  bool authenticated = false;
  bool waiting = false;

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
  Future<void> connect({String? acceptVersion = '1.2', Duration? delay}) async {
    await send(
        command: SnBluetoothBleStompClientFrameCommand.connect.value,
        headers: {
          'accept-version': acceptVersion!,
          'host': host,
          'login': login,
        },
        delay: delay);

    /// Evaluate the response.
    BluetoothBleStompClientFrame response;
    try {
      response = BluetoothBleStompClientFrame.fromBytes(bytes: await read());
    } on BluetoothBleStompClientResponseException {
      /// If a frame cannot be made of the response, then assume that the server
      /// is currently starting.
      waiting = true;
      return;
    }
    waiting = false;

    print(response.result);

    /// If a CONNECTED command is sent back, then attempt to authenticate.
    if (response.command ==
        SnBluetoothBleStompClientFrameCommand.connected.value) {
      session = response.headers['session']!;

      String authHashParamSalt = response.headers['auth-hash-param-salt']!;
      await _authenticate(
          salt: authHashParamSalt, date: DateTime.now().toUtc());
    }
  }

  /// Authenticate to the server.
  ///
  /// NOTE: Only the BCrypt digest algorithm is supported.
  Future<void> _authenticate(
      {required String salt, required DateTime date, Duration? delay}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientAuthenticateFrame(
            password: password, salt: salt, login: login, date: date),
        delay: delay);

    /// If the next read is a null, then assume that authentication was
    /// successful.
    if (await nullRead() == true) {
      authenticated = true;
      await subscribe(destination: setupDestination);
    }
  }

  /// Subscribe to a destination topic with the given id.
  Future<void> subscribe({required String destination, Duration? delay}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientSubscribeFrame(
            destination: destination, id: _getId()),
        delay: delay);
  }

  /// Get the latest datum of the node.
  ///
  /// NOTE: A successful request does not mean that the latest datum is correct
  /// or as the user may expect.
  ///
  /// For example, this can result in an empty body of "[]". This is an
  /// expected result from the server's perspective, so it is returned as not
  /// null, but it might not be what the user expects.
  Future<String?> getLatestDatum({Duration? delay}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientSendFrame(headers: {
          'destination': latestDatumDestination,
          'request-id': _getRequestId()
        }),
        delay: delay);

    BluetoothBleStompClientFrame response;
    try {
      response = BluetoothBleStompClientFrame.fromBytes(bytes: await read());
      if (response.headers['status']! ==
          SnBluetoothBleStompClientMessageStatus.ok.value) {
        return response.bodyReadable;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get the status of internet access.
  ///
  /// If there is no provided serviceName, then the destination will be sent to:
  ///
  ///   /setup/network/ping
  ///
  /// Providing serviceName results in the destination:
  ///
  ///   /setup/network/ping/serviceName
  Future<bool?> getInternetAccess(
      {Duration? delay, String? serviceName}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientSendFrame(headers: {
          'destination': serviceName == null
              ? pingDestination
              : pingDestination + '/$serviceName'
        }),
        delay: delay);

    BluetoothBleStompClientFrame response;
    try {
      response = BluetoothBleStompClientFrame.fromBytes(bytes: await read());
      if ((response.headers['status']! ==
              SnBluetoothBleStompClientMessageStatus.ok.value) &&
          response.body != null &&
          response.body == '\u0000') {
        return true;
      }
    } catch (e) {
      return false;
    }

    return false;
  }
}
