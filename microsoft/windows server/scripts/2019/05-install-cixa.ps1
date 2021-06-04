# Second-phase configuration of vanilla Windows Server installation to progress Packer.io builds
# @author Ralph Brynard

cd $env:TEMP

function Write-ProgressHelper {
    param(
        [int]$StepNumber,
        [string]$Message
    )

    Write-Progress -Activity 'Title' -Status $Message -PercentComplete (($StepNumber / $steps) * 100)
}

$script:steps = ([System.Management.Automation.PsParser]::Token((gc "$PSScriptRoot\$(MyInvocation.MyCommand.Name)"), [ref]$null) | Where-Object { $_.Type -eq 'Command' -and $_.Content -eq 'Write-ProgressHelper' }).count

$stepCounter = 0

Write-ProgressHelper -Message 'Downloading Sophos Installer...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 5

#Set TLS Version
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$url="https://dzr-api-amzn-us-west-2-fa88.api-upe.p.hmr.sophos.com/api/download/a24f232171f6e3dd9d913518503c1de4/SophosSetup.exe"
$installer = "SophosSetup.exe"
curl $url -OutFile $installer

Write-ProgressHelper -Message 'Running Sophos Installer...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 5

Start-Process $env:TEMP\"SophosSetup.exe" -ArgumentList "--customertoken=9a02d9a7-02b9-446b-873a-ad752e668a6d --epinstallerserver=dzr-api-amzn-us-west-2-fa88.api-upe.p.hmr.sophos.com --products=all --quiet" -Wait

Write-ProgressHelper -Message 'Preparing Golden Image Script file...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 5

Get-Content A:\SophosGoldImagePrep.bat > C:\SophosGoldImagePrep.bat

Write-ProgressHelper -Message 'Getting endpoint registration token...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 5

$registrationToken = getString -firstString "<registrationToken>" -secondString "</registrationToken>" -importPath "C:\ProgramData\Sophos\Management Communications System\Endpoint\Config\Config.xml"

function findInTextFile {
    [CmdletBinding(DefaultParameterSetName = 'NewFile')]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path -Path $_ -PathType 'Leaf'})]
        [string[]]$FilePath,
        [Parameter(Mandatory = $true)]
        [string]$Find,
        [Parameter()]
        [string]$Replace,
        [Parameter(ParameterSetName = 'NewFile')]
        [ValidateScript({ Test-Path -Path ($_ | Split-Path -Parent) -PathType 'Container' })]
        [string]$NewFilePath,
        [Parameter(ParameterSetName = 'NewFile')]
        [switch]$Force
    )
    begin {
        $Find = [regex]::Escape($Find)
    }
    process {
        try {
            foreach ($File in $FilePath) {
                if ($Replace) {
                    if ($NewFilePath) {
                        if ((Test-Path -Path $NewFilePath -PathType 'Leaf') -and $Force.IsPresent) {
                            Remove-Item -Path $NewFilePath -Force
                            (Get-Content $File) -replace $Find, $Replace | Add-Content -Path $NewFilePath -Force
                        } elseif ((Test-Path -Path $NewFilePath -PathType 'Leaf') -and !$Force.IsPresent) {
                            Write-Warning "The file at '$NewFilePath' already exists and the -Force param was not used"
                        } else {
                            (Get-Content $File) -replace $Find, $Replace | Add-Content -Path $NewFilePath -Force
                        }
                    } else {
                        (Get-Content $File) -replace $Find, $Replace | Add-Content -Path "$File.tmp" -Force
                        Remove-Item -Path $File
                        Move-Item -Path "$File.tmp" -Destination $File
                    }
                } else {
                    Select-String -Path $File -Pattern $Find
                }
            }
        } catch {
            Write-Error $_.Exception.Message
        }
    }
}

Write-ProgressHelper -Message 'Modifying Golden Image Preparation Script...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 5

findInTextFile -FilePath 'C:\SophosGoldImagePrep.bat' -Find 'GOLD_IMAGE_HOSTNAME' -Replace '$(hostname)'
findInTextFile -File 'C:\SophosGoldImagePrep.bat' -find 'REGISTRATION_TOKEN' -Replace $registrationToken

Write-ProgressHelper -Message 'Creating Scheduled Task...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 5

function schTaskGoldImagePrep (){
    $class = cimclass MSFT_TASKEventTrigger root/Microsoft/Windows/TaskScheduler
    $trigger = $class | New-CimInstance -ClientOnly
    $trigger.Enabled = $true
    $trigger.Subscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1074]]</Select></Query></QueryList>'

    $ActionParameters = @{
        Execute = "C:\SophosGoldImagePrep.bat"
    }

    $Action = New-ScheduledTaskAction @ActionParameters
    $Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount
    $Settings = New-ScheduledTaskSettingsSet

    $RegSchTaskParameters = @{
        TaskName        = 'SophosGoldImagePrep'
        Description     = 'Completes preparation steps in Sophos KB-000035040.'
        TaskPath        = '\'
        Action          = $Action
        Principal       = $Principal
        Settings        = $Settings
        Trigger         = $Trigger

    }

    Register-ScheduledTask @RegSchTaskParameters
}

schTaskGoldImagePrep

Write-Host -ForegroundColor Green "Installation of Intercept X Advanced is complete!"
