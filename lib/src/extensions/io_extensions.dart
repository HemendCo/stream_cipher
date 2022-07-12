library stream_cipher.io_extensions;

import 'dart:io';

import '../../stream_cipher.dart';
import '../io_utils/file/secure_file.dart';

extension SecuredFile on File {
  /// get a [SecureFile] from this file
  SecureFile asSecureFile({
    int maxBlockSize = 1024,
    required IByteDataEncrypter encrypter,
    required IByteDataDecrypter decrypter,
    bool useBase64 = false,
    required EncryptStreamMeta streamMeta,
  }) =>
      SecureFile(
        this,
        maxBlockSize: maxBlockSize,
        encrypter: encrypter,
        decrypter: decrypter,
        useBase64: useBase64,
        streamMeta: streamMeta,
      );
}
