// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('../assets/data/pustak_data.json');
  if (!await file.exists()) {
    print('File not found: ${file.path}');
    return;
  }

  final jsonString = await file.readAsString();
  final data = jsonDecode(jsonString);

  // Toc is likely in data['toc']
  if (data['toc'] != null) {
    for (var item in data['toc']) {
      // Remove pustakPage for everything except "Hand written arti" (or similar)
      if (item['title'] != null &&
          !item['title'].toString().toLowerCase().contains('arti')) {
        item.remove('pustakPage');
      }
    }
  }

  // Pretty print back
  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(data));
  print('Successfully updated TOC in pustak_data.json');
}
