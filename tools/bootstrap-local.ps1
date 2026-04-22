param(
  [switch]$SkipDocker
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$python = if (Get-Command py -ErrorAction SilentlyContinue) { "py" } elseif (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { throw "Python was not found in PATH." }
$venvPath = Join-Path $projectRoot ".venv"
$workbookPath = Join-Path $projectRoot "docs\\Education_Management_Dataset.xlsx"
$exportsPath = Join-Path $projectRoot "docs\\assets\\exports"

if (-not (Test-Path -LiteralPath $workbookPath)) {
  throw "Workbook not found at docs/Education_Management_Dataset.xlsx"
}

if (-not (Test-Path -LiteralPath $venvPath)) {
  & $python -m venv $venvPath
}

$venvPython = Join-Path $venvPath "Scripts\\python.exe"
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r (Join-Path $projectRoot "requirements.txt")
& $venvPython (Join-Path $projectRoot "tools\\build-fvsd-prepared-exports.py")

Write-Host "Prepared exports generated in docs/assets/exports"

if (-not $SkipDocker) {
  docker compose up -d
  Write-Host "Local stack started. Open http://localhost:3000"
}
