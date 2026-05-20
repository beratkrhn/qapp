//
//  DailyVerseWidget.swift
//  AkhWidget
//
//  Shows one Qur'an verse per day, rotating deterministically by the
//  day-of-year. Always displays the Arabic original plus a translation
//  in the user's currently selected app language (DE / EN / TR).
//
//  Translations are bundled directly in the widget to keep the extension
//  self-contained — no resource lookups, no network calls.
//

import WidgetKit
import SwiftUI

// MARK: - Verse model + curated rotation

struct DailyVerse {
    let surahName: String       // e.g. "Al-Fātiḥa"
    let surah: Int
    let ayah: Int
    let arabic: String
    let de: String
    let en: String
    let tr: String

    var reference: String { "\(surahName) · \(surah):\(ayah)" }
}

enum DailyVerseCatalog {

    /// Curated, short, encouraging verses. Rotates by day-of-year so the
    /// verse stays the same for a full calendar day across all widget refreshes.
    static let verses: [DailyVerse] = [
        DailyVerse(
            surahName: "Al-Fātiḥa", surah: 1, ayah: 5,
            arabic: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
            de: "Dir allein dienen wir, und Dich allein bitten wir um Hilfe.",
            en: "It is You we worship, and You we ask for help.",
            tr: "Yalnız Sana ibadet eder ve yalnız Senden yardım dileriz."
        ),
        DailyVerse(
            surahName: "Al-Baqara", surah: 2, ayah: 152,
            arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ",
            de: "Gedenkt Meiner, so gedenke Ich euer; und dankt Mir und seid nicht undankbar.",
            en: "So remember Me; I will remember you. Be grateful to Me, and do not be ungrateful.",
            tr: "Öyleyse Beni anın ki Ben de sizi anayım; Bana şükredin, nankörlük etmeyin."
        ),
        DailyVerse(
            surahName: "Al-Baqara", surah: 2, ayah: 153,
            arabic: "يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ",
            de: "O die ihr glaubt, sucht Hilfe in der Geduld und im Gebet! Wahrlich, Allah ist mit den Standhaften.",
            en: "O you who believe, seek help through patience and prayer. Indeed, Allah is with the patient.",
            tr: "Ey iman edenler! Sabır ve namazla Allah'tan yardım dileyin. Şüphesiz Allah sabredenlerle beraberdir."
        ),
        DailyVerse(
            surahName: "Al-Baqara", surah: 2, ayah: 186,
            arabic: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ",
            de: "Und wenn dich Meine Diener nach Mir fragen — wahrlich, Ich bin nahe.",
            en: "And when My servants ask you about Me — indeed I am near.",
            tr: "Kullarım sana Beni sorduklarında, gerçekten Ben çok yakınım."
        ),
        DailyVerse(
            surahName: "Al-Baqara", surah: 2, ayah: 286,
            arabic: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
            de: "Allah erlegt keiner Seele mehr auf, als sie zu leisten vermag.",
            en: "Allah does not burden a soul beyond what it can bear.",
            tr: "Allah, hiçbir kimseye gücünün yeteceğinden başkasını yüklemez."
        ),
        DailyVerse(
            surahName: "Āl-ʿImrān", surah: 3, ayah: 8,
            arabic: "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا",
            de: "Unser Herr, lass unsere Herzen nicht abschweifen, nachdem Du uns rechtgeleitet hast.",
            en: "Our Lord, let not our hearts deviate after You have guided us.",
            tr: "Rabbimiz! Bizi hidayete erdirdikten sonra kalplerimizi eğriltme."
        ),
        DailyVerse(
            surahName: "Āl-ʿImrān", surah: 3, ayah: 173,
            arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ",
            de: "Uns genügt Allah, und welch ein vortrefflicher Sachwalter ist Er!",
            en: "Sufficient for us is Allah, and He is the best Disposer of affairs.",
            tr: "Allah bize yeter; O ne güzel vekildir."
        ),
        DailyVerse(
            surahName: "Āl-ʿImrān", surah: 3, ayah: 200,
            arabic: "يَا أَيُّهَا الَّذِينَ آمَنُوا اصْبِرُوا وَصَابِرُوا وَرَابِطُوا وَاتَّقُوا اللَّهَ",
            de: "O die ihr glaubt, seid standhaft, übt euch in Standhaftigkeit, haltet zusammen und fürchtet Allah.",
            en: "O you who believe, be patient, persevere, hold firm, and fear Allah.",
            tr: "Ey iman edenler! Sabredin, sabır yarışında öne geçin, hazırlıklı olun ve Allah'tan korkun."
        ),
        DailyVerse(
            surahName: "An-Nisāʾ", surah: 4, ayah: 103,
            arabic: "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا",
            de: "Wahrlich, das Gebet ist den Gläubigen zu bestimmten Zeiten vorgeschrieben.",
            en: "Indeed, prayer has been decreed upon the believers at specified times.",
            tr: "Şüphesiz namaz, müminlere belirli vakitlerde farz kılınmıştır."
        ),
        DailyVerse(
            surahName: "Al-Anʿām", surah: 6, ayah: 162,
            arabic: "قُلْ إِنَّ صَلَاتِي وَنُسُكِي وَمَحْيَايَ وَمَمَاتِي لِلَّهِ رَبِّ الْعَالَمِينَ",
            de: "Sprich: Wahrlich, mein Gebet und mein Opfer, mein Leben und mein Sterben gehören Allah, dem Herrn der Welten.",
            en: "Say: Indeed, my prayer, my rites of sacrifice, my living and my dying are for Allah, Lord of the worlds.",
            tr: "De ki: Şüphesiz benim namazım, ibadetlerim, hayatım ve ölümüm âlemlerin Rabbi olan Allah içindir."
        ),
        DailyVerse(
            surahName: "Al-Aʿrāf", surah: 7, ayah: 56,
            arabic: "إِنَّ رَحْمَتَ اللَّهِ قَرِيبٌ مِّنَ الْمُحْسِنِينَ",
            de: "Wahrlich, die Barmherzigkeit Allahs ist denen nahe, die Gutes tun.",
            en: "Indeed, the mercy of Allah is near to those who do good.",
            tr: "Şüphesiz Allah'ın rahmeti, iyilik edenlere yakındır."
        ),
        DailyVerse(
            surahName: "Yūnus", surah: 10, ayah: 62,
            arabic: "أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ",
            de: "Wahrlich, über die Schützlinge Allahs soll keine Furcht kommen, noch sollen sie traurig sein.",
            en: "Truly, the friends of Allah will have no fear, nor will they grieve.",
            tr: "Bilesiniz ki, Allah'ın dostlarına korku yoktur; onlar üzülmeyeceklerdir de."
        ),
        DailyVerse(
            surahName: "Ar-Raʿd", surah: 13, ayah: 28,
            arabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
            de: "Wahrlich, im Gedenken Allahs finden die Herzen Ruhe.",
            en: "Verily, in the remembrance of Allah do hearts find rest.",
            tr: "Bilesiniz ki, kalpler ancak Allah'ı anmakla huzur bulur."
        ),
        DailyVerse(
            surahName: "Ibrāhīm", surah: 14, ayah: 7,
            arabic: "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
            de: "Wenn ihr dankbar seid, werde Ich euch wahrlich mehr geben.",
            en: "If you are grateful, I will surely increase you (in favor).",
            tr: "Andolsun, eğer şükrederseniz, elbette size (nimetimi) artırırım."
        ),
        DailyVerse(
            surahName: "An-Naḥl", surah: 16, ayah: 97,
            arabic: "مَنْ عَمِلَ صَالِحًا مِّن ذَكَرٍ أَوْ أُنثَىٰ وَهُوَ مُؤْمِنٌ فَلَنُحْيِيَنَّهُ حَيَاةً طَيِّبَةً",
            de: "Wer Gutes tut, sei es Mann oder Frau, und gläubig ist, dem werden Wir gewiss ein gutes Leben gewähren.",
            en: "Whoever does good — whether male or female — while being a believer, We will surely grant them a good life.",
            tr: "Erkek olsun, kadın olsun, kim mümin olarak iyi iş yaparsa, onu mutlaka güzel bir hayatla yaşatırız."
        ),
        DailyVerse(
            surahName: "Al-Isrāʾ", surah: 17, ayah: 80,
            arabic: "رَّبِّ أَدْخِلْنِي مُدْخَلَ صِدْقٍ وَأَخْرِجْنِي مُخْرَجَ صِدْقٍ",
            de: "Mein Herr, lass mich auf wahrhaftige Weise eingehen und auf wahrhaftige Weise ausziehen.",
            en: "My Lord, cause me to enter a sound entrance and exit a sound exit.",
            tr: "Rabbim! Beni doğruluk yerinde içeri al ve doğruluk yerinde dışarı çıkar."
        ),
        DailyVerse(
            surahName: "Al-Kahf", surah: 18, ayah: 10,
            arabic: "رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا",
            de: "Unser Herr, schenke uns von Dir Barmherzigkeit und bereite uns Rechtleitung in unserer Sache.",
            en: "Our Lord, grant us mercy from Yourself, and guide us rightly in our affair.",
            tr: "Ey Rabbimiz! Bize katından bir rahmet ver ve içinde bulunduğumuz durumdan bizim için bir kurtuluş yolu hazırla."
        ),
        DailyVerse(
            surahName: "Maryam", surah: 19, ayah: 96,
            arabic: "إِنَّ الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ سَيَجْعَلُ لَهُمُ الرَّحْمَٰنُ وُدًّا",
            de: "Wahrlich, denen, die glauben und gute Werke tun, wird der Allerbarmer Liebe gewähren.",
            en: "Indeed, those who believe and do righteous deeds — the Most Merciful will grant them love.",
            tr: "İman edip salih ameller işleyenler için Rahman bir sevgi yaratacaktır."
        ),
        DailyVerse(
            surahName: "Ṭā-Hā", surah: 20, ayah: 14,
            arabic: "إِنَّنِي أَنَا اللَّهُ لَا إِلَٰهَ إِلَّا أَنَا فَاعْبُدْنِي وَأَقِمِ الصَّلَاةَ لِذِكْرِي",
            de: "Wahrlich, Ich bin Allah. Es gibt keinen Gott außer Mir. So diene Mir und verrichte das Gebet zu Meinem Gedenken.",
            en: "Indeed, I am Allah. There is no deity except Me, so worship Me and establish prayer for My remembrance.",
            tr: "Şüphesiz Ben Allah'ım. Benden başka hiçbir ilâh yoktur. O hâlde Bana kulluk et ve Beni anmak için namaz kıl."
        ),
        DailyVerse(
            surahName: "Al-Anbiyāʾ", surah: 21, ayah: 87,
            arabic: "لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ",
            de: "Es gibt keinen Gott außer Dir. Preis sei Dir! Ich gehörte ja zu den Ungerechten.",
            en: "There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.",
            tr: "Senden başka hiçbir ilâh yoktur, Seni eksikliklerden uzak tutarım. Ben gerçekten zalimlerden olmuşum."
        ),
        DailyVerse(
            surahName: "Al-Muʾminūn", surah: 23, ayah: 1,
            arabic: "قَدْ أَفْلَحَ الْمُؤْمِنُونَ",
            de: "Wahrlich, erfolgreich sind die Gläubigen.",
            en: "Truly successful are the believers.",
            tr: "Şüphesiz müminler kurtuluşa ermiştir."
        ),
        DailyVerse(
            surahName: "Al-Furqān", surah: 25, ayah: 74,
            arabic: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ",
            de: "Unser Herr, schenke uns an unseren Gattinnen und Nachkommen Augentrost.",
            en: "Our Lord, grant us from our spouses and offspring comfort to our eyes.",
            tr: "Rabbimiz! Bize eşlerimizden ve neslimizden göz aydınlığı bağışla."
        ),
        DailyVerse(
            surahName: "An-Naml", surah: 27, ayah: 62,
            arabic: "أَمَّن يُجِيبُ الْمُضْطَرَّ إِذَا دَعَاهُ وَيَكْشِفُ السُّوءَ",
            de: "Oder wer erhört den Notleidenden, wenn er Ihn anruft, und nimmt das Übel hinweg?",
            en: "Is He (not best) who responds to the desperate one when he calls upon Him and removes evil?",
            tr: "Yahut kendisine dua ettiği zaman zorda kalmışa cevap veren ve kötülüğü gideren mi?"
        ),
        DailyVerse(
            surahName: "Al-ʿAnkabūt", surah: 29, ayah: 69,
            arabic: "وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا",
            de: "Diejenigen, die sich Unsertwegen abmühen, werden Wir wahrlich auf Unseren Wegen rechtleiten.",
            en: "Those who strive for Us — We will surely guide them to Our ways.",
            tr: "Bizim uğrumuzda cihad edenleri, elbette kendi yollarımıza eriştireceğiz."
        ),
        DailyVerse(
            surahName: "Az-Zumar", surah: 39, ayah: 53,
            arabic: "لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا",
            de: "Verzweifelt nicht an der Barmherzigkeit Allahs. Wahrlich, Allah vergibt alle Sünden.",
            en: "Do not despair of the mercy of Allah. Indeed, Allah forgives all sins.",
            tr: "Allah'ın rahmetinden ümit kesmeyin. Şüphesiz Allah bütün günahları bağışlar."
        ),
        DailyVerse(
            surahName: "Ghāfir", surah: 40, ayah: 60,
            arabic: "ادْعُونِي أَسْتَجِبْ لَكُمْ",
            de: "Ruft Mich an, so erhöre Ich euch.",
            en: "Call upon Me; I will respond to you.",
            tr: "Bana dua edin, size icabet edeyim."
        ),
        DailyVerse(
            surahName: "Aš-Šūrā", surah: 42, ayah: 19,
            arabic: "اللَّهُ لَطِيفٌ بِعِبَادِهِ يَرْزُقُ مَن يَشَاءُ",
            de: "Allah ist gütig zu Seinen Dienern; Er versorgt, wen Er will.",
            en: "Allah is gentle with His servants; He provides for whom He wills.",
            tr: "Allah, kullarına çok lütufkârdır; dilediğini rızıklandırır."
        ),
        DailyVerse(
            surahName: "Aḍ-Ḍuḥā", surah: 93, ayah: 5,
            arabic: "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ",
            de: "Und wahrlich, dein Herr wird dir geben, und du wirst zufrieden sein.",
            en: "And your Lord is going to give you, and you will be satisfied.",
            tr: "Şüphesiz Rabbin sana verecek ve sen razı olacaksın."
        ),
        DailyVerse(
            surahName: "Aš-Šarḥ", surah: 94, ayah: 6,
            arabic: "إِنَّ مَعَ الْعُسْرِ يُسْرًا",
            de: "Wahrlich, mit der Mühe kommt Erleichterung.",
            en: "Indeed, with hardship comes ease.",
            tr: "Şüphesiz, güçlükle beraber bir kolaylık vardır."
        ),
        DailyVerse(
            surahName: "Al-ʿAṣr", surah: 103, ayah: 3,
            arabic: "إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ",
            de: "Außer denen, die glauben und gute Werke tun und einander zur Wahrheit und zur Geduld anhalten.",
            en: "Except for those who believe, do righteous deeds, and advise each other to truth and to patience.",
            tr: "Ancak iman edip salih ameller işleyen, birbirlerine hakkı ve sabrı tavsiye edenler bunun dışındadır."
        ),
    ]

    /// Picks today's verse deterministically by day-of-year so it stays the
    /// same for the whole calendar day regardless of widget refresh count.
    static func verse(for date: Date) -> DailyVerse {
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % verses.count
        return verses[index]
    }
}

// MARK: - Translation per app language

private extension DailyVerse {
    /// Selects the translation to display based on the user's app language.
    /// English → en; Turkish → tr; everything else (de, de_ar, de_tr) → de.
    func translation(forLanguageRaw raw: String) -> String {
        switch raw {
        case "en":           return en
        case "tr":           return tr
        default:             return de
        }
    }
}

// MARK: - Timeline Entry

struct DailyVerseEntry: TimelineEntry {
    let date: Date
    let verse: DailyVerse
    let languageRaw: String
    let accentThemeRaw: String

    var accentColor: Color { WidgetTheme.accentColor(rawValue: accentThemeRaw) }
    var translation: String { verse.translation(forLanguageRaw: languageRaw) }

    static func makePlaceholder() -> DailyVerseEntry {
        DailyVerseEntry(
            date: Date(),
            verse: DailyVerseCatalog.verses[0],
            languageRaw: "de",
            accentThemeRaw: "emerald_green"
        )
    }
}

// MARK: - Timeline Provider

struct DailyVerseProvider: TimelineProvider {

    func placeholder(in context: Context) -> DailyVerseEntry { .makePlaceholder() }

    func getSnapshot(in context: Context, completion: @escaping (DailyVerseEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyVerseEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(for: now)

        // Refresh once at the next local midnight so the verse rolls over.
        let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86_400)

        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry(for date: Date) -> DailyVerseEntry {
        DailyVerseEntry(
            date: date,
            verse: DailyVerseCatalog.verse(for: date),
            languageRaw: WidgetDataSource.loadLanguageRaw(),
            accentThemeRaw: WidgetDataSource.loadAccentRaw()
        )
    }
}

// MARK: - Lock-screen Rectangular

private struct DailyVerseRectangularView: View {
    let entry: DailyVerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            // Top row: reference (e.g. "Al-Fātiḥa · 1:5")
            HStack(spacing: 4) {
                Image(systemName: "book.fill")
                    .font(.system(size: 9, weight: .bold))
                    .widgetAccentable()
                Text(entry.verse.reference)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // Arabic — right-aligned, single line, scales to fit.
            Text(entry.verse.arabic)
                .font(.system(size: 13, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            // Translation — two lines max, scales down.
            Text(entry.translation)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Lock-screen Inline

private struct DailyVerseInlineView: View {
    let entry: DailyVerseEntry

    var body: some View {
        // Inline can only render a single short line of text.
        Text("\(entry.verse.reference) · \(entry.translation)")
    }
}

// MARK: - Entry View Router

struct DailyVerseEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DailyVerseEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryInline: DailyVerseInlineView(entry: entry)
            default:               DailyVerseRectangularView(entry: entry)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Widget Definition

struct DailyVerseWidget: Widget {
    let kind: String = "DailyVerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyVerseProvider()) { entry in
            DailyVerseEntryView(entry: entry)
        }
        .configurationDisplayName("Vers des Tages")
        .description("Ein Qur'an-Vers pro Tag – Arabisch und in deiner Sprache.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Previews

#Preview("Vers · Rect", as: .accessoryRectangular) {
    DailyVerseWidget()
} timeline: {
    DailyVerseEntry.makePlaceholder()
}

#Preview("Vers · Inline", as: .accessoryInline) {
    DailyVerseWidget()
} timeline: {
    DailyVerseEntry.makePlaceholder()
}
