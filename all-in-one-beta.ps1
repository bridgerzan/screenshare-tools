[Console]::OutputEncoding = [Text.UTF8Encoding]::new()

$username = $env:USERNAME
$consoleHistoryPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
$crashDumpPath = "C:\Users\$username\AppData\Local\CrashDumps"

# -----formats-----
$drives = Get-Volume | Where-Object { $_.DriveLetter -ne $null }
$fatDrives = @()
$ntfsDrives = @()
foreach ($d in $drives) {
    switch ($d.FileSystem) {
        "FAT32" { $fatDrives += "$($d.DriveLetter):" }
        "exFAT" { $fatDrives += "$($d.DriveLetter):" }
        "NTFS" { $ntfsDrives += "$($d.DriveLetter):" }
    }
}
$fats = if ($fatDrives.Count -gt 0) { $fatDrives -join ", " } else { "No FAT32 or exFAT drives found" }
$ntfss = if ($ntfsDrives.Count -gt 0) { $ntfsDrives -join ", " } else { "No NTFS drives found" }

# -----OS info-----
$OSinfo = Get-CimInstance Win32_OperatingSystem
$lastBootUp = try {
    (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
} catch {
    "Unavailable"
}

$installDateParsed = try {
    (Get-CimInstance -ClassName Win32_OperatingSystem).InstallDate | Get-Date -Format "yyyy-MM-dd HH:mm:ss"
} catch {
    "Not Found"
}

# -----crash dumps-----
$crashDumps = @()
if (Test-Path $crashDumpPath) {
    $crashFiles = Get-ChildItem -Path $crashDumpPath -Filter *.dmp -ErrorAction SilentlyContinue
    foreach ($file in $crashFiles) {
        $crashDumps += [PSCustomObject]@{
            FileName = $file.Name
            LastModified = $file.LastWriteTime
        }
    }
} else {
    $crashDumps += [PSCustomObject]@{ FileName = "No crash dumps found"; LastModified = "N/A" }
}

# -----console history-----
$consoleHistoryLastModified = if (Test-Path $consoleHistoryPath) {
    (Get-Item $consoleHistoryPath).LastWriteTime
} else {
    "File Not Found"
}

# -----service check-----
$servicesToCheck = @(
    "SysMain", "bam", "CDPSvc", "PcaSvc",
    "EventLog", "Appinfo", "Dnscache", "DiagTrack",
    "WSearch", "Schedule"
)

$serviceStatuses = foreach ($svc in $servicesToCheck) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        $startupType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$svc'").StartMode
        [PSCustomObject]@{
            Name = $svc
            Status = $service.Status
            StartupType = $startupType
        }
    } else {
        [PSCustomObject]@{
            Name = $svc
            Status = "Not Found"
            StartupType = "N/A"
        }
    }
}

# -----event log check-----
$eventIDsToCheck = @(3079, 4616, 4634, 1102)
$eventLogResults = @()

foreach ($id in $eventIDsToCheck) {
    $logName = if ($id -in 3079) { "Application" } else { "Security" }
    
    $events = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$id]]" -MaxEvents 5 -ErrorAction SilentlyContinue
    
    if ($events) {
        foreach ($event in $events) {
            $eventLogResults += [PSCustomObject]@{
                EventID = $id
                LogName = $logName
                TimeCreated = $event.TimeCreated
                Message = ($event.Message -split "`n")[0] 
            }
        }
    } else {
        $eventLogResults += [PSCustomObject]@{
            EventID = $id
            LogName = $logName
            TimeCreated = "No events found"
            Message = "N/A"
        }
    }
}

# ----- Don't Log Finder -----
$logPaths = @(
    "$env:APPDATA\.minecraft\logs",
    "$env:APPDATA\.minecraft\logs\blclient\minecraft",
    "$env:USERPROFILE\.lunarclient\logs\game"
)

$latestLogs = @()

foreach ($path in $logPaths) {
    if (Test-Path $path) {
        $logFile = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending |
                   Select-Object -First 1

        if ($logFile) {
            $containsDontLog = $null
            try {
                $contentSample = Get-Content -Path $logFile.FullName -TotalCount 1000 -ErrorAction Stop
                $joinedContent = $contentSample -join "`n"
                $containsDontLog = $joinedContent -match "(?i)don'?t\s+log"
            } catch {
                $containsDontLog = $null
            }

            $latestLogs += [PSCustomObject]@{
                Path = $path
                LatestLogFile = $logFile.Name
                LastModified = $logFile.LastWriteTime
                FullPath = $logFile.FullName
                ContainsDontLog = if ($containsDontLog -eq $null) { "Error or unreadable" } else { $containsDontLog }
            }
        } else {
            $latestLogs += [PSCustomObject]@{
                Path = $path
                LatestLogFile = "No files found"
                LastModified = "N/A"
                FullPath = "N/A"
                ContainsDontLog = "N/A"
            }
        }
    } else {
        $latestLogs += [PSCustomObject]@{
            Path = $path
            LatestLogFile = "Directory not found"
            LastModified = "N/A"
            FullPath = "N/A"
            ContainsDontLog = "N/A"
        }
    }
}

cls
# -----html-----
$html = @"
<!DOCTYPE html>
<html lang='en'>
<head>
<meta charset='UTF-8'>
<title>Vortex All In One Tool</title>
<link id="favicon" rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🌸</text></svg>">
<style>
    body {
        margin: 0;
        font-family: 'Segoe UI', sans-serif;
        color: #4a148c;
        padding: 30px;
        position: relative;
        z-index: 0;
    }
    #particles-js {
        position: fixed;
        width: 100%;
        height: 100%;
        z-index: -1;
        top: 0;
        left: 0;
    }
    h1, h2, h3 {
        text-align: center;
        color: #ad1457;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 25px;
    }
    th, td {
        border: 1px solid #f48fb1;
        padding: 12px;
        text-align: center;
    }
    th {
        background: #ec407a;
        color: white;
    }
    tr:nth-child(even) td {
        background: #fce4ec;
    }
    .copy-box {
        background: #ffffff;
        border: 2px solid #ec407a;
        padding: 10px;
        width: 200px;
        margin: 0 auto 20px auto;
        font-weight: bold;
        font-size: 18px;
        text-align: center;
        border-radius: 10px;
        box-shadow: 0 0 8px #f48fb1;
        cursor: pointer;
        transition: all 0.3s;
        color: #ad1457;
        user-select: none;
    }
    .copy-box:hover {
        background: #fce4ec;
        transform: scale(1.05);
    }
    .copy-box.copied {
        background: #e8f5e9;
        color: #2e7d32;
    }
    footer {
        text-align: center;
        margin-top: 40px;
        color: #880e4f;
        font-size: 14px;
    }
    footer a {
        color: #d81b60;
        text-decoration: none;
        font-weight: bold;
    }
    .found {
        color: #2e7d32;
        font-weight: bold;
    }
    .not-found {
        color: #c62828;
        font-weight: bold;
    }
</style>
</head>
<body>
<div id="particles-js"></div>

<h1>🌸 Vortex All In One Tool</h1>
<div class="copy-box" id="copyBox" onclick="copyNumber()">Click to copy downloader</div>

<h3>👤 Username: $username</h3>

<h2>💽 Drives</h2>
<table>
<tr><th>FAT32 / exFAT Drives</th><td>$fats</td></tr>
<tr><th>NTFS Drives</th><td>$ntfss</td></tr>
</table>

<h2>📅 OS Info</h2>
<table>
<tr><th>Last Boot Time</th><td>$lastBootUp</td></tr>
<tr><th>Windows Install Date</th><td>$installDateParsed</td></tr>
</table>

<h2>🧨 Crash Dumps</h2>
<table><tr><th>File Name</th><th>Last Modified</th></tr>
"@

foreach ($cd in $crashDumps) {
    $html += "<tr><td>$($cd.FileName)</td><td>$($cd.LastModified)</td></tr>`n"
}

$html += @"
</table>

<h2>📜 Console History</h2>
<p style="text-align:center;">Last Modified: $consoleHistoryLastModified</p>

<h2>🛠️ Services Status</h2>
<table><tr><th>Service</th><th>Status</th><th>Startup Type</th></tr>
"@

foreach ($svc in $serviceStatuses) {
    $html += "<tr><td>$($svc.Name)</td><td>$($svc.Status)</td><td>$($svc.StartupType)</td></tr>`n"
}

$html += @"
</table>

<h2>📋 Event Logs</h2>
<table><tr><th>Event ID</th><th>Log Name</th><th>Time Created</th><th>Message</th></tr>
"@

foreach ($event in $eventLogResults) {
    $html += "<tr><td>$($event.EventID)</td><td>$($event.LogName)</td><td>$($event.TimeCreated)</td><td>$($event.Message)</td></tr>`n"
}

$html += @"
</table>

<h2>🔍 Don't Log Finder</h2>
<table><tr><th>Log Path</th><th>Latest Log File</th><th>Last Modified</th><th>Contains "dont log"</th></tr>
"@

foreach ($log in $latestLogs) {
    $dontLogStatus = if ($log.ContainsDontLog -eq $true) {
        "<span class='found'>✅ Found</span>"
    } elseif ($log.ContainsDontLog -eq $false) {
        "<span class='not-found'>❌ Not found</span>"
    } else {
        $log.ContainsDontLog
    }
    
    $html += "<tr><td>$($log.Path)</td><td>$($log.LatestLogFile)</td><td>$($log.LastModified)</td><td>$dontLogStatus</td></tr>`n"
}

$html += @"
</table>

<footer>
    <p>🔗 Join our Discord: <a href="https://discord.gg/maWx9njuty" target="_blank">discord.gg/maWx9njuty</a></p>
    <p>created by bridgezan</p>
</footer>

<script src="https://cdn.jsdelivr.net/particles.js/2.0.0/particles.min.js"></script>
<script>
// Function to copy the number
function copyNumber() {
    const number = 'powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/bridgerzan/screenshare-tools/refs/heads/main/downloader.ps1)';
    navigator.clipboard.writeText(number).then(() => {
        const box = document.getElementById('copyBox');
        box.textContent = 'Copied: ' + number;
        box.classList.add('copied');
        
        setTimeout(() => {
            box.textContent = 'Click to copy downloader';
            box.classList.remove('copied');
        }, 2000);
    });
}

// Function to change icon and title
function updatePageVisibility() {
    if (document.hidden) {
        document.title = "why did you leave?";
        document.getElementById('favicon').href = "data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🍓</text></svg>";
    } else {
        document.title = "Vortex All In One Tool";
        document.getElementById('favicon').href = "data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🌸</text></svg>";
    }
}

// Page visibility events
document.addEventListener('visibilitychange', updatePageVisibility);
document.addEventListener('pagehide', updatePageVisibility);

// Particles.js configuration
particlesJS("particles-js", {
  "particles": {
    "number": { "value": 70, "density": { "enable": true, "value_area": 800 } },
    "color": { "value": "#e91e63" },
    "shape": { "type": "circle" },
    "opacity": { "value": 0.5 },
    "size": { "value": 3, "random": true },
    "line_linked": {
      "enable": true,
      "distance": 150,
      "color": "#ec407a",
      "opacity": 0.4,
      "width": 1
    },
    "move": { "enable": true, "speed": 3, "out_mode": "out" }
  },
  "interactivity": {
    "detect_on": "canvas",
    "events": {
      "onhover": { "enable": true, "mode": "grab" },
      "onclick": { "enable": true, "mode": "push" }
    },
    "modes": {
      "grab": { "distance": 140, "line_linked": { "opacity": 0.6 } },
      "push": { "particles_nb": 4 }
    }
  },
  "retina_detect": true
});
</script>

</body>
</html>
"@

# -----save to temp-----
$outFile = "$env:TEMP\VortexAllInOneTool.html"
$html | Out-File -FilePath $outFile -Encoding utf8
Start-Process $outFile
