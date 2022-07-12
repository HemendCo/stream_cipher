library stream_cipher.cipher_models;

import 'dart:io' show File, gzip;
import 'dart:typed_data' show Uint8List;
import 'package:encrypt/encrypt.dart' //
    show
        AES,
        IV,
        Encrypter,
        Key;
import 'package:pointycastle/asymmetric/rsa.dart' show RSAEngine;
import 'package:pointycastle/pointycastle.dart' //
    show
        PublicKeyParameter,
        RSAPublicKey;

import '../stream_cipher.dart' show IByteDataEncrypter;
import 'cipher_utils/rsa/rsa_key_extensions.dart';
import 'cipher_utils/rsa/rsa_tools.dart';

class NoEncryptionByteDataEncrypter extends IByteDataEncrypter {
  @override
  Uint8List encrypt(Uint8List data) => data;

  @override
  String get encryptMethod => 'NONE';
}

class AESByteDataEncrypter extends IByteDataEncrypter {
  /// AESKey is a key that is used to encrypt and decrypt data.
  ///
  /// it is a `two-way` key.
  final Key key;

  /// AES-IV is a initialization vector that is used to encrypt and decrypt data
  final IV iv;

  /// AES Encrypter instance that is used to encrypt data.
  final Encrypter _encrypter;

  /// A [IByteDataEncrypter] that encrypts data using AES.
  AESByteDataEncrypter({
    required this.key,
    required this.iv,
  }) : _encrypter = Encrypter(AES(key));

  /// create [AESByteDataEncrypter] instance with
  /// utf8 [String] of [Key] and [IV]
  factory AESByteDataEncrypter.fromString({
    required String key,
    required String iv,
  }) =>
      AESByteDataEncrypter(
        key: Key.fromUtf8(key),
        iv: IV.fromUtf8(iv),
      );

  /// create [AESByteDataEncrypter] instance with random secure [Key] and [IV]
  ///
  /// consider saving the [key] and [iv] after using this method.
  /// this values will be lost if you don't store them.
  factory AESByteDataEncrypter.randomSecureKey() => AESByteDataEncrypter(
        key: Key.fromSecureRandom(32),
        iv: IV.fromSecureRandom(16),
      );

  /// lowest security level. only use in development.
  factory AESByteDataEncrypter.empty() => AESByteDataEncrypter(
        key: Key.fromLength(32),
        iv: IV.fromLength(16),
      );

  /// encrypt method that receives a [Uint8List] and then
  /// returns an encrypted [Uint8List]
  @override
  Uint8List encrypt(Uint8List data) {
    final encrypted = _encrypter.encryptBytes(data, iv: iv);
    return encrypted.bytes;
  }

  @override
  String get encryptMethod => 'AES';
}

class RSAByteDataEncrypter extends IByteDataEncrypter {
  /// [RSAPublicKey] is a key that is used to encrypt data.
  final RSAPublicKey publicKey;

  /// RSA Encrypter instance that is used to encrypt data.
  // final Encrypter _encrypter;
  final RSAEngine _engine;
  int get inputBlocSize => _engine.inputBlockSize;
  RSAByteDataEncrypter({required this.publicKey})
      : _engine = RSAEngine()
          ..init(
            true,
            PublicKeyParameter<RSAPublicKey>(
              publicKey,
            ),
          );

  /// parse a string into [RSAPublicKey] object
  factory RSAByteDataEncrypter.fromString(String key) {
    final isPkcs1 = key
            .split(
              '\n',
            )
            .first ==
        RSAKeyMetaData.BEGIN_RSA_PUBLIC_KEY;
    return RSAByteDataEncrypter(
      publicKey: isPkcs1
          ? RSAKeyTools.rsaPublicKeyFromPemPkcs1(
              key,
            )
          : RSAKeyTools.rsaPublicKeyFromPem(
              key,
            ),
    );
  }

  /// loads public key from a file in async mode.
  static Future<RSAByteDataEncrypter> fromFile(String fileAddress) async {
    final publicKey = await File(fileAddress).readAsString();
    return RSAByteDataEncrypter.fromString(publicKey);
  }

  /// loads public key from a file in sync mode.
  factory RSAByteDataEncrypter.fromFileSync(String fileAddress) {
    final file = File(fileAddress);
    final key = file.readAsStringSync();
    return RSAByteDataEncrypter.fromString(key);
  }

  /// encrypt method that receives a [Uint8List] and then returns an
  /// encrypted [Uint8List] using RSA.
  @override
  Uint8List encrypt(Uint8List data) {
    assert(
      inputBlocSize >= data.length,
      '''data bloc size is bigger than expected. given bloc size is (${data.length}), expected bloc size is ($inputBlocSize)''',
    );

    final encrypted = _engine.process(data);

    return encrypted;
  }

  @override
  String get encryptMethod => _engine.algorithmName;

  @override
  Future<void> reset() async {
    _engine.reset();
  }
}

class GZipByteDataEncoder extends IByteDataEncrypter {
  @override
  Uint8List encrypt(Uint8List data) {
    return Uint8List.fromList(gzip.encoder.convert(data));
  }

  @override
  String get encryptMethod => 'GZIP';
}

class MultiLayerEncrypter extends IByteDataEncrypter {
  final List<IByteDataEncrypter> _encrypters;
  MultiLayerEncrypter(
    List<IByteDataEncrypter> encrypters,
  ) : _encrypters = encrypters.reversed.toList();
  @override
  Uint8List encrypt(Uint8List data) {
    var result = data;
    for (final encrypter in _encrypters) {
      result = encrypter.encrypt(result);
    }
    return result;
  }

  @override
  String get encryptMethod => _encrypters.reversed
      .map(
        (e) => e.encryptMethod,
      )
      .join(
        '->',
      );
}
