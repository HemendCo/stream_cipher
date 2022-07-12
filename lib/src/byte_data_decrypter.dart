library stream_cipher.cipher_models;

import 'dart:io' show File, gzip;
import 'dart:typed_data' show Uint8List;
import 'package:encrypt/encrypt.dart' //
    show
        AES,
        Encrypted,
        Encrypter,
        IV,
        Key;
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/pointycastle.dart' show PrivateKeyParameter, RSAPrivateKey;

import 'cipher_utils/rsa/rsa_key_extensions.dart';
import 'cipher_utils/rsa/rsa_tools.dart';
import 'stream_cipher_base.dart' show EncryptMethod, IByteDataDecrypter;

class NoEncryptionByteDataDecrypter extends IByteDataDecrypter {
  @override
  Uint8List decrypt(Uint8List data) => data;

  @override
  EncryptMethod get encryptMethod => EncryptMethod.none;
}

class AESByteDataDecrypter extends IByteDataDecrypter {
  /// AESKey is a key that is used to encrypt and decrypt data.
  ///
  /// it is a `two-way` key.
  final Key key;

  /// AES-IV is a initialization vector that is used to encrypt and decrypt data
  final IV iv;

  /// AES Decrypter instance that is used to encrypt data.
  final Encrypter _decrypter;

  /// A [IByteDataDecrypter] that encrypts data using AES.
  AESByteDataDecrypter({
    required this.key,
    required this.iv,
  }) : _decrypter = Encrypter(AES(key));

  /// create [AESByteDataDecrypter] instance with
  /// utf8 [String] of [Key] and [IV]
  factory AESByteDataDecrypter.fromString({
    required String key,
    required String iv,
  }) =>
      AESByteDataDecrypter(
        key: Key.fromUtf8(key),
        iv: IV.fromUtf8(iv),
      );

  /// create [AESByteDataDecrypter] instance with random secure [Key] and [IV]
  ///
  /// consider saving the [key] and [iv] after using this method.
  /// this values will be lost if you don't store them.
  factory AESByteDataDecrypter.randomSecureKey() => AESByteDataDecrypter(
        key: Key.fromSecureRandom(32),
        iv: IV.fromSecureRandom(16),
      );

  /// lowest security level. only use in development.
  factory AESByteDataDecrypter.empty() => AESByteDataDecrypter(
        key: Key.fromLength(32),
        iv: IV.fromLength(16),
      );

  /// encrypt method that receives a [Uint8List] and then
  /// returns an encrypted [Uint8List]
  @override
  Uint8List decrypt(Uint8List data) {
    final encrypted = _decrypter.decryptBytes(Encrypted(data), iv: iv);
    return Uint8List.fromList(encrypted);
  }

  @override
  EncryptMethod get encryptMethod => EncryptMethod.aes;
}

class RSAByteDataDecrypter extends IByteDataDecrypter {
  /// [RSAPrivateKey] is a key that is used to encrypt data.
  final RSAPrivateKey privateKey;

  /// RSA Decrypter instance that is used to encrypt data.

  final RSAEngine _engine;

  RSAByteDataDecrypter({required this.privateKey})
      : _engine = RSAEngine()
          ..init(
            false,
            PrivateKeyParameter<RSAPrivateKey>(
              privateKey,
            ),
          );

  /// loads private key from a file in async mode.

  /// parse a string into [RSAPrivateKey] object
  factory RSAByteDataDecrypter.fromString(String key) {
    final isPkcs1 = key.split('\n').first == KeyMetaData.BEGIN_RSA_PRIVATE_KEY;
    return RSAByteDataDecrypter(
      privateKey: isPkcs1
          ? RSAKeyTools.rsaPrivateKeyFromPemPkcs1(
              key,
            )
          : RSAKeyTools.rsaPrivateKeyFromPem(
              key,
            ),
    );
  }
  static Future<RSAByteDataDecrypter> fromFile(String fileAddress) async {
    final privateKey = await File(fileAddress).readAsString();
    return RSAByteDataDecrypter.fromString(privateKey);
  }

  /// loads private key from a file in sync mode.
  factory RSAByteDataDecrypter.fromFileSync(String fileAddress) {
    // return parser.parse(key) as T;
    final file = File(fileAddress);
    final key = file.readAsStringSync();
    return RSAByteDataDecrypter.fromString(key);
  }

  /// encrypt method that receives a [Uint8List] and then returns an
  /// encrypted [Uint8List] using RSA.
  @override
  Uint8List decrypt(Uint8List data) {
    final decrypted = _engine.process(data);
    return Uint8List.fromList(
      decrypted
          .where(
            (element) => element != 0,
          )
          .toList(),
    );
  }

  @override
  EncryptMethod get encryptMethod => EncryptMethod.rsa;
}

class GZipByteDataDecoder extends IByteDataDecrypter {
  @override
  Uint8List decrypt(Uint8List data) {
    return Uint8List.fromList(gzip.decode(data));
  }

  @override
  EncryptMethod get encryptMethod => EncryptMethod.gzip;
}
