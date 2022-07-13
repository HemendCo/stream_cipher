library stream_cipher.rsa_key_tools;
// ignore_for_file: constant_identifier_names

import 'dart:convert' show base64;
import 'dart:typed_data' show Uint8List;

import 'package:pointycastle/asn1.dart' //
    show
        ASN1BitString,
        ASN1Integer,
        ASN1Object,
        ASN1ObjectIdentifier,
        ASN1OctetString,
        ASN1Sequence;
import 'package:pointycastle/export.dart' show RSAPrivateKey, RSAPublicKey;

import '../../extensions/list_extensions.dart';

abstract class RSAKeyMetaData {
  static const BEGIN_PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----';
  static const END_PRIVATE_KEY = '-----END PRIVATE KEY-----';

  static const BEGIN_PUBLIC_KEY = '-----BEGIN PUBLIC KEY-----';
  static const END_PUBLIC_KEY = '-----END PUBLIC KEY-----';

  static const BEGIN_RSA_PRIVATE_KEY = '-----BEGIN RSA PRIVATE KEY-----';
  static const END_RSA_PRIVATE_KEY = '-----END RSA PRIVATE KEY-----';

  static const BEGIN_RSA_PUBLIC_KEY = '-----BEGIN RSA PUBLIC KEY-----';
  static const END_RSA_PUBLIC_KEY = '-----END RSA PUBLIC KEY-----';
}

/// following extensions are from: [https://github.com/Ephenodrom/Dart-Basic-Utils#cryptoutils]
extension PrivateKeyTools on RSAPrivateKey {
  /// extract private key to PEMPkcs1 encoded string
  String toPemPkcs1String() {
    final version = ASN1Integer(BigInt.from(0));
    final modulus = ASN1Integer(n);
    final publicExponent = ASN1Integer(BigInt.parse('65537'));
    final privateExponent = ASN1Integer(this.privateExponent);

    final p = ASN1Integer(this.p);
    final q = ASN1Integer(this.q);
    final dP = this.privateExponent! %
        (this.p! -
            BigInt.from(
              1,
            ));
    final exp1 = ASN1Integer(dP);
    final dQ = this.privateExponent! %
        (this.q! -
            BigInt.from(
              1,
            ));
    final exp2 = ASN1Integer(dQ);
    final iQ = this.q!.modInverse(this.p!);
    final co = ASN1Integer(iQ);

    final topLevelSeq = ASN1Sequence()
      ..add(version)
      ..add(modulus)
      ..add(publicExponent)
      ..add(privateExponent)
      ..add(p)
      ..add(q)
      ..add(exp1)
      ..add(exp2)
      ..add(co);
    final dataBase64 = base64.encode(topLevelSeq.encode());

    final chunks = dataBase64.codeUnits.sliceToPiecesOfSize(64).map(
          String.fromCharCodes,
        );
    // ignore: lines_longer_than_80_chars
    return '${RSAKeyMetaData.BEGIN_RSA_PRIVATE_KEY}\n${chunks.join('\n')}\n${RSAKeyMetaData.END_RSA_PRIVATE_KEY}';
  }

  /// extract private key to PEM encoded string
  String toPemString() {
    final version = ASN1Integer(BigInt.from(0));

    final algorithmSeq = ASN1Sequence();
    final algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList(
        [
          0x6,
          0x9,
          0x2a,
          0x86,
          0x48,
          0x86,
          0xf7,
          0xd,
          0x1,
          0x1,
          0x1,
        ],
      ),
    );
    final paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq
      ..add(algorithmAsn1Obj)
      ..add(paramsAsn1Obj);

    final privateKeySeq = ASN1Sequence();
    final modulus = ASN1Integer(n);
    final publicExponent = ASN1Integer(BigInt.parse('65537'));
    final privateExponent = ASN1Integer(this.privateExponent);
    final p = ASN1Integer(this.p);
    final q = ASN1Integer(this.q);
    final dP = this.privateExponent! % (this.p! - BigInt.from(1));
    final exp1 = ASN1Integer(dP);
    final dQ = this.privateExponent! % (this.q! - BigInt.from(1));
    final exp2 = ASN1Integer(dQ);
    final iQ = this.q!.modInverse(this.p!);
    final co = ASN1Integer(iQ);

    privateKeySeq
      ..add(version)
      ..add(modulus)
      ..add(publicExponent)
      ..add(privateExponent)
      ..add(p)
      ..add(q)
      ..add(exp1)
      ..add(exp2)
      ..add(co);
    final publicKeySeqOctetString = ASN1OctetString(
      octets: Uint8List.fromList(
        privateKeySeq.encode(),
      ),
    );

    final topLevelSeq = ASN1Sequence()
      ..add(version)
      ..add(algorithmSeq)
      ..add(publicKeySeqOctetString);
    final dataBase64 = base64.encode(topLevelSeq.encode());
    final chunks = dataBase64.codeUnits.sliceToPiecesOfSize(64).map(
          String.fromCharCodes,
        );
    return '''${RSAKeyMetaData.BEGIN_PRIVATE_KEY}\n${chunks.join('\n')}\n${RSAKeyMetaData.END_PRIVATE_KEY}''';
  }
}

extension PublicKeyTools on RSAPublicKey {
  /// extract public key to PEMPkcs1 encoded string
  String toPemPkcs1String() {
    final topLevelSeq = ASN1Sequence()
      ..add(ASN1Integer(modulus))
      ..add(ASN1Integer(exponent));

    final dataBase64 = base64.encode(topLevelSeq.encode());
    final chunks = dataBase64.codeUnits.sliceToPiecesOfSize(64).map(
          String.fromCharCodes,
        );
    return '''${RSAKeyMetaData.BEGIN_RSA_PUBLIC_KEY}\n${chunks.join('\n')}\n${RSAKeyMetaData.END_RSA_PUBLIC_KEY}''';
  }

  /// extract public key to PEM encoded string
  String toPemString() {
    final algorithmSeq = ASN1Sequence();
    final paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq
      ..add(ASN1ObjectIdentifier.fromName('rsaEncryption'))
      ..add(paramsAsn1Obj);

    final publicKeySeq = ASN1Sequence()
      ..add(ASN1Integer(modulus))
      ..add(ASN1Integer(exponent));
    final publicKeySeqBitString = ASN1BitString(
      stringValues: Uint8List.fromList(
        publicKeySeq.encode(),
      ),
    );

    final topLevelSeq = ASN1Sequence()
      ..add(algorithmSeq)
      ..add(publicKeySeqBitString);
    final dataBase64 = base64.encode(topLevelSeq.encode());
    final chunks = dataBase64.codeUnits.sliceToPiecesOfSize(64).map(
          String.fromCharCodes,
        );

    return '''${RSAKeyMetaData.BEGIN_PUBLIC_KEY}\n${chunks.join('\n')}\n${RSAKeyMetaData.END_PUBLIC_KEY}''';
  }
}
