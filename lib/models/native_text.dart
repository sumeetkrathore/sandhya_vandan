enum NativeLanguage { sindhi, roman, hindi }

class NativeStanza {
  final int? stanzaNumber;
  final String sindhiText;
  final String romanText;
  final String? hindiText;
  final String? sindhiImagePath;
  final String? sindhiDarkImagePath;

  final bool isCenteredBold;

  const NativeStanza({
    this.stanzaNumber,
    required this.sindhiText,
    required this.romanText,
    this.hindiText,
    this.sindhiImagePath,
    this.sindhiDarkImagePath,
    this.isCenteredBold = false,
  });
}

class NativeSection {
  final String id;
  final String headingSindhi;
  final String headingRoman;
  final String? headingHindi;
  final String? subheadingSindhi;
  final String? trailingImagePath;
  final String? trailingDarkImagePath;
  final List<NativeStanza> stanzas;

  const NativeSection({
    required this.id,
    required this.headingSindhi,
    required this.headingRoman,
    this.headingHindi,
    this.subheadingSindhi,
    this.trailingImagePath,
    this.trailingDarkImagePath,
    required this.stanzas,
  });

  String get sindhiTitle => headingSindhi;
  String get romanTitle => headingRoman;
  String? get hindiTitle => headingHindi;
}
