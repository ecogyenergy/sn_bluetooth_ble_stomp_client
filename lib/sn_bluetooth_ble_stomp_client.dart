library sn_bluetooth_ble_stomp_client;

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_response_exception.dart';
import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_stomp_status.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_authenticate_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_send_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_subscribe_frame.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_authorization_exception.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_frame_command.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_message_status.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_timeout_exception.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_unexpected_exception.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_waiting_exception.dart';

/// A simple SolarNetwork specific BLE STOMP client that uses
/// bluetooth_ble_stomp_client.
class SnBluetoothBleStompClient extends BluetoothBleStompClient {
  static const String setupDestination = '/setup/**';
  static const String latestDatumDestination = '/setup/datum/latest';
  static const String internetAccessDestination = '/setup/internet/access';
  static const String pingDestination = '/setup/network/ping';

  SnBluetoothBleStompClient({
    required DiscoveredDevice device,
    required Uuid serviceUuid,
    required Uuid readCharacteristicUuid,
    required Uuid writeCharacteristicUuid,
    Function(ConnectionStateUpdate)? stateCallback,
    Duration? actionDelay = const Duration(milliseconds: 500),
    void Function(String)? logMessage,
    BluetoothBleStompClientStompStatus status =
        BluetoothBleStompClientStompStatus.authenticated,
    required this.login,
    required this.password,
    required this.host,
  }) : super(
            device: device,
            serviceUuid: serviceUuid,
            readCharacteristicUuid: readCharacteristicUuid,
            writeCharacteristicUuid: writeCharacteristicUuid,
            stateCallback: stateCallback,
            logMessage: logMessage,
            status: status,
            actionDelay: actionDelay);

  final String login;
  final String password;
  final String host;

  late String session;
  int _latestId = 0;
  int _latestRequestId = 0;

  /// Check for an authenticated error frame.
  static bool isAuthorizedError({required BluetoothBleStompClientFrame frame}) {
    if (frame.command == SnBluetoothBleStompClientFrameCommand.error.value) {
      if (frame.headers['message'] == 'Not authorized.' ||
          frame.headers['message'] ==
              'Must start with CONNECT or STOMP frame.') {
        return true;
      }
    }
    return false;
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

  /// Connect to the the server.
  Future<bool> connect({String? acceptVersion = '1.2', Duration? delay}) async {
    await send(
        command: SnBluetoothBleStompClientFrameCommand.connect.value,
        headers: {
          'accept-version': acceptVersion!,
          'host': host,
          'login': login,
        },
        delay: delay);

    /// Evaluate the response.
    List<int> rawResponse = await read();
    BluetoothBleStompClientFrame response;
    try {
      response = BluetoothBleStompClientFrame.fromBytes(
          bytes: rawResponse,
          validCommands: validSnBluetoothBleStompClientFrameCommandValues);
    } on BluetoothBleStompClientResponseException {
      /// In the case of any bad response when connecting, assume that the
      /// server is waiting. Timeout should not be an issue for this operation.
      status = BluetoothBleStompClientStompStatus.unauthenticated;
      throw SnBluetoothBleStompClientWaitingException();
    }

    /// Check if already connected and authenticated.
    if (response.headers['message'] == "Already connected.") {
      status = BluetoothBleStompClientStompStatus.unauthenticated;
      return false;
    }

    /// If a CONNECTED command is sent back, then attempt to authenticate.
    String authHashParamSalt;
    try {
      session = response.headers['session']!;
      authHashParamSalt = response.headers['auth-hash-param-salt']!;
    } catch (e) {
      throw SnBluetoothBleStompClientUnexpectedException(frame: response);
    }

    return await _authenticate(
        salt: authHashParamSalt, date: DateTime.now().toUtc());
  }

  /// Authenticate to the server.
  ///
  /// NOTE: Only the BCrypt digest algorithm is supported.
  Future<bool> _authenticate(
      {required String salt, required DateTime date, Duration? delay}) async {
    await sendFrame(
        frame: SnBluetoothBleStompClientAuthenticateFrame(
            password: password, salt: salt, login: login, date: date),
        delay: delay);

    List<int> rawResponse = await read();
    try {
      BluetoothBleStompClientFrame.fromBytes(
          bytes: rawResponse,
          validCommands: validSnBluetoothBleStompClientFrameCommandValues);
    } on BluetoothBleStompClientResponseException {
      if (BluetoothBleStompClient.readResponseEquality(
          one: rawResponse, two: BluetoothBleStompClient.nullResponse)) {
        status = BluetoothBleStompClientStompStatus.authenticated;

        /// All authenticated clients should be subscribed to the setup
        /// destination.
        await subscribe(
            destination: SnBluetoothBleStompClient.setupDestination);
        return true;
      }
    }

    status = BluetoothBleStompClientStompStatus.unauthenticated;
    return false;
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

    List<int> rawResponse = await read();
    BluetoothBleStompClientFrame response;
    try {
      response = BluetoothBleStompClientFrame.fromBytes(
          bytes: rawResponse,
          validCommands: validSnBluetoothBleStompClientFrameCommandValues);

      /// Check for not authenticated.
      if (SnBluetoothBleStompClient.isAuthorizedError(frame: response)) {
        status = BluetoothBleStompClientStompStatus.unauthenticated;
        throw SnBluetoothBleStompClientAuthorizationException();
      }

      /// Evaluate response.
      if (response.headers['status'] ==
          SnBluetoothBleStompClientMessageStatus.ok.value) {
        return response.bodyReadable;
      }
    } on BluetoothBleStompClientResponseException {
      if (BluetoothBleStompClient.readResponseEquality(
          one: rawResponse, two: BluetoothBleStompClient.warningResponse)) {
        status = BluetoothBleStompClientStompStatus.unauthenticated;
        throw SnBluetoothBleStompClientWaitingException();
      } else if (BluetoothBleStompClient.readResponseEquality(
          one: rawResponse, two: BluetoothBleStompClient.nullResponse)) {
        throw SnBluetoothBleStompClientTimeoutException();
      }
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

    List<int> rawResponse = await read();
    BluetoothBleStompClientFrame response;
    try {
      response = BluetoothBleStompClientFrame.fromBytes(
          bytes: rawResponse,
          validCommands: validSnBluetoothBleStompClientFrameCommandValues);

      /// Check for not authenticated.
      if (SnBluetoothBleStompClient.isAuthorizedError(frame: response)) {
        status = BluetoothBleStompClientStompStatus.unauthenticated;
        throw SnBluetoothBleStompClientAuthorizationException();
      }

      /// Evaluate response.
      if ((response.headers['status']! ==
              SnBluetoothBleStompClientMessageStatus.ok.value) &&
          response.body != null &&
          response.body == '\u0000') {
        return true;
      }
    } on BluetoothBleStompClientResponseException {
      if (BluetoothBleStompClient.readResponseEquality(
          one: rawResponse, two: BluetoothBleStompClient.warningResponse)) {
        status = BluetoothBleStompClientStompStatus.unauthenticated;
        throw SnBluetoothBleStompClientWaitingException();
      } else if (BluetoothBleStompClient.readResponseEquality(
          one: rawResponse, two: BluetoothBleStompClient.nullResponse)) {
        throw SnBluetoothBleStompClientTimeoutException();
      }
    }
  }
}
