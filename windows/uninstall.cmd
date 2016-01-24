@ECHO OFF
::
:: Copyright (c) 2015 Maru
::

SETLOCAL ENABLEEXTENSIONS
SET me=%~n0
SET parent_dir=%~dp0

ECHO.
ECHO Welcome to the Maru Uninstaller.
ECHO.
ECHO This script will ease the process of restoring your
ECHO device to factory settings.
ECHO.
ECHO Please ensure your device is connected to your computer.
ECHO.

SET /P confirm="Are you ready to uninstall Maru? (yes/no): "
ECHO.
IF NOT "%confirm%"=="yes" (
    ECHO Aborting uninstall.
    EXIT /B 0
)

ECHO.
ECHO 1. Please download the factory image for the Android version you want:
ECHO.
ECHO    https://developers.google.com/android/nexus/images?hl=en#hammerhead
ECHO.
ECHO 2. Install 7-Zip and unzip the downloaded factory archive: http://www.7-zip.org/
ECHO.
ECHO 3. Copy-paste the full path to the unzipped directory below.
ECHO    It should look something like:
ECHO.
ECHO    C:\Documents and Settings\John\My Documents\Downloads\hammerhead-lmy48m
ECHO.

SET /P factory_dir="Please enter the full path to the factory image directory: "
ECHO.

SET PATH=%PATH%;%parent_dir%

PUSHD %factory_dir%
adb reboot bootloader
PING.EXE -n 7 127.0.0.1 > NUL
flash-all

ECHO Done!
PAUSE
POPD
EXIT /B 0
