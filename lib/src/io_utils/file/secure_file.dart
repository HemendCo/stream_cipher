library stream_cipher.secure_file;

import 'dart:convert' show Encoding, utf8;
import 'dart:io' show File, FileMode;
import 'dart:typed_data' show Uint8List;

import '../../../stream_cipher.dart' //
    show
        EncryptStreamMeta,
        IByteDataDecrypter,
        IByteDataEncrypter,
        ListBreaker,
        StreamDecrypter,
        StreamEncryptTools;

class SecureFile {
  /// attached file
  final File file;

  /// [IByteDataEncrypter] instance used during write operations
  final IByteDataEncrypter encrypter;

  /// [IByteDataDecrypter] instance used during read operations
  final IByteDataDecrypter decrypter;
  final EncryptStreamMeta streamMeta;
  final bool useBase64;
  final int maxBlockSize;
  SecureFile(
    this.file, {
    this.maxBlockSize = 1024,
    required this.encrypter,
    required this.decrypter,
    this.useBase64 = false,
    this.streamMeta = const EncryptStreamMeta.sameSeparatorAsEnding(
      '#SEPARATOR#',
    ),
  }) : assert(
          encrypter.encryptMethod == decrypter.encryptMethod,
          '''both of encrypter and decrypter in secure file must use same method.''',
        );
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
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) async {
    final fileWriter = file.openWrite(
      encoding: encoding,
      mode: mode,
    );
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
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) async {
    return write(
      Stream.fromIterable(
        data.sliceToPiecesOfSize(15).map(
              (e) => Uint8List.fromList(
                e.toList(),
              ),
            ),
      ),
      mode: mode,
      encoding: encoding,
      blockSize: blockSize,
    );
  }

  Future<Uint8List> readByteArray() async {
    final buffer = <int>[];
    await read().forEach(buffer.addAll);
    return Uint8List.fromList(buffer);
  }

  Future<void> writeString(
    String data, {
    int? blockSize,
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) async {
    return writeByteArray(
      Uint8List.fromList(data.codeUnits),
      blockSize: blockSize,
      encoding: encoding,
      mode: mode,
    );
  }

  Future<String> readString() async {
    return String.fromCharCodes(await readByteArray());
  }
}
