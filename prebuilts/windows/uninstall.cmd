@ECHO OFF
::
:: Copyright 2015-2016 Preetam J. D'Souza
:: Copyright 2016 The Maru OS Project
::
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::    http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.
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
ECHO 1. Connect your device to your computer over USB
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
ECHO WARNING: Uninstalling Maru will wipe all your personal data
ECHO so make sure you first back-up anything important!
ECHO.

SET /P confirm="Are you ready to uninstall Maru? (yes/no): "
ECHO.
IF NOT "%confirm%"=="yes" (
    ECHO Aborting uninstall.
    EXIT /B 0
)

ECHO.
ECHO 1. Please download your device's factory image for the Android version you want:
ECHO.
ECHO    https://developers.google.com/android/images
ECHO.
ECHO 2. Extract the downloaded factory archive. You may need to install a program
ECHO	that can extract compressed tar files, like 7-Zip.
ECHO.
ECHO 3. Copy-paste the full path to the extracted directory below.
ECHO    It should look something like:
ECHO.
ECHO    C:\Users\Einstein\Downloads\hammerhead-lmy48m
ECHO.

SET /P factory_dir="Please enter the full path to the factory image directory (right-click to paste): "
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
