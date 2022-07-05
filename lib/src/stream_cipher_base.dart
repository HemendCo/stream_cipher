import 'dart:typed_data' show Uint8List;

/// abstract of the Decrypter model
abstract class IByteDataDecrypter {
  const IByteDataDecrypter();

  /// the method that receives a normal [Uint8List] then
  /// returns an encrypted [Uint8List]
  Uint8List decrypt(Uint8List data);
}

/// abstract of the encrypter model
abstract class IByteDataEncrypter {
  const IByteDataEncrypter();

  /// can be override to alter the header of the request
  Map<String, dynamic> alterHeader(Map<String, dynamic> headers) => headers;

  /// the method that receives a normal [Uint8List] then
  /// returns an encrypted [Uint8List]
  Uint8List encrypt(
    Uint8List data,
  );
}

abstract class NoEncryption {}
