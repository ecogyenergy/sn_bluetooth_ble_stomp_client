import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_ble_stomp_client/bluetooth_ble_stomp_client_frame.dart';
import 'package:crypto/crypto.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:hex/hex.dart';
import 'package:sn_bluetooth_ble_stomp_client/frames/sn_bluetooth_ble_stomp_client_authorization_utils.dart';
import 'package:sn_bluetooth_ble_stomp_client/sn_bluetooth_ble_stomp_client_frame_command.dart';

/// Create an authenticate frame to send to the SolarNetwork STOMP server.
class SnBluetoothBleStompClientAuthenticateFrame
    extends BluetoothBleStompClientFrame {
  static const String authorizationComponentCredential = 'Credential';
  static const String authorizationComponentHeaders = 'SignedHeaders';
  static const String authorizationComponentSignature = 'Signature';

  static const String signingKeyMessageLiteral = 'sns_request';
  static const String signingScheme = 'SNS';

  static const String authenticateDestination = '/setup/authenticate';

  SnBluetoothBleStompClientAuthenticateFrame(
      {required String password,
      required String salt,
      required this.login,
      required this.date})
      : super(

            /// Construct most of the expected header here, except for the
            /// actual authorization header.
            ///
            /// The date header is:
            ///   1. In HTTP format
            ///   2. Formatted with ':' replaced with '\\c' to differentiate it
            ///      from a header:value pair.
            command: SnBluetoothBleStompClientFrameCommand.send.value,
            headers: {
              'destination': authenticateDestination,
              'date': HttpDate.format(date).replaceAll(':', '\\c'),
              'authorization': authorizationHeader(
                  createSecret(password, salt), date, login),
            });

  final String login;
  final DateTime date;

  /// Create a secret key given a password and salt.
  static String createSecret(String password, String salt) {
    return sha256
        .convert(utf8.encode(DBCrypt().hashpw(password, salt)))
        .toString();
  }

  /// Construct the expected authorization header.
  /// Should follow the form of:
  ///
  /// signingScheme Credential=login,SignedHeaders=date,Signature=signature
  static String authorizationHeader(
      String secret, DateTime date, String login) {
    /// 1. Get the signing key.
    Uint8List signingKey = computeSigningKey(signingScheme, date, secret);

    /// 2. Build the signature.
    String signature = buildSignature(signingKey, date);

    /// 3, Write the header.
    StringBuffer buf = StringBuffer(signingScheme);
    buf.writeAll([
      ' ',
      authorizationComponentCredential,
      '=',
      login,
      ',',
      authorizationComponentHeaders,
      '=',
      'date',
      ',',
      authorizationComponentSignature,
      '=',
      signature
    ]);
    return buf.toString();
  }

  /// Compute the signing key from the secret key and date.
  ///
  /// The passed date should be in form:
  /// YYYYMMDD
  static Uint8List computeSigningKey(
      String schemeName, DateTime date, String secret) {
    return SnBluetoothBleStompClientAuthorizationUtils
        .computeHmacSha256Uint8List(
            Uint8List.fromList(SnBluetoothBleStompClientAuthorizationUtils
                .computeHmacSha256String(
                    schemeName + secret,
                    SnBluetoothBleStompClientAuthorizationUtils
                        .signingKeyDateFormat
                        .format(date.toUtc()))),
            signingKeyMessageLiteral);
  }

  /// Build a signature value.
  static String buildSignature(Uint8List signingKey, DateTime date) {
    String signatureData = computeSignatureData(
        date, computeCanonicalRequestMessage(['date'], date));
    return SnBluetoothBleStompClientAuthorizationUtils.computeHmacSha256Hex(
        signingKey, signatureData);
  }

  /// Compute the final signature data.
  ///
  /// The date used in the timestamp should be in the form of:
  /// YYYYMMDDZ
  static String computeSignatureData(
      DateTime date, String canonicalRequestMessage) {
    return signingScheme +
        '-HMAC-SHA256\n' +
        SnBluetoothBleStompClientAuthorizationUtils.authorizationTimestampFormat
            .format(date) +
        '\n' +
        HEX.encode(sha256.convert(utf8.encode(canonicalRequestMessage)).bytes);
  }

  /// Compute the canonical request message.
  static String computeCanonicalRequestMessage(
      List<String> headerNames, DateTime date) {
    StringBuffer buf = StringBuffer('SEND');

    buf.write('\n$authenticateDestination\n');

    buf.write('date:');
    buf.write(HttpDate.format(date));

    buf.write('\ndate\n');
    buf.write(SnBluetoothBleStompClientAuthorizationUtils.emptyStringSha256Hex);

    return buf.toString();
  }
}
