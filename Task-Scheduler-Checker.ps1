$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$taskDir = "C:\Windows\System32\Tasks"
$resultsDir = "$desktopPath\tasks"
$commandsFile        = "$resultsDir\commands"
$argumentsFile       = "$resultsDir\arguments"
$actionsFile         = "$resultsDir\actions"
$detectionsFile      = "$resultsDir\detections"
$errorsFile          = "$resultsDir\errors"
$deletedFile         = "$resultsDir\deleted"
$userTasksFile       = "$resultsDir\user_tasks"
$journalDeletedFile  = "$resultsDir\journal_deleted"
$exeFile             = "$resultsDir\executables"
$dllFile             = "$resultsDir\dlls"
$batFile             = "$resultsDir\bats"
$ps1File             = "$resultsDir\ps1s"
$warningFile         = "$resultsDir\warnings"
$outputFormat = Read-Host "Enter output format: csv or txt (default: txt)"
if ($outputFormat -ne 'csv') {
    $outputFormat = 'txt'
}




$commandsFile       += ".$outputFormat"
$argumentsFile      += ".$outputFormat"
$actionsFile        += ".$outputFormat"
$detectionsFile     += ".$outputFormat"
$errorsFile         += ".$outputFormat"
$deletedFile        += ".$outputFormat"
$userTasksFile      += ".$outputFormat"
$journalDeletedFile += ".$outputFormat"
$exeFile            += ".$outputFormat"
$dllFile            += ".$outputFormat"
$batFile            += ".$outputFormat"
$ps1File            += ".$outputFormat"
$warningFile        += ".$outputFormat"


if (-not (Test-Path -Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir | Out-Null
}
Remove-Item $commandsFile, $argumentsFile, $actionsFile, $detectionsFile, $errorsFile, `
            $deletedFile, $userTasksFile, $journalDeletedFile, $exeFile, $dllFile, $batFile, $ps1File, $warningFile `
            -ErrorAction SilentlyContinue
$suspiciousKeywords = @(
    "CMD", "Type", "Powershell", "Powershell_ISE",
    "TaskScheduler", "Task_Scheduler", "MMC"
)
$builtInTasks = @(
    'Microsoft', 'Windows', 'NvTask', 'GoogleUpdateTaskMachine', 'Adobe Acrobat Update Task'
)
Write-Host "Scanning tasks in $taskDir and subfolders..." -ForegroundColor Yellow
$existingTasks = @{}
if (Test-Path $commandsFile) {
    if ($outputFormat -eq 'txt') {
        Get-Content $commandsFile | ForEach-Object {
            $taskName = ($_ -split ' -> ')[0]
            $existingTasks[$taskName] = $true
        }
    } elseif ($outputFormat -eq 'csv') {
        Import-Csv $commandsFile | ForEach-Object {
            $existingTasks[$_.TaskFilePath] = $true
        }
    }
}
function Add-ContentOrCsv {
    param (
        [Parameter(Mandatory=$true)] [string] $Path,
        [Parameter(Mandatory=$true)] $Content,
        [Parameter(Mandatory=$true)] [string] $Type
    )
    if ($Type -eq 'csv') {
        if (-not (Test-Path $Path)) {
            $Content | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        } else {
            $Content | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8 -Append
        }
    }
    else {
        Add-Content -Path $Path -Value $Content
    }
}

function Process-TaskFile {
    param (
        [string]$taskFilePath
    )
    try {
        if ($taskFilePath -like "C:\\Windows\\System32\\Tasks\\Microsoft*") {
            return
        }
        $taskXml = Get-Content -Path $taskFilePath -Raw -ErrorAction Stop
        $task = [xml]$taskXml
        $userAuthor = $task.Task.RegistrationInfo.Author
        if ($userAuthor -and -not ($builtInTasks -contains $userAuthor) -and $userAuthor -ne "SYSTEM") {
            if ($outputFormat -eq 'csv') {
                $obj = [PSCustomObject]@{
                    TaskFilePath = $taskFilePath
                    Author       = $userAuthor
                }
                Add-ContentOrCsv -Path $userTasksFile -Content $obj -Type 'csv'
            } else {
                Add-ContentOrCsv -Path $userTasksFile -Content ("{0} -> Author: {1}" -f $taskFilePath, $userAuthor) -Type 'txt'
            }
        }
        if (-not $task.Task.Actions) {
            Add-ContentOrCsv -Path $errorsFile -Content ("{0} -> No actions found" -f $taskFilePath) -Type $outputFormat
            return
        }
        foreach ($action in $task.Task.Actions.Exec) {
            $command = $action.Command
            $arguments = $action.Arguments
            $existingTasks.Remove($taskFilePath)
            if ($command) {
                if ($outputFormat -eq 'csv') {
                    $obj = [PSCustomObject]@{
                        TaskFilePath = $taskFilePath
                        Command      = $command
                    }
                    Add-ContentOrCsv -Path $commandsFile -Content $obj -Type 'csv'
                } else {
                    Add-ContentOrCsv -Path $commandsFile -Content ("{0} -> {1}" -f $taskFilePath, $command) -Type 'txt'
                }
            }
            if ($arguments) {
                if ($outputFormat -eq 'csv') {
                    $obj = [PSCustomObject]@{
                        TaskFilePath = $taskFilePath
                        Arguments    = $arguments
                    }
                    Add-ContentOrCsv -Path $argumentsFile -Content $obj -Type 'csv'
                } else {
                    Add-ContentOrCsv -Path $argumentsFile -Content ("{0} -> {1}" -f $taskFilePath, $arguments) -Type 'txt'
                }
            }
            if ($command) {
                if ($command -match '\.exe$') {
                    if ($outputFormat -eq 'csv') {
                        $obj = [PSCustomObject]@{
                            TaskFilePath = $taskFilePath
                            Command      = $command
                            Type         = 'Executable'
                            Arguments    = $arguments
                        }
                        Add-ContentOrCsv -Path $exeFile -Content $obj -Type 'csv'
                    } else {
                        Add-ContentOrCsv -Path $exeFile -Content ("{0} | {1} | {2}" -f $taskFilePath, $command, $arguments) -Type 'txt'
                    }
                    Write-Host ("{0} -> Executable: {1}" -f $taskFilePath, $command) -ForegroundColor Blue
                    $exePath = $command
                    if (-not [System.IO.Path]::IsPathRooted($exePath)) {
                        $taskFolder = Split-Path $taskFilePath
                        $exePath = Join-Path $taskFolder $command
                    }
                    if ($exePath -notmatch [regex]::Escape("C:\Windows\System32")) {
                        $warningText = "WARNING: {0} -> Executable outside System32: {1}" -f $taskFilePath, $exePath
                        if ($outputFormat -eq 'csv') {
                            $objWarn = [PSCustomObject]@{
                                TaskFilePath = $taskFilePath
                                Warning      = "Executable outside System32"
                                Command      = $exePath
                            }
                            Add-ContentOrCsv -Path $warningFile -Content $objWarn -Type 'csv'
                        } else {
                            Add-ContentOrCsv -Path $warningFile -Content $warningText -Type 'txt'
                        }
                    }
                }
                elseif ($command -match '\.dll$') {
                    if ($outputFormat -eq 'csv') {
                        $obj = [PSCustomObject]@{
                            TaskFilePath = $taskFilePath
                            Command      = $command
                            Type         = 'DLL'
                            Arguments    = $arguments
                        }
                        Add-ContentOrCsv -Path $dllFile -Content $obj -Type 'csv'
                    } else {
                        Add-ContentOrCsv -Path $dllFile -Content ("{0} | {1} | {2}" -f $taskFilePath, $command, $arguments) -Type 'txt'
                    }
                    Write-Host ("{0} -> DLL file detected: {1}" -f $taskFilePath, $command) -ForegroundColor DarkCyan
                }
                elseif ($command -match '\.bat$') {
                    if ($outputFormat -eq 'csv') {
                        $obj = [PSCustomObject]@{
                            TaskFilePath = $taskFilePath
                            Command      = $command
                            Type         = 'Batch Script'
                            Arguments    = $arguments
                        }
                        Add-ContentOrCsv -Path $batFile -Content $obj -Type 'csv'
                    } else {
                        Add-ContentOrCsv -Path $batFile -Content ("{0} | {1} | {2}" -f $taskFilePath, $command, $arguments) -Type 'txt'
                    }
                    Write-Host ("{0} -> Batch script detected: {1}" -f $taskFilePath, $command) -ForegroundColor Yellow
                }
                elseif ($command -match '\.ps1$') {
                    if ($outputFormat -eq 'csv') {
                        $obj = [PSCustomObject]@{
                            TaskFilePath = $taskFilePath
                            Command      = $command
                            Type         = 'PowerShell Script'
                            Arguments    = $arguments
                        }
                        Add-ContentOrCsv -Path $ps1File -Content $obj -Type 'csv'
                    } else {
                        Add-ContentOrCsv -Path $ps1File -Content ("{0} | {1} | {2}" -f $taskFilePath, $command, $arguments) -Type 'txt'
                    }
                    Write-Host ("{0} -> PowerShell script detected: {1}" -f $taskFilePath, $command) -ForegroundColor Magenta
                }
                else {
                    Write-Host ("{0} -> Other command: {1}" -f $taskFilePath, $command) -ForegroundColor Red
                }
            }

            foreach ($keyword in $suspiciousKeywords) {
                $regex = "\b$keyword\b"
                if (($command -and $command -match $regex) -or ($arguments -and $arguments -match $regex)) {
                    $detectText = "{0} -> Detected keyword: {1}" -f $taskFilePath, $keyword
                    if ($outputFormat -eq 'csv') {
                        $objDetect = [PSCustomObject]@{
                            TaskFilePath = $taskFilePath
                            Keyword      = $keyword
                            Command      = $command
                            Arguments    = $arguments
                        }
                        Add-ContentOrCsv -Path $detectionsFile -Content $objDetect -Type 'csv'
                    } else {
                        Add-ContentOrCsv -Path $detectionsFile -Content $detectText -Type 'txt'
                    }
                }
            }
        }
    } catch {
        Add-ContentOrCsv -Path $errorsFile -Content ("Error processing {0}: {1}" -f $taskFilePath, $_.Exception.Message) -Type $outputFormat
    }
}
$allTasks = Get-ChildItem -Path $taskDir -Recurse -File | Where-Object { $_.FullName -notlike "C:\\Windows\\System32\\Tasks\\Microsoft*" }
$totalTasks = $allTasks.Count
$counter = 0

foreach ($taskFile in $allTasks) {
    $counter++
    Write-Host ("Processing task {0} / {1}: {2}" -f $counter, $totalTasks, $taskFile.Name) -ForegroundColor Cyan
    Process-TaskFile -taskFilePath $taskFile.FullName
}
foreach ($taskName in $existingTasks.Keys) {
    if ($outputFormat -eq 'csv') {
        $objDel = [PSCustomObject]@{
            TaskFilePath = $taskName
            Status       = "Deleted"
        }
        Add-ContentOrCsv -Path $deletedFile -Content $objDel -Type 'csv'
    } else {
        Add-ContentOrCsv -Path $deletedFile -Content ("Deleted task: {0}" -f $taskName) -Type 'txt'
    }
}





$UserRN = $env:USERNAME
Write-Host "`nChecking tasks created by user: $UserRN" -ForegroundColor Red
$userCreatedTasks = Get-ScheduledTask |
    Where-Object { $_.Author -match $UserRN } |
    Select-Object TaskName, TaskPath, 
                  @{Name='Action';Expression={($_.Actions | ForEach-Object { $_.Execute })}}, 
                  @{Name='Arguments';Expression={($_.Actions | ForEach-Object { if ($_.Arguments) { $_.Arguments } else { 'None' } })}}
if ($userCreatedTasks) {
    foreach ($task in $userCreatedTasks) {
        if ($outputFormat -eq 'csv') {
            $objUserTask = [PSCustomObject]@{
                TaskName  = $task.TaskName
                TaskPath  = $task.TaskPath
                Action    = ($task.Action -join ', ')
                Arguments = ($task.Arguments -join ', ')
            }
            Add-ContentOrCsv -Path $userTasksFile -Content $objUserTask -Type 'csv'
        } else {
            $line = "TaskName: $($task.TaskName), Path: $($task.TaskPath), Action: $($task.Action -join ', '), Arguments: $($task.Arguments -join ', ')"
            Add-ContentOrCsv -Path $userTasksFile -Content $line -Type 'txt'
        }
    }
    Write-Host "User created tasks saved to $userTasksFile" -ForegroundColor Green
} else {
    Write-Host "No manually created tasks found for user $UserRN" -ForegroundColor Yellow
}



Write-Host "`nChecking Event Journal for deleted tasks..." -ForegroundColor Yellow
try {
    $logInfo = wevtutil get-log "Microsoft-Windows-TaskScheduler/Operational"
    if ($logInfo -match "enabled:\s+true") {
        $deletedEvents = Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" `
                                       -FilterXPath "*[System[(EventID=141)]]" `
                                       -ErrorAction Stop

        foreach ($event in $deletedEvents) {
            $time = $event.TimeCreated
            $message = $event.Message -replace "`r`n", " "
            if ($outputFormat -eq 'csv') {
                $objEvent = [PSCustomObject]@{
                    Time    = $time
                    Message = $message
                }
                Add-ContentOrCsv -Path $journalDeletedFile -Content $objEvent -Type 'csv'
            } else {
                Add-ContentOrCsv -Path $journalDeletedFile -Content ("[{0}] -> {1}" -f $time, $message) -Type 'txt'
            }
        }

        Write-Host "Deleted tasks from journal saved to $journalDeletedFile" -ForegroundColor Green
    } else {
        Write-Host "Task Scheduler Operational log is not enabled. Skipping journal scan." -ForegroundColor DarkYellow
    }
} catch {
    Add-ContentOrCsv -Path $errorsFile -Content "Error reading Event Journal: $($_.Exception.Message)" -Type $outputFormat
    Write-Host "Error reading Event Journal. Skipped journal-based deletion check." -ForegroundColor Red
}

Write-Host "`nScan complete! Processed $counter tasks." -ForegroundColor Green
Write-Host "Results saved in $resultsDir."
