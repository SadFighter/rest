$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

$TaskName   = "ResthomeServer"
$HostName   = "rest.home"
$Port       = 8000
$ProfileDir = Join-Path $ScriptDir "firefox-setup-profile"
$VenvDir    = Join-Path $ScriptDir ".venv"
$LogFile    = Join-Path $ScriptDir "server.log"
$HostsPath  = "$env:SystemRoot\System32\drivers\etc\hosts"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Si rilancia da solo come Amministratore (serve per hosts + task pianificato)
if (-not (Test-Admin)) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`""
        )
    } catch {
        Write-Host "Error: Administrator privileges are required." -ForegroundColor Red
        Read-Host "Press Enter to exit" | Out-Null
    }
    exit
}

Set-Location $ScriptDir

function Wait-Key {
    Read-Host "Press Enter to return to menu..." | Out-Null
}

function Show-Menu {
    Clear-Host
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "       REST. - Control Menu           " -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "1) Install rest. (Server + Hosts)"
    Write-Host "2) Start server"
    Write-Host "3) Stop server"
    Write-Host "4) Check server status"
    Write-Host "5) Uninstall everything"
    Write-Host "6) Exit"
    Write-Host "======================================" -ForegroundColor Cyan
    $global:Choice = Read-Host "Choose an option [1-6]"
}

# ---------- utilita' ----------

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

function Test-PythonExe($exe) {
    if (-not $exe) { return $false }
    try {
        $out = & $exe --version 2>&1
        return (($LASTEXITCODE -eq 0) -and ("$out" -match "Python 3"))
    } catch {
        return $false
    }
}

function Find-Python {
    foreach ($name in @("python", "py", "python3")) {
        $cmds = Get-Command $name -All -ErrorAction SilentlyContinue
        foreach ($c in $cmds) {
            if ($c.Source -and (Test-PythonExe $c.Source)) { return $c.Source }
        }
    }
    foreach ($p in @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
        "$env:ProgramFiles\Python312\python.exe",
        "$env:ProgramFiles\Python313\python.exe"
    )) {
        if ((Test-Path $p) -and (Test-PythonExe $p)) { return $p }
    }
    return $null
}

function Install-WithWinget($id) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $false }
    winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
    Update-SessionPath
    return $true
}

function Ensure-Python {
    $py = Find-Python
    if (-not $py) {
        Write-Host "Python 3 not found. Installing with winget..." -ForegroundColor Yellow
        Install-WithWinget "Python.Python.3.12" | Out-Null
        $py = Find-Python
    }
    if (-not $py) {
        Write-Host "Error: Python 3 not found and could not be installed. Install it from python.org and try again." -ForegroundColor Red
        return $null
    }

    # Se esiste requirements.txt installa i moduli in un venv dedicato
    $req = Join-Path $ScriptDir "requirements.txt"
    if (Test-Path $req) {
        Write-Host "Installing Python modules from requirements.txt..." -ForegroundColor Cyan
        $venvPy = Join-Path $VenvDir "Scripts\python.exe"
        if (-not (Test-Path $venvPy)) {
            if (Test-Path $VenvDir) { Remove-Item -Recurse -Force $VenvDir -ErrorAction SilentlyContinue }
            & $py -m venv $VenvDir
            if (-not (Test-Path $venvPy)) {
                Write-Host "Error: could not create virtual environment." -ForegroundColor Red
                return $null
            }
        }
        & $venvPy -m pip install --upgrade pip -q
        & $venvPy -m pip install -r $req
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: module installation failed." -ForegroundColor Red
            return $null
        }
        $py = $venvPy
    }
    return $py
}

# ---------- Firefox ----------

function Find-Firefox {
    $candidates = @(
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe",
        "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    foreach ($key in @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe"
    )) {
        $item = Get-ItemProperty $key -ErrorAction SilentlyContinue
        if ($item) {
            $p = $item."(default)"
            if ($p -and (Test-Path $p)) { return $p }
        }
    }
    return $null
}

function Ensure-Firefox {
    $ff = Find-Firefox
    if (-not $ff) {
        Write-Host "Firefox not found. Installing with winget..." -ForegroundColor Yellow
        Install-WithWinget "Mozilla.Firefox" | Out-Null
        $ff = Find-Firefox
    }
    if (-not $ff) {
        Write-Host "Error: Firefox not found and could not be installed. Install it from mozilla.org and try again." -ForegroundColor Red
    }
    return $ff
}

function Write-UserJs {
    $prefs = @(
        'user_pref("browser.shell.checkDefaultBrowser", false);',
        'user_pref("browser.startup.page", 0);',
        'user_pref("browser.startup.homepage_override.mstone", "ignore");',
        'user_pref("startup.homepage_welcome_url", "");',
        'user_pref("startup.homepage_welcome_url.additional", "");',
        'user_pref("browser.aboutwelcome.enabled", false);',
        'user_pref("browser.rights.3.shown", true);',
        'user_pref("browser.tabs.warnOnClose", false);',
        'user_pref("datareporting.policy.dataSubmissionEnabled", false);',
        'user_pref("datareporting.policy.firstRunURL", "");',
        'user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);',
        'user_pref("trailhead.firstrun.didSeeAboutWelcome", true);',
        'user_pref("signon.rememberSignons", false);',
        'user_pref("signon.autofillForms", false);',
        'user_pref("network.trr.mode", 5);',
        'user_pref("network.proxy.type", 0);',
        'user_pref("dom.security.https_only_mode", false);',
        'user_pref("app.update.auto", false);',
        'user_pref("app.update.enabled", false);'
    )
    Set-Content -Path (Join-Path $ProfileDir "user.js") -Value $prefs -Encoding ASCII
}

function Wait-Server([int]$Seconds = 30) {
    $tries = $Seconds * 2
    for ($i = 0; $i -lt $tries; $i++) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $iar = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
            $done = $iar.AsyncWaitHandle.WaitOne(500)
            if ($done -and $client.Connected) { $client.Close(); return $true }
        } catch { }
        try { $client.Close() } catch { }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

function Launch-Setup($FirefoxPath) {
    $url = "http://${HostName}:${Port}/setup.html"
    ipconfig /flushdns | Out-Null
    $useHost = $false
    try {
        $ips = [System.Net.Dns]::GetHostAddresses($HostName) | ForEach-Object { $_.IPAddressToString }
        $useHost = ($ips -contains "127.0.0.1")
    } catch { }
    if (-not $useHost) { $url = "http://127.0.0.1:${Port}/setup.html" }

    # Profilo nuovo e isolato + -no-remote = SEMPRE una nuova finestra Firefox separata,
    # anche se Firefox e' gia' aperto con il profilo normale.
    if (Test-Path $ProfileDir) { Remove-Item -Recurse -Force $ProfileDir -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    Write-UserJs

    Start-Process -FilePath $FirefoxPath -ArgumentList @("-no-remote", "-profile", "`"$ProfileDir`"", "-kiosk", $url)

    # Aspetta che la finestra del setup venga davvero chiusa
    Start-Sleep -Seconds 5
    while ($true) {
        $running = Get-CimInstance Win32_Process -Filter "Name='firefox.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -and $_.CommandLine.Contains($ProfileDir) }
        if (-not $running) { break }
        Start-Sleep -Seconds 1
    }
    Start-Sleep -Seconds 1
    Remove-Item -Recurse -Force $ProfileDir -ErrorAction SilentlyContinue
}

# ---------- azioni menu ----------

function Install-Rest {
    Write-Host "`nInstalling..." -ForegroundColor Cyan

    if (-not (Test-Path (Join-Path $ScriptDir "server.py"))) {
        Write-Host "Error: server.py not found in $ScriptDir" -ForegroundColor Red
        Wait-Key
        return
    }

    $PythonExe = Ensure-Python
    if (-not $PythonExe) { Wait-Key; return }

    $FirefoxPath = Ensure-Firefox
    if (-not $FirefoxPath) { Wait-Key; return }

    # Task pianificato: avvia il server nascosto a ogni logon, con log su file
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $Cmd   = "Set-Location '$ScriptDir'; & '$PythonExe' -u server.py *> '$LogFile'"
    $Enc   = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Cmd))
    $User  = "$env:USERDOMAIN\$env:USERNAME"
    $Action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $Enc" -WorkingDirectory $ScriptDir
    $Trigger   = New-ScheduledTaskTrigger -AtLogOn -User $User
    $Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Limited
    $Settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null

    if (-not (Select-String -Path $HostsPath -Pattern "rest\.home" -Quiet)) {
        Add-Content -Path $HostsPath -Value "`r`n127.0.0.1 rest.home" -Encoding ASCII
    }
    ipconfig /flushdns | Out-Null

    Start-ScheduledTask -TaskName $TaskName

    Write-Host "Waiting for the server..." -ForegroundColor Cyan
    if (-not (Wait-Server 30)) {
        Write-Host "Error: server did not start on port $Port. Last log lines:" -ForegroundColor Red
        if (Test-Path $LogFile) { Get-Content $LogFile -Tail 15 }
        Wait-Key
        return
    }

    Write-Host "[OK] Installation complete!" -ForegroundColor Green
    Write-Host "Launching setup in a new fullscreen Firefox window..." -ForegroundColor Cyan
    Write-Host "(close the setup window with Alt+F4 when you are done)" -ForegroundColor Yellow

    Launch-Setup $FirefoxPath

    Write-Host "`n[OK] Setup complete!" -ForegroundColor Green
    Write-Host "rest. is now available at http://${HostName}:${Port}" -ForegroundColor Cyan
    Wait-Key
}

function Start-Rest {
    Write-Host "`nStarting server..." -ForegroundColor Cyan
    if (-not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
        Write-Host "Not installed. Use option 1 first." -ForegroundColor Red
    } else {
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "[OK] Server started." -ForegroundColor Green
    }
    Wait-Key
}

function Stop-Rest {
    Write-Host "`nStopping server..." -ForegroundColor Cyan
    if (-not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
        Write-Host "Not installed." -ForegroundColor Red
    } else {
        Stop-ScheduledTask -TaskName $TaskName
        Write-Host "[OK] Server stopped." -ForegroundColor Green
    }
    Wait-Key
}

function Status-Rest {
    Write-Host "`nServer status:" -ForegroundColor Cyan
    $State = (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue).State
    if ($State -eq "Running") { Write-Host "Active." -ForegroundColor Green }
    elseif ($State) { Write-Host "Ready (not running)." -ForegroundColor Yellow }
    else { Write-Host "Not installed." -ForegroundColor Red }
    Wait-Key
}

function Uninstall-Rest {
    Write-Host "`nUninstalling..." -ForegroundColor Red

    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    $Content = Get-Content $HostsPath | Where-Object { $_ -notmatch "rest\.home" }
    Set-Content -Path $HostsPath -Value $Content -Encoding ASCII
    ipconfig /flushdns | Out-Null

    foreach ($p in @($ProfileDir, $VenvDir)) {
        if (Test-Path $p) { Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue }
    }

    Write-Host "[OK] Uninstallation complete." -ForegroundColor Green
    Wait-Key
}

while ($true) {
    Show-Menu
    switch ($global:Choice) {
        "1" { Install-Rest }
        "2" { Start-Rest }
        "3" { Stop-Rest }
        "4" { Status-Rest }
        "5" { Uninstall-Rest }
        "6" { Write-Host "Exiting."; exit }
        default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
}
