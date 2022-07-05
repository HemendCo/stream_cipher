import 'dart:convert' show base64Encode;
import 'dart:typed_data' show Uint8List;

import '../../../http_request_cipher.dart'
    show EncryptStreamMeta, IByteDataEncrypter, ListBreaker;

extension RequestEncryptTools on IByteDataEncrypter {
  Stream<Uint8List> alterEncryptStream(
    Stream<Uint8List> sourceStream, {
    int maxBlocSize = 1024,
    required EncryptStreamMeta streamMeta,
    bool useBase64 = false,
  }) async* {
    var isFirst = true;

    /// receiving data from source stream.
    await for (final sourceStreamData in sourceStream) {
      // yield Uint8List.fromList(streamMeta.beginning.codeUnits);

      /// breaking [effectiveData] into parts of maximumSize.
      /// remember the last part may be smaller than maximumSize.
      for (final dataPart
          in sourceStreamData.sliceToPiecesOfSize(maxBlocSize)) {
        if (isFirst) {
          isFirst = false;
        } else {
          yield Uint8List.fromList(streamMeta.separator.codeUnits);
        }

        /// encrypting data part.
        final encrypted = encrypt(Uint8List.fromList(dataPart.toList()));

        /// detects if the data needs to be converted to base64 or not.
        final List<int> effectiveData;
        if (useBase64) {
          effectiveData = base64Encode(encrypted).codeUnits;
        } else {
          effectiveData = encrypted;
        }

        /// yielding encrypted data part.
        yield Uint8List.fromList(effectiveData);
      }
    }

    /// adding pad to end of body
    yield Uint8List.fromList(streamMeta.ending.codeUnits);
  }
}
