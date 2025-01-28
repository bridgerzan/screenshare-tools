function Menu {
    param (
        [string]$Title = @'
 ______     ______        ______   ______     ______     __        
/\  ___\   /\  ___\      /\__  _\ /\  __ \   /\  __ \   /\ \       
\ \___  \  \ \___  \     \/_/\ \/ \ \ \/\ \  \ \ \/\ \  \ \ \____  
 \/\_____\  \/\_____\       \ \_\  \ \_____\  \ \_____\  \ \_____\ 
  \/_____/   \/_____/        \/_/   \/_____/   \/_____/   \/_____/ 
'@
    )
    Clear-Host
    Write-Host "===================="
    Write-Host "       $Title       "
    Write-Host "===================="
    Write-Host "1. BAM"
    Write-Host "2. Recycle Bin"
    Write-Host "3. Check Services"
    Write-Host "4. USB Events"
    Write-Host "5. Soon"
    Write-Host "6. Exit"
    Write-Host "===================="
}
function Get-RecycleBinLastModified {
    # Create a Shell.Application instance
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(10)  # 10 is the identifier for the Recycle Bin
    

    $items = @()
    for ($i = 0; $i -lt $recycleBin.Items().Count; $i++) {
        $item = $recycleBin.Items().Item($i)
        $items += [pscustomobject]@{
            Name = $item.Name
            Path = $item.Path
            LastModified = $item.ModifyDate
        }
    }

    if ($items.Count -gt 0) {
        $lastModified = $items | Sort-Object LastModified -Descending | Select-Object -First 1
        
        if ($lastModified) {
            Write-Host "The most recently modified file in the Recycle Bin is:"
            Write-Host "Name: $($lastModified.Name)"
            Write-Host "Path: $($lastModified.Path)"
            Write-Host "Last Modified: $($lastModified.LastModified)"
        } else {
            Write-Host "No files found in the Recycle Bin."
        }
    } else {
        Write-Host "No files found in the Recycle Bin."
    }
}


function Get-USBEvents {
    # Set the date range for the query (last 7 days, for example)
    $startDate = (Get-Date).AddDays(-7)
    $endDate = Get-Date

    # Filter USB-related events from the System event log
    $usbEvents_System = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        StartTime = $startDate
        EndTime = $endDate
    } | Where-Object {
        $_.Message -like '*USB*' -or $_.Message -like '*Device connected*' -or $_.Message -like '*Device disconnected*'
    } | Select-Object TimeCreated, Id, Message

    # Filter USB-related events from the DriverFrameworks event log
    $usbEvents_Driver = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-DriverFrameworks-UserMode/Operational'
        StartTime = $startDate
        EndTime = $endDate
    } | Where-Object {
        $_.Message -like '*USB*' -or $_.Message -like '*Device connected*' -or $_.Message -like '*Device disconnected*'
    } | Select-Object TimeCreated, Id, Message

    # Combine and sort events by time
    $events = $usbEvents_System + $usbEvents_Driver | Sort-Object TimeCreated

    # Display the events
    $events | ForEach-Object {
        [PSCustomObject]@{
            Time = $_.TimeCreated
            Event = $_.Id
            Message = $_.Message
        }
    } | Format-Table -AutoSize
}

function Process-Menu {
    param (
        [string]$Choice
    )
    switch($Choice) {
        '1' {
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
            Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1)
        }
        '2' {
            Get-RecycleBinLastModified
            Start-Sleep 15
            Clear-Host
            Menu
            $selection = Read-Host "Select an option"
            Process-Menu -Choice $selection
        }
        '4' {
            Get-USBEvents
            Start-Sleep 15
            Clear-Host
            Menu
            $selection = Read-Host "Select an option"
            Process-Menu -Choice $selection
        }
        '3' {
            $ErrorActionPreference = "SilentlyContinue"  
            Get-Service | findstr -i "pcasvc"; get-service | findstr -i "DPS"; Get-Service | findstr -i "sysmain"; get-service |findstr -i "eventlog"; get-service | findstr -i "bam"; get-service | findstr -i "Appinfo"; get-service | findstr -i "DusmSvc"; get-service | findstr -i "DiagTrack"; get-service | -i "SgrmBroker"; get-service | findstr -i "DcomLaunch"; get-service | findstr -i "BFE"; get-service | findstr -i "Dnscache"; get-service | findstr -i "WSearch"; get-service | findstr -i "Schedule"; get-service | findstr "StorSvc"
            Start-Sleep 15
            Clear-Host
            Menu
            $selection = Read-Host "Select an option"
            Process-Menu -Choice $selection
        }
        '6' {
            Clear-Host
            Write-Host -ForegroundColor Green "Exiting... Thank you for using my tool - bridgezan"
            Start-Sleep 3
            exit
        }
        default {
            Write-Host "Invalid option, please try again."
        }
    }
}

Menu
$selection = Read-Host "Select an option"
Process-Menu -Choice $selection
