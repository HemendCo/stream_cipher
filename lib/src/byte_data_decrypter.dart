library stream_cipher.cipher_models;

import 'dart:convert';
import 'dart:typed_data' show Uint8List;
import 'package:pointycastle/asymmetric/rsa.dart' show RSAEngine;
import 'package:pointycastle/block/aes.dart' show AESEngine;
import 'package:pointycastle/block/modes/cbc.dart' show CBCBlockCipher;
import 'package:pointycastle/pointycastle.dart' //
    show
        KeyParameter,
        ParametersWithIV,
        PrivateKeyParameter,
        RSAPrivateKey;

import 'cipher_utils/rsa/rsa_key_extensions.dart' show RSAKeyMetaData;
import 'cipher_utils/rsa/rsa_tools.dart' show RSAKeyTools;
import 'stream_cipher_base.dart' show IByteDataDecrypter;

/// this class will not decrypt/decode anything
///
/// the usecases may be as follows:
///
/// - receive raw data from a network request when request body needs to
/// be encrypted but body is raw data.
class NoEncryptionByteDataDecrypter extends IByteDataDecrypter {
  @override
  Uint8List decrypt(Uint8List data) => data;

  @override
  String get encryptMethod => 'NONE';
}

/// AES ByteData decrypter with CBC mode
///
/// using `PointyCastle` library to decrypt data
class AESByteDataDecrypter extends IByteDataDecrypter {
  /// AES Decrypter instance that is used to encrypt data.
  final CBCBlockCipher _engine;

  /// Creating an instance of [AESByteDataDecrypter] with aes key and iv.
  ///
  /// using [CBCBlockCipher] to decrypt data.
  AESByteDataDecrypter({
    required Uint8List key,
    required Uint8List iv,
  }) : _engine = CBCBlockCipher(AESEngine())
          ..init(
            false,
            ParametersWithIV(
              KeyParameter(key),
              iv,
            ),
          );

  /// create [AESByteDataDecrypter] instance with String key and String iv.
  factory AESByteDataDecrypter.fromString({
    required String key,
    required String iv,
  }) =>
      AESByteDataDecrypter(
        key: Uint8List.fromList(key.codeUnits),
        iv: Uint8List.fromList(iv.codeUnits),
      );

  /// lowest security level. only use in development.
  factory AESByteDataDecrypter.empty() => AESByteDataDecrypter(
        key: Uint8List(32),
        iv: Uint8List(16),
      );

  /// encrypt method that receives a [Uint8List] and then
  /// returns an encrypted [Uint8List]
  @override
  Uint8List decrypt(Uint8List data) {
    final paddedPlainText = Uint8List(data.length); // allocate space

    var offset = 0;
    while (offset < data.length) {
      offset += _engine.processBlock(data, offset, paddedPlainText, offset);
    }
    assert(offset == data.length);

    return Uint8List.fromList(
      paddedPlainText.where((byte) => byte != 0).toList(),
    );
  }

  @override
  Future<void> reset() async {
    _engine.reset();
  }

  @override
  String get encryptMethod => _engine.algorithmName;
}

/// RSA ByteData decrypter with RSA-OAEP
///
/// using `PointyCastle` library to decrypt data
class RSAByteDataDecrypter extends IByteDataDecrypter {
  /// RSA Decrypter instance that is used to encrypt data.
  final RSAEngine _engine;

  /// maximum possible input bloc size of RSA decrypter.
  int get inputBlocSize => _engine.inputBlockSize;
  int get outputBlocSize => _engine.outputBlockSize;

  /// generating a new [RSAByteDataDecrypter] instance with a [RSAPrivateKey].
  RSAByteDataDecrypter({required RSAPrivateKey privateKey})
      : _engine = RSAEngine()
          ..init(
            false,
            PrivateKeyParameter<RSAPrivateKey>(
              privateKey,
            ),
          );

  /// parse a string into [RSAPrivateKey] object
  factory RSAByteDataDecrypter.fromString(String key) {
    final isPkcs1 = key
            .split(
              '\n',
            )
            .first ==
        RSAKeyMetaData.BEGIN_RSA_PRIVATE_KEY;
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

  /// encrypt method that receives a [Uint8List] and then returns an
  /// encrypted [Uint8List] using RSA.
  @override
  Uint8List decrypt(Uint8List data) {
    assert(
      inputBlocSize >= data.length,
      '''data bloc size is bigger than expected. given bloc size is (${data.length}), expected bloc size is ($inputBlocSize)''',
    );
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
  String get encryptMethod => _engine.algorithmName;
  @override
  Future<void> reset() async {
    _engine.reset();
  }
}

/// a simple base64 decoder.
class Base64ByteDataDecoder extends IByteDataDecrypter {
  @override
  String get encryptMethod => 'BASE64';

  @override
  Uint8List decrypt(Uint8List data) {
    return Uint8List.fromList(
      base64.decoder.convert(
        String.fromCharCodes(data),
      ),
    );
  }
}

/// [MultiLayerDecrypter] can be used to concat a list of decrypters together
class MultiLayerDecrypter extends IByteDataDecrypter {
  final List<IByteDataDecrypter> _decrypters;

  /// creating an instance of [MultiLayerDecrypter] with given `decrypters`
  ///
  /// **note** : if you are using an `RSA` model or any other methods that
  /// limits the input size of decrypt method make sure to test this model
  MultiLayerDecrypter(this._decrypters) {
    final rsaDecrypters = _decrypters.where(
      (element) => element.encryptMethod == 'RSA',
    );
    if (rsaDecrypters.isNotEmpty) {
      print(
        'RSA is not ideal in MultiLayerDecrypter and may throw exception',
      );
    }
  }

  @override
  Future<void> reset() async {
    _decrypters.forEach((decrypter) => decrypter.reset());
  }

  @override
  Uint8List decrypt(Uint8List data) {
    var result = data;
    for (final decrypter in _decrypters) {
      result = decrypter.decrypt(result);
    }
    return result;
  }

  @override
  String get encryptMethod => _decrypters
      .map(
        (e) => e.encryptMethod,
      )
      .join(
        '->',
      );
}
