$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TaskName = "ResthomeServer"

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

function Install-Rest {
    Write-Host "`nInstalling..." -ForegroundColor Cyan
    
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Error: This script must be run as Administrator." -ForegroundColor Red
        Pause
        return
    }

    $PythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $PythonExe) { $PythonExe = (Get-Command py -ErrorAction SilentlyContinue).Source }
    if (-not $PythonExe) {
        Write-Host "Error: Python not found." -ForegroundColor Red
        Pause
        return
    }

    $Action = New-ScheduledTaskAction -Execute $PythonExe -Argument "-m http.server 8000" -WorkingDirectory $ScriptDir
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force | Out-Null

    $HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (-not (Select-String -Path $HostsPath -Pattern "rest.home" -Quiet)) {
        Add-Content -Path $HostsPath -Value "`r`n127.0.0.1 rest.home"
    }

    Start-ScheduledTask -TaskName $TaskName
    Write-Host "✓ Installation complete! Go to http://rest.home:8000" -ForegroundColor Green
    Pause
}

function Start-Rest {
    Write-Host "`nStarting server..." -ForegroundColor Cyan
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "✓ Server started." -ForegroundColor Green
    Pause
}

function Stop-Rest {
    Write-Host "`nStopping server..." -ForegroundColor Cyan
    Stop-ScheduledTask -TaskName $TaskName
    Write-Host "✓ Server stopped." -ForegroundColor Green
    Pause
}

function Status-Rest {
    Write-Host "`nServer status:" -ForegroundColor Cyan
    $State = (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue).State
    if ($State -eq "Running") { Write-Host "Active." -ForegroundColor Green } 
    elseif ($State) { Write-Host "Ready (not running)." -ForegroundColor Yellow }
    else { Write-Host "Not installed." -ForegroundColor Red }
    Pause
}

function Uninstall-Rest {
    Write-Host "`nUninstalling..." -ForegroundColor Red
    
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Error: This script must be run as Administrator." -ForegroundColor Red
        Pause
        return
    }

    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    
    $HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $Content = Get-Content $HostsPath | Where-Object { $_ -notmatch "rest.home" }
    Set-Content -Path $HostsPath -Value $Content

    Write-Host "✓ Uninstallation complete." -ForegroundColor Green
    Pause
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