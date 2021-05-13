$netconnectionname = Get-NetConnectionProfile | Select -First 1 | foreach {$_.Name}
Set-NetConnectionProfile -Name $netconnectionname -NetworkCategory "Private"
