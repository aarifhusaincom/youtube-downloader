$ErrorActionPreference = "Stop"

function Show-ProgressBar($percent, $frame) {
    $barLength = 30
    $filled = [math]::Round(($percent / 100) * $barLength)
    $empty = $barLength - $filled

    $spinner = @("|","/","-","\")
    $spin = $spinner[$frame % 4]

    return "$spin [" + ("#" * $filled) + ("-" * $empty) + "]"
}

Write-Host "==============================" -ForegroundColor Cyan
Write-Host "  YouTube Downloader (PRO UI) " -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path "link.txt")) {
    Write-Host "ERROR: link.txt not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

$url = Get-Content "link.txt"

if ([string]::IsNullOrWhiteSpace($url)) {
    Write-Host "ERROR: URL is empty!" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

Write-Host "URL: $url" -ForegroundColor Yellow
Write-Host ""

# node detect (portable)
$env:PATH = "$PWD;$env:PATH"

# yt-dlp process
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "yt-dlp.exe"
$psi.Arguments = "-f `"bv*[height<=1080]+ba/best[height<=1080]`" --recode-video mp4 --merge-output-format mp4 --progress --js-runtimes node -o `"%(title)s.%(ext)s`" `"$url`""
$psi.RedirectStandardOutput = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
$process.Start() | Out-Null

$frame = 0
$mergeStarted = $false

while (-not $process.HasExited) {
    $line = $process.StandardOutput.ReadLine()

    if ($line -match "\[download\]\s+(\d+(\.\d+)?)%\s+of\s+.*?\s+at\s+([\d\.A-Za-z/]+)\s+ETA\s+([\d:]+)") {
        $percent = [double]$matches[1]
        $speed = $matches[3]
        $eta = $matches[4]

        $bar = Show-ProgressBar $percent $frame

        Write-Host "`rDownload $bar " -NoNewline
        Write-Host ("{0,6}%" -f $percent) -ForegroundColor Cyan -NoNewline
        Write-Host " | " -NoNewline
        Write-Host "$speed" -ForegroundColor Green -NoNewline
        Write-Host " | ETA " -NoNewline
        Write-Host "$eta" -ForegroundColor Yellow -NoNewline

        $frame++
    }

    elseif (-not $mergeStarted -and $line -match "\[Merger\]") {
        $mergeStarted = $true

        Write-Host ""
        Write-Host "Starting Merge..." -ForegroundColor Magenta

        for ($i=0; $i -le 100; $i+=5) {
            $bar = Show-ProgressBar $i $frame
            Write-Host "`rMerge    $bar " -NoNewline
            Write-Host ("{0,6}%" -f $i) -ForegroundColor Magenta -NoNewline
            Start-Sleep -Milliseconds 80
            $frame++
        }

        Write-Host ""
        Write-Host "Merge Completed ✔" -ForegroundColor Green
    }

    # ❌ ignore extra ffmpeg spam
    elseif ($line -match "\[ffmpeg\]") {
        continue
    }
}

Write-Host ""
Write-Host "🎉 All Done!" -ForegroundColor Green

Read-Host "Press Enter to exit..."