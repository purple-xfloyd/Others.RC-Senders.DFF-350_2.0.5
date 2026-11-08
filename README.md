# DDF-350 Firmware-Update – deutsche Fassung (`Firmware-Update_DE.bat`)

> ## ⚠️ WICHTIGE WARNUNG
>
> **Die Datei `Firmware-Update_DE.bat` wurde mit Claude (KI von Anthropic) erzeugt.** Sie ist eine inoffizielle, übersetzte und überarbeitete Fassung des Original-Skripts `Upgrade firmware_2026CN.bat` von DumboRC und wurde **nicht auf einem Windows-Rechner getestet**.
>
> **Es wird keinerlei Garantie für eine korrekte Funktion gegeben.** Die Nutzung erfolgt **vollständig auf eigene Gefahr**. Für Schäden aller Art, insbesondere für Fehlfunktionen, Datenverlust oder das **Beschädigen oder Unbrauchbarmachen („Bricken“) der DumboRC DDF-350**, wird **keinerlei Haftung übernommen**.
>
> Laut DumboRC muss ein Sender, dessen USB-Update unterbrochen wurde, ins Werk zurück und dort mit einem Programmiergerät neu bespielt werden. Im Zweifel das Original-Skript von DumboRC verwenden oder den Hersteller fragen.

---

## Inhalt des Ordners

| Datei | Zweck |
|---|---|
| `DDF.bin` | Hauptfirmware V2.0.5 |
| `DDF_BOOT_Firmware.bin` | Bootloader-Update, nur nötig bei Firmware älter als 1.1.5 |
| `DDF_BOOT1_Firmware.bin` | Wird von keinem der beiden Skripte benutzt. **Nicht von Hand auf den Sender kopieren.** |
| `Upgrade firmware_2026CN.bat` | Original-Skript von DumboRC (Chinesisch) |
| `Firmware-Update_DE.bat` | Deutsche, überarbeitete Fassung (mit Claude erzeugt, siehe Warnung) |

## Wie das Update funktioniert

Im Flash-Modus meldet sich der Sender am PC als kleines USB-Laufwerk an. Das Skript kopiert nur die passende `.bin`-Datei auf dieses Laufwerk. **Das eigentliche Flashen macht der Sender selbst.** Das Skript baut keine Netzwerkverbindung auf und ändert nichts an Windows. Auf dem Sender-Laufwerk löscht es nur den Windows-Ordner `System Volume Information`.

## Voraussetzungen

- Windows-PC (Windows 10 oder 11). Am Mac oder in einer virtuellen Maschine nicht empfohlen.
- DDF-350 mit **Type-C-Buchse**. Bei Micro-USB ist unklar, ob V2.0.5 passt.
- Type-C-Kabel, **direkt** am PC, nicht über einen USB-Hub.
- **Keine Batterien oder Akkus im Sender.** Er wird nur über USB versorgt.
- Alle anderen USB-Sticks, SD-Karten und externen Laufwerke abziehen.
- Die ZIP-Datei vollständig entpacken. Das Skript muss im selben Ordner liegen wie die `.bin`-Dateien.
- Die aktuelle Firmware-Version vom Sender ablesen und notieren.

## Ablauf

1. **Skript starten:** Doppelklick auf `Firmware-Update_DE.bat`.
2. **Hinweise bestätigen:** Das Skript zeigt die Voraussetzungen an.
3. **Version eingeben:** Im Format `x.x.x`, zum Beispiel `1.1.4` oder `1.2.0`.
   - Abgelehnt werden zum Beispiel `119`, `v1.1.5` und `1.0.0` (das ist die Software-, nicht die Firmware-Version).
   - Bei 2.0.5 oder neuer fragt das Skript, ob trotzdem geflasht werden soll.
4. **Das Skript wählt den Weg:**
   - **Ab 1.1.5:** Ein Schritt, nur die Hauptfirmware.
   - **Unter 1.1.5:** Zwei Schritte, erst der Bootloader, dann die Hauptfirmware.
5. **Flash-Modus:** CH3 und CH4 gedrückt halten, kurz die Power-Taste drücken. Ein Ton bestätigt den Flash-Modus, dann alle drei Tasten loslassen.
6. **Laufwerk bestätigen:** Das Skript listet alle Wechseldatenträger mit Name und Größe.
   - Gibt es ein Laufwerk namens `DUMBORC` oder nur ein einziges, schlägt das Skript es vor. Du bestätigst mit `J`.
   - Sonst gibst du den Laufwerksbuchstaben ein. Leer lassen bricht ab.
   - Ist das Laufwerk größer als 64 MB, warnt das Skript, denn dann ist es vermutlich ein USB-Stick.
7. **Kopieren:** Das Skript kopiert die Datei, vergleicht die Dateigröße und wartet 10 Sekunden.
8. **Nur bei zwei Schritten:** Nach dem Bootloader das Kabel abziehen, wieder einstecken und kurz Power drücken. Das USB-Update läuft, bis 100 % erreicht sind. Erst dann das Kabel abziehen. Danach geht es mit Schritt 5 für die Hauptfirmware weiter.
9. **Abschluss:** Kabel abziehen und den Sender neu einschalten. Wird ein Fortschritt angezeigt, bis 100 % warten und erst dann etwas abziehen.

## Nach dem Update

- In den Einstellungen des Senders prüfen, ob **V2.0.5** angezeigt wird.
- **Binding**, **Failsafe** (Gas auf Neutral) und die **Modelleinstellungen** kontrollieren.
- Vor dem nächsten Einsatz eine Probefahrt machen.
- Die ZIP-Datei aufheben. DumboRC entfernt ältere Versionen von der Website.

## Probelauf ohne Risiko

Das Skript ohne angeschlossenen Sender starten. Du siehst dann alle Texte und die Versionsabfrage. Bei der Laufwerkssuche meldet es „Kein Wechseldatenträger gefunden“. Mit `A` abbrechen, es wurde nichts kopiert.

## Unterschiede zum Original-Skript

| Problem im Original | Lösung in der deutschen Fassung |
|---|---|
| Chinesische Texte erscheinen auf deutschem Windows als Zeichensalat | Deutsche Texte, nur ASCII-Zeichen („ae/oe/ue“ statt Umlauten) |
| Nutzt `wmic`, das in neuen Windows-11-Versionen fehlt | Laufwerkssuche per PowerShell |
| Nimmt ohne Rückfrage den ersten Wechseldatenträger, eventuell einen USB-Stick | Liste aller Laufwerke, Bestätigung oder Auswahl, Warnung ab 64 MB |
| Die Prüfung der Versionseingabe greift praktisch nicht | Funktionierende Prüfung, führende Nullen werden korrekt behandelt |
| Findet die `.bin`-Dateien nicht, wenn es „Als Administrator“ gestartet wird | Wechselt immer in den eigenen Ordner und prüft vorab, ob die Dateien da sind |
| Meldet „abgeschlossen“ direkt nach dem Kopieren | Größenvergleich, 10 s Wartezeit, klarer Hinweis, dass der Sender selbst flasht |
| Laufwerksbuchstabe wird nur einmal gesucht | Neue Suche vor jedem Kopierschritt |
| Fenster schließt sich nach 4 Sekunden | Fenster bleibt offen, bis eine Taste gedrückt wird |

Der eigentliche Ablauf ist unverändert: Dieselben Dateien werden in derselben Reihenfolge auf den Sender kopiert.

## Fehlerbehebung

- **„DDF.bin oder DDF_BOOT_Firmware.bin fehlt“:** Die ZIP-Datei ist nicht entpackt, oder die `.bat` liegt in einem anderen Ordner.
- **„Kein Wechseldatenträger gefunden“:** Sender nicht im Flash-Modus (kein Ton), Kabel nur zum Laden geeignet oder ein USB-Hub dazwischen. Mit `W` erneut suchen.
- **„Kopieren fehlgeschlagen“ oder Größenwarnung:** Den Sender **nicht normal einschalten**. Skript neu starten, Sender wieder in den Flash-Modus bringen und erneut kopieren.
- **Sender reagiert nach dem Update nicht:** DumboRC-Support kontaktieren.

---

*Erstellt mit Claude, November 2026. Keine offizielle Dokumentation von DumboRC.*
