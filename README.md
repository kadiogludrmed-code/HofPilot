# HofPilot · iOS

Maschinen. Termine. Alles im Blick.

Native SwiftUI-App für **iOS 17 und neuer**, ohne externe Swift-Abhängigkeiten.
Dies ist Version 0.1: ein lokaler Prototyp, keine fertige Mehrbenutzer-Plattform.

## In Xcode starten

1. Dieses Repository klonen oder auf GitHub über **Code → Download ZIP** herunterladen und entpacken.
2. Auf einem Mac **HofPilot.xcodeproj** öffnen. Kein neues Projekt anlegen, keine Dateien einzeln kopieren. Xcode 15 oder neuer verwenden; für ein aktuelles iPhone ein Xcode mit Unterstützung für dessen iOS-Version.
3. Oben das Scheme **HofPilot** und einen iPhone-Simulator mit iOS 17 oder neuer wählen.
4. **⌘R** startet die App. Im Simulator ist kein Entwicklerteam erforderlich.
5. Mit **⌘U** die Unit-Tests ausführen.

Alternativ im Terminal:

```bash
git clone https://github.com/kadiogludrmed-code/HofPilot.git
cd HofPilot
open HofPilot.xcodeproj
```

Falls sich der Code noch auf einem Entwicklungsbranch befindet, diesen Branch vor dem Öffnen auschecken. Auf GitHub beim ZIP-Download zuerst den richtigen Branch auswählen.

## Auf dem eigenen iPhone ausprobieren

1. In **Xcode → Settings → Accounts** deinen Apple-Account hinzufügen.
2. iPhone mit dem Mac verbinden, dem Computer vertrauen und gegebenenfalls den Entwicklermodus auf dem iPhone aktivieren.
3. In Xcode das Projekt wählen, dann **TARGETS → HofPilot → Signing & Capabilities**.
4. **Automatically manage signing** aktivieren und unter **Team** dein eigenes Team wählen.
5. Die Bundle Identifier bei Bedarf auf eine eigene eindeutige Kennung ändern, z. B. `de.deinname.hofpilot`. Für das Testtarget eine Kennung mit `.tests` verwenden.
6. Das iPhone als Ausführungsziel wählen und **⌘R** drücken. Falls iOS es verlangt, das Entwicklerprofil in den Geräteeinstellungen bestätigen.

Für persönliche Gerätetests kann ein kostenloses Personal Team mit Einschränkungen genügen. TestFlight und App-Store-Verteilung benötigen das Apple Developer Program. Zugangsdaten und Zertifikate gehören nicht in dieses öffentliche Repository.

## Bereits implementiert

- Hofübersicht und bearbeitbarer Hofname.
- Bis zu 20 Geräte: Anlegen, Bearbeiten, Suche, Kategorie, Marke, Modell, Standort, Seriennummer/Kennzeichen, Notizen und Einsatzstatus.
- Gerätefoto über die iOS-Fotoauswahl, auf maximal 1200 Pixel verkleinert.
- Lokale JSON-Speicherung im Application-Support-Verzeichnis; atomare Schreibvorgänge. Ladefehler sperren Schreibvorgänge, damit beschädigte Daten nicht überschrieben werden.
- Aufgaben und Termine pro Gerät, Fälligkeit, Erledigen/Wiederöffnen und Verlauf.
- QR-Code je Geräte-ID, Bild teilen, Etikett mit Namen über AirPrint drucken.
- QR-Scanner auf unterstützten Geräten, alternativ manuelle Geräte-ID für Simulator und ältere Geräte.
- Einmalige Kalenderübernahme über Apples EventKitUI-Dialog; Erinnerung dort anpassbar. Auch in iOS eingerichtete beschreibbare Google-Kalender können gewählt werden.
- Warnung vor erneutem Kalenderexport; keine Kalender-Leseberechtigung erforderlich.
- Helle/dunkle Systemdarstellung und native iOS-Bedienelemente.

## Bewusst noch nicht implementiert

- Apple-/Google-/E-Mail-Anmeldung, Einladungen, Rollen und gemeinsamer Serverdienst.
- Web-App und geräteübergreifende Synchronisierung. Ein QR-Code überträgt keine Geräteakte; das Zielgerät muss die Akte bereits lokal besitzen.
- KI-Erkennung, Dokumentenablage und direkte Aufnahme von Maschinenfotos per Kamera (Fotoauswahl ist vorhanden).
- Automatische Push-/lokale Benachrichtigungen; Kalendererinnerungen sind über den Export möglich.
- Direkte Google-OAuth-Kalenderverbindung, ICS-Export und automatische Kalender-Synchronisierung.
- Zahlungsabwicklung, Löschen/Archivieren von Geräten, Betriebsstunden und Datenexport/Backup-Oberfläche.
- Finales App-Icon und eigens implementierte Liquid-Glass-Effekte. Die App verwendet Standardkomponenten, die sich an das jeweilige iOS anpassen.

**Prototypdaten:** Nicht als einzige Ablage wichtiger Prüf- oder Wartungsnachweise verwenden. Deinstallation entfernt die lokalen Daten. Die JSON-Lösung ist für den ersten Test gedacht und muss vor großen Beständen/Mehrbenutzerbetrieb durch eine robuste Daten- und Dateiverwaltung ersetzt werden.

## Erster Testlauf

1. Im Tab Hof ein Gerät anlegen, Foto wählen und speichern.
2. App beenden und neu öffnen: Gerät und Foto müssen erhalten bleiben.
3. Gerät bearbeiten, Status ändern, Termin eintragen und im Tab Aufgaben öffnen.
4. Termin in Kalender übernehmen; erneut versuchen und die Duplikatwarnung prüfen. Auf einem Simulator ohne eingerichteten Kalender am realen iPhone testen.
5. QR-Etikett öffnen. Im Simulator UUID kopieren und unter Scannen einfügen. Auf dem iPhone den ausgedruckten Code scannen.
6. Aufgabe erledigen: Sie verschwindet aus der offenen Liste, bleibt unter „Erledigte anzeigen“ und im Geräteverlauf sichtbar.
7. 20 Geräte anlegen: Das 21. wird abgelehnt; Bearbeiten bestehender Geräte bleibt möglich.
8. Dunkelmodus und große Systemschrift prüfen; Kamera ablehnen und den manuellen Weg testen.

## Technische Struktur

- `Models.swift`: stabile Geräte-IDs, Aufgaben, versioniertes Datenformat und Link-Parser.
- `FarmStore.swift`: zentraler lokaler Zustand und Speicherung; später durch gemeinsame API und lokalen Cache erweiterbar.
- `RootView.swift`, `MachineViews.swift`, `TaskViews.swift`: vier Tabs und Bearbeitungsansichten.
- `QRViews.swift`: Code-Erzeugung, AirPrint und VisionKit-Scanner.
- `CalendarEditor.swift`: systemeigener Dialog für einmalige Kalenderübernahme.
- `HofPilotTests`: Persistenz, Datenverlustschutz, Geräte-Limit und Linkvalidierung.
- `.github/workflows/ios.yml`: Build und Unit-Tests auf einem macOS-Runner.

## Verifikation

Das Projekt wurde in einer Linux-Umgebung erstellt, in der Xcode und iOS-Simulator nicht verfügbar sind. Ein erfolgreicher iOS-Build darf erst nach bestandenem GitHub-Actions-Lauf oder lokalem Xcode-Build angenommen werden. Kamera, Kalender und AirPrint müssen zusätzlich auf einem echten Gerät geprüft werden.

## Nächste Entwicklungsschritte

1. Simulator- und iPhone-Test abschließen, Fehler und Bedienungsfeedback sammeln.
2. Datenbank und API mit Hofzuordnung und serverseitigen Rechten entwickeln; erst dann Anmeldung und Teamfreigaben aktivieren.
3. Web-App mit derselben API anbinden; lokale Daten kontrolliert migrieren.
4. KI-Erfassung und Dokumente ergänzen, anschließend Benachrichtigungen und Kalenderverbindungen.

## Apple-Referenzen

- [EventKit und EventKitUI](https://developer.apple.com/documentation/eventkit/accessing-calendar-using-eventkit-and-eventkitui)
- [DataScannerViewController](https://developer.apple.com/documentation/visionkit/datascannerviewcontroller)
- [Tests und Verteilung](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
