library http_request_cipher.dio;

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../stream_cipher.dart';

/// A [Dio] adapter that encrypts and decrypts data
/// using a [IByteDataEncrypter].
///
/// The [IByteDataEncrypter] is used to encrypt the data while sending
/// it to the server.
///
/// This adapter needs a base [HttpClientAdapter] to fork from it.
///
/// [useBase64] flag will be used to encode data to base64 string before
/// encoding it to bytes.
class CipherDioHttpAdapter extends HttpClientAdapter {
  /// [HttpClientAdapter] there will be an instance of this adapter on []
  final HttpClientAdapter _baseAdapter;

  /// [IByteDataEncrypter] used to encrypt data.
  final IByteDataEncrypter encrypter;

  /// [IByteDataDecrypter] used to decrypt response data.
  final IByteDataDecrypter decrypter;

  /// A flag to use Base64String instead of ByteArray before encrypting
  /// parts of the data. remember the request will still be in bytes.
  final bool useBase64;

  /// Part size of byte data passing to [IByteDataEncrypter] to encrypt.
  ///
  /// remember this value is maximum part size and data parts can be
  /// smaller than this value.
  ///
  /// this value may need to be adjusted depending on the [IByteDataEncrypter]
  ///
  /// for example if you are using [RSAByteDataEncrypter] and you have to lower
  /// this value to avoid `memory`,`Cipher Input data too large`,etc. issues.
  final int maximumPartSize;

  /// key that separates size value from encrypted bytes value.
  ///
  /// this value is used to separate the encoded parts and it **MUST** be
  /// a String you know for sure it cannot be in output of [IByteDataEncrypter]
  ///
  ///# if sending data huge the chance of duplicating this key is high.
  /// to reduce the chance of duplicating this key you should use a
  /// **MEANINGFUL** key. that is long enough to be unique
  ///
  /// this key must be shared with the server in order to parse data.
  final EncryptStreamMeta streamMeta;

  /// [CipherDioHttpAdapter] instance. will proxy requests and and responses to
  /// encrypt request body and decrypt response body.
  ///
  /// - `baseAdapter` [HttpClientAdapter] there will be an instance
  /// of this adapter on []
  ///
  /// - `encrypter` [IByteDataEncrypter] used to encrypt data.
  ///
  /// - `useBase64` A flag to use Base64String instead of ByteArray
  /// before encrypting
  /// parts of the data. remember the request will still be in bytes.
  ///
  ///
  /// - `maximumPartSize` of byte data
  /// passing to [IByteDataEncrypter] to encrypt.
  ///
  /// remember this value is maximum part size and data parts can be
  /// smaller than this value.
  ///
  /// this value may need to be adjusted depending on the [IByteDataEncrypter]
  /// for example if you are using [RSAByteDataEncrypter] and you have to lower
  /// this value to avoid `memory`,`Cipher Input data too large`,etc. issues.
  CipherDioHttpAdapter({
    HttpClientAdapter? baseAdapter,
    required this.encrypter,
    required this.decrypter,
    this.useBase64 = false,
    this.streamMeta = const EncryptStreamMeta(
      ending: '#ENDING#',
      separator: '#SEPARATOR#',
    ),
    this.maximumPartSize = 1024,
  }) : _baseAdapter = baseAdapter ?? Dio().httpClientAdapter;

  @override
  void close({bool force = false}) => _baseAdapter.close(force: force);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    var outputOptions = options.copyWith(
      headers: {
        ...options.headers,

        /// removing `content-length` from header to
        /// avoid `content length mismatch` issue.
        'content-length': null,
        'type_id': useBase64 ? 1 : 0,
      },
    );

    outputOptions = outputOptions.copyWith(
      headers: encrypter.alterHeader(
        outputOptions.headers,
      ),
    );
    final response = await _baseAdapter.fetch(
      outputOptions,

      /// alternate request body stream with encrypter.
      requestStream != null
          ? encrypter.alterEncryptStream(
              requestStream,
              streamMeta: streamMeta,
              maxBlocSize: maximumPartSize,
              useBase64: useBase64,
            )
          : requestStream,
      cancelFuture,
    );

    /// alternate response body with decrypter.
    return ResponseBody(
      decrypter.alterDecryptStream(
        response.stream,
        streamMeta: streamMeta,
        useBase64: useBase64,
      ),
      response.statusCode,
      statusMessage: response.statusMessage,
      headers: response.headers,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
    );
  }
}
