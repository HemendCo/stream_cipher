library stream_cipher.rsa_key_tools;
// ignore_for_file: constant_identifier_names

import 'dart:convert' show LineSplitter, base64Decode;
import 'dart:typed_data' show Uint8List;

import 'package:pointycastle/asn1.dart' //
    show
        ASN1BitString,
        ASN1Integer,
        ASN1Parser,
        ASN1Sequence;
import 'package:pointycastle/export.dart'
    show
        AsymmetricKeyPair,
        ParametersWithRandom,
        RSAKeyGenerator,
        RSAKeyGeneratorParameters,
        RSAPrivateKey,
        RSAPublicKey,
        SecureRandom;

/// following toolkit will allow you to generate RSA keys or load them from PEM
/// encoded strings.
abstract class RSAKeyTools {
  RSAKeyTools._();

  /// generating a `Key-Pair` with a given [bitLength] as keySize
  /// and [secureRandom]
  ///
  /// this is not a asynchronous operation so be careful when using it.
  ///
  /// this operation will take time depending on the [bitLength]
  ///
  ///
  /// in my tests using isolates
  ///
  /// - it took less than `a second` to generate a key with a
  /// bitLength of `2048` bits.
  ///
  /// - `2` `seconds` to generate a key with a bitLength of `4096` bits.
  ///
  /// - `a minute` to generate a key with a bitLength of `8192` bits.
  ///
  /// - for a bitLength of `16384` bits it took about `15 minutes` to
  /// generate a key.
  ///
  /// so as you can see generating bigger keys need more time and for
  /// most usecases it is not an ideal solution.
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom, {
    int bitLength = 2048,
  }) {
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(
            BigInt.parse('65537'),
            bitLength,
            64,
          ),
          secureRandom,
        ),
      );

    final pair = keyGen.generateKeyPair();

    final pubKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(pubKey, privateKey);
  }

  /// load RSA (Public/Private) keys from **PEM Encoded String** (not file path).
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> loadKeyPair({
    required String privateKey,
    required String publicKey,
  }) {
    final pubKey = rsaPublicKeyFromPem(publicKey);
    final privKey = rsaPrivateKeyFromPem(privateKey);
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pubKey,
      privKey,
    );
  }

  /// load RSA (Public/Private) keys from **PEMPkcs1 Encoded String** (not file path).
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> loadKeyPairPkcs1({
    required String privateKey,
    required String publicKey,
  }) {
    final pubKey = rsaPublicKeyFromPemPkcs1(publicKey);
    final privKey = rsaPrivateKeyFromPemPkcs1(privateKey);
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pubKey,
      privKey,
    );
  }

  /// load RSA (Private) keys from **PEM Encoded String** (not file path).
  static RSAPrivateKey rsaPrivateKeyFromPem(String pem) {
    final bytes = _getBytesFromPEMString(pem);
    return _rsaPrivateKeyFromDERBytes(bytes);
  }

  /// load RSA (Private) keys from **PEMPkcs1 Encoded String** (not file path).
  static RSAPrivateKey rsaPrivateKeyFromPemPkcs1(String pem) {
    final bytes = _getBytesFromPEMString(pem);
    return _rsaPrivateKeyFromDERBytesPkcs1(bytes);
  }

  /// load RSA (Public) keys from **PEM Encoded String** (not file path).
  static RSAPublicKey rsaPublicKeyFromPem(String pem) {
    final bytes = _getBytesFromPEMString(pem);
    return _rsaPublicKeyFromDERBytes(bytes);
  }

  /// load RSA (Public) keys from **PEMPkcs1 Encoded String** (not file path).
  static RSAPublicKey rsaPublicKeyFromPemPkcs1(String pem) {
    final bytes = _getBytesFromPEMString(pem);
    return _rsaPublicKeyFromDERBytesPkcs1(bytes);
  }

  static Uint8List _getBytesFromPEMString(
    String pem, {
    bool checkHeader = true,
  }) {
    final lines = LineSplitter.split(pem)
        .map((line) => line.trim())
        .where(
          (line) => line.isNotEmpty,
        )
        .toList();
    String base64;
    if (checkHeader) {
      if (lines.length < 2 ||
          !lines.first.startsWith(
            '-----BEGIN',
          ) ||
          !lines.last.startsWith(
            '-----END',
          )) {
        throw ArgumentError(
          'The given string does not have the correct '
          'begin/end markers expected in a PEM file.',
        );
      }
      base64 = lines.sublist(1, lines.length - 1).join();
    } else {
      base64 = lines.join();
    }

    return Uint8List.fromList(base64Decode(base64));
  }

  static RSAPrivateKey _rsaPrivateKeyFromDERBytesPkcs1(Uint8List bytes) {
    final asn1Parser = ASN1Parser(bytes);
    final pkSeq = asn1Parser.nextObject() as ASN1Sequence;

    final modulus = pkSeq.elements![1] as ASN1Integer;
    final privateExponent = pkSeq.elements![3] as ASN1Integer;
    final p = pkSeq.elements![4] as ASN1Integer;
    final q = pkSeq.elements![5] as ASN1Integer;

    final rsaPrivateKey = RSAPrivateKey(
      modulus.integer!,
      privateExponent.integer!,
      p.integer,
      q.integer,
    );

    return rsaPrivateKey;
  }

  static RSAPrivateKey _rsaPrivateKeyFromDERBytes(Uint8List bytes) {
    var asn1Parser = ASN1Parser(bytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    final privateKey = topLevelSeq.elements![2];

    asn1Parser = ASN1Parser(privateKey.valueBytes);
    final pkSeq = asn1Parser.nextObject() as ASN1Sequence;

    final modulus = pkSeq.elements![1] as ASN1Integer;
    final privateExponent = pkSeq.elements![3] as ASN1Integer;
    final p = pkSeq.elements![4] as ASN1Integer;
    final q = pkSeq.elements![5] as ASN1Integer;

    final rsaPrivateKey = RSAPrivateKey(
      modulus.integer!,
      privateExponent.integer!,
      p.integer,
      q.integer,
    );

    return rsaPrivateKey;
  }

  ///
  /// Decode the given [bytes] into an [RSAPublicKey].
  ///
  static RSAPublicKey _rsaPublicKeyFromDERBytes(Uint8List bytes) {
    final asn1Parser = ASN1Parser(bytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    ASN1Sequence publicKeySeq;
    if (topLevelSeq.elements![1].runtimeType == ASN1BitString) {
      final publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString;

      final publicKeyAsn = ASN1Parser(
        publicKeyBitString.stringValues as Uint8List?,
      );
      publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    } else {
      publicKeySeq = topLevelSeq;
    }
    final modulus = publicKeySeq.elements![0] as ASN1Integer;
    final exponent = publicKeySeq.elements![1] as ASN1Integer;

    final rsaPublicKey = RSAPublicKey(modulus.integer!, exponent.integer!);

    return rsaPublicKey;
  }

  ///
  /// Decode the given [bytes] into an [RSAPublicKey].
  ///
  /// The [bytes] need to follow the the pkcs1 standard
  ///
  static RSAPublicKey _rsaPublicKeyFromDERBytesPkcs1(Uint8List bytes) {
    final publicKeyAsn = ASN1Parser(bytes);
    final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    final modulus = publicKeySeq.elements![0] as ASN1Integer;
    final exponent = publicKeySeq.elements![1] as ASN1Integer;

    final rsaPublicKey = RSAPublicKey(modulus.integer!, exponent.integer!);
    return rsaPublicKey;
  }
}
