import 'dart:convert';
import 'dart:typed_data';

import 'package:http_request_cipher/src/list_extensions.dart';

import 'helper_types.dart';

/// abstract of the Decrypter model
abstract class IByteDataDecrypter {
  const IByteDataDecrypter();

  /// the method that receives a normal [ByteData] then
  /// returns an encrypted [ByteData]
  Uint8List decrypt(Uint8List data);

  Stream<Uint8List> alterDecryptStream(
    Stream<Uint8List> sourceStream, {
    required EncryptStreamMeta streamMeta,
    bool useBase64 = false,
  }) async* {
    List<int> waiter = [];
    await for (final i in sourceStream) {
      final paddedList = waiter + i;
      final slicedList = paddedList.splitByPart(streamMeta.separator.codeUnits);
      waiter = slicedList.last.toList();
      for (final part in slicedList.take(slicedList.length - 1)) {
        final effectiveData = useBase64 ? base64Decode(String.fromCharCodes(part)) : part.toList();
        final encrypted = decrypt(Uint8List.fromList(effectiveData));
        yield encrypted;
      }
      final waiterParser = waiter.splitByPart(streamMeta.ending.codeUnits);
      if (waiterParser.length > 1) {
        for (final part in waiterParser.where((element) => element.isNotEmpty)) {
          final effectiveData = useBase64 ? base64Decode(String.fromCharCodes(part)) : part.toList();
          final encrypted = decrypt(Uint8List.fromList(effectiveData));
          yield encrypted;
        }
      }
    }
  }
}

/// abstract of the encrypter model
abstract class IByteDataEncrypter {
  const IByteDataEncrypter();

  /// the method that receives a normal [ByteData] then
  /// returns an encrypted [ByteData]
  Uint8List encrypt(
    Uint8List data,
  );

  Stream<Uint8List> alterEncryptStream(
    Stream<Uint8List> sourceStream, {
    int maxBlocSize = 1024,
    required EncryptStreamMeta streamMeta,
    bool useBase64 = false,
  }) async* {
    bool isFirst = true;

    /// receiving data from source stream.
    await for (final sourceStreamData in sourceStream) {
      // yield Uint8List.fromList(streamMeta.beginning.codeUnits);

      /// breaking [effectiveData] into parts of maximumSize.
      /// remember the last part may be smaller than maximumSize.
      for (var dataPart in sourceStreamData.breakToPieceOfSize(maxBlocSize)) {
        if (isFirst) {
          isFirst = false;
        } else {
          yield Uint8List.fromList(streamMeta.separator.codeUnits);
        }

        /// encrypting data part.
        var encrypted = encrypt(Uint8List.fromList(dataPart.toList()));

        /// detects if the data needs to be converted to base64 or not.
        final effectiveData = useBase64 ? base64Encode(encrypted).codeUnits : encrypted;

        /// yielding encrypted data part.
        ///
        /// the result is a Uint8List of length of data and the data array is next to it
        yield Uint8List.fromList(effectiveData);
      }

      /// adding pad to end of body
    }
    yield Uint8List.fromList(streamMeta.ending.codeUnits);
  }
}
