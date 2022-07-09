import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:stream_cipher/src/io_utils/client_adapters/dio_client_adapter.dart';
import 'package:stream_cipher/src/io_utils/file/secure_file.dart';
import 'package:stream_cipher/stream_cipher.dart';

import 'sample_dart_backend.dart';

const kServerPort = 8088;
// const kRawEchoApiUrl = 'http://0.0.0.0:3000/example/echo_server.php';
const kDecodedEchoAPIUrl = 'http://0.0.0.0:$kServerPort/decoded_echo';
const kRawEchoApiUrl = 'http://0.0.0.0:$kServerPort/raw_echo';
const kMiddleEchoApiUrl = 'http://0.0.0.0:$kServerPort/middle_cipher';
const kMaxPartSize = 35;
final logger = Logger();
Future<void> main() async {
  final server = await dartBackEnd();
  await rrrr();
  await errr();
  await erdr();
  await erdr2();
  await erdr3();
  await ioWriteAndRead();
  server.close(force: true);
}

final testFile = File('test.test');
const streamMeta = EncryptStreamMeta(
  ending: '#ENDING#',
  separator: '#=#',
);
Future<void> ioWriteAndRead() async {
  final encrypter = AESByteDataEncrypter.randomSecureKey();
  final decrypter = AESByteDataDecrypter(key: encrypter.key, iv: encrypter.iv);
  final testData =
      '''Elit mollit Lorem et cillum voluptate id aliqua. Ipsum velit mollit duis cupidatat exercitation aliqua excepteur eu anim excepteur ad. Sint dolor eiusmod aliquip proident elit. Qui cupidatat veniam minim do cillum enim aute veniam sit duis. Voluptate quis consectetur duis reprehenderit. Excepteur sunt occaecat in labore ea consequat dolor culpa ex aliquip aute consequat.
Culpa do labore id. Ex ea sunt veniam. Occaecat Lorem occaecat culpa laboris fugiat dolore sit labore. Enim excepteur sit amet do laboris mollit esse nulla do occaecat pariatur id. Ut sit sit sit velit tempor dolore adipisicing pariatur aliquip aute cillum ipsum.''';
  final secureFile = SecureFile(
    testFile,
    encrypter: encrypter,
    decrypter: decrypter,
    streamMeta: streamMeta,
    useBase64: true,
    maxBlockSize: kMaxPartSize,
  );
  await secureFile.writeString(testData);
  logger.i(
    'File adapter test isValid: ${await secureFile.readString() == testData}',
    null,
    StackTrace.fromString('DartExample'),
  );
  // final fileWriter = testFile.openWrite();
  // await fileWriter.addStream(
  //   encrypter.alterEncryptStream(
  //     testData.map(
  //       (event) => Uint8List.fromList(
  //         event.toList(),
  //       ),
  //     ),
  //     streamMeta: streamMeta,
  //   ),
  // );
  // fileWriter.close();
  // final fileReader = testFile.openRead();
  // final decryptedStream = decrypter.alterDecryptStream(
  //   fileReader.map(
  //     (event) => Uint8List.fromList(
  //       event.toList(),
  //     ),
  //   ),
  //   streamMeta: streamMeta,
  // );
  // final buffer = <int>[];
  // await decryptedStream.forEach(buffer.addAll);
  // logger.i('Encrypted and Decrypted IO Task: ${String.fromCharCodes(buffer)}');
}

Future<void> rrrr() async {
  final encrypter = NoEncryptionByteDataEncrypter();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CipherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: kMaxPartSize,
  );

  final dio = Dio()..httpClientAdapter = dioClient;
  await dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    logger.i(
      'Raw echo request -> Raw response: ${response.data}',
      null,
      StackTrace.fromString('DartExample'),
    );
  });
}

Future<void> errr() async {
  final encrypter = AESByteDataEncrypter.empty();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CipherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: kMaxPartSize,
  );

  final dio = Dio()..httpClientAdapter = dioClient;
  await dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    logger.i(
      'Encrypted echo request -> raw response: ${response.data}',
      null,
      StackTrace.fromString('DartExample'),
    );
  });
}

Future<void> erdr() async {
  final encrypter = AESByteDataEncrypter.randomSecureKey();
  final decrypter = AESByteDataDecrypter(key: encrypter.key, iv: encrypter.iv);
  final dioClient = CipherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: kMaxPartSize,
  );
  final dio = Dio()..httpClientAdapter = dioClient;

  await dio
      .post(
    kRawEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  )
      .then((response) {
    logger.i(
      'Encrypted echo request -> decrypted response: ${response.data}',
      null,
      StackTrace.fromString('DartExample'),
    );
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
  logger.i(
    'Encrypted request -> decrypted in backend: ${response.data}',
    null,
    StackTrace.fromString('DartExample'),
  );
}

Future<void> erdr3() async {
  final encrypter = AESByteDataEncrypter.empty();
  final decrypter = NoEncryptionByteDataDecrypter();
  final dioClient = CipherDioHttpAdapter(
    decrypter: decrypter,
    encrypter: encrypter,
    maximumPartSize: kMaxPartSize,
  );

  final dio = Dio()..httpClientAdapter = dioClient;

  final response = await dio.post(
    kMiddleEchoApiUrl,
    data: '{"note":"this will be encrypted"}',
  );
  logger.i(
    'Encrypted request -> decrypted in backend (MiddleWare): ${response.data}',
    null,
    StackTrace.fromString('DartExample'),
  );
}
