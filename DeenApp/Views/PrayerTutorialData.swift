//
//  PrayerTutorialData.swift
//  DeenApp
//
//  Vollständige Gebetsdaten für alle 5 Fard-Gebete (Hanafi).
//  Reusable Helper-Funktionen halten die Komposition kompakt und korrekt.
//  Jeder Schritt enthält den vollständigen arabischen Text, Transliteration und Übersetzung.
//

import Foundation

enum PrayerTutorialData {

    // MARK: - Public API

    static func steps(for prayer: PrayerKind) -> [PrayerStep] {
        switch prayer {
        case .imsak:   return fajrSteps
        case .shuruuq: return []
        case .dhuhr:   return dhuhrSteps
        case .asr:     return asrSteps
        case .maghrib: return maghribSteps
        case .isha:    return ishaSteps
        default:       return []
        }
    }

    // MARK: - Full Text Constants

    private static let takbirArabic = "اللّٰهُ أَكْبَرُ"
    private static let takbirTranslit = "Allahu Akbar"
    private static let takbirDmg = "Allāhu ʾakbar"
    private static let takbirTransl = "Allah ist der Größte."

    private static let subhanekeArabic = """
    سُبْحَانَكَ اللّٰهُمَّ وَبِحَمْدِكَ \
    وَتَبَارَكَ اسْمُكَ وَتَعَالَىٰ جَدُّكَ \
    وَلَا إِلٰهَ غَيْرُكَ
    """
    private static let subhanekeTranslit = "Subhanek-Allahumma wa bihamdik, wa tebeerakesmuk wa ta’alaa-jedduk welaa illaha ghayruk"
    private static let subhanekeDmg = """
    Subḥānaka ʾllāhumma wa-bi-ḥamdik wa-tabāraka smuk wa-taʿālā jadduk \
    wa-lā ilāha ġayruk
    """
    private static let subhanekeTransl = "Gepriesen seist Du, o Allah, und gelobt. Gesegnet ist Dein Name, erhaben ist Deine Majestät, und es gibt keinen Gott außer Dir."

    private static let euzuBesmeleArabic = """
    أَعُوذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيمِ \
    بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ
    """
    private static let euzuBesmeleTranslit = "Audhu billahi minesh sheytanirrajim, bismillahir-rahmanir-rahim"
    private static let euzuBesmeleDmg = """
    Aʿūḏu bi-llāhi mina š-šayṭāni r-rajīm \
    Bi-smi llāhi r-raḥmāni r-raḥīm
    """
    private static let euzuBesmeleTransl = "Ich suche Zuflucht bei Allah vor dem verfluchten Teufel. Im Namen Allahs, des Allerbarmers, des Barmherzigen."

    private static let fatihaArabic = """
    اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِينَ ۝ \
    اَلرَّحْمٰنِ الرَّحِيمِ ۝ \
    مَالِكِ يَوْمِ الدِّينِ ۝ \
    إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ \
    اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ \
    صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ ۝ \
    غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ
    """
    private static let fatihaTranslit = "Elhamdulillahi rabbil'aalemin. Errahman-irrahiim. Maalikiyaumid diin. iyyaake na'budu we iyyaake nesta'iin. Ihdinessiraatal-mustaqiim. Siraatalledhiine en'amte 'aleyhim, ghayrilmeghduubi 'aleyhim weladdaalliin. (Amin)"
    private static let fatihaDmg = """
    Al-ḥamdu li-llāhi rabbi l-ʿālamīn \
    Ar-raḥmāni r-raḥīm \
    Māliki yawmi d-dīn \
    Iyyāka naʿbudu wa-iyyāka nastaʿīn \
    Ihdinā ṣ-ṣirāṭa l-mustaqīm \
    Ṣirāṭa lladīna ʾanʿamta ʿalayhim \
    Ġayri l-maġḍūbi ʿalayhim wa-lā ḍ-ḍāllīn
    """
    private static let fatihaTransl = "Alles Lob gebührt Allah, dem Herrn der Welten. Dem Allerbarmer, dem Barmherzigen. Dem Herrscher am Tage des Gerichts. Dir allein dienen wir, und Dich allein bitten wir um Hilfe. Führe uns den geraden Weg. Den Weg derer, denen Du Gnade erwiesen hast, nicht derer, die Deinen Zorn erregt haben, und nicht der Irregehenden."

    private static let fatihaWithBesmeleArabic = """
    بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ ۝ \
    اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِينَ ۝ \
    اَلرَّحْمٰنِ الرَّحِيمِ ۝ \
    مَالِكِ يَوْمِ الدِّينِ ۝ \
    إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ \
    اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ \
    صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ ۝ \
    غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ
    """
    private static let fatihaWithBesmeleTranslit = "Elhamdulillahi rabbil'aalemin. Errahman-irrahiim. Maalikiyaumid diin. iyyaake na'budu we iyyaake nesta'iin. Ihdinessiraatal-mustaqiim. Siraatalledhiine en'amte 'aleyhim, ghayrilmeghduubi 'aleyhim weladdaalliin. (Amin)"
    private static let fatihaWithBesmeleDmg = """
    Bi-smi llāhi r-raḥmāni r-raḥīm \
    Al-ḥamdu li-llāhi rabbi l-ʿālamīn \
    Ar-raḥmāni r-raḥīm \
    Māliki yawmi d-dīn \
    Iyyāka naʿbudu wa-iyyāka nastaʿīn \
    Ihdinā ṣ-ṣirāṭa l-mustaqīm \
    Ṣirāṭa lladīna ʾanʿamta ʿalayhim \
    Ġayri l-maġḍūbi ʿalayhim wa-lā ḍ-ḍāllīn
    """
    private static let fatihaWithBesmeleTransl = "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Alles Lob gebührt Allah, dem Herrn der Welten. Dem Allerbarmer, dem Barmherzigen. Dem Herrscher am Tage des Gerichts. Dir allein dienen wir, und Dich allein bitten wir um Hilfe. Führe uns den geraden Weg. Den Weg derer, denen Du Gnade erwiesen hast, nicht derer, die Deinen Zorn erregt haben, und nicht der Irregehenden."

    private static let ikhlasArabic = """
    قُلْ هُوَ اللّٰهُ أَحَدٌ ۝ \
    اَللّٰهُ الصَّمَدُ ۝ \
    لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ \
    وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ
    """
    private static let ikhlasTranslit = "Qul hu wAllahu ahad. Allahu-ssamed. Lem yelid we lem yuuled. we lem yekullehuu kufuwen ahad."
    private static let ikhlasDmg = """
    Qul huwa Allāhu aḥad \
    Allāhu ṣ-ṣamad \
    Lam yalid wa-lam yūlad \
    Wa-lam yakul lahu kufuwan aḥad
    """
    private static let ikhlasTransl = "Sprich: Er ist Allah, der Einzige. Allah, der Ewige. Er zeugt nicht und ist nicht gezeugt worden. Und niemand ist Ihm gleich."

    private static let rukuArabic = "سُبْحَانَ رَبِّيَ الْعَظِيمِ"
    private static let rukuTranslit = "Subhane Rabbiyel-Azim (3×)"
    private static let rukuDmg = "Subḥāna rabbiya l-ʿaẓīm (3×)"
    private static let rukuTransl = "Gepriesen sei mein Herr, der Allmächtige."

    private static let qawmahArabic = """
    سَمِعَ اللّٰهُ لِمَنْ حَمِدَهُ \
    رَبَّنَا لَكَ الْحَمْدُ
    """
    private static let qawmahTranslit = "Semi'Allahu limen hamideh. Rabbena lekel-hamd."
    private static let qawmahDmg = """
    Samiʿa llāhu li-man ḥamidah \
    Rabbanā laka l-ḥamd
    """
    private static let qawmahTransl = "Allah hört den, der Ihn lobt. Unser Herr, Dir gebührt alles Lob."

    private static let sujudArabic = "سُبْحَانَ رَبِّيَ الْأَعْلَىٰ"
    private static let sujudTranslit = "Subhane Rabbiyel-A'la (3×)"
    private static let sujudDmg = "Subḥāna rabbiya l-aʿlā (3×)"
    private static let sujudTransl = "Gepriesen sei mein Herr, der Allerhöchste."

    private static let tahiyyatArabic = """
    اَلتَّحِيَّاتُ لِلّٰهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ \
    اَلسَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللّٰهِ وَبَرَكَاتُهُ \
    اَلسَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللّٰهِ الصَّالِحِينَ \
    أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ \
    وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ
    """
    private static let tahiyyatTranslit = "Ettehiyyaatu lillahi wes-salawaatu wettayyibaat. esselamu 'aleyke eyyuhen-nebiyyu we rahmetullahi we berakatuh. Esselamu 'aleyna we 'ala 'ibadillahis-salihin. Eshedu en la ilahe illAllah we eshedu enne Muhammeden abduhu we rasuluh"
    private static let tahiyyatDmg = """
    At-taḥiyyātu li-llāhi wa-ṣ-ṣalawātu wa-ṭ-ṭayyibāt \
    As-salāmu ʿalayka ayyuha n-nabiyyu wa-raḥmatu llāhi wa-barakātuh \
    As-salāmu ʿalaynā wa-ʿalā ʿibādi llāhi ṣ-ṣāliḥīn \
    Aš-hadu ʾan lā ilāha illā llāh \
    Wa-aš-hadu ʾanna muḥammadan ʿabduhu wa-rasūluhu
    """
    private static let tahiyyatTransl = "Die Grüße, die Gebete und die reinen Worte gebühren Allah. Friede sei auf dir, o Prophet, und die Barmherzigkeit Allahs und Seine Segnungen. Friede sei auf uns und auf den rechtschaffenen Dienern Allahs. Ich bezeuge, dass es keinen Gott gibt außer Allah, und ich bezeuge, dass Muhammad Sein Diener und Gesandter ist."

    private static let salliArabic = """
    اَللّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ \
    كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ \
    إِنَّكَ حَمِيدٌ مَجِيدٌ
    """
    private static let salliTranslit = "Allahumme salli 'ala Muhammedin ve 'ala ali Muhammad. Kema salleyte 'ala Ibrahime ve 'ala ali Ibrahim. Inneke hamidun mejid."
    private static let salliDmg = """
    Allāhumma ṣalli ʿalā Muḥammadin wa-ʿalā āli Muḥammad \
    Kamā ṣallayta ʿalā Ibrāhīma wa-ʿalā āli Ibrāhīm \
    Innaka ḥamīdun maǧīdun
    """
    private static let salliTransl = "O Allah, segne Muhammad und die Familie Muhammads, so wie Du Ibrahim und die Familie Ibrahims gesegnet hast. Wahrlich, Du bist der Lobenswürdige, der Ruhmreiche."

    private static let barikArabic = """
    اَللّٰهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ \
    كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ \
    إِنَّكَ حَمِيدٌ مَجِيدٌ
    """
    private static let barikTranslit = "Allahumme barik 'ala Muhammedin ve 'ala ali Muhammad. Kema barekte 'ala Ibrahime ve 'ala ali Ibrahim. Inneke hamidun mejid."
    private static let barikDmg = """
    Allāhumma bārik ʿalā Muḥammadin wa-ʿalā āli Muḥammad \
    Kamā bārakta ʿalā Ibrāhīma wa-ʿalā āli Ibrāhīm \
    Innaka ḥamīdun maǧīdun
    """
    private static let barikTransl = "O Allah, segne Muhammad und die Familie Muhammads mit Segen, so wie Du Ibrahim und die Familie Ibrahims gesegnet hast. Wahrlich, Du bist der Lobenswürdige, der Ruhmreiche."

    private static let rabbenaArabic = """
    رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً \
    وَفِي الْآخِرَةِ حَسَنَةً \
    وَقِنَا عَذَابَ النَّارِ
    """
    private static let rabbenaTranslit = "Rabbena aatina fid-dunya haseneh, ve fil-aakhireti haseneh, ve qinaa 'adheben-nar."
    private static let rabbenaDmg = """
    Rabbanā ātinā fī d-dunyā ḥasanatan \
    Wa-fī l-āḫirati ḥasanatan \
    Wa-qinā ʿaḏāba n-nār
    """
    private static let rabbenaTransl = "Unser Herr, gib uns im Diesseits Gutes und im Jenseits Gutes und bewahre uns vor der Strafe des Feuers."

    private static let rabbenaghfirliArabic = """
    رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ \
    وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ
    """
    private static let rabbenaghfirliTranslit = "Rabbighfirli ve li-welideyye ve lil-mu'minine yaume yequmul-hisab."
    private static let rabbenaghfirliDmg = """
    Rabbi ġfir lī wa-li-wālidayya \
    Wa-lil-muʾminīna yawma yaqūmu l-ḥisāb
    """
    private static let rabbenaghfirliTransl = "Mein Herr, vergib mir und meinen Eltern und den Gläubigen am Tag, an dem die Abrechnung stattfindet."

    private static let salamArabic = "اَلسَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ"
    private static let salamTranslit = "Esselamu aleykum ve rahmetullah."
    private static let salamDmg = "As-salāmu ʿalaykum wa-raḥmatu llāh"
    private static let salamTransl = "Der Friede und die Barmherzigkeit Allahs sei mit euch."

    // MARK: - Atomic Step Builders

    private static func niyyah(_ p: String, rakatCount: Int, prayerName: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_niyyah",
            title: "Absicht (Niyyah)",
            translation: "Ich beabsichtige, das \(rakatCount)-Rak'at-Pflichtgebet des \(prayerName) zu verrichten, um Allahs Willen, in Richtung der Qibla.",
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func takbirIhram(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_takbir",
            title: "Takbir (Iftitah-Tekbir)",
            arabicText: takbirArabic,
            transliteration: takbirTranslit,
            dmgTransliteration: takbirDmg,
            translation: takbirTransl,
            imageNameMale: "pose_male_takbir_ears",
            imageNameFemale: "pose_female_takbir_shoulders"
        )
    }

    private static func subhaneke(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_subhaneke",
            title: "Subhaneke (Sana-Gebet)",
            arabicText: subhanekeArabic,
            transliteration: subhanekeTranslit,
            dmgTransliteration: subhanekeDmg,
            translation: subhanekeTransl,
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func euzuBesmele(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_euzu_besmele",
            title: "audhu-Besmele",
            arabicText: euzuBesmeleArabic,
            transliteration: euzuBesmeleTranslit,
            dmgTransliteration: euzuBesmeleDmg,
            translation: euzuBesmeleTransl,
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func fatihaAfterEuzu(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_fatiha",
            title: "Al-Fatiha (\(r). Rak'a)",
            arabicText: fatihaArabic,
            transliteration: fatihaTranslit,
            dmgTransliteration: fatihaDmg,
            translation: fatihaTransl,
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func fatihaWithBesmele(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_besmele_fatiha",
            title: "Besmele + Fatiha (\(r). Rak'a)",
            arabicText: fatihaWithBesmeleArabic,
            transliteration: fatihaWithBesmeleTranslit,
            dmgTransliteration: fatihaWithBesmeleDmg,
            translation: fatihaWithBesmeleTransl,
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func fatihaOnlyHanafi(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_besmele_fatiha",
            title: "Besmele + Fatiha (\(r). Rak'a – nur Fatiha, Hanafi)",
            arabicText: fatihaWithBesmeleArabic,
            transliteration: fatihaWithBesmeleTranslit,
            dmgTransliteration: fatihaWithBesmeleDmg,
            translation: fatihaWithBesmeleTransl,
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func additionalSurah(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_ikhlas",
            title: "Sure Al-Ikhlas (\(r). Rak'a)",
            arabicText: ikhlasArabic,
            transliteration: ikhlasTranslit,
            dmgTransliteration: ikhlasDmg,
            translation: ikhlasTransl,
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func ruku(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_ruku",
            title: "Ruku (\(r). Rak'a)",
            arabicText: rukuArabic,
            transliteration: rukuTranslit,
            dmgTransliteration: rukuDmg,
            translation: rukuTransl,
            imageNameMale: "pose_male_ruku",
            imageNameFemale: "pose_female_ruku"
        )
    }

    private static func qawmah(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_qawmah",
            title: "Qawmah (\(r). Rak'a)",
            arabicText: qawmahArabic,
            transliteration: qawmahTranslit,
            dmgTransliteration: qawmahDmg,
            translation: qawmahTransl,
            imageNameMale: "pose_male_qawmah",
            imageNameFemale: "pose_female_qawmah"
        )
    }

    private static func firstSujud(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_sujud_1",
            title: "Erste Sajda (\(r). Rak'a)",
            arabicText: sujudArabic,
            transliteration: sujudTranslit,
            dmgTransliteration: sujudDmg,
            translation: sujudTransl,
            imageNameMale: "pose_male_sujud",
            imageNameFemale: "pose_female_sujud"
        )
    }

    private static func jalsa(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_jalsa",
            title: "Dschalsa (\(r). Rak'a)",
            transliteration: nil,
            translation: "Kurzes, ruhiges Sitzen zwischen den beiden Niederwerfungen.",
            imageNameMale: "pose_male_jalsa",
            imageNameFemale: "pose_female_jalsa"
        )
    }

    private static func secondSujud(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_sujud_2",
            title: "Zweite Sajda (\(r). Rak'a)",
            arabicText: sujudArabic,
            transliteration: sujudTranslit,
            dmgTransliteration: sujudDmg,
            translation: sujudTransl,
            imageNameMale: "pose_male_sujud",
            imageNameFemale: "pose_female_sujud"
        )
    }

    private static func standUp(_ p: String, toRakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_standup",
            title: "Aufstehen zur \(r). Rak'a",
            arabicText: takbirArabic,
            transliteration: takbirTranslit,
            dmgTransliteration: takbirDmg,
            translation: "Man steht auf und beginnt die \(r). Gebetseinheit.",
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func tahiyyat(_ p: String, label: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_\(label)_tahiyyat",
            title: "Tahiyyat (Ettehiyyatu)",
            arabicText: tahiyyatArabic,
            transliteration: tahiyyatTranslit,
            dmgTransliteration: tahiyyatDmg,
            translation: tahiyyatTransl,
            imageNameMale: "pose_male_qa_da",
            imageNameFemale: "pose_female_qa_da"
        )
    }

    private static func salli(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_salli",
            title: "Salli-Gebet (Salavat)",
            arabicText: salliArabic,
            transliteration: salliTranslit,
            dmgTransliteration: salliDmg,
            translation: salliTransl,
            imageNameMale: "pose_male_qa_da",
            imageNameFemale: "pose_female_qa_da"
        )
    }

    private static func barik(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_barik",
            title: "Barik-Gebet",
            arabicText: barikArabic,
            transliteration: barikTranslit,
            dmgTransliteration: barikDmg,
            translation: barikTransl,
            imageNameMale: "pose_male_qa_da",
            imageNameFemale: "pose_female_qa_da"
        )
    }

    private static func rabbenaAtina(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_rabbena",
            title: "Rabbena Atina (Bittgebet)",
            arabicText: rabbenaArabic,
            transliteration: rabbenaTranslit,
            dmgTransliteration: rabbenaDmg,
            translation: rabbenaTransl,
            imageNameMale: "pose_male_qa_da",
            imageNameFemale: "pose_female_qa_da"
        )
    }

    private static func rabbenaghfirli(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_rabbenaghfirli",
            title: "Rabbenaghfirli (Vergebungsbitte)",
            arabicText: rabbenaghfirliArabic,
            transliteration: rabbenaghfirliTranslit,
            dmgTransliteration: rabbenaghfirliDmg,
            translation: rabbenaghfirliTransl,
            imageNameMale: "pose_male_qa_da",
            imageNameFemale: "pose_female_qa_da"
        )
    }

    private static func salamRight(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_salam_right",
            title: "Salam nach rechts",
            arabicText: salamArabic,
            transliteration: salamTranslit,
            dmgTransliteration: salamDmg,
            translation: salamTransl,
            imageNameMale: "pose_male_salam_right",
            imageNameFemale: "pose_female_salam_right"
        )
    }

    private static func salamLeft(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_salam_left",
            title: "Salam nach links",
            arabicText: salamArabic,
            transliteration: salamTranslit,
            dmgTransliteration: salamDmg,
            translation: salamTransl,
            imageNameMale: "pose_male_salam_left",
            imageNameFemale: "pose_female_salam_left"
        )
    }

    // MARK: - Composite Rak'at Builders

    /// Opening of the prayer: Niyyah + Takbir + Subhaneke + Euzu-Besmele
    private static func opening(_ p: String, rakatCount: Int, prayerName: String) -> [PrayerStep] {
        [
            niyyah(p, rakatCount: rakatCount, prayerName: prayerName),
            takbirIhram(p),
            subhaneke(p),
            euzuBesmele(p)
        ]
    }

    /// First rak'at body: Fatiha (no Besmele, was in Euzu step) + Surah + Ruku cycle
    private static func firstRakatBody(_ p: String) -> [PrayerStep] {
        [
            fatihaAfterEuzu(p, rakat: 1),
            additionalSurah(p, rakat: 1),
            ruku(p, rakat: 1),
            qawmah(p, rakat: 1),
            firstSujud(p, rakat: 1),
            jalsa(p, rakat: 1),
            secondSujud(p, rakat: 1)
        ]
    }

    /// Rak'at WITH surah (2nd rak'at, or 1st/2nd in any prayer): Besmele+Fatiha + Surah + Ruku cycle
    private static func rakatWithSurah(_ p: String, rakat r: Int) -> [PrayerStep] {
        [
            fatihaWithBesmele(p, rakat: r),
            additionalSurah(p, rakat: r),
            ruku(p, rakat: r),
            qawmah(p, rakat: r),
            firstSujud(p, rakat: r),
            jalsa(p, rakat: r),
            secondSujud(p, rakat: r)
        ]
    }

    /// Rak'at with Fatiha ONLY — Hanafi: no additional surah in 3rd/4th rak'at
    private static func rakatFatihaOnly(_ p: String, rakat r: Int) -> [PrayerStep] {
        [
            fatihaOnlyHanafi(p, rakat: r),
            ruku(p, rakat: r),
            qawmah(p, rakat: r),
            firstSujud(p, rakat: r),
            jalsa(p, rakat: r),
            secondSujud(p, rakat: r)
        ]
    }

    /// Qa'dah Ula (first sitting, after 2nd rak'at in 3+ rak'at prayers): Tahiyyat only
    private static func qaadahUla(_ p: String) -> [PrayerStep] {
        [tahiyyat(p, label: "ula")]
    }

    /// Qa'dah Akhirah (final sitting): Tahiyyat + Salli + Barik + Rabbena + Rabbenaghfirli + Salam
    private static func qaadahAkhirah(_ p: String) -> [PrayerStep] {
        [
            tahiyyat(p, label: "akhirah"),
            salli(p),
            barik(p),
            rabbenaAtina(p),
            rabbenaghfirli(p),
            salamRight(p),
            salamLeft(p)
        ]
    }

    // MARK: - Prayer Step Arrays (All 5 Fard)

    // Fajr – 2 Rak'at
    private static var fajrSteps: [PrayerStep] {
        let p = "fajr"
        var s = opening(p, rakatCount: 2, prayerName: "Morgengebets (Fajr)")
        s += firstRakatBody(p)
        s += [standUp(p, toRakat: 2)]
        s += rakatWithSurah(p, rakat: 2)
        s += qaadahAkhirah(p)
        return s
    }

    // Dhuhr – 4 Rak'at
    private static var dhuhrSteps: [PrayerStep] {
        let p = "dhuhr"
        var s = opening(p, rakatCount: 4, prayerName: "Mittagsgebets (Dhuhr)")
        s += firstRakatBody(p)
        s += [standUp(p, toRakat: 2)]
        s += rakatWithSurah(p, rakat: 2)
        s += qaadahUla(p)
        s += [standUp(p, toRakat: 3)]
        s += rakatFatihaOnly(p, rakat: 3)
        s += [standUp(p, toRakat: 4)]
        s += rakatFatihaOnly(p, rakat: 4)
        s += qaadahAkhirah(p)
        return s
    }

    // Asr – 4 Rak'at
    private static var asrSteps: [PrayerStep] {
        let p = "asr"
        var s = opening(p, rakatCount: 4, prayerName: "Nachmittagsgebets (Asr)")
        s += firstRakatBody(p)
        s += [standUp(p, toRakat: 2)]
        s += rakatWithSurah(p, rakat: 2)
        s += qaadahUla(p)
        s += [standUp(p, toRakat: 3)]
        s += rakatFatihaOnly(p, rakat: 3)
        s += [standUp(p, toRakat: 4)]
        s += rakatFatihaOnly(p, rakat: 4)
        s += qaadahAkhirah(p)
        return s
    }

    // Maghrib – 3 Rak'at
    private static var maghribSteps: [PrayerStep] {
        let p = "maghrib"
        var s = opening(p, rakatCount: 3, prayerName: "Abendgebets (Maghrib)")
        s += firstRakatBody(p)
        s += [standUp(p, toRakat: 2)]
        s += rakatWithSurah(p, rakat: 2)
        s += qaadahUla(p)
        s += [standUp(p, toRakat: 3)]
        s += rakatFatihaOnly(p, rakat: 3)
        s += qaadahAkhirah(p)
        return s
    }

    // Isha – 4 Rak'at
    private static var ishaSteps: [PrayerStep] {
        let p = "isha"
        var s = opening(p, rakatCount: 4, prayerName: "Nachtgebets (Isha)")
        s += firstRakatBody(p)
        s += [standUp(p, toRakat: 2)]
        s += rakatWithSurah(p, rakat: 2)
        s += qaadahUla(p)
        s += [standUp(p, toRakat: 3)]
        s += rakatFatihaOnly(p, rakat: 3)
        s += [standUp(p, toRakat: 4)]
        s += rakatFatihaOnly(p, rakat: 4)
        s += qaadahAkhirah(p)
        return s
    }
}
