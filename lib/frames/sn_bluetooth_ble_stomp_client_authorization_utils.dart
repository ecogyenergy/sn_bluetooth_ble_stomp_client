import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:intl/intl.dart';

/// Authorization utilities that are used to properly encrypt and format
/// the authorization header.
class SnBluetoothBleStompClientAuthorizationUtils {
  static final signingKeyDateFormat = DateFormat('yyyyMMdd');
  static final authorizationTimestampFormat =
  DateFormat("yyyyMMdd'T'HHmmss'Z'");
  static final emptyStringSha256Hex = sha256.convert([]);

  /// Compute a HMAC-SHA256 digest from UTF-8 string value key.
  static Uint8List computeHmacSha256String(final String key, final String msg) {
    return Uint8List.fromList(computeMacDigestString(key, msg).bytes);
  }

  /// Compute a HMAC-SHA256 digest from a byte array key.
  static Uint8List computeHmacSha256Uint8List(
      final Uint8List key, final String msg) {
    return Uint8List.fromList(
        computeMacDigestUint8List(key, Uint8List.fromList(utf8.encode(msg)))
            .bytes);
  }

  /// Compute a MAC digest from UTF-8 values.
  static Digest computeMacDigestString(final String secret, final String msg) {
    return computeMacDigestUint8List(Uint8List.fromList(utf8.encode(secret)),
        Uint8List.fromList(utf8.encode(msg)));
  }

  /// Compute a MAC digest from a byte array.
  static Digest computeMacDigestUint8List(
      final Uint8List key, final Uint8List msg) {
    var hmacSha256 = Hmac(sha256, key);
    return hmacSha256.convert(msg);
  }

  /// Compute an HMAC-SHA256 hex-encoded signature value from a given signing
  /// key and signature data.
  static String computeHmacSha256Hex(
      Uint8List signingKey, String signatureData) {
    return HEX.encode(computeHmacSha256Uint8List(signingKey, signatureData));
  }
}
