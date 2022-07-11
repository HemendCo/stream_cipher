import 'package:pointycastle/export.dart'
    show
        AsymmetricKeyPair,
        ParametersWithRandom,
        RSAKeyGenerator,
        RSAKeyGeneratorParameters,
        RSAPrivateKey,
        RSAPublicKey,
        SecureRandom;

abstract class RSATools {
  RSATools._();
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom, {
    int bitLength = 256,
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
}
