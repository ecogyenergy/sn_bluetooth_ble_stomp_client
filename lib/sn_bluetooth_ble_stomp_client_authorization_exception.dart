library sn_bluetooth_ble_stomp_client;

/// An exception raised after a timeout.
///
/// For this specific implementation, when we receive a
/// BluetoothBleStompClient.nullResponse, we infer that the server has reached a
/// time out.
class SnBluetoothBleStompClientAuthorizationException implements Exception {
  SnBluetoothBleStompClientAuthorizationException(
      {this.message = 'Client is not authorized.'});

  final String? message;
}
