import 'dart:typed_data' show Uint8List;

/// abstract of the Decrypter model
abstract class IByteDataDecrypter {
  const IByteDataDecrypter();
  EncryptMethod get encryptMethod;

  /// the method that receives a normal [Uint8List] then
  /// returns an encrypted [Uint8List]
  Uint8List decrypt(Uint8List data);
}

/// abstract of the encrypter model
abstract class IByteDataEncrypter {
  const IByteDataEncrypter();
  EncryptMethod get encryptMethod;

  /// can be override to alter the header of the request
  Map<String, dynamic> alterHeader(Map<String, dynamic> headers) => headers;

  /// the method that receives a normal [Uint8List] then
  /// returns an encrypted [Uint8List]
  Uint8List encrypt(
    Uint8List data,
  );
}

enum EncryptMethod {
  none,
  aes,
  rsa,
  gzip,

  /// if you are adding extra encryption method you can use this enum
  custom,

  /// this mode is used for testing purposes
  test;
}
