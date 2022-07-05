import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:stream_cipher/stream_cipher.dart';
import 'package:stream_cipher/src/client_adapters/dio_client_adapter.dart';

import 'sample_dart_backend.dart';

const kServerPort = 8092;
// const kRawEchoApiUrl = 'http://0.0.0.0:3000/example/echo_server.php';
const kDecodedEchoAPIUrl = 'http://0.0.0.0:$kServerPort/decoded_echo';
const kRawEchoApiUrl = 'http://0.0.0.0:$kServerPort/raw_echo';
const kMaxPartSize = 5;
Future<void> main() async {
  final server = await dartBackEnd();
  rrrr();
  errr();
  erdr();
  await erdr2();
  await ioWriteAndRead();
  server.close(force: true);
}

final testFile = File('test.test');
const streamMeta = EncryptStreamMeta(
  ending: '#ENDING#',
  separator: '#SEPARATOR#',
);
Future<void> ioWriteAndRead() async {
  final encrypter = AESByteDataEncrypter.randomSecureKey();
  final decrypter = AESByteDataDecrypter(key: encrypter.key, iv: encrypter.iv);
  final testData = Stream.fromIterable(
    '{"note":"this will be encrypted"}'.codeUnits.sliceToPiecesOfSize(
          kMaxPartSize,
        ),
  );
  final fileWriter = testFile.openWrite();
  await fileWriter.addStream(
    encrypter.alterEncryptStream(
      testData.map(
        (event) => Uint8List.fromList(
          event.toList(),
        ),
      ),
      streamMeta: streamMeta,
    ),
  );
  fileWriter.close();
  final fileReader = testFile.openRead();
  final decryptedStream = decrypter.alterDecryptStream(
    fileReader.map(
      (event) => Uint8List.fromList(
        event.toList(),
      ),
    ),
    streamMeta: streamMeta,
  );
  final buffer = <int>[];
  await decryptedStream.forEach(buffer.addAll);
  print('Encrypted and Decrypted IO Task: ${String.fromCharCodes(buffer)}');
}

void rrrr() {
  final encrypter = NoEncryptionByteDataEncrypter();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CipherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: kMaxPartSize,
  );

  final dio = Dio()..httpClientAdapter = dioClient;
  dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    print('Raw echo request -> Raw response: ${response.data}');
  });
}

void errr() {
  final encrypter = AESByteDataEncrypter.randomSecureKey();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CipherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: kMaxPartSize,
  );

  final dio = Dio()..httpClientAdapter = dioClient;
  dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    print('Encrypted echo request -> raw response: ${response.data}');
  });
}

void erdr() {
  final encrypter = AESByteDataEncrypter.randomSecureKey();
  final decrypter = AESByteDataDecrypter(key: encrypter.key, iv: encrypter.iv);
  final dioClient = CipherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: kMaxPartSize,
  );
  final dio = Dio()..httpClientAdapter = dioClient;

  dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    print('Encrypted echo request -> decrypted response: ${response.data}');
  });
}

Future<void> erdr2() async {
  final encrypter = AESByteDataEncrypter.empty();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CipherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: kMaxPartSize,
  );

  final dio = Dio()..httpClientAdapter = dioClient;

  final response = await dio.post(
    kDecodedEchoAPIUrl,
    data: '{"note":"this will be encrypted"}',
  );
  print('Encrypted request -> decrypted in backend: ${response.data}');
}
