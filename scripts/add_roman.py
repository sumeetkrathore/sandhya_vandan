import re

def update_reading_sequence():
    path = 'lib/models/reading_sequence.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add Prarthana Jai Samadha (55-59) and Geeta Jo Saar (68) mappings
    new_blocks = """      } else if (page.assetPage == 55) {
        final section = nativeSections.firstWhere((s) => s.id == 'PRARTHANA_JAI_SAMADHA');
        int endIndex = i + 5;
        if (endIndex > pustak.pages.length) endIndex = pustak.pages.length;
        final replaced = pustak.pages.sublist(i, endIndex);
        items.add(NativeSectionItem(
          sequenceIndex: seqIdx++,
          startAssetPage: 55,
          endAssetPage: 59,
          section: section,
          replacedPages: replaced,
        ));
        i += 5;
      } else if (page.assetPage == 68) {
        final section = nativeSections.firstWhere((s) => s.id == 'GEETA_JO_SAAR');
        items.add(NativeSectionItem(
          sequenceIndex: seqIdx++,
          startAssetPage: 68,
          endAssetPage: 68,
          section: section,
          replacedPages: [page],
        ));
        i += 1;
"""
    # Insert before the `else { // Standard Scanned Page`
    content = content.replace("      } else {\n        // Standard Scanned Page", new_blocks + "      } else {\n        // Standard Scanned Page")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


def generate_new_sections():
    # Long Prarthana (Prarthana Jai Samadha)
    prarthana_sindhi = [
        "ٻول سَماڌن واري صاحب ڪي جئه\nشِو سَرُوپ سَتگُرو سُوامي شِو ڀَڄن صاحب ڪي جئه \nرحمي بابا رحم ڪر",
        "اوم ڀُور ڀوھه، سوهه تَت سَويتر، وَريڻِيم ڀَرڳو دیوَسِيه ڌي مَهي ڌِيويونھه پَرچوديات",
        "اوم پار بِرهم ڪو سمرڪي سري وشنولئه ڌياءِ \nشري رام ڪرشن اوتارھري شنڪر هوءِ سهاءِ",
        "ماتِ ڀَڳونتي سِمرڪي شِري سَتگرو ديو ڀَڳوان\nسَـنَڪ سَنَـندن، سَناتن سَنت ڪُمار شِري \nسَتگُرو بابا هَر ڀَڄن صاحب جي چَرن ڪَملون \nڪا ڌيان ڌر ڪي بولو... هري اوم",
        "چوویهن اوتارن سَروَ رِشیون مُنيون جَپـیون\nتَپيون ڪا ڌِيان ڌَر ڪي بولو… هري اوم",
        "سَروَ مَهنتون، سَنتون ڀَڳتون، سَروَ ديوِي\nدیوتائون ڪا ڌِيان ڌَر ڪي بولو… هري اوم",
        "اَٺ سَٺ تیِرٿون، چارون ڌام، چاروید،\nڇَهه شاستر، اَٺارهه پُراڻ، سَروَ ڌَرم گِرنٿون ڪا\nڌِيان ڌَرڪي بولو… هري اوم",
        "آڌي آسٿان پُوج شِري سَماڌا آشرم جي ڪا ڌيان\nڌَر ڪي بولو… هري اوم",
        "اَکنڊ آدویت جوتي سَرُوپ جي ڪا ڌِيان \nڌَرڪي بولو… هري اوم",
        "اُداسیِن آچاریہ، یوگیشور بال جَتي جَڳت گُرو\nبابا سِریچند ڀَڳوان، بابا لَكمي چَند صاحب،\nبابا المَست صاحب جي ڪي نيڪ ڪمائي ڪا\nڌِيان ڌَرڪي بولو… هري اوم",
        "هِنڌ سِنڌُ جي سَنتن، دَرويشن\nسائين جي پیارن جي نيڪ ڪمائي ڪا ڌِيان ڌَر ڪي بولو… هري اوم",
        "سِرِي رام سُک ڌام شِري ڪِرشن آنند ڪَند ڀَڳوان،\nشِري اَمر لعل صاحب، شَنڪر ڀَڳوان،\nآد شَڪتِي جوڳ ماتا جي ڪا ڌِيان ڌرڪي بولو… هري اوم",
        "شِري پَوتر ڌُوڻِي صاحب جي ڪا ڌِيان \nڌرڪي بولو… هري اوم",
        "هي نِماڻن جا ماڻ، اَڙین جا آڌار، بي سَهارَن جا سَهارا،\nبي وسِيلن جا وسِيلا، هي ديِن ٻَندون،\nهي ڪِرپا ساگر پَرم پُوجنیه،\nاوم شِري بِرهم سَرُوپ، شِري شانتِي سَرُوپ، شِري آنند سَرُوپ،\nپُوج شِري سَتگُرو بابا هَر ڀَڄن صاحب،\nبابا رام ڀَڄن صاحب، بابا رُوپ ڀَڄن صاحب،\nبابا ڪِشن ڀَڄن صاحب،\nدِیناناٿ دَيال سَتگُرو بابا گوبند ڀَڄن صاحب،\nاڙین جا آڌار، بي واهَن جا واهه، شِو سَرُوپ شِري سَتگُرو بابا شِوڀَڄن صاحب جي ڪي پَوترنيڪ ڪَمائي اور چَرنون ڪَملون ڪا ڌِيان ڌَرڪي بولو… هري اوم",
        "حاضران حضور ظاهران ظهور سَتگُرو شَهنشاهه پُوج سَماڌِن واري سائين جي پَوِتر دَرشن دِیدار ڪا ڌِيان ڌَرڪي بولو… هري اوم",
        "سَتگُرو تُون نَه ڇَڏيج، مان ته جِيئان تُنهنجي آسري\nسَڀئي پاڙون سُورَ جُون، هڪ لَهظي منجهه لَٽيج\nسَتگُرو تُون نه مُنهن مَٽيج، جي لوڪ مَٽيو ته گهوريو",
        "اس ويلي ڪي پِرارٿنا، تيري آگي پِرارٿنا،\nتيري نام ڪي پِرارٿنا، سَنڌيا ڪال ڪي پِرارٿنا،\nآرتِي صاحب ڪي پِرارٿنا،\nاَکر ٽِیـپی پوَڙي، لاڪنا كِن ماتران، واڌِي گهاٽِي بَخش لينا،\nڀُل چُڪ معاف، بي اَدبي مُعاف ڪَرڻي،\nدَرٻار صاحب ڪي پِرارٿنا،\nدَرٻارصاحب سَدائين قائم رَهي، چُلها تَپدا رَهي،\nشیوڪ نام جپندا رَهي،\nآئي سَنگت ڪي پِرارٿنا، سـاري سَنگت جا ڪـارِج راس،\nدُک ڪليش ناس ڪرڻا، پَئنچن ڪي پَت، پَئنچن ڪي بــول بــالا ڪرڻي،\nنَنگري ڪا ڪَلياڻ، جڻي چوٽِي ڪي لاج، هنڌو ڌرم ڪي جئه، ڏيو سُمت، ڪَٽيو ڪُمت،\nهي دِینن جا دیال نهه اوٽيان ڪي اوٽ،\nنِرٻـلا ڪاٻـل، سَتگُرو سماڌن وارا سائين ڪيو سَتاري\nتوهان جي در تي آهي هَر دَم بابا توبَهه – توبَهه – توبَهه زارِي،\nنِماڻن جا ماڻ سَتگُرو شَهنشاهه جَهڙا تَهڙا توهان جا آهُيون،\nپنهنجي رام نام جي چادَر ۾ ڍڪي وَٺو،\nمَتِ اوُچي من نيــون ڪيو،\nسَتگُرو شَهنشاهه اُهي ڪَم ڪَرايو جنهن ۾ توهان راضي رَهو،\nاُهي ڪم نه ڪَرايو جنهن ۾ توهان ناراض ٿيو،\nويساهُه وڌايو، مَن نه وڌايو، ويساهه وڌايو، من نه وڌايو، ويساهُه وڌايو، مَن نَه وڌايو\nسَڀني جي اَندر گِیان جو پِرڪاش ڪَرڻو، اَگیان جو پَردو دُور ڪَرڻو،",
        "رَحمي بابا رَحم ڪَيو، رَحمي بابا رَحم ڪَيو،\nرَحمي بابا رَحم ڪَيو، رَحمي بابا رَحم ڪَيو،\nرَحمي بابا رَحم ڪَيو، رَحمي بابا رَحم ڪَيو",
        "هي نِماڻن جا ماڻ جِيئن ڏينهن جا چار پَھر سُک سان گُذاریا اَٿو،\nتیئن رات جا چار پَھر سُک سان گُذارجو، گَھڙی گَهڙي سُک سان گُذارجو،\nهي سَتگُرو داتار اَن پاڻي جا ڀَنڊارا ڀرپور، ڪال ڪَنٺڪ وِگهِن سَڀ دُور،\nهِنڌو ڌرم ڪي رَڪشا ڪرو، جهان جهان هِنڌو تهان تهان رَڪشا ڪرو،\nاَهڙي دَیا ڪَیو سَتگُرو توهان جو نام، توهان جو ڌِيان،\nاَسان جي چِت ۾ اَچي، لاج رَکُ سَتگُرو پَردي رَحم جي پَلڪَ نِڀاءِ،\nسَتگُرو پَرم پِتا شِري سَتگُرو بابا هَر ڀَڄن صاحب،\nآپ ڪي شَرن ۾ سارِي سَنگت ڪا ڀَلا پيري پئي، سدائين جئه...."
    ]

    prarthana_roman = [
        "Bol Samadhan Wari Sahib ki Jai\nShiv Saroop Satguru Swami Shiv Bhajan Sahib ki Jai\nRahmi Baba Reham Kar",
        "Om Bhur Bhuvaḥ Suvaha\nTat-savitur Vareñyaṃ\nBhargo Devasya Dheemahi\nDhiyo Yonaḥ Prachodayāt",
        "Om Paar Brahm ko simarki Sri Vishnu laye dhiyaae\nSri Ram Krishan Avtaar Hari Shankar hoe sahaae",
        "Maat Bhagwanti simarki Shri Satgur Dev Bhagwan\nSanak Sanandan, Sanatan Sant Kumar Shri\nSatguru Baba Har Bhajan Sahib je charan kamalon\nKa dhyaan dhar ke bolo... Hari Om",
        "Chouvihan Avtaaran Sarv Rishiyon Muniyon Japiyon\nTapiyon ka dhyaan dhar ke bolo... Hari Om",
        "Sarv Mahanton, Santon Bhagton, Sarv Devi\nDevtaon ka dhyaan dhar ke bolo... Hari Om",
        "Ath Sath Teerthon, Chaaron Dhaam, Chaar Ved,\nChhe Shastra, Atharah Puraan, Sarv Dharam Granthon ka\nDhyaan dhar ke bolo... Hari Om",
        "Aadhi Aasthaan Pooj Shri Samadha Ashram ji ka dhyaan\nDhar ke bolo... Hari Om",
        "Akhand Advait Jyoti Saroop ji ka dhyaan\nDhar ke bolo... Hari Om",
        "Udaaseen Acharya, Yogeshwar Bal Jati Jagat Guru\nBaba Srichand Bhagwan, Baba Lakmi Chand Sahib,\nBaba Almast Sahib ji ki nek kamaai ka\nDhyaan dhar ke bolo... Hari Om",
        "Hind Sindh ji santan, darveshan\nSain je pyaaran ji nek kamaai ka dhyaan dhar ke bolo... Hari Om",
        "Sri Ram Sukh Dhaam Shri Krishan Anand Kand Bhagwan,\nShri Amar Lal Sahib, Shankar Bhagwan,\nAad Shakti Jog Mata ji ka dhyaan dhar ke bolo... Hari Om",
        "Shri Pavitr Dhooni Sahib ji ka dhyaan\nDhar ke bolo... Hari Om",
        "He nimaanan ja maan, ariyin ja aadhaar, be sahaaran ja sahaara,\nBe waseelan ja waseela, He deen bandhu,\nHe Kripa Saagar Param Poojniya,\nOm Shri Brahm Saroop, Shri Shanti Saroop, Shri Anand Saroop,\nPooj Shri Satguru Baba Har Bhajan Sahib,\nBaba Ram Bhajan Sahib, Baba Roop Bhajan Sahib,\nBaba Kishan Bhajan Sahib,\nDeenanath Dayal Satguru Baba Gobind Bhajan Sahib,\nAriyin ja aadhaar, be waahan ja waah, Shiv Saroop Shri Satguru Baba Shiv Bhajan Sahib ji ki pavitr nek kamaai aur charnon kamalon ka dhyaan dhar ke bolo... Hari Om",
        "Haazraan Hazoor Zaahiran Zahoor Satguru Shahenshah Pooj Samadhan wari Sain ji pavitr darshan deedar ka dhyaan dhar ke bolo... Hari Om",
        "Satguru toon na chhadij, maan ta jiyaan tuhinje aasre\nSabhie paaroon sooran joon, hik lahze manjh latej\nSatguru toon na munh matej, je lok matyo ta ghoryo",
        "Is vele ki prarthana, teri aage prarthana,\nTeri naam ki prarthana, Sandhya kaal ki prarthana,\nAarti Sahib ki prarthana,\nAkhar tipi powri, laakna kin maatran, waadhi ghaati bakhsh lena,\nBhul chuk maaf, be-adbi maaf karni,\nDarbar Sahib ki prarthana,\nDarbar Sahib sadain qaaim rahe, chulha tapda rahe,\nSevak naam japda rahe,\nAayi sangat ki prarthana, saari sangat ja kaaraj raas,\nDukh kalesh naas karna, panchan ki pat, panchan ki bol baala karni,\nNagari ka kalyaan, jani choti ki laaj, Hindu Dharam ki jai, diyo sumat, katiyo kumat,\nHe deenan ja dayal, ne-otiyan ki ot,\nNirbala ka bal, Satguru Samadhan wara Sain kayo sataari\nTawhan je dar te aahe har dam Baba toba - toba - toba zaari,\nNimaanan ja maan Satguru Shahenshah jahra tahra tawhan ja aahyun,\nPanhinje Ram Naam ji chaadar mein dhaki watho,\nMat uchi, man niwan kayo,\nSatguru Shahenshah uhe kam karaayo janhin mein tawhan raazi raho,\nUhe kam na karaayo janhin mein tawhan naraaz thiyo,\nVisah wadhayo, man na wadhayo, Visah wadhayo, man na wadhayo, Visah wadhayo, man na wadhayo\nSabhni je andar gyaan jo prakaash karno, agyaan jo pardo door karno,",
        "Rahmi Baba reham kayo, Rahmi Baba reham kayo,\nRahmi Baba reham kayo, Rahmi Baba reham kayo,\nRahmi Baba reham kayo, Rahmi Baba reham kayo",
        "He nimaanan ja maan jiyen dinhan ja chaar pahar sukh saan guzaarya atho,\nTiyen raat ja chaar pahar sukh saan guzaarjo, ghari ghari sukh saan guzaarjo,\nHe Satguru Daatar an paani ja bhandara bharpoor, kaal kanthak vighan sabh door,\nHindu Dharam ki raksha karo, jahaan jahaan Hindu tahaan tahaan raksha karo,\nAhri daya kayo Satguru tawhan jo naam, tawhan jo dhyaan,\nAsaan je chit mein ache, laaj rakh Satguru parde reham ji palak nibhaae,\nSatguru Param Pita Shri Satguru Baba Har Bhajan Sahib,\nAap ki sharan mein saari sangat ka bhala peri pai, sadain jai...."
    ]

    # Geeta Jo Saar
    geeta_sindhi = [
        "گــــيتا جو سار\n\nجيڪو ٿيو سُٺو ٿِيو\nجو ٿي رھيو آھي، اُھو سُٺوٿي رھيو آھي\nجيڪِي ٿيندو، اُھو پِڻ سُٺو ئي ٿيندو\nتُنھنجو ڇا ويو، جو تون روئِين ٿو؟\nتون ڇا آندو ھو، جو تون وِڃايو آھي؟\nتون ڇا پيدا ڪَيو، جو ناس ٿي ويو؟\nتون جيڪو ورتو، ھتان .ئِي ورتو\nتون جيڪِي ڏنو، ھتي ئِي ڏِنو\nجيڪِي اَڄ تُنھنجو آھي،ڪالھ ڪَنھن ٻئي جو ٿيندو\nبَدل سَدل سَنسار جو نِيم آھي\nچِنتا نہ ڪر، ھَلندو ھَل"
    ]

    geeta_roman = [
        "Geeta Jo Saar\n\nJeko thiyo sutho thiyo\nJo thi rahyo aahe, uho sutho thi rahyo aahe\nJeki theendo, uho pin sutho ee theendo\nTuhinjo cha wiyo, jo toon ro-een tho?\nToon cha aando ho, jo toon vinjaayo aahe?\nToon cha paida kayo, jo naas thi wiyo?\nToon jeko warto, hitaan ee warto\nToon jeki dino, hite ee dino\nJeki ajj tuhinjo aahe, kalh kanhin biye jo theendo\nBadal sadal sansaar jo neem aahe\nChinta na kar, halando hal"
    ]

    new_sections_dart = """
  NativeSection(
    id: 'PRARTHANA_JAI_SAMADHA',
    headingSindhi: '''پِــــرارٿــنـــــا جئه سماڌا''',
    headingRoman: '''Prarthana Jai Samadha''',
    stanzas: [
"""
    for s, r in zip(prarthana_sindhi, prarthana_roman):
        new_sections_dart += f"""      NativeStanza(
        sindhiText: '''{s}''',
        romanText: '''{r}''',
      ),
"""
    new_sections_dart += """    ],
  ),
  NativeSection(
    id: 'GEETA_JO_SAAR',
    headingSindhi: '''گــــيتا جو سار''',
    headingRoman: '''Geeta Jo Saar''',
    stanzas: [
"""
    for s, r in zip(geeta_sindhi, geeta_roman):
        new_sections_dart += f"""      NativeStanza(
        sindhiText: '''{s}''',
        romanText: '''{r}''',
      ),
"""
    new_sections_dart += """    ],
  ),
"""

    path = 'lib/data/native_text_data.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Append before the last ];
    content = content.replace("];\n", new_sections_dart + "];\n")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


def update_aarti_roman_and_numbers():
    path = 'lib/data/native_text_data.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add stanza numbers to AARTI_SAHIB (Baba Roop Bhajan)
    # Stanzas 1 to 5 need numbers
    content = content.replace("        sindhiText: '''شڪارپور ۾ جَنم وٺي توهان مَندر کي ٺاهيو", "        stanzaNumber: 1,\n        sindhiText: '''شڪارپور ۾ جَنم وٺي توهان مَندر کي ٺاهيو")
    content = content.replace("        sindhiText: '''ڪو نه موٽيو ڪو سُوالي سَتگُر دَر تَوهان جي تان خالي", "        stanzaNumber: 2,\n        sindhiText: '''ڪو نه موٽيو ڪو سُوالي سَتگُر دَر تَوهان جي تان خالي")
    content = content.replace("        sindhiText: '''جيڪي اَوهان وٽ اَچن ٿا وَڃن ٿا، سَڀ سُڌري بابا", "        stanzaNumber: 3,\n        sindhiText: '''جيڪي اَوهان وٽ اَچن ٿا وَڃن ٿا، سَڀ سُڌري بابا")
    content = content.replace("        sindhiText: '''آرتي ٺاهي جوتِ جِڳائي نِوڙي نِياز ڪَريون", "        stanzaNumber: 4,\n        sindhiText: '''آرتي ٺاهي جوتِ جِڳائي نِوڙي نِياز ڪَريون")
    content = content.replace("        sindhiText: '''هري اَوهان جي آرتي سَتگُر تَن مَن سان ڳائي", "        stanzaNumber: 5,\n        sindhiText: '''هري اَوهان جي آرتي سَتگُر تَن مَن سان ڳائي")

    # Update AARTI_SHIV_BHAJAN roman text
    shiv_roman = [
        "Om Jai Shiv Saroop Bhagwan\nO Baba Shiv Bhajan Meherwan\nO Baba Samadhan ja jawan\nAahiyo nimaanan ja maan sadaain\nAahiyo nimaanan ja maan sadaain\nSoorat ja sultaan\nJai Jai Shiv Saroop Bhagwan...",
        "Diwan Thakur Das je ghar\nSatgur janam thiyo subhaan\nDeviyn devtayn gulra wasaya\nDeviyn devtayn gulra wasaya\nAaya Ishwar paan\nJai Jai Shiv Saroop Bhagwan...",
        "Wah wah rahni mithri kahni\nDaani dilawar dayawan,\nSuwaal sabhin ja poora kiyaun\nSuwaal sabhin ja poora kiyaun\nReham bhariya Rehman\nJai Jai Shiv Saroop Bhagwan...",
        "Aarti gaayan sant sabhei\nMahima aahe mahaan\nJogi ji mahima aahe mahaan\nNaam ji chaadar gyaan ja saagar\nNaam ji chaadar gyaan ja saagar\nGaayun sada gun gaan\nJai Jai Shiv Saroop Bhagwan...",
        "Sangat ji rag rag mein\nSatgur pyaar bhariyaun jaam\nSaari sangat ja aahiyo sahaara\nSaari sangat ja aahiyo sahaara\nAala awhan jo shaan\nJai Jai Shiv Saroop Bhagwan..."
    ]

    parts = content.split("'''Roman text coming soon.'''")
    if len(parts) == 6:
        new_content = parts[0]
        for i in range(5):
            new_content += f"'''{shiv_roman[i]}'''" + parts[i+1]
        content = new_content

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_reading_sequence()
    generate_new_sections()
    update_aarti_roman_and_numbers()
    print("Done generating and injecting roman texts.")
