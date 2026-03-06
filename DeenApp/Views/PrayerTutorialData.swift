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
        case .fajr:    return fajrSteps
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
    private static let takbirTransl = "Allah ist der Größte."

    private static let subhanekeArabic = """
    سُبْحَانَكَ اللّٰهُمَّ وَبِحَمْدِكَ \
    وَتَبَارَكَ اسْمُكَ وَتَعَالَىٰ جَدُّكَ \
    وَلَا إِلٰهَ غَيْرُكَ
    """
    private static let subhanekeTranslit = "Subhanekellahümme ve bihamdik, ve tebarekesmük ve teala ceddük, ve la ilahe gayrük."
    private static let subhanekeTransl = "Gepriesen seist Du, o Allah, und gelobt. Gesegnet ist Dein Name, erhaben ist Deine Majestät, und es gibt keinen Gott außer Dir."

    private static let euzuBesmeleArabic = """
    أَعُوذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيمِ \
    بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ
    """
    private static let euzuBesmeleTranslit = "Euzu billahi mineş-şeytanir-racim. Bismillahir-rahmanir-rahim."
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
    private static let fatihaTranslit = "Elhamdü lillahi rabbil-alemin. Er-rahmanir-rahim. Maliki yevmid-din. İyyake na'büdü ve iyyake neste'in. İhdinas-siratal-müstakim. Siratal-lezine en'amte aleyhim. Gayril-magdubi aleyhim ve led-dallin. (Amin)"
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
    private static let fatihaWithBesmeleTranslit = "Bismillahir-rahmanir-rahim. Elhamdü lillahi rabbil-alemin. Er-rahmanir-rahim. Maliki yevmid-din. İyyake na'büdü ve iyyake neste'in. İhdinas-siratal-müstakim. Siratal-lezine en'amte aleyhim. Gayril-magdubi aleyhim ve led-dallin. (Amin)"
    private static let fatihaWithBesmeleTransl = "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Alles Lob gebührt Allah, dem Herrn der Welten. Dem Allerbarmer, dem Barmherzigen. Dem Herrscher am Tage des Gerichts. Dir allein dienen wir, und Dich allein bitten wir um Hilfe. Führe uns den geraden Weg. Den Weg derer, denen Du Gnade erwiesen hast, nicht derer, die Deinen Zorn erregt haben, und nicht der Irregehenden."

    private static let ikhlasArabic = """
    قُلْ هُوَ اللّٰهُ أَحَدٌ ۝ \
    اَللّٰهُ الصَّمَدُ ۝ \
    لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ \
    وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ
    """
    private static let ikhlasTranslit = "Kul hüvallahü ehad. Allahüs-samed. Lem yelid ve lem yuled. Ve lem yekün lehu küfüven ehad."
    private static let ikhlasTransl = "Sprich: Er ist Allah, der Einzige. Allah, der Ewige. Er zeugt nicht und ist nicht gezeugt worden. Und niemand ist Ihm gleich."

    private static let rukuArabic = "سُبْحَانَ رَبِّيَ الْعَظِيمِ"
    private static let rukuTranslit = "Subhane Rabbiyel-Azim (3×)"
    private static let rukuTransl = "Gepriesen sei mein Herr, der Allmächtige."

    private static let qawmahArabic = """
    سَمِعَ اللّٰهُ لِمَنْ حَمِدَهُ \
    رَبَّنَا لَكَ الْحَمْدُ
    """
    private static let qawmahTranslit = "Semi'Allahu limen hamideh. Rabbena lekel-hamd."
    private static let qawmahTransl = "Allah hört den, der Ihn lobt. Unser Herr, Dir gebührt alles Lob."

    private static let sujudArabic = "سُبْحَانَ رَبِّيَ الْأَعْلَىٰ"
    private static let sujudTranslit = "Subhane Rabbiyel-A'la (3×)"
    private static let sujudTransl = "Gepriesen sei mein Herr, der Allerhöchste."

    private static let tahiyyatArabic = """
    اَلتَّحِيَّاتُ لِلّٰهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ \
    اَلسَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللّٰهِ وَبَرَكَاتُهُ \
    اَلسَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللّٰهِ الصَّالِحِينَ \
    أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ \
    وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ
    """
    private static let tahiyyatTranslit = "Ettehiyyatü lillahi ves-salevatü vet-tayyibat. Es-selamü aleyke eyyühen-nebiyyü ve rahmetullahi ve berekatüh. Es-selamü aleyna ve ala ibadillahis-salihin. Eşhedü en la ilahe illallah ve eşhedü enne Muhammeden abdühü ve resulüh."
    private static let tahiyyatTransl = "Die Grüße, die Gebete und die reinen Worte gebühren Allah. Friede sei auf dir, o Prophet, und die Barmherzigkeit Allahs und Seine Segnungen. Friede sei auf uns und auf den rechtschaffenen Dienern Allahs. Ich bezeuge, dass es keinen Gott gibt außer Allah, und ich bezeuge, dass Muhammad Sein Diener und Gesandter ist."

    private static let salliArabic = """
    اَللّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ \
    كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ \
    إِنَّكَ حَمِيدٌ مَجِيدٌ
    """
    private static let salliTranslit = "Allahümme salli ala Muhammedin ve ala ali Muhammad. Kema salleyte ala İbrahime ve ala ali İbrahim. İnneke hamidün mecid."
    private static let salliTransl = "O Allah, segne Muhammad und die Familie Muhammads, so wie Du Ibrahim und die Familie Ibrahims gesegnet hast. Wahrlich, Du bist der Lobenswürdige, der Ruhmreiche."

    private static let barikArabic = """
    اَللّٰهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ \
    كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ \
    إِنَّكَ حَمِيدٌ مَجِيدٌ
    """
    private static let barikTranslit = "Allahümme barik ala Muhammedin ve ala ali Muhammad. Kema barekte ala İbrahime ve ala ali İbrahim. İnneke hamidün mecid."
    private static let barikTransl = "O Allah, segne Muhammad und die Familie Muhammads mit Segen, so wie Du Ibrahim und die Familie Ibrahims gesegnet hast. Wahrlich, Du bist der Lobenswürdige, der Ruhmreiche."

    private static let rabbenaArabic = """
    رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً \
    وَفِي الْآخِرَةِ حَسَنَةً \
    وَقِنَا عَذَابَ النَّارِ
    """
    private static let rabbenaTranslit = "Rabbena atina fid-dünya haseneten ve fil-ahireti haseneten ve kına azaben-nar."
    private static let rabbenaTransl = "Unser Herr, gib uns im Diesseits Gutes und im Jenseits Gutes und bewahre uns vor der Strafe des Feuers."

    private static let rabbenaghfirliArabic = """
    رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ \
    وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ
    """
    private static let rabbenaghfirliTranslit = "Rabbighfir li ve li-valideyye ve lil-mu'minine yevme yekumul-hisab."
    private static let rabbenaghfirliTransl = "Mein Herr, vergib mir und meinen Eltern und den Gläubigen am Tag, an dem die Abrechnung stattfindet."

    private static let salamArabic = "اَلسَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ"
    private static let salamTranslit = "Es-selamü aleyküm ve rahmetullah."
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
            translation: subhanekeTransl,
            imageNameMale: "pose_male_qiyam_navel",
            imageNameFemale: "pose_female_qiyam_chest"
        )
    }

    private static func euzuBesmele(_ p: String) -> PrayerStep {
        PrayerStep(
            id: "\(p)_euzu_besmele",
            title: "Euzu-Besmele",
            arabicText: euzuBesmeleArabic,
            transliteration: euzuBesmeleTranslit,
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
            translation: qawmahTransl,
            imageNameMale: "pose_male_qawmah",
            imageNameFemale: "pose_female_qawmah"
        )
    }

    private static func firstSujud(_ p: String, rakat r: Int) -> PrayerStep {
        PrayerStep(
            id: "\(p)_r\(r)_sujud_1",
            title: "Erste Sadschda (\(r). Rak'a)",
            arabicText: sujudArabic,
            transliteration: sujudTranslit,
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
            title: "Zweite Sadschda (\(r). Rak'a)",
            arabicText: sujudArabic,
            transliteration: sujudTranslit,
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
