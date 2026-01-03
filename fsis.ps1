# ===============================
# Full Software Inventory Script
# ===============================

$apps = @()

# ---------- Helper ----------
function Add-App($name, $version, $source, $path) {
    if (![string]::IsNullOrWhiteSpace($name)) {
        $apps += [PSCustomObject]@{
            Name    = $name.Trim()
            Version = $version
            Source  = $source
            Path    = $path
        }
    }
}

# ---------- Registry Installed Apps ----------
$regPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.DisplayName -and !$_.SystemComponent) {
            Add-App $_.DisplayName $_.DisplayVersion "Registry" $_.InstallLocation
        }
    }
}

# ---------- Winget ----------
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget list --source winget | Select-Object -Skip 2 | ForEach-Object {
        if ($_ -match "(.+?)\s{2,}(.+?)\s{2,}(.+?)$") {
            Add-App $matches[1] $matches[3] "Winget" ""
        }
    }
}

# ---------- Microsoft Store (Non-system only) ----------
Get-AppxPackage | Where-Object {
    $_.SignatureKind -ne "System" -and
    $_.Name -notmatch "Microsoft.Windows|Microsoft.VCLibs|Microsoft.NET"
} | ForEach-Object {
    Add-App $_.Name $_.Version "MicrosoftStore" $_.InstallLocation
}

# ---------- Portable Apps Scan ----------
$portableDirs = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Tools",
    "C:\Tools",
    "C:\Reverse",
    "C:\Program Files",
    "C:\Program Files (x86)"
)

foreach ($dir in $portableDirs) {
    if (Test-Path $dir) {
        Get-ChildItem $dir -Directory -Depth 2 -ErrorAction SilentlyContinue | ForEach-Object {
            if (Get-ChildItem $_.FullName -File -Include *.exe,*.bat,*.ps1 -ErrorAction SilentlyContinue) {
                Add-App $_.Name "" "Portable" $_.FullName
            }
        }
    }
}



# ---------- Deduplicate ----------
$final = $apps |
    Sort-Object Name, Version -Unique |
    Where-Object {
        $_.Name -notmatch "Update|Runtime|Redist|Driver"
    }

# ---------- Output ----------
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$outFile = "$PWD\installed_apps_$timestamp.json"
$final | ConvertTo-Json -Depth 4 | Out-File $outFile -Encoding UTF8

Write-Host "Saved inventory to $outFile"

# ---------- OPTIONAL: POST TO API ----------
# Uncomment and set endpoint if needed
# $endpoint = "https://your-api.example/upload"
# Invoke-RestMethod -Uri $endpoint -Method POST -Body ($final | ConvertTo-Json -Depth 4) -ContentType "application/json"
