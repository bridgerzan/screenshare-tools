Clear-Host
Write-Host "Developed by bridgezan" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Enter path to mods folder (press Enter for default):" -NoNewline
Write-Host " $env:USERPROFILE\AppData\Roaming\.minecraft\mods" -ForegroundColor DarkGray
$modsPath = Read-Host "PATH"
if (-not $modsPath) { $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods" }

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "Invalid mods folder path!" -ForegroundColor Red
    exit 1
}

$mcProcess = Get-Process -Name javaw, java -ErrorAction SilentlyContinue | Sort-Object StartTime | Select-Object -First 1
if ($mcProcess) {
    $uptime = (Get-Date) - $mcProcess.StartTime
    Write-Host "[Minecraft Running]" -ForegroundColor Green
    Write-Host ("{0} PID {1} started at {2} (Up: {3}h {4}m {5}s)" -f $mcProcess.Name, $mcProcess.Id, $mcProcess.StartTime, $uptime.Hours, $uptime.Minutes, $uptime.Seconds)
} else {
    Write-Host "[!] Minecraft is not running." -ForegroundColor Red
}

$explorerProcess = Get-Process -Name explorer -ErrorAction SilentlyContinue | Sort-Object StartTime | Select-Object -First 1
if ($explorerProcess) {
    $explorerUptime = (Get-Date) - $explorerProcess.StartTime
    Write-Host "[Explorer Running]" -ForegroundColor Cyan
    Write-Host ("{0} PID {1} started at {2} (Up: {3}h {4}m {5}s)" -f $explorerProcess.Name, $explorerProcess.Id, $explorerProcess.StartTime, $explorerUptime.Hours, $explorerUptime.Minutes, $explorerUptime.Seconds)
}
Write-Host ""

function GetFileSHA1($path) {
    try { (Get-FileHash -Path $path -Algorithm SHA1).Hash }
    catch { return "" }
}

function GetZoneIdentifier($file) {
    $zone = Get-Content -Raw -Stream Zone.Identifier -ErrorAction SilentlyContinue -Path $file
    if ($zone -match "HostUrl=(.+)") { return $matches[1] }
    return $null
}

$blacklist = @(
    "AimAssist","AnchorTweaks","AutoAnchor","AutoCrystal","AutoDoubleHand","AutoHitCrystal","AutoPot",
    "AutoTotem","AutoArmor","InventoryTotem","Hitboxes","JumpReset","LegitTotem","PingSpoof",
    "SelfDestruct","ShieldBreaker","TriggerBot","Velocity","AxeSpam","WebMacro","FastPlace",
    "matrix_client","krypton_b12","raven","sigma","lynx","nova_b15","vape-client","argon-aspirah",
    "krypton","krypton-old","krypton-plus-v2-0","krypton-plus-v2-3","krypton-plus-v2-6","krypton-plus-v2-7",
    "scrims","scrims-2","scrims-2-1","scrims-2-2","scrims-v2-3","scrims-2-4","polar","prestige",
    "clickcrystals","clickcrystals-hidden","clickcrystals-ported","remnant-wif","wing-client","hellion-client",
    "marlow-client","francium","francium-reborn","onyx","pugware","walhack","valiant-client","virgin-",
    "virgin-2","virgin-v3","virgin-4","lumina","skilli"
)

function FindBlacklistStrings($filePath) {
    $found = [System.Collections.Generic.HashSet[string]]::new()
    try {
        $content = Get-Content -Raw -ErrorAction Stop $filePath
        foreach ($item in $blacklist) {
            if ($content -match $item) { $found.Add($item) | Out-Null }
        }
    } catch {}
    return $found
}

function QueryModrinth($sha1) {
    try {
        $response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$sha1" -UseBasicParsing -ErrorAction Stop
        if ($response.project_id) {
            $project = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($response.project_id)" -UseBasicParsing -ErrorAction Stop
            return @{ Name = $project.title; Source = "Modrinth" }
        }
    } catch {}
    return $null
}

function QueryCurseforge($sha1) {
    try {
        $response = Invoke-RestMethod -Uri "https://addons-ecs.forgesvc.net/api/v2/addonfile/$sha1" -UseBasicParsing -ErrorAction Stop
        if ($response.addonId) {
            return @{ Name = $response.displayName; Source = "CurseForge" }
        }
    } catch {}
    return $null
}

function DetectByName($fileName) {
    if ($fileName -match "OptiFine") { return @{ Name = $fileName; Source = "Optifine (name)" } }
    if ($fileName -match "tlauncher") { return @{ Name = $fileName; Source = "TLauncher (name)" } }
    if ($fileName -match "minecraftmods") { return @{ Name = $fileName; Source = "MinecraftMods (name)" } }
    return $null
}

$jars = Get-ChildItem -Path $modsPath -Filter *.jar -File
$total = $jars.Count
$spinnerChars = @("|", "/", "-", "\")
$index = 0

$knownMods = @()
$suspiciousMods = @()

$tempFolder = Join-Path $env:TEMP "bridgezan_modscan"
if (Test-Path $tempFolder) { Remove-Item -Force -Recurse $tempFolder }
New-Item -ItemType Directory -Path $tempFolder | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($jar in $jars) {
    $index++
    $spinner = $spinnerChars[$index % $spinnerChars.Length]
    Write-Host ("`r[{0}] Scanning {1}/{2}: {3}..." -f $spinner, $index, $total, $jar.Name) -ForegroundColor Yellow -NoNewline

    $sha1 = GetFileSHA1 $jar.FullName
    $zoneInfo = GetZoneIdentifier $jar.FullName

    $modInfo = QueryModrinth $sha1
    if (-not $modInfo) { $modInfo = QueryCurseforge $sha1 }
    if (-not $modInfo) { $modInfo = DetectByName $jar.Name }

    $foundStrings = FindBlacklistStrings $jar.FullName

    if ($modInfo) {
        $knownMods += [PSCustomObject]@{
            ModName = $modInfo.Name
            Source = $modInfo.Source
            FileName = $jar.Name
            Path = $jar.FullName
            SHA1 = $sha1
            ZoneIdentifier = $zoneInfo
            SuspiciousStrings = $foundStrings
            FileDetails = $jar
        }
    } elseif ($foundStrings.Count -gt 0) {
        $suspiciousMods += [PSCustomObject]@{
            ModName = $null
            Source = $null
            FileName = $jar.Name
            Path = $jar.FullName
            SHA1 = $sha1
            ZoneIdentifier = $zoneInfo
            SuspiciousStrings = $foundStrings
            FileDetails = $jar
        }
    }
}

Remove-Item -Force -Recurse $tempFolder
Write-Host "`r$(' ' * 80)`r" -NoNewline

function DisplayKnownMod($mod) {
    $sizeMB = "{0:N2}" -f ($mod.FileDetails.Length / 1MB)
    Write-Host "> $($mod.FileName)" -ForegroundColor Green
    Write-Host "  Mod Name     : $($mod.ModName)" -ForegroundColor Cyan
    Write-Host "  Source       : $($mod.Source)" -ForegroundColor DarkCyan
    Write-Host "  SHA1         : $($mod.SHA1)" -ForegroundColor DarkGray
    if ($mod.ZoneIdentifier) { Write-Host "  ZoneId       : $($mod.ZoneIdentifier)" -ForegroundColor DarkGray }
    Write-Host "  Size         : $sizeMB MB" -ForegroundColor DarkGray
    Write-Host "  Created      : $($mod.FileDetails.CreationTime)" -ForegroundColor DarkGray
    Write-Host "  Modified     : $($mod.FileDetails.LastWriteTime)" -ForegroundColor DarkGray
    Write-Host "  Last Access  : $($mod.FileDetails.LastAccessTime)" -ForegroundColor DarkGray
    if ($mod.SuspiciousStrings.Count -gt 0) {
        Write-Host "  Suspicious Strings: [$($mod.SuspiciousStrings -join ', ')]" -ForegroundColor Magenta
    }
    Write-Host ""
}

function DisplaySuspiciousMod($mod) {
    $sizeMB = "{0:N2}" -f ($mod.FileDetails.Length / 1MB)
    Write-Host "> $($mod.FileName)" -ForegroundColor Yellow
    if ($mod.ModName) { Write-Host "  Mod Name     : $($mod.ModName)" -ForegroundColor Cyan }
    if ($mod.Source) { Write-Host "  Source       : $($mod.Source)" -ForegroundColor DarkCyan }
    Write-Host "  SHA1         : $($mod.SHA1)" -ForegroundColor DarkGray
    if ($mod.ZoneIdentifier) { Write-Host "  ZoneId       : $($mod.ZoneIdentifier)" -ForegroundColor DarkGray }
    if ($mod.SuspiciousStrings.Count -gt 0) {
        Write-Host "  Suspicious Strings: [$($mod.SuspiciousStrings -join ', ')]" -ForegroundColor Magenta
    }
    Write-Host "  Size         : $sizeMB MB" -ForegroundColor DarkGray
    Write-Host "  Created      : $($mod.FileDetails.CreationTime)" -ForegroundColor DarkGray
    Write-Host "  Modified     : $($mod.FileDetails.LastWriteTime)" -ForegroundColor DarkGray
    Write-Host "  Last Access  : $($mod.FileDetails.LastAccessTime)" -ForegroundColor DarkGray
    Write-Host ""
}

if ($knownMods.Count -gt 0) {
    Write-Host "{ Verified Mods }" -ForegroundColor Cyan
    foreach ($mod in $knownMods) { DisplayKnownMod $mod }
    Write-Host ""
}

if ($suspiciousMods.Count -gt 0) {
    Write-Host "{ Suspicious Mods }" -ForegroundColor Yellow
    foreach ($mod in $suspiciousMods) { DisplaySuspiciousMod $mod }
    Write-Host ""
}

Write-Host "Scan completed." -ForegroundColor Green
