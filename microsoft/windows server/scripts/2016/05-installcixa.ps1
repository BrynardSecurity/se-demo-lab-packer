# Second-phase configuration of vanilla Windows Server installation to progress Packer.io builds
# @author Ralph Brynard
$ErrorActionPreference = "Inquire"

cd $env:TEMP

#Set TLS Version
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$url="https://dzr-api-amzn-us-west-2-fa88.api-upe.p.hmr.sophos.com/api/download/a24f232171f6e3dd9d913518503c1de4/SophosSetup.exe"
$installer = "SophosSetup.exe"
curl $url -OutFile $installer 
& Start-Process -FilePath "$env:TEMP"+SophosSetup.exe -ArgumentList --customertoken="9a02d9a7-02b9-446b-873a-ad752e668a6d" --epinstallerserver="dzr-api-amzn-us-west-2-fa88.api-upe.p.hmr.sophos.com" --products="all"


$registrationToken = getString -firstString "<registrationToken>" -secondString "</registrationToken>" -importPath "C:\ProgramData\Sophos\Management Communications System\Endpoint\Config\Config.xml"

Get-Content A:\SophosGoldImagePrep.bat > C:\SophosGoldImagePrep.bat
function getString() {
    param (
        [parameter(mandatory=$true)][string]$firstString =$(throw "Parameter missing: -firstString 'string1' "),
        [parameter(mandatory=$false)][string]$secondString =$(throw "Parameter missing: -secondString 'string2' "),
        [parameter(mandatory=$true)][string]$importPath =$(throw "Parameter missing: -importPath '\path\to\import\file' ")
    )
    
    #Get content from file
    $file = Get-Content $importPath

    #Regex pattern to compare two strings
    $pattern = "$firstString(.*?)$secondString"

    #Perform the operation
    $result = [regex]::Match($file,$pattern).Groups[1].Value

    #Return result
    return $result
}

findInTextFile -FilePath 'C:\SophosGoldImagePrep.bat' -Find 'GOLD_IMAGE_HOSTNAME' -Replace '$(hostname)'
findInTextFile -File 'C:\SophosGoldImagePrep.bat' -find 'REGISTRATION_TOKEN' -Replace $registrationToken
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

schTaskGoldImagePrep
function schTaskGoldImagePrep (){
    $class = cimclass MSFT_TASKEventTrigger root/Microsoft/Windows/TaskScheduler
    $trigger = $class | New-CimInstance -ClientOnly
    $trigger.Enabled = $true
    $trigger.Subscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=User32] and EventID=1074]]</Select></Query></QueryList>'

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
