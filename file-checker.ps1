$pFile = "p.txt"
$outputFile = "SignatureResults.html"
if (!(Test-Path $pFile)) {
    Write-Host "p.txt not found." -ForegroundColor Red
    exit
}
$filePaths = Get-Content $pFile | Where-Object { $_ -match "^\w{1}:\\.*" } | Sort-Object -Unique
function Check-Signature {
    param ([string]$filePath)
    
    try {
        $signature = Get-AuthenticodeSignature -FilePath $filePath -ErrorAction Stop
        if ($signature.Status -eq 'Valid') {
            return "✅ Valid"
        } elseif ($signature.Status -eq 'NotSigned') {
            return "⚠ Not Signed"
        } else {
            return "❌ Invalid"
        }
    } catch {
        return "⚠ Not Signed"
    }
} 
$html = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <title>Signature & File Check - bridgezan</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #0d1117; color: #c9d1d9; text-align: center; }
        h1 { color: #58a6ff; }
        .container { width: 90%; margin: 0 auto; }
        table { width: 100%; margin: 20px 0; border-collapse: collapse; background-color: #161b22; border-radius: 10px; overflow: hidden; }
        th, td { padding: 15px; border-bottom: 1px solid #30363d; text-align: left; cursor: pointer; }
        th { background-color: #21262d; color: #58a6ff; text-transform: uppercase; }
        tr:hover { background-color: #30363d; }
        .valid { color: #3fb950; font-weight: bold; }
        .invalid { color: #f85149; font-weight: bold; }
        .not-signed { color: #f0b400; font-weight: bold; }
        .deleted { color: #f85149; font-weight: bold; }
        .footer { margin-top: 20px; font-size: 14px; color: #8b949e; }
        .footer a { color: #58a6ff; text-decoration: none; }
        .footer a:hover { text-decoration: underline; }
        .message { color: green; }
        .ellipsis { text-overflow: ellipsis; white-space: nowrap; overflow: hidden; max-width: 200px; display: inline-block; }
        .file-name:hover { font-size: 1.1em; transition: font-size 0.2s; }
        tr:hover td { transform: scale(1.05); transition: all 0.2s ease-in-out; }
        .sort-menu { margin: 10px 0; }
        .sort-menu select { padding: 8px; font-size: 16px; border-radius: 5px; }
        .search-bar { margin: 10px 0; }
        .search-bar input { padding: 8px; font-size: 16px; border-radius: 5px; width: 200px; }
    </style>
    <script>
        function copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(function() {
                var message = document.getElementById('copyMessage');
                message.textContent = 'copied!';
                setTimeout(function() { message.textContent = ''; }, 2000);
            });
        }

        function sortTable(columnIndex, isDate = false) {
            var table = document.getElementById("fileTable");
            var rows = Array.from(table.rows).slice(1);
            var sortedRows = rows.sort(function(a, b) {
                var cellA = a.cells[columnIndex].textContent.trim();
                var cellB = b.cells[columnIndex].textContent.trim();
                
                if (isDate) {
                    cellA = new Date(cellA);
                    cellB = new Date(cellB);
                }
                
                return cellA.localeCompare(cellB);
            });
            sortedRows.forEach(function(row) {
                table.appendChild(row);
            });
        }

        function searchFiles() {
            var input = document.getElementById("searchInput").value.toLowerCase();
            var table = document.getElementById("fileTable");
            var rows = table.getElementsByTagName("tr");
            for (var i = 1; i < rows.length; i++) {
                var row = rows[i];
                var cells = row.getElementsByTagName("td");
                var match = false;
                for (var j = 0; j < cells.length; j++) {
                    if (cells[j].textContent.toLowerCase().includes(input)) {
                        match = true;
                        break;
                    }
                }
                if (match) {
                    row.style.display = "";
                } else {
                    row.style.display = "none";
                }
            }
        }
    </script>
</head>
<body>
    <div class="container">
        <h1>File Checker - bridgezan</h1>
        <div class="search-bar">
            <input type="text" id="searchInput" onkeyup="searchFiles()" placeholder="Search for files...">
        </div>
        <div class="sort-menu">
            <label for="sortBy">Sort by: </label>
            <select id="sortBy" onchange="sortTable(this.selectedIndex, this.selectedIndex == 5)">
                <option value="0">File Name</option>
                <option value="1">Path</option>
                <option value="2">Signature</option>
                <option value="3">Drive</option>
                <option value="4">Size</option>
                <option value="5">Last Modified</option>
                <option value="6">Exists</option>
            </select>
        </div>
        <table id="fileTable">
            <thead>
                <tr>
                    <th>File Name</th>
                    <th>Path</th>
                    <th>Signature</th>
                    <th>Drive</th>
                    <th>Size (Bytes)</th>
                    <th>Last Modified</th>
                    <th>Exists</th>
                </tr>
            </thead>
            <tbody>
"@

$checkedCount = 0
$deletedCount = 0
$invalidSignatureCount = 0
foreach ($path in $filePaths) {
    $exists = Test-Path $path
    $status = if ($exists) { Check-Signature -filePath $path } else { "❌ Deleted" }
    $class = if ($status -eq "✅ Valid") { "valid" } elseif ($status -eq "❌ Invalid") { "invalid" } elseif ($status -eq "❌ Deleted") { "deleted" } else { "not-signed" }
    $fileName = [System.IO.Path]::GetFileName($path)
    $drive = if ($exists) { [System.IO.Path]::GetPathRoot($path) } else { "N/A" }
    $size = if ($exists) { (Get-Item $path).Length } else { "N/A" }
    $lastModified = if ($exists) { (Get-Item $path).LastWriteTime } else { "N/A" }
    if ($exists) { $checkedCount++ }
    if ($status -eq "❌ Deleted") { $deletedCount++ }
    if ($status -eq "❌ Invalid") { $invalidSignatureCount++ }
    $html += "<tr onclick='copyToClipboard(`"$fileName`")'>
                <td class='ellipsis file-name $class'>$fileName</td>
                <td class='$class'>$path</td>
                <td class='$class'>$status</td>
                <td class='$class'>$drive</td>
                <td class='$class'>$size</td>
                <td class='$class'>$lastModified</td>
                <td class='$class'>$exists</td>
              </tr>`n"
}
$html += @"
        </tbody>
    </table>
    <div class='message' id='copyMessage'></div>
    <div class='footer'>
        Made by <b>bridgezan</b> | <a href='https://github.com/bridgerzan' target='_blank'>GitHub</a><br>
        <b>$checkedCount</b> files checked, <b>$deletedCount</b> files deleted, <b>$invalidSignatureCount</b> files with invalid signature.
    </div>
</div>
</body>
</html>
"@
$html | Out-File -Encoding UTF8 $outputFile
Start-Process $outputFile
Write-Host "Signature check complete. Results saved to $outputFile check your browser"
Write-Host "codded by bridgezan"
