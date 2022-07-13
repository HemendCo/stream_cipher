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
import '../../byte_data_decrypter.dart' //
    show
        Base64ByteDataDecoder,
        MultiLayerDecrypter;
import '../../byte_data_encrypter.dart' //
    show
        Base64ByteDataEncoder,
        MultiLayerEncrypter;

/// a link for a file that writes and reads `encrypted`\`decrypted` data
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

  /// creating an instance of [SecureFile] with given [file]
  ///
  /// if [useBase64] is true de/encrypter will have an other stage with
  /// [Base64ByteDataDecoder] and [Base64ByteDataEncoder]
  /// so if you are using any kind of `RSA` methods in input it may print some
  /// warning
  SecureFile(
    this.file, {
    this.maxBlockSize = 1024,
    required IByteDataEncrypter encrypter,
    required IByteDataDecrypter decrypter,
    this.useBase64 = false,
    this.streamMeta = const EncryptStreamMeta.sameSeparatorAsEnding(
      '#SEPARATOR#',
    ),
  })  : assert(
          encrypter.encryptMethod == decrypter.encryptMethod,
          '''both of encrypter and decrypter in secure file must use same method.''',
        ),
        encrypter = useBase64
            ? MultiLayerEncrypter([
                Base64ByteDataEncoder(),
                encrypter,
              ])
            : encrypter,
        decrypter = useBase64
            ? MultiLayerDecrypter([
                Base64ByteDataDecoder(),
                decrypter,
              ])
            : decrypter;

  /// creating an instance with given path
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

  /// writes [Stream] of binary data into the file
  /// encrypts data before writing into the file
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
        maxBlockSize: blockSize ?? maxBlockSize,
        streamMeta: streamMeta,
      ),
    );
    fileWriter.close();
  }

  /// read [Stream] binary data from file and decrypt it
  Stream<Uint8List> read() {
    return decrypter.alterDecryptStream(
      file.openRead().map(Uint8List.fromList),
      streamMeta: streamMeta,
    );
  }

  /// encrypt and write a list of binary data into the file
  ///
  /// **if you are changing [mode] make sure to test it**
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

  /// reads and decrypt binary data from the file
  Future<Uint8List> readByteArray() async {
    final buffer = <int>[];
    await read().forEach(buffer.addAll);
    return Uint8List.fromList(buffer);
  }

  /// encrypt and write a list of [String] [data] into the file
  ///
  /// **if you are changing [mode] make sure to test it**
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

  /// reads and decrypt [String] data from the file
  Future<String> readString() async {
    return String.fromCharCodes(await readByteArray());
  }
}
