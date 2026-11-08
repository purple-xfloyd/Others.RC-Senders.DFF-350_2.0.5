@echo off
rem ==========================================================================
rem  DDF-350 Firmware-Update - deutsche Fassung
rem  Basiert auf "Upgrade firmware_2026CN.bat" von DumboRC.
rem
rem  Aenderungen gegenueber dem Original:
rem   - laeuft immer im eigenen Ordner, auch bei "Als Administrator ausfuehren"
rem   - prueft vorab, ob die .bin-Dateien vorhanden sind
rem   - Laufwerkssuche per PowerShell statt wmic, das in neuen Windows-11-
rem     Versionen fehlt
rem   - Laufwerk wird angezeigt und muss bestaetigt werden; bei mehreren
rem     Wechseldatentraegern wird gefragt statt einfach der erste genommen
rem   - Warnung, wenn das Laufwerk fuer den Sender verdaechtig gross ist
rem   - funktionierende Pruefung der Versionseingabe, fuehrende Nullen erlaubt
rem   - Hinweis, wenn bereits 2.0.5 oder neuer installiert ist
rem   - Laufwerk wird vor jedem Kopierschritt neu gesucht
rem   - Groessenvergleich nach dem Kopieren und 10 s Wartezeit
rem   - Fenster schliesst sich am Ende nicht mehr von selbst
rem   - nur ASCII-Zeichen, damit nichts als Zeichensalat erscheint
rem   - DDF_BOOT1_Firmware.bin wird wie im Original NICHT benutzt
rem ==========================================================================

cd /d "%~dp0"
setlocal EnableExtensions EnableDelayedExpansion
title DDF-350 Firmware-Update

if not exist "DDF.bin" goto missing_files
if not exist "DDF_BOOT_Firmware.bin" goto missing_files

echo ========================================
echo  DDF-350 Firmware-Update
echo ========================================
echo.
echo Bitte vorher pruefen:
echo  1. Fernsteuerung mit einem Type-C-Kabel direkt an den PC anschliessen,
echo     nicht ueber einen USB-Hub.
echo  2. KEINE Batterien oder Akkus im Sender. Waehrend des Updates darf die
echo     Stromversorgung nicht unterbrochen werden.
echo  3. Aktuelle Firmware-Version des Senders notieren, sie wird gleich
echo     abgefragt.
echo  4. Alle anderen USB-Sticks, SD-Karten und externen Laufwerke abziehen.
echo.
pause
cls

rem ========== Firmware-Version abfragen ==========
:input_version
echo.
echo ========================================
echo  Firmware-Version
echo ========================================
echo.
echo Bitte die aktuelle Firmware-Version des Senders eingeben.
echo Format: x.x.x, zum Beispiel 1.1.4 oder 1.2.0
echo Nicht erlaubt: 119 oder v1.1.5
echo.
set "ver_input="
set /p "ver_input=Version: "
if not defined ver_input goto ver_empty
set "ver_input=!ver_input: =!"
if not defined ver_input goto ver_empty

> "%TEMP%\ddf_ver.txt" echo(!ver_input!
findstr /r /x "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" "%TEMP%\ddf_ver.txt" >nul
set "fmt_err=!errorlevel!"
del "%TEMP%\ddf_ver.txt" >nul 2>&1
if not "!fmt_err!"=="0" goto ver_format

if "!ver_input!"=="1.0.0" goto ver_software

for /f "tokens=1-3 delims=." %%a in ("!ver_input!") do (
    set "v1=%%a"
    set "v2=%%b"
    set "v3=%%c"
)
call :strip_zeros v1
call :strip_zeros v2
call :strip_zeros v3
set /a ver_num=v1*10000+v2*100+v3

if !ver_num! GEQ 20005 goto already_current
:after_current

set "need_boot=0"
if !ver_num! LSS 10105 set "need_boot=1"

echo.
if "!need_boot!"=="1" echo Version !ver_input! ist aelter als 1.1.5: Update in zwei Schritten, erst Bootloader, dann Hauptfirmware.
if "!need_boot!"=="0" echo Version !ver_input! ist 1.1.5 oder neuer: ein Schritt genuegt.
echo.
pause

if "!need_boot!"=="1" goto step_boot
goto step_main


rem ========== Schritt 1/2: Bootloader ==========
:step_boot
cls
echo ========================================
echo  Schritt 1/2: Bootloader aktualisieren
echo ========================================
echo.
call :enter_flash_mode
call :select_drive || goto end
call :clean_svi
call :copy_file "DDF_BOOT_Firmware.bin" || goto end
echo.
echo Warte 10 Sekunden, bis der Sender die Datei verarbeitet hat ...
timeout /t 10 /nobreak >nul
echo.
echo Jetzt:
echo  1. Kabel abziehen und wieder einstecken.
echo  2. Kurz die Power-Taste druecken, das USB-Update startet.
echo  3. Warten, bis 100%% angezeigt wird.
echo  4. Erst dann das Kabel abziehen.
echo.
echo Danach eine beliebige Taste druecken, um mit Schritt 2 weiterzumachen.
pause >nul
cls
echo ========================================
echo  Schritt 2/2: Hauptfirmware aktualisieren
echo ========================================
echo.
echo Kabel wieder einstecken.
call :enter_flash_mode
goto do_main


rem ========== Hauptfirmware ==========
:step_main
cls
echo ========================================
echo  Hauptfirmware aktualisieren
echo ========================================
echo.
call :enter_flash_mode

:do_main
call :select_drive || goto end
call :clean_svi
call :copy_file "DDF.bin" || goto end
echo.
echo Warte 10 Sekunden, bis der Sender die Datei verarbeitet hat ...
timeout /t 10 /nobreak >nul
cls
echo ========================================
echo  Datei ist auf dem Sender
echo ========================================
echo.
echo Das Skript hat nur die Datei kopiert. Das eigentliche Flashen macht
echo der Sender selbst.
echo.
echo Jetzt:
echo  1. Kabel abziehen und den Sender neu einschalten. Laut Original geht
echo     das auch durch langes Druecken der Power-Taste.
echo  2. Wird dabei ein Fortschritt angezeigt: warten, bis 100%% erreicht
echo     sind, und erst dann etwas abziehen.
echo  3. In den Einstellungen pruefen, ob V2.0.5 angezeigt wird.
echo  4. Binding, Failsafe und Modelleinstellungen kontrollieren.
echo.
goto finish


rem ========== Fehlermeldungen Versionseingabe ==========
:ver_empty
echo.
echo Die Eingabe darf nicht leer sein.
goto input_version

:ver_format
echo.
echo Formatfehler: bitte im Format x.x.x eingeben, zum Beispiel 1.1.4
goto input_version

:ver_software
echo.
echo Warnung: 1.0.0 ist die Software-Version, nicht die Firmware-Version!
echo Die Firmware-Version ist normalerweise 1.1.x oder hoeher.
goto input_version

:already_current
echo.
echo Hinweis: Version !ver_input! ist bereits 2.0.5 oder neuer.
choice /c JN /n /m "Trotzdem erneut flashen? [J/N] "
if errorlevel 2 goto end
goto after_current


rem ========== Ende ==========
:missing_files
echo FEHLER: DDF.bin oder DDF_BOOT_Firmware.bin fehlt im Ordner
echo %CD%
echo Die .bat-Datei muss im selben Ordner liegen wie die .bin-Dateien,
echo und die ZIP-Datei muss vorher entpackt sein.
goto end

:finish
echo Taste druecken zum Beenden.
pause >nul
endlocal
exit /b 0

:end
echo.
echo Abgebrochen. Taste druecken zum Beenden.
pause >nul
endlocal
exit /b 1


rem ==========================================================================
rem  Unterprogramme
rem ==========================================================================

rem ---------- Sender in den Flash-Modus bringen ----------
:enter_flash_mode
echo CH3 und CH4 gedrueckt halten und dann kurz die Power-Taste druecken.
echo Ein Ton bestaetigt den Flash-Modus. Danach alle drei Tasten loslassen.
echo.
echo Wenn der Ton zu hoeren war, eine beliebige Taste druecken ...
pause >nul
exit /b 0


rem ---------- Laufwerk des Senders suchen und bestaetigen lassen ----------
:select_drive
set "DRIVE="
set "proposal="
set "labeled="
set "rcount=0"
set "rlist="
echo.
echo Suche Wechseldatentraeger ...
timeout /t 3 /nobreak >nul

for /f "delims=" %%d in ('powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | ForEach-Object { $_.DeviceID }" 2^>nul') do (
    set /a rcount+=1
    set "rlist=!rlist! %%d"
    set "proposal=%%d"
)
if "!rcount!"=="0" goto sd_none

for /f "delims=" %%d in ('powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -and $_.VolumeName -eq 'DUMBORC' } | ForEach-Object { $_.DeviceID }" 2^>nul') do set "labeled=%%d"

echo.
echo Gefundene Wechseldatentraeger:
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | ForEach-Object { '  ' + $_.DeviceID + '   Name: ' + $_.VolumeName + '   Groesse: ' + [math]::Round($_.Size / 1MB) + ' MB' }"
echo.

if defined labeled set "proposal=!labeled!"
if defined labeled goto sd_confirm
if "!rcount!"=="1" goto sd_confirm
goto sd_manual

:sd_confirm
choice /c JN /n /m "Ist !proposal! der Sender? [J/N] "
if errorlevel 2 goto sd_manual
set "DRIVE=!proposal!"
goto sd_check

:sd_manual
set "letter="
set /p "letter=Laufwerksbuchstaben des Senders eingeben, z. B. E - leer lassen zum Abbrechen: "
if not defined letter exit /b 1
set "letter=!letter::=!"
set "letter=!letter: =!"
if not defined letter exit /b 1
if not "!letter:~1!"=="" (
    echo Bitte nur einen Buchstaben eingeben.
    goto sd_manual
)
set "DRIVE=!letter!:"
set "ok=0"
for %%x in (!rlist!) do if /i "%%x"=="!DRIVE!" set "ok=1"
if "!ok!"=="0" (
    echo !DRIVE! ist kein gefundener Wechseldatentraeger.
    goto sd_manual
)

:sd_check
set "dsize=0"
for /f "delims=" %%s in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:DRIVE }).Size / 1MB)" 2^>nul') do set "dsize=%%s"
if !dsize! GTR 64 (
    echo.
    echo ACHTUNG: !DRIVE! ist !dsize! MB gross. Der Sender im Flash-Modus ist
    echo normalerweise ein sehr kleines Laufwerk. Das koennte ein USB-Stick sein.
    choice /c JN /n /m "Trotzdem !DRIVE! verwenden? [J/N] "
    if errorlevel 2 goto sd_manual
)
echo Verwende Laufwerk !DRIVE!
exit /b 0

:sd_none
echo.
echo FEHLER: Kein Wechseldatentraeger gefunden.
echo Ist der Sender im Flash-Modus und das Kabel direkt am PC angeschlossen?
choice /c WA /n /m "W = erneut suchen, A = abbrechen: "
if errorlevel 2 exit /b 1
goto select_drive


rem ---------- Windows-Systemordner vom Sender entfernen ----------
:clean_svi
if exist "!DRIVE!\System Volume Information\" (
    echo Entferne !DRIVE!\System Volume Information ...
    rd /s /q "!DRIVE!\System Volume Information" >nul 2>&1
    if exist "!DRIVE!\System Volume Information\" echo Hinweis: Ordner liess sich nicht entfernen, das Update wird trotzdem versucht.
)
exit /b 0


rem ---------- Datei kopieren und Groesse pruefen ----------
:copy_file
set "src=%~1"
echo.
echo Kopiere !src! nach !DRIVE! ...
copy /b /y "!src!" "!DRIVE!\" >nul
if errorlevel 1 (
    echo FEHLER: Kopieren fehlgeschlagen. Verbindung und Laufwerk pruefen.
    exit /b 1
)
set "ssize="
set "tsize="
for %%F in ("!src!") do set "ssize=%%~zF"
for %%F in ("!DRIVE!\!src!") do set "tsize=%%~zF"
if not "!ssize!"=="!tsize!" (
    echo WARNUNG: Die Datei auf dem Sender hat !tsize! statt !ssize! Bytes.
    echo Sender NICHT normal einschalten. Skript neu starten, Sender wieder in
    echo den Flash-Modus bringen und erneut kopieren.
    exit /b 1
)
echo Kopiert und Groesse geprueft: !ssize! Bytes.
exit /b 0


rem ---------- fuehrende Nullen entfernen, damit set /a nicht oktal rechnet ----------
:strip_zeros
set "sz=!%1!"
:strip_loop
if "!sz:~0,1!"=="0" if not "!sz!"=="0" (
    set "sz=!sz:~1!"
    goto strip_loop
)
set "%1=!sz!"
exit /b 0
