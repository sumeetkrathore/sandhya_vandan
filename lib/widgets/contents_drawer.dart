import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/native_text_data.dart';
import '../models/native_text.dart';
import '../providers/settings_provider.dart';
import '../providers/audio_provider.dart';
import '../models/audio_section.dart';
import '../screens/reader_screen.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';

class ContentsDrawer extends ConsumerWidget {
  const ContentsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(settingsProvider).selectedLanguage;
    final isSindhi = selectedLanguage == NativeLanguage.sindhi;
    final isHindi = selectedLanguage == NativeLanguage.hindi;

    final List<Widget> listItems = [];

    void navigateToSection(int sectionIndex, String sectionId) {
      // Determine if this TOC item corresponds to a major audio section
      final mapping = {
        'MANGALA_CHARAN': 'mangla_charan',
        'USTATI': 'ustati',
        'AMRIT_VANI': 'amrit_vani',
        'AARTI_SAHIB': 'aarti_roop_bhajan',
        'AARTI_SHIV_BHAJAN': 'aarti_shiv_bhajan',
        'AARTI_OM_JAI_JAGDISH': 'aarti_om_jai_jagdish',
        'PRARTHANA_JAI_SAMADHA': 'dhyan',
        'PRARTHANA': 'prarthana',
      };

      final audioSectionId = mapping[sectionId];
      if (audioSectionId != null) {
        final section = audioSections.firstWhere(
          (s) => s.id == audioSectionId,
          orElse: () => audioSections.first,
        );
        if (section.isAvailable) {
          ref.read(audioProvider.notifier).playSection(section, autoPlay: true);
        }
      }

      Navigator.popUntil(context, (route) => route.isFirst);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderScreen(initialSectionIndex: sectionIndex),
        ),
      );
    }

    for (int i = 0; i < nativeSections.length; i++) {
      final section = nativeSections[i];
      if (section.id == 'PRARTHANA') {
        continue;
      }
      final title = isSindhi
          ? section.headingSindhi
          : (isHindi && section.headingHindi != null)
          ? TextUtils.toDevanagariDigits(section.headingHindi!)
          : section.headingRoman;

      if (listItems.isNotEmpty) {
        listItems.add(
          Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            indent: 16,
            endIndent: 16,
          ),
        );
      }

      listItems.add(
        ListTile(
          title: Text(
            title,
            style: isSindhi
                ? const TextStyle(
                    fontFamily: AppTheme.sindhiRegularFont,
                    fontSize: 32,
                    fontWeight: FontWeight.normal,
                  )
                : (isHindi
                      ? const TextStyle(
                          fontFamily: AppTheme.serifFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        )
                      : AppTheme.cardTitleCompact.copyWith(
                          fontWeight: FontWeight.normal,
                        )),
            textAlign: isSindhi ? TextAlign.right : TextAlign.left,
          ),
          onTap: () {
            Navigator.pop(context); // Close drawer
            navigateToSection(i, section.id);
          },
        ),
      );
    }

    return Directionality(
      textDirection: isSindhi ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isHindi
                          ? 'अनुक्रमणिका'
                          : (isSindhi ? 'فهرست' : 'Contents'),
                      style: isSindhi
                          ? TextStyle(
                              fontFamily: AppTheme.sindhiHeadingFont,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          : AppTheme.sheetTitle.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: listItems,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
