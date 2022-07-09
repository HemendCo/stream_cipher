library stream_cipher.secure_file;

import 'dart:io';
import 'dart:typed_data';

import '../../../stream_cipher.dart';

class SecureFile {
  final File file;
  final IByteDataEncrypter encrypter;
  final IByteDataDecrypter decrypter;
  final EncryptStreamMeta streamMeta;
  final bool useBase64;
  final int maxBlockSize;
  const SecureFile(
    this.file, {
    this.maxBlockSize = 1024,
    required this.encrypter,
    required this.decrypter,
    this.useBase64 = false,
    required this.streamMeta,
  });
  factory SecureFile.fromPath(
    String path, {
    required IByteDataEncrypter encrypter,
    required IByteDataDecrypter decrypter,
    required EncryptStreamMeta streamMeta,
    int maxBlockSize = 1024,
    bool useBase64 = false,
  }) =>
      SecureFile(
        File(path),
        encrypter: encrypter,
        decrypter: decrypter,
        streamMeta: streamMeta,
        useBase64: useBase64,
        maxBlockSize: maxBlockSize,
      );
  Future<void> write(
    Stream<Uint8List> data, {
    int? blockSize,
  }) async {
    final fileWriter = file.openWrite();
    await fileWriter.addStream(
      encrypter.alterEncryptStream(
        data.map(
          (event) => Uint8List.fromList(
            event.toList(),
          ),
        ),
        useBase64: useBase64,
        maxBlockSize: blockSize ?? maxBlockSize,
        streamMeta: streamMeta,
      ),
    );
    fileWriter.close();
  }

  Stream<Uint8List> read() {
    return decrypter.alterDecryptStream(
      file.openRead().map(Uint8List.fromList),
      streamMeta: streamMeta,
      useBase64: useBase64,
    );
  }

  Future<void> writeByteArray(
    Uint8List data, {
    int? blockSize,
  }) async {
    return write(
      Stream.fromIterable(
        data.sliceToPiecesOfSize(15).map(
              (e) => Uint8List.fromList(
                e.toList(),
              ),
            ),
      ),
      blockSize: blockSize,
    );
  }

  Future<Uint8List> readByteArray() async {
    final buffer = <int>[];
    await read().forEach(buffer.addAll);
    return Uint8List.fromList(buffer);
  }

  Future<void> writeString(String data, {int? blockSize}) async {
    return writeByteArray(
      Uint8List.fromList(data.codeUnits),
      blockSize: blockSize,
    );
  }

  Future<String> readString() async {
    return String.fromCharCodes(await readByteArray());
  }
}
