part of 'stream_cipher_test.dart';

class _NoEncryptionByteDataEncrypter extends IByteDataEncrypter {
  @override
  Uint8List encrypt(Uint8List data) => data;
}

class _NoEncryptionByteDataDecrypter extends IByteDataDecrypter {
  @override
  Uint8List decrypt(Uint8List data) => data;
}
