REM Sophos Gold Image Prep script
REM Knowledge base article 000035040
REM Version 1.2
REM Revised: March 2021
REM Replace the following keywords below before running:
REM GOLD_IMAGE_HOSTNAME, TP_PASSWORD, REGISTRATION_TOKEN

@echo off
echo Checking if the system is the gold image
IF /i "%COMPUTERNAME%" == "GOLD_IMAGE_HOSTNAME" GOTO RESET
echo System is not the gold image, exiting
EXIT

:RESET
echo System is the gold image, proceeding with Gold Image prep

echo Turning Tamper Protection off and waiting 10 seconds
"C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -TPoff  | rem
TIMEOUT 10

echo Turning MCS Client off and waiting 5 seconds, then setting the service to delayed-start
SC STOP "Sophos MCS Client"  | rem
TIMEOUT 5
SC CONFIG "Sophos MCS Client" start= delayed-auto | rem

echo Turning off the MTR service (May not be present)
SC STOP "Sophos Managed Threat Response" | rem
TIMEOUT 5

echo Deleting existing credentials
Del "%ProgramData%\Sophos\Management Communications System\Endpoint\Persist\Credentials" /q
echo Deleting existing identity
Del "%ProgramData%\Sophos\Management Communications System\Endpoint\Persist\EndpointIdentity.txt" /q
echo Deleting Persistent xml files
Del "%ProgramData%\Sophos\Management Communications System\Endpoint\Persist\*.xml" /q
echo Delete MCS status
Del "%ProgramData%\Sophos\Management Communications System\Endpoint\Cache\*.status" /q
echo Delete autoupdate machine_id
Del "%ProgramData%\Sophos\AutoUpdate\data\machine_ID.txt" /q
echo Delete Endpoint Health Status
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Sophos\AutoUpdate\UpdateStatus\Details" /v EventStateLastTime /f
echo Delete MTR files (If present)
if exist "%ProgramData%\Sophos\Managed Threat Response\config\policy.xml" Del "%ProgramData%\Sophos\Managed Threat Response\data\osquery.db\*" /q
if exist "%ProgramData%\Sophos\Managed Threat Response\config\policy.xml" Del "%ProgramData%\Sophos\Managed Threat Response\config\policy.xml" /q

echo Remove registration file (If present)
if exist "%ProgramData%\Sophos\Management Communications System\Endpoint\Config\registration.txt" Del "%ProgramData%\Sophos\Management Communications System\Endpoint\Config\registration.txt"

echo Write registration.txt file
Echo [McsClient] > "%ProgramData%\Sophos\Management Communications System\Endpoint\Config\registration.txt"
Echo Token= REGISTRATION_TOKEN >> "%ProgramData%\Sophos\Management Communications System\Endpoint\Config\registration.txt"

echo Enable Tamper Protection
"C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -TPon  | rem