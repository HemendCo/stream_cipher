library stream_cipher.cipher_models;

import 'dart:convert' show base64;
import 'dart:math' show Random;
import 'dart:typed_data' show Uint8List;

import 'package:pointycastle/asymmetric/rsa.dart' show RSAEngine;
import 'package:pointycastle/block/aes.dart' show AESEngine;
import 'package:pointycastle/block/modes/cbc.dart' show CBCBlockCipher;
import 'package:pointycastle/pointycastle.dart' //
    show
        KeyParameter,
        ParametersWithIV,
        PublicKeyParameter,
        RSAPublicKey;

import '../stream_cipher.dart' show IByteDataEncrypter;
import 'cipher_utils/rsa/rsa_key_extensions.dart' show RSAKeyMetaData;
import 'cipher_utils/rsa/rsa_tools.dart' show RSAKeyTools;

/// this class will not encrypt/encode anything
///
/// the usecases may be as follows:
///
/// - sending raw data to network but receiving an encoded/encrypted message
class NoEncryptionByteDataEncrypter extends IByteDataEncrypter {
  @override
  Uint8List encrypt(Uint8List data) => data;

  @override
  String get encryptMethod => 'NONE';
}

/// an [IByteDataEncrypter] that uses `PointyCastle`'s `CBC/AES` method
/// to encode data.
class AESByteDataEncrypter extends IByteDataEncrypter {
  /// AESKey is a key that is used to encrypt and decrypt data.
  ///
  /// it is a `two-way` key.
  final Uint8List key;

  /// AES-IV is a initialization vector that is used to encrypt and decrypt data
  final Uint8List iv;

  /// AES Encrypter instance that is used to encrypt data.
  final CBCBlockCipher _engine;

  /// A [IByteDataEncrypter] that encrypts data using AES.
  AESByteDataEncrypter({
    required this.key,
    required this.iv,
  }) : _engine = CBCBlockCipher(AESEngine())
          ..init(
            true,
            ParametersWithIV(
              KeyParameter(key),
              iv,
            ),
          );

  /// create [AESByteDataEncrypter] instance with
  /// utf8 [String] of key and utf8 [String] of iv.
  factory AESByteDataEncrypter.fromString({
    required String key,
    required String iv,
  }) =>
      AESByteDataEncrypter(
        key: Uint8List.fromList(key.codeUnits),
        iv: Uint8List.fromList(iv.codeUnits),
      );

  /// create [AESByteDataEncrypter] instance with random secure `key` and `iv`.
  ///
  /// consider saving the [key] and [iv] after using this method.
  /// this values will be lost if you don't store them.
  factory AESByteDataEncrypter.randomSecureKey() => AESByteDataEncrypter(
        key: Uint8List.fromList(
          List<int>.generate(32, (i) => Random.secure().nextInt(255)).toList(),
        ),
        iv: Uint8List.fromList(
          List<int>.generate(16, (i) => Random.secure().nextInt(255)).toList(),
        ),
      );

  /// lowest security level. only use in development.
  factory AESByteDataEncrypter.empty() => AESByteDataEncrypter(
        key: Uint8List(32),
        iv: Uint8List(16),
      );

  /// encrypt method that receives a [Uint8List] and then
  /// returns an encrypted [Uint8List]
  @override
  Uint8List encrypt(Uint8List data) {
    final buffer = Uint8List.fromList(<int>[
      ...data,
      if (data.length % 16 != 0) ...List<int>.filled(16 - data.length % 16, 0),
    ]);
    final destination = Uint8List(buffer.length); // allocate space
    var offset = 0;
    while (offset < buffer.length) {
      offset += _engine.processBlock(buffer, offset, destination, offset);
    }
    assert(offset == buffer.length);
    return destination;
  }

  @override
  String get encryptMethod => _engine.algorithmName;
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

/// simple `Base64` byte data encoder
class Base64ByteDataEncoder extends IByteDataEncrypter {
  @override
  Uint8List encrypt(Uint8List data) {
    return Uint8List.fromList(base64.encoder.convert(data).codeUnits);
  }

  @override
  String get encryptMethod => 'BASE64';
}

/// [MultiLayerEncrypter] can be used to concat a list of encrypters together
class MultiLayerEncrypter extends IByteDataEncrypter {
  final List<IByteDataEncrypter> _encrypters;

  /// creating an instance of [MultiLayerEncrypter] with given `encrypters`
  ///
  /// **note** : if you are using an `RSA` model or any other methods that
  /// limits the input size of encrypt method make sure to test this model
  MultiLayerEncrypter(
    List<IByteDataEncrypter> encrypters,
  ) : _encrypters = encrypters.reversed.toList() {
    final rsaEncrypters = encrypters.where(
      (element) => element.encryptMethod == 'RSA',
    );
    if (rsaEncrypters.isNotEmpty) {
      print(
        'RSA is not ideal in MultiLayerEncrypter and may throw exception',
      );
    }
  }
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
