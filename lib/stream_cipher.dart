///
/// This is the main entry point to the stream cipher library API.
///
/// It includes the following libraries:
/// * **decrypter.dart** = models used for decryption
/// * **encrypter.dart** = models used for encryption
/// * **./extensions/.** = useful extensions
/// * **base.dart** = interface of en/decryption models
/// * **models.dart** = helper models like meta data
///
library stream_cipher;

export 'src/byte_data_decrypter.dart';
export 'src/byte_data_encrypter.dart';
export 'src/extensions/list_extensions.dart';
export 'src/extensions/stream_decrypter.dart';
export 'src/extensions/stream_encrypter.dart';
export 'src/helper_models.dart';
export 'src/stream_cipher_base.dart';
