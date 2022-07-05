library http_request_cipher.cipher_models;

import 'dart:io';
import 'dart:typed_data';
import 'package:blowfish_ecb/blowfish_ecb.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

import '../http_request_cipher.dart';

class NoEncryptionByteDataEncrypter extends IByteDataEncrypter {
  @override
  Uint8List encrypt(Uint8List data) => data;
}

class AESByteDataEncrypter extends IByteDataEncrypter {
  /// AESKey is a key that is used to encrypt and decrypt data.
  ///
  /// it is a `two-way` key.
  final Key key;

  /// AES-IV is a initialization vector that is used to encrypt and decrypt data.
  final IV iv;

  /// AES Encrypter instance that is used to encrypt data.
  final Encrypter _encrypter;

  /// A [IByteDataEncrypter] that encrypts data using AES.
  AESByteDataEncrypter({required this.key, required this.iv}) : _encrypter = Encrypter(AES(key));

  /// create [AESByteDataEncrypter] instance with utf8 [String] of [Key] and [IV]
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
}

class RSAByteDataEncrypter extends IByteDataEncrypter {
  /// [RSAPublicKey] is a key that is used to encrypt data.
  final RSAPublicKey publicKey;

  /// RSA Encrypter instance that is used to encrypt data.
  final Encrypter _encrypter;
  RSAByteDataEncrypter({required this.publicKey})
      : _encrypter = Encrypter(RSA(
          publicKey: publicKey,
        ));

  /// parse a string into [RSAPublicKey] object
  factory RSAByteDataEncrypter.fromString(String key) {
    final parser = RSAKeyParser();
    return RSAByteDataEncrypter(
      publicKey: parser.parse(key) as RSAPublicKey,
    );
  }

  // /// load public key from an asset file.
  // static Future<RSAByteDataEncrypter> loadPublicKeyFromAsset(String assetId) async {
  //   return RSAByteDataEncrypter.fromString(await rootBundle.loadString(assetId));
  // }

  /// loads public key from a file in async mode.
  static Future<RSAByteDataEncrypter> fromFile(String fileAddress) async {
    final publicKey = await File(fileAddress).readAsString();
    return RSAByteDataEncrypter.fromString(publicKey);
  }

  /// loads public key from a file in sync mode.
  factory RSAByteDataEncrypter.fromFileSync(String fileAddress) {
    // return parser.parse(key) as T;
    final file = File(fileAddress);
    final key = file.readAsStringSync();
    return RSAByteDataEncrypter.fromString(key);
  }

  /// encrypt method that receives a [Uint8List] and then returns an
  /// encrypted [Uint8List] using RSA.
  @override
  Uint8List encrypt(Uint8List data) {
    final encrypted = _encrypter.encryptBytes(data);
    return encrypted.bytes;
  }
}

class BlowFishByteDataEncrypter extends IByteDataEncrypter {
  // final key = Uint8List.fromList([15, 15, 15, 15, 15, 15, 15, 15, 15]);
  final BlowfishECB encoder;
  BlowFishByteDataEncrypter({required Uint8List key})
      : assert(key.length < 56, "key size cannot be bigger than 56 bytes"),
        encoder = BlowfishECB(key);
  factory BlowFishByteDataEncrypter.fromString(String key) =>
      BlowFishByteDataEncrypter(key: Uint8List.fromList(key.codeUnits));
  @override
  Uint8List encrypt(Uint8List data) {
    int padLength = 0;
    if (data.length % 8 != 0) {
      padLength = (8 - (data.length % 8));
      data = Uint8List(data.length + padLength);
    }
    if (padLength == 4) {
      print(data);
    }
    return Uint8List.fromList([padLength, ...encoder.encode(data)]);
    // return Future.value(Uint8List.fromList(gzip.encoder.convert(data)));
  }
}

class GZipByteDataEncrypter extends IByteDataEncrypter {
  @override
  Uint8List encrypt(Uint8List data) {
    return Uint8List.fromList(gzip.encoder.convert(data));
  }
}
