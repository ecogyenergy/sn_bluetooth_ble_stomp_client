/// Possible message status responses from the server.
enum SnBluetoothBleStompClientMessageStatus {
  ok,
  accepted,
  notFound,
  unProcessable,
  internalError
}

/// Values associated with each message status.
extension SnBluetoothBleStompClientMessageStatusExtension
on SnBluetoothBleStompClientMessageStatus {
  String get value {
    switch (this) {
      case SnBluetoothBleStompClientMessageStatus.ok:
        return '200';
      case SnBluetoothBleStompClientMessageStatus.accepted:
        return '202';
      case SnBluetoothBleStompClientMessageStatus.notFound:
        return '404';
      case SnBluetoothBleStompClientMessageStatus.unProcessable:
        return '422';
      case SnBluetoothBleStompClientMessageStatus.internalError:
        return '500';
    }
  }
}
