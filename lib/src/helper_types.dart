library stream_cipher.helper_types;

class EncryptStreamMeta {
  /// the ending of the stream.
  /// this will be used to parse data in a stream.
  final String ending;

  /// the separator of the encrypted data
  /// will be placed between each encrypted parts
  final String separator;

  const EncryptStreamMeta({
    required this.ending,
    required this.separator,
  }) : assert(ending != separator);
}
