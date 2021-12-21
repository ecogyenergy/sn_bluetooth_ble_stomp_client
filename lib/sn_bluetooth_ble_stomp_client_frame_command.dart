library sn_bluetooth_ble_stomp_client;

/// The commands found in the SolarNetwork STOMP server.
enum SnBluetoothBleStompClientFrameCommand {
  abort,
  ack,
  begin,
  commit,
  connect,
  connected,
  disconnect,
  error,
  message,
  nack,
  receipt,
  send,
  subscribe,
  stomp,
  unsubscribe
}

/// The corresponding command value expected in the frame.
extension SnBluetoothBleStompClientFrameCommandExtension
    on SnBluetoothBleStompClientFrameCommand {
  String get value {
    switch (this) {
      case SnBluetoothBleStompClientFrameCommand.abort:
        return 'ABORT';
      case SnBluetoothBleStompClientFrameCommand.ack:
        return 'ACK';
      case SnBluetoothBleStompClientFrameCommand.begin:
        return 'BEGIN';
      case SnBluetoothBleStompClientFrameCommand.commit:
        return 'COMMIT';
      case SnBluetoothBleStompClientFrameCommand.connect:
        return 'CONNECT';
      case SnBluetoothBleStompClientFrameCommand.connected:
        return 'CONNECTED';
      case SnBluetoothBleStompClientFrameCommand.disconnect:
        return 'DISCONNECT';
      case SnBluetoothBleStompClientFrameCommand.error:
        return 'ERROR';
      case SnBluetoothBleStompClientFrameCommand.message:
        return 'MESSAGE';
      case SnBluetoothBleStompClientFrameCommand.nack:
        return 'NACK';
      case SnBluetoothBleStompClientFrameCommand.receipt:
        return 'RECEIPT';
      case SnBluetoothBleStompClientFrameCommand.send:
        return 'SEND';
      case SnBluetoothBleStompClientFrameCommand.subscribe:
        return 'SUBSCRIBE';
      case SnBluetoothBleStompClientFrameCommand.stomp:
        return 'STOMP';
      case SnBluetoothBleStompClientFrameCommand.unsubscribe:
        return 'UNSUBSCRIBE';
    }
  }
}

const Set<String> validSnBluetoothBleStompClientFrameCommandValues = {
  'ABORT',
  'ACK',
  'BEGIN',
  'COMMIT',
  'CONNECT',
  'CONNECTED',
  'DISCONNECT',
  'ERROR',
  'MESSAGE',
  'NACK',
  'RECEIPT',
  'SEND',
  'SUBSCRIBE',
  'STOMP',
  'UNSUBSCRIBE'
};
