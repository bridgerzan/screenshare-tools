
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$taskDir = "C:\Windows\System32\Tasks"
$resultsDir = "$desktopPath\tasks"

$commandsFile = "$resultsDir\commands.txt"
$argumentsFile = "$resultsDir\arguments.txt"
$actionsFile = "$resultsDir\actions.txt"
$detectionsFile = "$resultsDir\detections.txt"
$errorsFile = "$resultsDir\errors.txt"
$deletedFile = "$resultsDir\deleted.txt"


if (-not (Test-Path -Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir | Out-Null
}

Remove-Item $commandsFile, $argumentsFile, $actionsFile, $detectionsFile, $errorsFile, $deletedFile -ErrorAction SilentlyContinue

$suspiciousKeywords = @(
    "CMD",
    "Type",
    "Echo",
    "Powershell",
    "Powershell_ISE",
    "PowershellISE",
    "TaskScheduler",
    "Task_Scheduler",
    "MMC"
)


$builtInTasks = @(
    'Microsoft',
    'Windows',
    'NvTask',
    'GoogleUpdateTaskMachine',
    'Adobe Acrobat Update Task'
)

Write-Host "Scanning tasks in $taskDir and subfolders..." -ForegroundColor Yellow


$existingTasks = @{}
if (Test-Path $commandsFile) {
    Get-Content $commandsFile | ForEach-Object {
        $taskName = ($_ -split ' -> ')[0]
        $existingTasks[$taskName] = $true
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


        if ($builtInTasks -contains $task.Task.RegistrationInfo.Author) {
            return
        }

        if (-not $task.Task.Actions) {
            Add-Content -Path $errorsFile -Value ("{0} -> No actions found" -f $taskFilePath)
            return
        }

        foreach ($action in $task.Task.Actions.Exec) {
            $command = $action.Command
            $arguments = $action.Arguments
            
            $existingTasks.Remove($taskFilePath)

            if ($command) {
                Add-Content -Path $commandsFile -Value ("{0} -> {1}" -f $taskFilePath, $command)
            }

            if ($arguments) {
                Add-Content -Path $argumentsFile -Value ("{0} -> {1}" -f $taskFilePath, $arguments)
            }


            if ($command -match '\.exe$') {
                Write-Host ("{0} -> Executable: {1}" -f $taskFilePath, $command) -ForegroundColor Blue
            } elseif ($command -match '\.(py|bat|cmd|ps1)$') {
                Write-Host ("{0} -> Script file detected: {1}" -f $taskFilePath, $command) -ForegroundColor Magenta
                Add-Content -Path $detectionsFile -Value ("{0} -> Detected script file: {1}" -f $taskFilePath, $command)
            } else {
                Write-Host ("{0} -> Non-.exe action: {1}" -f $taskFilePath, $command) -ForegroundColor Red
            }

            foreach ($keyword in $suspiciousKeywords) {
                $regex = "\b$keyword\b"
                if ($command -match $regex -or $arguments -match $regex) {
                    Add-Content -Path $detectionsFile -Value ("{0} -> Detected keyword: {1}" -f $taskFilePath, $keyword)
                }
            }
        }
    } catch {
        Add-Content -Path $errorsFile -Value ("Error processing {0}: {1}" -f $taskFilePath, $_.Exception.Message)
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
    Add-Content -Path $deletedFile -Value ("Deleted task: {0}" -f $taskName)
}

Write-Host "`nScan complete! Processed $counter tasks." -ForegroundColor Green
Write-Host "Results saved in $resultsDir."
