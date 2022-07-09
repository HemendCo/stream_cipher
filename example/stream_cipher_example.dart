import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:stream_cipher/src/io_utils/client_adapters/dio_client_adapter.dart';
import 'package:stream_cipher/src/io_utils/file/secure_file.dart';
import 'package:stream_cipher/stream_cipher.dart';

import 'sample_dart_backend.dart';

const kServerPort = 8088;
// const kRawEchoApiUrl = 'http://0.0.0.0:3000/example/echo_server.php';
const kDecodedEchoAPIUrl = 'http://0.0.0.0:$kServerPort/decoded_echo';
const kRawEchoApiUrl = 'http://0.0.0.0:$kServerPort/raw_echo';
const kMaxPartSize = 35;
Future<void> main() async {
  final server = await dartBackEnd();
  // rrrr();
  await errr();
  // erdr();
  // await erdr2();
  // await ioWriteAndRead();
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
  print(await secureFile.readString());
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
  // print('Encrypted and Decrypted IO Task: ${String.fromCharCodes(buffer)}');
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
