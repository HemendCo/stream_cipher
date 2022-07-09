library stream_cipher.stream_extensions;

import 'dart:convert' show base64Decode;
import 'dart:typed_data' show Uint8List;

import '../../stream_cipher.dart' //
    show
        EncryptMethod,
        EncryptStreamMeta,
        IByteDataDecrypter,
        ListBreaker;

extension StreamDecrypter on IByteDataDecrypter {
  Stream<Uint8List> alterDecryptStream(
    Stream<Uint8List> sourceStream, {
    required EncryptStreamMeta streamMeta,
    bool useBase64 = false,
  }) async* {
    if (encryptMethod != EncryptMethod.none) {
      /// this will hold last part of source stream data
      /// this is due to the fact that the source stream will not send data
      /// in predictable chunks or in a predictable order.
      var waiter = <int>[];

      await for (final i in sourceStream) {
        /// adding the last part of older stream data to start of new stream data
        final paddedList = waiter + i;

        /// splitting the new stream data into chunks
        final slicedList = paddedList.splitByPart(
          streamMeta.separator.codeUnits,
        );

        /// passing last part of sliced list to waiter
        waiter = slicedList.last.toList();

        /// iterating over the sliced list but last part
        final slices = slicedList.take(slicedList.length - 1);
        for (final part in slices) {
          /// unloading the part to its binary value by decoding if it was base64
          final List<int> effectiveData;
          if (useBase64) {
            effectiveData = base64Decode(String.fromCharCodes(part));
          } else {
            effectiveData = part.toList();
          }

          /// decrypting the part by [decrypt] method
          final encrypted = decrypt(Uint8List.fromList(effectiveData));
          yield encrypted;
        }

        /// checking waiter if it is the last part of the stream with checking
        /// presence of [streamMeta.ending]
        /// the rest is like above
        final waiterParser = waiter.splitByPart(streamMeta.ending.codeUnits);
        if (waiterParser.length > 1) {
          final parts = waiterParser.where((element) => element.isNotEmpty);
          for (final part in parts) {
            final List<int> effectiveData;
            if (useBase64) {
              effectiveData = base64Decode(String.fromCharCodes(part));
            } else {
              effectiveData = part.toList();
            }
            final encrypted = decrypt(Uint8List.fromList(effectiveData));
            yield encrypted;
          }
          waiter = [];
        }
      }
    } else {
      yield* sourceStream;
    }
  }
}
