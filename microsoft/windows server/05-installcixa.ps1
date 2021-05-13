# Second-phase configuration of vanilla Windows Server installation to progress Packer.io builds
# @author Ralph Brynard
$ErrorActionPreference = "Inquire"

cd $env:TEMP

#Set TLS Version
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$url="https://dzr-api-amzn-us-west-2-fa88.api-upe.p.hmr.sophos.com/api/download/a24f232171f6e3dd9d913518503c1de4/SophosSetup.exe"
$installer = "SophosSetup.exe"
curl $url -OutFile $installer 
$result = Start-Process -Wait -FilePath $installer -ArgumentList '--customertoken="9a02d9a7-02b9-446b-873a-ad752e668a6d" --epinstallerserver="dzr-api-amzn-us-west-2-fa88.api-upe.p.hmr.sophos.com" --products="all" --quiet'  

## Testing Steps

