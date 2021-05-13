# Second-phase configuration of vanilla Windows Server installation to progress Packer.io builds
# @author Ralph Brynard

$url = "https://api-cloudstation-us-east-2.prod.hydra.sophos.com/api/download/9287a9b85973f795f5c7e6b7fd0f4e32/SophosSetup.exe"
$output = "$env:TEMP\SophosSetup.exe"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url,$output)