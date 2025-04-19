[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$console = $Host.UI.RawUI
$console.BackgroundColor = "Black"
$console.ForegroundColor = "White"
Clear-Host
Write-Host @"
 |\/\/\/|  
 |      |  
 |      |  
 | (o)(o)  
 C      _)  maked by bridgezan
  | ,___|  
  |   /    
 /____\    
/      \ 
"@
$services = "PcaSvc", "CDPSvc", "DPS", "SysMain", "EventLog", "Appinfo", "DiagTrack", "Dnscache", "WSearch", "Schedule"
foreach ($service in $services) {
    try {
        $serviceInfo = Get-Service -Name $service -ErrorAction Stop
        $serviceConfig = Get-CimInstance -ClassName Win32_Service -Filter "Name='$service'"
        $startType = switch ($serviceConfig.StartMode) {
            "Auto" { "Automatic"; break }
            "Manual" { "Manual"; break }
            "Disabled" { "Disabled"; break }
            default { $serviceConfig.StartMode }
        }
        if ($serviceInfo.Status -eq "Stopped") {
            Write-Host "$service - STOPPED (Start Type: $startType)" -ForegroundColor Red
        } else {
            $event = Get-WinEvent -FilterHashtable @{
                LogName='System'
                ProviderName='Service Control Manager'
                ID=7045
            } -MaxEvents 100 | Where-Object {
                $_.Properties[0].Value -like "*$service*"
            } | Select-Object -First 1

            if ($event) {
                $startTime = $event.TimeCreated.ToString("HH:mm:ss")
                Write-Host "$service - RUNNING (Start Type: $startType, Started at: $startTime)" -ForegroundColor Green
            }
            elseif ($serviceInfo.ProcessId -gt 0) {
                try {
                    $process = Get-Process -Id $serviceInfo.ProcessId -ErrorAction Stop
                    $startTime = $process.StartTime.ToString("HH:mm:ss")
                    Write-Host "$service - RUNNING (Start Type: $startType, Process started: $startTime)" -ForegroundColor Green
                } catch {
                    Write-Host "$service - RUNNING (Start Type: $startType)" -ForegroundColor Green
                }
            }
            else {
                Write-Host "$service - RUNNING (Start Type: $startType)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "$service - NOT FOUND" -ForegroundColor Yellow
    }
}

Pause
exit
