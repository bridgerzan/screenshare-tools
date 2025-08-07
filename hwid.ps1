Clear-Host
$Host.UI.RawUI.WindowTitle = "HWID Extractor"

function Get-RAMTypeName($type) {
    switch ($type) {
        20 { return "DDR" }
        21 { return "DDR2" }
        22 { return "DDR2 FB-DIMM" }
        24 { return "DDR3" }
        26 { return "DDR4" }
        30 { return "DDR5" }
        default { return "Unknown" }
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "============================="
    Write-Host "       HWID Extractor"
    Write-Host "============================="
    Write-Host "[1] Extract HWID and System Info"
    Write-Host "[2] Change Webhook URL"
    Write-Host "[3] Clear Logs"
    Write-Host "[4] Exit"
}

function Extract-HWID {
    Clear-Host
    if (-not $WebhookURL) {
        $ans = Read-Host "Do you have a Discord Webhook URL? (y/n)"
        if ($ans -eq "y" -or $ans -eq "Y") {
            $WebhookURL = Read-Host "Enter your Webhook URL"
            $DiscordID = Read-Host "Enter your Discord ID"
            $Reason = Read-Host "Why do you want to upload HWID?"
        }
    }

    $UserName = $env:USERNAME
    $Desktop = [Environment]::GetFolderPath("Desktop")
    $ResultsDir = Join-Path $Desktop "$UserName-HWID"
    if (!(Test-Path $ResultsDir)) { New-Item -ItemType Directory -Path $ResultsDir | Out-Null }
    $HWIDFile = Join-Path $ResultsDir "$UserName-HWID.txt"

    # جمع آوری اطلاعات
    $ComputerName = $env:COMPUTERNAME
    $UserDomain = $env:USERDOMAIN
    $OS = (Get-CimInstance Win32_OperatingSystem).Caption
    $UUID = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    $CPUId = (Get-CimInstance Win32_Processor).ProcessorId
    $MAC = (Get-NetAdapter | Where-Object Status -eq 'Up').MacAddress -join ", "
    $Model = (Get-CimInstance Win32_ComputerSystem).Model
    $Manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
    $GPU = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name

    $UserFolders = Get-ChildItem -Path 'C:\Users\' -Directory | ForEach-Object { $_.Name }

    $CPUInfo = Get-CimInstance Win32_Processor
    $CPUName = $CPUInfo.Name
    $CPUCores = $CPUInfo.NumberOfCores
    $CPUThreads = $CPUInfo.NumberOfLogicalProcessors
    $CPUSpeedGHz = [math]::Round($CPUInfo.MaxClockSpeed / 1000, 2)

    $RAMModules = Get-CimInstance Win32_PhysicalMemory
    $TotalRAMGB = [math]::Round(($RAMModules.Capacity | Measure-Object -Sum).Sum / 1GB, 2)
    $RAMSlots = $RAMModules.Count
    $RAMType = Get-RAMTypeName (($RAMModules | Select-Object -First 1).MemoryType)

    $Disks = Get-CimInstance Win32_DiskDrive
    $DiskInfo = foreach ($disk in $Disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        $type = if ($disk.MediaType -match "SSD") { "SSD" } else { "HDD" }
        "Model: $($disk.Model)`n    Size : $sizeGB GB`n    Type : $type"
    }

    $content = @"
==============================================
          HWID AND SYSTEM INFORMATION
==============================================

[ USER INFORMATION ]
    User Name       : $UserName
    User Folder     : C:\Users\$UserName
    Computer Name   : $ComputerName
    User Domain     : $UserDomain

[ WINDOWS INFORMATION ]
    Version         : $OS
    UUID            : $UUID
    CPU ID          : $CPUId
    MAC Address(es) : $MAC

[ HARDWARE INFORMATION ]
    Manufacturer    : $Manufacturer
    Model           : $Model
    GPU             : $GPU

----------------------------------------------
[ CPU DETAILS ]
    Model           : $CPUName
    Cores           : $CPUCores
    Threads         : $CPUThreads
    Clock Speed     : $CPUSpeedGHz GHz

[ RAM DETAILS ]
    Total Installed : $TotalRAMGB GB
    Slots Used      : $RAMSlots
    Type            : $RAMType

[ DISK DETAILS ]
$(($DiskInfo -join "`n----------------------------------------------`n"))

----------------------------------------------
[ ALL USER FOLDERS IN C:\Users ]
$(($UserFolders -join "`n"))
==============================================
"@

    $content | Out-File -FilePath $HWIDFile -Encoding UTF8

    Write-Host "[+] HWID and system info saved: $HWIDFile" -ForegroundColor Green
    Start-Process -FilePath "notepad.exe" -ArgumentList $HWIDFile

    if ($WebhookURL) {
        Write-Host "Uploading file to Webhook..." -ForegroundColor Yellow
        try {
            $boundary = [System.Guid]::NewGuid().ToString()
            $LF = "`r`n"
            $fileContent = [System.IO.File]::ReadAllBytes($HWIDFile)
            $fileContentEncoded = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileContent)

            # پیام ID و دلیل
            $DiscordMessage = "ID: $DiscordID`nReason: $Reason"

            $bodyLines = @()
            $bodyLines += "--$boundary"
            $bodyLines += 'Content-Disposition: form-data; name="content"'
            $bodyLines += ''
            $bodyLines += $DiscordMessage
            $bodyLines += "--$boundary"
            $bodyLines += "Content-Disposition: form-data; name=`"file`"; filename=`"$UserName-HWID.txt`""
            $bodyLines += "Content-Type: text/plain"
            $bodyLines += ''
            $bodyLines += $fileContentEncoded
            $bodyLines += "--$boundary--"

            $body = $bodyLines -join $LF

            Invoke-RestMethod -Uri $WebhookURL `
                              -Method Post `
                              -ContentType "multipart/form-data; boundary=$boundary" `
                              -Body $body

            Write-Host "[+] Upload complete!" -ForegroundColor Green
        } catch {
            Write-Host "[!] Failed to upload file: $_" -ForegroundColor Red
        }
    }
}

function Change-Webhook {
    Clear-Host
    $script:WebhookURL = Read-Host "Enter new Webhook URL"
    Write-Host "[+] Webhook updated successfully!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

function Clear-Logs {
    Clear-Host
    $UserName = $env:USERNAME
    $Desktop = [Environment]::GetFolderPath("Desktop")
    $ResultsDir = Join-Path $Desktop "$UserName-HWID"
    if (Test-Path $ResultsDir) {
        Remove-Item "$ResultsDir\*" -Force
        Write-Host "[+] Logs cleared!" -ForegroundColor Green
    } else {
        Write-Host "[!] No logs found." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 2
}

$ExitApp = $false
do {
    Show-Menu
    $choice = Read-Host "Select an option"
    switch ($choice) {
        "1" { Extract-HWID }
        "2" { Change-Webhook }
        "3" { Clear-Logs }
        "4" { $ExitApp = $true }
        default { Write-Host "Invalid choice, try again." -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
} while (-not $ExitApp)

Write-Host "Exiting... Bye!" -ForegroundColor Cyan
Start-Sleep -Seconds 1
exit
