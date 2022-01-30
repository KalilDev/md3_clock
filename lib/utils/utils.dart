extension InterleavedE<T> on Iterable<T> {
  Iterable<T> interleaved(T Function(int) interleaveBuilder) sync* {
    int i = -1;
    for (final e in this) {
      if (i == -1) {
        i++;
      } else {
        yield interleaveBuilder(i++);
      }
      yield e;
    }
  }
}
