import 'dart:io';
import 'dart:typed_data';

import 'package:stream_cipher/src/io_utils/file/secure_file.dart';
import 'package:stream_cipher/stream_cipher.dart';
import 'package:test/test.dart';

void main() {
  group('Secure File', () {
    late SecureFile testFile;
    late Uint8List testData;
    const kRSAPublicPkcs1Key = '''-----BEGIN RSA PUBLIC KEY-----
MCgCIQCaBSJ+BdvQiyHIP6xphzXr7PAAcaDgcfQ7HiE46kd6kwIDAQAB
-----END RSA PUBLIC KEY-----''';
    const kRSAPrivatePkcs1Key = '''-----BEGIN RSA PRIVATE KEY-----
MIGpAgEAAiEAmgUifgXb0IshyD+saYc16+zwAHGg4HH0Ox4hOOpHepMCAwEAAQIg
OU9j0ETZ0DWVMnAO9Y1sUHOTd/szRNdAPT7h8jCAKSECEQDNc9okvvM34O+X5Jgz
csWbAhEAv+ngppV1xvHivojfbGsqaQIQUohirnZC0ES9GwCKn8hQVwIQF6buXfl7
m3pCNLNPvd/zSQIQHb9zWGpmoCAtqvof8vputQ==
-----END RSA PRIVATE KEY-----''';
    setUp(() {
      final testDir = Directory('test/temp');
      if (!testDir.existsSync()) {
        testDir.createSync(recursive: true);
      }
      final file = File('test/temp/test_file.dat');

      // final _aesEncrypter = AESByteDataEncrypter.randomSecureKey();
      // final _aesDecrypter = AESByteDataDecrypter(
      //   key: _aesEncrypter.key,
      //   iv: _aesEncrypter.iv,
      // );
      final _rsaEncrypter = RSAByteDataEncrypter.fromString(kRSAPublicPkcs1Key);
      final _rsaDecrypter =
          RSAByteDataDecrypter.fromString(kRSAPrivatePkcs1Key);

      final encrypter = MultiLayerEncrypter([
        _rsaEncrypter,
      ]);
      final decrypter = MultiLayerDecrypter([
        _rsaDecrypter,
      ]);

      testFile = SecureFile(
        file,
        maxBlockSize: _rsaEncrypter.inputBlocSize,
        encrypter: encrypter,
        decrypter: decrypter,
        useBase64: true,
      );

      testData = File('test/_test_file.exe').readAsBytesSync();
    });
    test('write test', () async {
      await testFile.writeByteArray(testData);
      final readData = await testFile.readByteArray();
      expect(readData, testData);
    });
  });
}
