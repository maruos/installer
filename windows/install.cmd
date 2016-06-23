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
SET /A ERROR_INSTALLER=1
SET /A ERROR_RECOVERY=2
SET /A ERROR_UNLOCK=4
SET me=%~n0
SET parent_dir=%~dp0

ECHO.
ECHO Welcome to the Maru installer!
ECHO.
ECHO In order to install Maru you will need to:
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
ECHO WARNING: Installing Maru will wipe all your personal data
ECHO so make sure you first back-up anything important!
ECHO.

SET /P confirm="Are you ready to install Maru? (yes/no): "
ECHO.
IF NOT "%confirm%"=="yes" (
    ECHO Aborting installation.
    CALL :mexit 0
)

ECHO Excellent, let's get Maru up and running on your device.
ECHO.

PUSHD %parent_dir%

ECHO Checking for a complete installation zip...
CALL :check_zip
IF /I "%ERRORLEVEL%" NEQ "0" (
    ECHO.
    ECHO Hmm, looks like your installer is missing a few things.
    ECHO.
    ECHO Are you running this install script outside the directory
    ECHO you unzipped Maru in?
    ECHO.
    ECHO If that isn't it, please try downloading the installer again.
    ECHO.
    CALL :mexit %ERROR_INSTALLER%
)

ECHO Checking whether your device is in recovery mode...
CALL :check_recovery
IF /I "%ERRORLEVEL%" EQU "0" (
    GOTO :bootloader
)

:recovery_adb
ECHO Rebooting your device into recovery mode...
adb reboot bootloader > NUL 2>&1
IF /I "%ERRORLEVEL%" NEQ "0" (
    CALL :echo_device_not_found
    CALL :mexit %ERROR_RECOVERY%
)
PING.EXE -n 7 127.0.0.1 > NUL

ECHO Checking whether your device is in recovery mode...
CALL :check_recovery
IF /I "%ERRORLEVEL%" NEQ "0" (
    CALL :echo_device_not_found
    CALL :mexit %ERROR_RECOVERY%
)

:bootloader
ECHO Checking bootloader lock state...
CALL :check_unlocked
IF /I "%ERRORLEVEL%" EQU "0" (
    GOTO :flash
)

ECHO Unlocking bootloader, you will need to confirm this on your device...
fastboot oem unlock > NUL 2>&1
CALL :check_unlocked
IF /I "%ERRORLEVEL%" EQU "0" (
    CALL :echo_unlock_reboot
    fastboot reboot > NUL 2>&1
    CALL :mexit 0
) ELSE (
    ECHO Failed to unlock bootloader!
    CALL :fatal
    CALL :mexit %ERROR_UNLOCK%
)

:: ECHO BAIL!
:: PAUSE
:: EXIT /B 0

:flash
ECHO.
ECHO Installing Maru, please keep your device connected...
fastboot format cache
fastboot flash boot boot.img
fastboot flash system system.img
fastboot format userdata

ECHO.
ECHO Installation complete!
ECHO.
ECHO The first boot will take 2-3 mins as Maru sets up
ECHO your device so please be patient.
ECHO.
ECHO Rebooting into Maru...
fastboot reboot > NUL 2>&1
CALL :mexit 0


:: functions

:check_zip
IF NOT EXIST "boot.img" EXIT /B 1
IF NOT EXIST "system.img" EXIT /B 1
EXIT /B 0

:check_recovery
FOR /F "tokens=* USEBACKQ" %%F IN (`fastboot devices`) DO (
    SET recovery_check=fastboot devices
)
IF "%recovery_check%"=="" (EXIT /B 1)
EXIT /B 0

:manual_recovery
ECHO.
ECHO Please reboot your device into recovery mode:
ECHO.
ECHO 1. Power off your device
ECHO 2. Hold down the Volume Up, Volume Down, and Power buttons on your
ECHO    device for a couple of seconds
ECHO.
SET /P ready="Hit ENTER when your device is in recovery mode: "
ECHO.
ECHO Checking whether your device is in recovery mode...
CALL :check_recovery
IF /I "%ERRORLEVEL%" NEQ "0" (
    ECHO Your device isn't in recovery mode, please try again.
    CALL :manual_recovery
)
EXIT /B 0

:check_unlocked
fastboot oem device-info 2>&1 | FINDSTR "unlocked" | FINDSTR "true"
IF /I "%ERRORLEVEL%" NEQ "0" (EXIT /B 1)
EXIT /B 0

:echo_device_not_found
ECHO.
ECHO Hmm, your device can't be found.
ECHO.
ECHO Please ensure that:
ECHO.
ECHO 1. Your device is connected to your computer over USB
ECHO 2. You have USB Debugging enabled, see above for instructions
ECHO 3. You unlock your device and tap "OK" if you see a dialog asking you
ECHO    to allow USB Debugging for your computer's RSA key fingerprint
ECHO 4. You have the Google USB Driver properly installed for your device
ECHO    as described in HELP.txt (this is the main source of problems on Windows!)
ECHO.
ECHO Go ahead and re-run the installer when you're ready.
ECHO.
EXIT /B 0

:echo_unlock_reboot
ECHO.
ECHO Successfully unlocked bootloader!
ECHO.
ECHO Your device will need to reboot before continuing. It will factory
ECHO reset, so this reboot can take a few minutes longer than usual.
ECHO.
ECHO Please re-run this script after your device completely boots up
ECHO and you have re-enabled USB Debugging.
ECHO.
EXIT /B 0

:fatal
ECHO.
ECHO Yikes, something went wrong with the installation. We're sorry.
ECHO.
ECHO Please contact us at hello@maruos.com with the issue you are facing
ECHO and we'll personally walk you through the install process.
ECHO.
EXIT /B 0

:mexit
ECHO.
ECHO Press any key to exit...
PAUSE > NUL
POPD
EXIT %1
