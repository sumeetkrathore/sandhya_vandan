import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/composition.dart';

final amritVaniProvider = FutureProvider<Composition>((ref) async {
  final jsonString = await rootBundle.loadString(
    'assets/data/amrit_vani_pilot.json',
  );
  final jsonMap = jsonDecode(jsonString);
  return Composition.fromJson(jsonMap);
});
