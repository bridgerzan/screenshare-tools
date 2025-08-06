if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "run this script as Administrator" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.UI.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.ForegroundColor = "White"
function Show-Banner {
    Clear-Host
    Write-Host @"
 |\/\/\/|  
 |      |  
 |      |  
 | (o)(o)  
 C      _)  by bridgezan
  | ,___|  
  |   /    
 /____\    
/      \ 
"@
}
$svcList = @("PcaSvc","CDPSvc","DPS","SysMain","EventLog","Appinfo","DiagTrack","Dnscache","WSearch","Schedule")
while ($true) {
    Show-Banner
    Write-Host "`[1] Show services status"
    Write-Host "[2] Set all to Automatic and Start them"
    Write-Host "[3] Exit"
    $opt = Read-Host "`nChoose an option "
    if ($opt -eq "1") {
        Show-Banner
        Write-Output "`n    Services Status `n"
        foreach ($svc in $svcList) {
            try {
                $info = Get-Service -Name $svc -ErrorAction Stop
                $cfg = Get-CimInstance Win32_Service -Filter "Name='$svc'"
                $mode = if ($cfg.StartMode -eq "Auto") { "Automatic" } elseif ($cfg.StartMode -eq "Manual") { "Manual" } else { $cfg.StartMode }
                
                if ($info.Status -eq "Stopped") {
                    Write-Host "$svc - STOPPED (Start: $mode)" -ForegroundColor Red
                } else {
                    $ev = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Service Control Manager'; ID=7045} -MaxEvents 100 |
                          Where-Object { $_.Properties[0].Value -like "*$svc*" } | Select-Object -First 1
                    if ($ev) {
                        $t = $ev.TimeCreated.ToString("HH:mm:ss")
                        Write-Host "$svc - RUNNING (Start: $mode, Started at: $t)" -ForegroundColor Green
                    } else {
                        Write-Host "$svc - RUNNING (Start: $mode)" -ForegroundColor Green
                    }
                }
            } catch {
                Write-Host "$svc - NOT FOUND" -ForegroundColor Yellow
            }
        }
        Read-Host "`nPress Enter"
    }
    elseif ($opt -eq "2") {
        Show-Banner
        Write-Host "`n    Setting all to Automatic and starting them    `n"
        foreach ($svc in $svcList) {
            try {
                Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop
                Start-Service -Name $svc -ErrorAction Stop
                Write-Host "$svc - Done" -ForegroundColor Green
            } catch {
                Write-Host "$svc - Could not change (Access denied or restricted)" -ForegroundColor Yellow
            }
        }
        Read-Host "`nPress Enter to return to menu"
    }
    elseif ($opt -eq "3") {
        Write-Host "`nExiting...`n"
        break
    }
    else {
        Write-Host "Invalid choice!" -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}
