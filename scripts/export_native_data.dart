// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:sandhya_vandan/data/native_text_data.dart';

void main() async {
  final file = File('../assets/data/audio_timeline.json');
  String timelineStr = '{}';
  if (await file.exists()) {
    timelineStr = await file.readAsString();
  } else {
    // try direct path
    final file2 = File('assets/data/audio_timeline.json');
    if (await file2.exists()) {
      timelineStr = await file2.readAsString();
    }
  }
  final timelineData = jsonDecode(timelineStr);

  final List<Map<String, dynamic>> output = [];

  for (var section in nativeSections) {
    List<Map<String, dynamic>> stanzas = [];
    for (var stanza in section.stanzas) {
      stanzas.add({
        'stanzaNumber': stanza.stanzaNumber,
        'sindhiText': stanza.sindhiText,
        'romanText': stanza.romanText,
        'hindiText': stanza.hindiText,
        'isCenteredBold': stanza.isCenteredBold,
      });
    }

    output.add({
      'id': section.id,
      'headingSindhi': section.headingSindhi,
      'headingRoman': section.headingRoman,
      'stanzas': stanzas,
    });
  }

  final finalOutput = {
    'native_text': output,
    'audio_timeline': timelineData
  };

  final outFile = File('web_reader_data.json');
  await outFile.writeAsString(jsonEncode(finalOutput));
  print('Exported to web_reader_data.json');
}
