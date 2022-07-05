# Stream Cipher

this package commonly used to encrypt/decrypt data in stream form (e.g. HTTP, IO,etc)

this package initially comes with a http client adapter for `Dio` library.

>the following code snippet shows how to use the adapter:
>
>```Dart
>// this will create a `AESByteDataEncrypter` with random secure key
>final encrypter = AESByteDataEncrypter.randomSecureKey();
>// pass the key generated in the previous step to the `AESByteDataDecrypter` to create a decrypter instance with the same key
>final decrypter = AESByteDataDecrypter(
>        key: encrypter.key, 
>        iv:encrypter.iv,
>    );
>/// create instance of `CipherDioHttpAdapter` with created encrypter and decrypter
>final dioClient = CipherDioHttpAdapter(
>      decrypter: decrypter,
>      encrypter: encrypter,
>    );
>/// creating an instance of `Dio` with `CipherDioHttpAdapter`
>final dio = Dio()..httpClientAdapter = dioClient;
>```
>
>>1.in this method only the body of the request is encrypted.
>>
>>2.in this method only the body of the request is encrypted.
>>
>>3.the header of request is not encrypted. to deform the header of request, you can extend one of `IByteDataEncrypter`s and override the `alterHeader` method to do so.

for backend side you can check example of this project
