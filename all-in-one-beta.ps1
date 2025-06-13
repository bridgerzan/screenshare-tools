[Console]::OutputEncoding = [Text.UTF8Encoding]::new()

$username = $env:USERNAME
$consoleHistoryPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
$crashDumpPath = "C:\Users\$username\AppData\Local\CrashDumps"

# Drives
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

# OS Info
$osInfo = Get-CimInstance Win32_OperatingSystem
try {
    $lastBootUp = [Management.ManagementDateTimeConverter]::ToDateTime($osInfo.LastBootUpTime)
} catch {
    $lastBootUp = "Unavailable"
}

$installDateParsed = try {
    [Management.ManagementDateTimeConverter]::ToDateTime($osInfo.InstallDate)
} catch {
    "Not Found"
}

# Crash Dumps
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

# Console history
$consoleHistoryLastModified = if (Test-Path $consoleHistoryPath) {
    (Get-Item $consoleHistoryPath).LastWriteTime
} else {
    "File Not Found"
}

# Service Check
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

# HTML
$html = @"
<!DOCTYPE html>
<html lang='en'>
<head>
<meta charset='UTF-8'>
<title>Vortex All In One Tool</title>
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
        width: 150px;
        margin: 0 auto 20px auto;
        font-weight: bold;
        font-size: 18px;
        text-align: center;
        border-radius: 10px;
        box-shadow: 0 0 8px #f48fb1;
        user-select: all;
        color: #ad1457;
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
</style>
</head>
<body>
<div id="particles-js"></div>

<h1>🌸 Vortex All In One Tool</h1>
<div class="copy-box">14482721</div>

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

<footer>
    <p>🔗 Join our Discord: <a href="https://discord.gg/maWx9njuty" target="_blank">discord.gg/maWx9njuty</a></p>
    <p>created by bridgezan</p>
</footer>

<script src="https://cdn.jsdelivr.net/particles.js/2.0.0/particles.min.js"></script>
<script>
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

# ذخیره فایل HTML
$outFile = "$env:TEMP\VortexAllInOneTool.html"
$html | Out-File -FilePath $outFile -Encoding utf8
Start-Process $outFile
