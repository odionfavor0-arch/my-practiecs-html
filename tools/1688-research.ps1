# Runs 1688-cli searches for every candidate in product-research.html,
# then pulls full price tiers for the top offers of each search.
#
# Usage (PowerShell, logged in to 1688.cmd already):
#   powershell -ExecutionPolicy Bypass -File .\1688-research.ps1
#   powershell -ExecutionPolicy Bypass -File .\1688-research.ps1 -Max 10 -Detail 3
#
# Output: .\1688-research\<product>\search.json and offers.json, zipped to
# .\1688-research.zip. Send the zip back to Claude to fill in the sheet.

param(
  [int]$Max = 10,     # listings per search
  [int]$Detail = 5,   # how many of those to fetch full price tiers for
  [int]$PauseSec = 3  # gap between calls so 1688 doesn't throttle
)

[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"

$candidates = [ordered]@{
  "scalp-massager" = "电动头皮按摩器"
  "star-projector" = "星空投影灯"
  "uv-toothbrush"  = "紫外线牙刷消毒器"
  "neck-fan"       = "挂脖风扇"
  "lint-remover"   = "毛球修剪器"
  "blender"        = "便携榨汁杯"
  "heatless-curler"= "懒人卷发棒"
  "car-vacuum"     = "车载吸尘器 无线"
}

$root = Join-Path (Get-Location) "1688-research"
New-Item -ItemType Directory -Force -Path $root | Out-Null

function Invoke-1688 {
  param([string[]]$CliArgs)
  for ($try = 1; $try -le 2; $try++) {
    $out = & 1688.cmd @CliArgs 2>&1 | Out-String
    if ($out -match "DAEMON_PAUSED|Another 1688 command is running") {
      Write-Host "  daemon busy, reloading..." -ForegroundColor Yellow
      & 1688.cmd daemon reload --profile default | Out-Null
      Start-Sleep -Seconds 5
      continue
    }
    return $out
  }
  return $out
}

foreach ($slug in $candidates.Keys) {
  $kw = $candidates[$slug]
  $dir = Join-Path $root $slug
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Write-Host "== $slug ($kw)" -ForegroundColor Cyan

  $raw = Invoke-1688 @("search", $kw, "--max", "$Max", "--json")
  $raw | Out-File -Encoding utf8 (Join-Path $dir "search.json")

  try { $ids = @(($raw | ConvertFrom-Json).offers.offerId) | Select-Object -First $Detail }
  catch { Write-Host "  search output wasn't JSON, see search.json" -ForegroundColor Red; continue }
  Write-Host "  $($ids.Count) offers to detail"

  $details = @()
  foreach ($id in $ids) {
    Start-Sleep -Seconds $PauseSec
    $o = Invoke-1688 @("offer", "$id", "--json")
    try { $details += ($o | ConvertFrom-Json) }
    catch { $details += [pscustomobject]@{ offerId = "$id"; error = $o.Trim() } }
  }
  ConvertTo-Json -InputObject $details -Depth 30 | Out-File -Encoding utf8 (Join-Path $dir "offers.json")
  Start-Sleep -Seconds $PauseSec
}

$zip = Join-Path (Get-Location) "1688-research.zip"
Compress-Archive -Path $root -DestinationPath $zip -Force
Write-Host "Done: $zip" -ForegroundColor Green
