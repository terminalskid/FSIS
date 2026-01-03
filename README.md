# FSIS

**Full Software Inventory Script**

FSIS is a PowerShell script that generates a **near-complete inventory of software installed on a Windows system** — including traditional installers, winget apps, Microsoft Store apps, and portable tools that don’t register themselves (like Ghidra).

Designed for:

- fresh OS rebuilds
- backup & restore workflows
- software migration
- automation tools like iMySoftware

No logins.
No telemetry.
No tracking.

---

## What FSIS Detects

FSIS merges **multiple sources** to get as close as possible to “everything installed”.

### Included

- Registry-installed applications (32-bit & 64-bit)
- `winget` installed software
- Microsoft Store apps (non-system only)
- Portable / extracted tools (no installer)
- Custom tool folders (reverse engineering, dev tools, etc.)

### Excluded

- Built-in Windows components
- System AppX packages
- Drivers
- Redistributables, runtimes, updaters (filtered)

> ⚠️ Note: Windows has no single authoritative list of installed software. FSIS is intentionally multi-source to cover real-world setups.

---

## Output

FSIS generates a **JSON file** containing all detected software.

Example entry:

```json
{
  "Name": "Ghidra",
  "Version": "",
  "Source": "Portable",
  "Path": "C:\\Reverse\\ghidra"
}
```

This format is ideal for:

- reinstallation scripts
- inventory tracking
- feeding into other tools (like iMySoftware)

---

## Usage

### 1. Download

```powershell
git clone https://github.com/terminalskid/FSIS
cd FSIS
```

Or just grab `fsis.ps1`.

---

### 2. Run

```powershell
.\fsis.ps1
```
```irm https://raw.githubusercontent.com/terminalskid/FSIS/main/fsis.ps1 | iex -FSIS
```

If PowerShell blocks execution:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

---

### 3. Output File

The script saves output as:

```
installed_apps_YYYY-MM-DD_HH-MM.json
```

in the current directory.

---

## Optional: POST Results to an API

FSIS supports sending the inventory to an external endpoint.

Inside the script, uncomment and set:

```powershell
$endpoint = "https://your-api.example/upload"
Invoke-RestMethod -Uri $endpoint -Method POST `
  -Body ($final | ConvertTo-Json -Depth 4) `
  -ContentType "application/json"
```

---

## Portable App Detection

FSIS scans common locations for tools that do not register themselves:

- Desktop
- Downloads
- `C:\Tools`
- `C:\Reverse`
- Program Files directories

A folder is considered an app if it contains:

- `.exe`
- `.bat`
- `.ps1`

You can customize scan paths directly in the script.

---

## Limitations (Honest Ones)

FSIS cannot guarantee 100% detection if:

- a tool has no executable
- a folder was renamed arbitrarily
- software lives in uncommon locations

That’s a Windows limitation, not a script bug.

In practice, FSIS captures **~90–95% of real-world setups**.

---

## Use Cases

- Export your current system before reinstalling Windows
- Rebuild a dev / RE environment quickly
- Generate install scripts automatically
- Feed inventory data into custom installers
- Audit machines without invasive software

---

## Security & Privacy

- Runs locally
- No network calls by default
- No telemetry
- No persistence

---

## Related Projects

- **iMySoftware** – software installation hub (planned FSIS import support)
- Winget
- Chocolatey (future support)
