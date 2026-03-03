# DailyDee – App testen

## 1. Doppelten Einstiegspunkt entfernen

Die App hat jetzt **einen** Einstieg: `DailyDeeApp.swift`.  
Damit der Build funktioniert, darf **nur diese Datei** als `@main` genutzt werden.

- Im **Project Navigator** (linke Seite) **DeenApp/DeenAppApp.swift** auswählen.
- Rechts in der **File Inspector** (⌥⌘1) unter **Target Membership** das Häkchen bei **DailyDee** **entfernen**.

(Dadurch wird die Datei nicht mehr kompiliert, der zweite `@main` verschwindet.)

## 2. Alle DeenApp-Dateien im Target

Stelle sicher, dass alle Swift-Dateien aus dem Ordner **DeenApp** zum Target **DailyDee** gehören:

- Im Project Navigator den Ordner **DeenApp** aufklappen.
- Alle `.swift`-Dateien durchgehen; in der File Inspector muss bei **Target Membership** **DailyDee** angehakt sein.

Falls du „Add Files“ genutzt hast und den ganzen Ordner hinzugefügt hast, sollte das schon der Fall sein.

## 3. Info.plist (Standort)

Damit die Gebetszeiten nach Standort geladen werden können:

- Target **DailyDee** auswählen → Tab **Info**.
- Unter **Custom iOS Target Properties** den Eintrag **Privacy - Location When In Use Usage Description** hinzufügen (oder aus der DeenApp-**Info.plist** übernehmen).
- Wert z. B.: `DailyDee nutzt deinen Standort, um die Gebetszeiten für deine Region zu laden.`

Falls eine eigene **Info.plist** im Target eingetragen ist, die **DeenApp/Info.plist** aus dem Projekt nutzen oder deren Keys in die Target-Info kopieren.

## 4. Build & Run

- Oben links einen **Simulator** wählen (z. B. iPhone 16).
- **Run** (⌘R) drücken.

Die App startet mit dem Dashboard. Im Simulator wird der Standort oft nicht genutzt; dann werden die Gebetszeiten für **Berlin** angezeigt (Fallback).

## 5. Auf dem echten Gerät testen

- iPhone per Kabel verbinden.
- Oben das Gerät statt Simulator wählen.
- Beim ersten Start ggf. unter **Einstellungen → Allgemein → VPN & Geräteverwaltung** das Entwickler-Zertifikat vertrauen.
- **Run** (⌘R) – dann werden die Gebetszeiten für deinen aktuellen Standort geladen.
