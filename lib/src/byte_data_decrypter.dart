library stream_cipher.cipher_models;

import 'dart:io' show File, gzip;
import 'dart:math' show Random;
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

class NoEncryptionByteDataDecrypter extends IByteDataDecrypter {
  @override
  Uint8List decrypt(Uint8List data) => data;

  @override
  String get encryptMethod => 'NONE';
}

class AESByteDataDecrypter extends IByteDataDecrypter {
  /// AESKey is a key that is used to encrypt and decrypt data.
  ///
  /// it is a `two-way` key.
  final Uint8List key;

  /// AES-IV is a initialization vector that is used to encrypt and decrypt data
  final Uint8List iv;

  /// AES Decrypter instance that is used to encrypt data.
  final CBCBlockCipher _engine;

  /// A [IByteDataDecrypter] that encrypts data using AES.
  AESByteDataDecrypter({
    required this.key,
    required this.iv,
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

  /// create [AESByteDataDecrypter] instance with random secure `key` and `iv`.
  ///
  /// consider saving the [key] and [iv] after using this method.
  /// this values will be lost if you don't store them.
  factory AESByteDataDecrypter.randomSecureKey() => AESByteDataDecrypter(
        key: Uint8List.fromList(
          List<int>.generate(32, (i) => Random.secure().nextInt(255)).toList(),
        ),
        iv: Uint8List.fromList(
          List<int>.generate(16, (i) => Random.secure().nextInt(255)).toList(),
        ),
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

class RSAByteDataDecrypter extends IByteDataDecrypter {
  /// [RSAPrivateKey] is a key that is used to encrypt data.
  final RSAPrivateKey privateKey;

  /// RSA Decrypter instance that is used to encrypt data.

  final RSAEngine _engine;
  int get inputBlocSize => _engine.inputBlockSize;
  int get outputBlocSize => _engine.outputBlockSize;
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

class GZipByteDataDecoder extends IByteDataDecrypter {
  @override
  Uint8List decrypt(Uint8List data) {
    return Uint8List.fromList(gzip.decode(data));
  }

  @override
  String get encryptMethod => 'GZIP';
}

class MultiLayerDecrypter extends IByteDataDecrypter {
  final List<IByteDataDecrypter> _decrypters;
  MultiLayerDecrypter(this._decrypters);
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
