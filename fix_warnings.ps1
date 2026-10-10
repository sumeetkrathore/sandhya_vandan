(Get-Content lib\main.dart) -replace "import 'screens/home_screen.dart';", "" | Set-Content lib\main.dart
(Get-Content lib\models\sandesh.dart) -replace "import 'dart:convert';", "" | Set-Content lib\models\sandesh.dart
(Get-Content lib\providers\audio_provider.dart) -replace "import 'package:audio_service/audio_service.dart';", "" | Set-Content lib\providers\audio_provider.dart
(Get-Content lib\providers\audio_provider.dart) -replace "print\(", "//print(" | Set-Content lib\providers\audio_provider.dart
(Get-Content lib\providers\settings_provider.dart) -replace "import 'dart:convert';", "" | Set-Content lib\providers\settings_provider.dart
(Get-Content lib\screens\audio_player_screen.dart) -replace "final currentSegment = _getCurrentSegment\(audioState\);", "//final currentSegment = _getCurrentSegment(audioState);" | Set-Content lib\screens\audio_player_screen.dart
(Get-Content lib\screens\audio_player_screen.dart) -replace "\}\)\.toList\(\),", "})," | Set-Content lib\screens\audio_player_screen.dart
(Get-Content lib\screens\home_screen.dart) -replace "import 'package:shared_preferences/shared_preferences.dart';", "" | Set-Content lib\screens\home_screen.dart
(Get-Content lib\screens\home_screen.dart) -replace "_ _", "_" | Set-Content lib\screens\home_screen.dart
(Get-Content lib\screens\reader_screen.dart) -replace "import 'package:shared_preferences/shared_preferences.dart';", "" | Set-Content lib\screens\reader_screen.dart
(Get-Content lib\screens\reader_screen.dart) -replace "\.\.scale\(1\.75\)", "..scaleByVector3(Vector3.all(1.75))" | Set-Content lib\screens\reader_screen.dart
(Get-Content lib\screens\reader_screen.dart) -replace "if \(ref\.read\(settingsProvider\)\.readingMode \!\= ReadingMode\.continuousScroll\)[\r\n\s]+return;", "if (ref.read(settingsProvider).readingMode != ReadingMode.continuousScroll) { return; }" | Set-Content lib\screens\reader_screen.dart
(Get-Content lib\screens\reader_screen.dart) -replace "if \(keepAwake\)[\r\n\s]+WakelockPlus\.enable\(\);[\r\n\s]+else[\r\n\s]+WakelockPlus\.disable\(\);", "if (keepAwake) { WakelockPlus.enable(); } else { WakelockPlus.disable(); }" | Set-Content lib\screens\reader_screen.dart
(Get-Content lib\screens\settings_screen.dart) -replace "activeColor:", "activeThumbColor:" | Set-Content lib\screens\settings_screen.dart
(Get-Content lib\widgets\audio_mini_player.dart) -replace "import '../models/audio_timeline.dart';", "" | Set-Content lib\widgets\audio_mini_player.dart
(Get-Content test_sandesh.dart) -replace "import 'dart:convert';", "" | Set-Content test_sandesh.dart
(Get-Content test_sandesh.dart) -replace "print\(", "//print(" | Set-Content test_sandesh.dart
