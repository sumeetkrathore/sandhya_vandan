// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('../assets/data/pustak_data.json');
  if (!await file.exists()) {
    print('File not found');
    return;
  }

  final jsonString = await file.readAsString();
  final data = jsonDecode(jsonString);

  if (data['toc'] != null) {
    for (var item in data['toc']) {
      print(item['title']);
    }
  }
}
