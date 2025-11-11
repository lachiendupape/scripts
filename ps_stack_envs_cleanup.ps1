# Run: powershell -ExecutionPolicy Bypass -File .\collect-env-vars.ps1

$scanPaths = @(
  "J:\Git\lachiendupape\Stacks",
  "J:\Git\lachiendupape\compose",
  "J:\Git\home-media-stack\stacks",
  "J:\Git\home-media-stack"
) | Where-Object { Test-Path $_ }

$regex = '\$\{([A-Z_][A-Z0-9_]*)'
$vars = @()

foreach ($p in $scanPaths) {
  Get-ChildItem -Path $p -Recurse -Include *.yml,*.yaml,*.env* -File -ErrorAction SilentlyContinue |
    ForEach-Object {
      $c = Get-Content -Raw -Path $_.FullName -ErrorAction SilentlyContinue
      if ($c) {
        [regex]::Matches($c, $regex) | ForEach-Object { $vars += $_.Groups[1].Value }
      }
    }
}

$vars = $vars | Sort-Object -Unique

$homeEnvPath = "J:\Git\home-media-stack\.env"
$existing = @()
if (Test-Path $homeEnvPath) {
  Get-Content $homeEnvPath | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=') { $existing += $Matches[1] }
  }
}

$missing = $vars | Where-Object { $_ -notin $existing }

# write template
$outPath = "J:\Git\home-media-stack\.env.merged"
"## Generated env template: fill values, move secrets to .env.local (gitignored)`n" | Out-File $outPath -Encoding utf8
foreach ($v in $vars) {
  if ($v -in $existing) {
    "$v=`n" | Out-File $outPath -Append -Encoding utf8
  } else {
    "$v=`n" | Out-File $outPath -Append -Encoding utf8
  }
}

Write-Output "Scanned paths: $($scanPaths -join ', ')"
Write-Output "Discovered variables: $($vars.Count)"
Write-Output "Already in .env: $($existing.Count)"
Write-Output "Missing keys: $($missing.Count)"
if ($missing.Count -gt 0) { Write-Output "Missing: $($missing -join ', ')" }
Write-Output "Template written to: $outPath"
Write-Output "Tip: add .env.local for secrets and add it to .gitignore in the home-media-stack folder."