library sn_bluetooth_ble_stomp_client;

/// An exception raised when the server is waiting to start.
class SnBluetoothBleStompClientWaitingException implements Exception {
  SnBluetoothBleStompClientWaitingException(
      {this.message = 'Server is waiting to start'});

  final String? message;
}
