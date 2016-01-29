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
ECHO In order to uninstall Maru you will need to:
ECHO.
ECHO 1. Connect your Nexus 5 to your computer over USB
ECHO. 
ECHO 2. Enable USB Debugging on your device:
ECHO.
ECHO    1.  Go to the Settings app and scroll down to
ECHO        the System section
ECHO.
ECHO        NOTE: If you already have "Developer options"
ECHO        under System then go directly to #5
ECHO.
ECHO    2.  Tap on "About phone"
ECHO    3.  Tap "Build number" 7 times until you get a message
ECHO        that says you are now a developer
ECHO    4.  Go back to the main Settings app
ECHO    5.  Tap on "Developer options"
ECHO    6.  Ensure that "USB debugging" is enabled
ECHO    7.  Tap "OK" if you see a dialog asking you to allow
ECHO        USB Debugging for your computer's RSA key fingerprint
ECHO.
ECHO IMPORTANT: Uninstalling Maru requires a factory reset of your device
ECHO (all your personal data will be wiped) so make sure you first
ECHO back-up any important data!
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
ECHO 2. Extract the downloaded factory archive. You may need to install a program
ECHO	that can extract compressed tar files, like 7-Zip.
ECHO.
ECHO 3. Copy-paste the full path to the extracted directory below.
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
