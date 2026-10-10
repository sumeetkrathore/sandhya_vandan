class AudioSection {
  final String id;
  final String displayTitle;
  final Duration? startTimestamp;
  final Duration? endTimestamp;

  const AudioSection({
    required this.id,
    required this.displayTitle,
    this.startTimestamp,
    this.endTimestamp,
  });

  bool get isAvailable =>
      id == 'full' || (startTimestamp != null && endTimestamp != null);
}

const List<AudioSection> audioSections = [
  AudioSection(
    id: 'full',
    displayTitle: 'Listen to Complete Sandhya Vandan Nem',
    startTimestamp: null,
    endTimestamp: null,
  ),
  AudioSection(
    id: 'mangla_charan',
    displayTitle: 'Mangla Charan',
    startTimestamp: Duration(minutes: 0, seconds: 13),
    endTimestamp: Duration(minutes: 1, seconds: 40),
  ),
  AudioSection(
    id: 'ustati',
    displayTitle: 'Samadha Ashram Ji Ustati',
    startTimestamp: Duration(minutes: 1, seconds: 41),
    endTimestamp: Duration(minutes: 3, seconds: 11),
  ),
  AudioSection(
    id: 'amrit_vani',
    displayTitle: 'Amrit Vani',
    startTimestamp: Duration(minutes: 3, seconds: 12),
    endTimestamp: Duration(minutes: 13, seconds: 3),
  ),
  AudioSection(
    id: 'aarti_roop_bhajan',
    displayTitle: 'Aarti - Satguru Baba Roop Bhajan Sahib',
    startTimestamp: Duration(minutes: 16, seconds: 37),
    endTimestamp: Duration(minutes: 20, seconds: 42),
  ),
  AudioSection(
    id: 'aarti_shiv_bhajan',
    displayTitle: 'Aarti - Satguru Baba Shiv Bhajan Sahib',
    startTimestamp: Duration(minutes: 20, seconds: 42),
    endTimestamp: Duration(minutes: 24, seconds: 4),
  ),
  AudioSection(
    id: 'aarti_om_jai_jagdish',
    displayTitle: 'Aarti - Om Jai Jagdish Hare',
    startTimestamp: Duration(minutes: 24, seconds: 5),
    endTimestamp: Duration(minutes: 29, seconds: 15),
  ),
  AudioSection(
    id: 'dhyan',
    displayTitle: 'Dhyan / Shanti Simran',
    startTimestamp: Duration(minutes: 29, seconds: 16),
    endTimestamp: Duration(minutes: 39, seconds: 40),
  ),
  AudioSection(
    id: 'prarthana',
    displayTitle: 'Prarthana',
    startTimestamp: Duration(minutes: 39, seconds: 58),
    endTimestamp: Duration(minutes: 46, seconds: 36),
  ),
];
