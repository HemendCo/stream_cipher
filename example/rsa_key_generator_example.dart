import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart' //
    as pointy_platform;
import 'package:stream_cipher/src/cipher_utils/rsa/rsa_key_extensions.dart';

import 'package:stream_cipher/src/cipher_utils/rsa/rsa_tools.dart';

void main() {
  // final private = File('private.pem').readAsStringSync();
  // final public = File('public.pem').readAsStringSync();
  final keyPair = RSAKeyTools //
      //     .loadKeyPair(
      //   privateKey: private,
      //   publicKey: public,
      // );
      .generateRSAkeyPair(
    secureRandom(),
  );
  // File('public.pem').writeAsStringSync(keyPair.publicKey.toString());
  final data = Uint8List.fromList('1515215125315'.codeUnits);
  dumpRsaKeys(keyPair);
  // print(dumpRsaKeys(keyPair, verbose: true));
  final encrypted = rsaSign(keyPair.privateKey, data);
  final decrypted = rsaVerify(keyPair.publicKey, data, encrypted);
  print(decrypted);
}

Uint8List rsaSign(RSAPrivateKey privateKey, Uint8List dataToSign) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
    // initialize with true, which means sign
    ..init(
      true,
      PrivateKeyParameter<RSAPrivateKey>(privateKey),
    );

  final sig = signer.generateSignature(dataToSign);

  return sig.bytes;
}

void dumpRsaKeys(
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> k,
) {
  File('public.pem').writeAsStringSync(k.publicKey.toPemString());
  File('private.pem').writeAsStringSync(k.privateKey.toPemString());
}

bool rsaVerify(
  RSAPublicKey publicKey,
  Uint8List signedData,
  Uint8List signature,
) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final sig = RSASignature(signature);

  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201')
    // initialize with false, which means verify
    ..init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

  try {
    return verifier.verifySignature(signedData, sig);
  } on ArgumentError {
    return false; // for Pointy Castle 1.0.2 when signature has been modified
  }
}

/// from pointycastle docs : https://github.com/bcgit/pc-dart/blob/master/tutorials/rsa.md
SecureRandom secureRandom() {
  final secureRandom = SecureRandom('Fortuna')
    ..seed(
      KeyParameter(
        pointy_platform.Platform.instance.platformEntropySource().getBytes(32),
      ),
    );
  return secureRandom;
}
