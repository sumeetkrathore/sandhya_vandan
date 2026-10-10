import 'native_text.dart';
import '../data/native_text_data.dart';

class ReadingSequence {
  final List<NativeSection> items;

  ReadingSequence._(this.items);

  static ReadingSequence build() {
    return ReadingSequence._(nativeSections);
  }
}
