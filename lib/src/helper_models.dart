/// hold value of [separator] and [ending] of a streamed data
class EncryptStreamMeta {
  /// the ending of the stream.
  /// this will be used to parse data in a stream.
  final String ending;

  /// the separator of the encrypted data
  /// will be placed between each encrypted parts
  final String separator;

  /// creating an instance of stream meta with given
  /// [separator] and [ending] value
  const EncryptStreamMeta({
    required this.ending,
    required this.separator,
  }) : assert(ending != separator);

  /// creating an instance of stream meta data with
  /// [separator] and [ending] with same [value]
  const EncryptStreamMeta.sameSeparatorAsEnding(String value)
      : ending = value,
        separator = value;
}
