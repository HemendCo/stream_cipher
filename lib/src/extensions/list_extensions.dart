library stream_cipher.extensions;

extension ListBreaker<T> on List<T> {
  /// split the list by given [splitter] as breaker
  ///
  /// this method will remove [splitter]s from the list and
  /// returns an [Iterable] of other parts
  Iterable<Iterable<T>> splitByPart(List<T> splitter) {
    final parts = <Iterable<T>>[];
    if (length < splitter.length) {
      return [this];
    }
    var start = 0;
    for (var i = 0; i < length; i++) {
      if (this[i] == splitter[0]) {
        if (splitter.length == 1) {
          parts.add(sublist(start, i));
          start = i + 1;
        } else {
          if (i + splitter.length <= length &&
              sublist(
                    i,
                    i + splitter.length,
                  ).join() ==
                  splitter.join()) {
            parts.add(sublist(start, i));
            start = i + splitter.length;
            i += splitter.length - 1;
          }
        }
      }
    }
    parts.add(sublist(start, length));
    return parts;
  }

  /// will slice the list by given [pieceSize]
  ///
  /// if [strict] was set to true will force all of sublists to have same size
  ///
  /// in this case if sublists was not in correct shape it will fill the last
  /// sublist with given [fillEmptyWith] to match the size
  Iterable<Iterable<T>> sliceToPiecesOfSize(
    int pieceSize, {
    bool strict = false,
    T? fillEmptyWith,
  }) {
    final result = <Iterable<T>>[];
    var current = <T>[];
    for (final item in this) {
      current.add(item);
      if (current.length == pieceSize) {
        result.add(current);
        current = <T>[];
      }
    }
    if (current.isNotEmpty) {
      if (strict) {
        if (fillEmptyWith == null) {
          throw Exception(
            '''size of list ($length) is not a multiple of $pieceSize and no filler passed to fill the empty space try passing `fillEmptyWith: <$T>`''',
          );
        }
        result.add([
          ...current,
          ...List<T>.filled(
            pieceSize - current.length,
            fillEmptyWith,
          ),
        ]);
      } else {
        result.add(current);
      }
    }
    return result;
  }
}
