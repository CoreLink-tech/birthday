param(
  [string]$EnvFile = ".env",
  [string]$OutputFile = "supabase-config.js"
)

function Read-EnvFile {
  param([string]$Path)

  $values = @{}

  if (-not (Test-Path -LiteralPath $Path)) {
    return $values
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()

    if (-not $trimmed -or $trimmed.StartsWith("#")) {
      continue
    }

    $parts = $trimmed -split "=", 2
    if ($parts.Count -ne 2) {
      continue
    }

    $name = $parts[0].Trim()
    $value = $parts[1].Trim()

    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
      $value = $value.Substring(1, $value.Length - 2)
    }

    $values[$name] = $value
  }

  return $values
}

$config = Read-EnvFile -Path $EnvFile

foreach ($name in @("SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_BUCKET")) {
  $envValue = (Get-Item -Path "Env:$name" -ErrorAction SilentlyContinue).Value
  if ($envValue) {
    $config[$name] = $envValue
  }
}

if (-not $config["SUPABASE_URL"]) {
  throw "Missing SUPABASE_URL. Set it in .env or your shell environment."
}

if (-not $config["SUPABASE_ANON_KEY"]) {
  throw "Missing SUPABASE_ANON_KEY. Set it in .env or your shell environment."
}

if (-not $config["SUPABASE_BUCKET"]) {
  $config["SUPABASE_BUCKET"] = "photos"
}

$payload = @{
  url = $config["SUPABASE_URL"]
  anonKey = $config["SUPABASE_ANON_KEY"]
  bucket = $config["SUPABASE_BUCKET"]
} | ConvertTo-Json -Compress

$output = @(
  "window.SUPABASE_CONFIG = Object.freeze($payload);",
  ""
) -join [Environment]::NewLine

Set-Content -LiteralPath $OutputFile -Value $output -Encoding UTF8
Write-Host "Wrote $OutputFile from $EnvFile"
