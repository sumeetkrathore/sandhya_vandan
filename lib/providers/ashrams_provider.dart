import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ashram.dart';
import '../services/ashram_service.dart';

final ashramServiceProvider = Provider<AshramService>((ref) {
  return AshramService();
});

final ashramsProvider = FutureProvider<List<Ashram>>((ref) async {
  final service = ref.read(ashramServiceProvider);
  return await service.fetchAshrams();
});
