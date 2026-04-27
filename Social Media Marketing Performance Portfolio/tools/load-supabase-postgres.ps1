param(
  [string]$ConnectionString = $env:SUPABASE_DB_URL,
  [string]$Schema = "social_media_marketing",
  [switch]$Clean
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ConnectionString)) {
  throw "Pass -ConnectionString or set SUPABASE_DB_URL."
}

if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
  throw "psql was not found on PATH."
}

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$exportsDir = Join-Path $projectRoot "docs\assets\exports"
$schemaSqlPath = Join-Path $projectRoot "postgres\sql\01-schema-and-load.sql"
$viewsSqlPath = Join-Path $projectRoot "postgres\sql\02-analytics-views.sql"

function Format-SqlIdentifier {
  param([string]$Name)
  '"' + ($Name -replace '"', '""') + '"'
}

function Format-CopyPath {
  param([string]$Path)
  ($Path -replace "\\", "/") -replace "'", "''"
}

$copyFiles = @(
  @{ table = "dim_platform"; file = "dim-platform.csv" },
  @{ table = "dim_region"; file = "dim-region.csv" },
  @{ table = "dim_content"; file = "dim-content.csv" },
  @{ table = "dim_hashtag"; file = "dim-hashtag.csv" },
  @{ table = "fact_social_post_performance"; file = "fact-social-post-performance.csv" },
  @{ table = "mart_platform_performance"; file = "mart-platform-performance.csv" },
  @{ table = "mart_region_content_performance"; file = "mart-region-content-performance.csv" },
  @{ table = "mart_posting_time_performance"; file = "mart-posting-time-performance.csv" },
  @{ table = "mart_hashtag_performance"; file = "mart-hashtag-performance.csv" },
  @{ table = "mart_content_type_comparison"; file = "mart-content-type-comparison.csv" },
  @{ table = "mart_video_live_region_performance"; file = "mart-video-live-region-performance.csv" },
  @{ table = "mart_correlation_inputs"; file = "mart-correlation-inputs.csv" }
)

foreach ($copy in $copyFiles) {
  $path = Join-Path $exportsDir $copy.file
  if (-not (Test-Path $path)) { throw "Missing export: $path" }
}

$schemaId = Format-SqlIdentifier $Schema
$schemaBody = Get-Content -Raw $schemaSqlPath
$schemaBody = [regex]::Replace($schemaBody, '(?m)^\s*drop schema if exists public cascade;\s*\r?\n?', '')
$schemaBody = [regex]::Replace($schemaBody, '(?m)^\s*create schema public;\s*\r?\n?', '')
$schemaBody = [regex]::Replace($schemaBody, '(?m)^\s*copy .+;\s*\r?\n?', '')

$viewsBody = Get-Content -Raw $viewsSqlPath
$tempSql = Join-Path ([System.IO.Path]::GetTempPath()) ("social-media-supabase-load-" + [guid]::NewGuid() + ".sql")

try {
  $sql = New-Object System.Collections.Generic.List[string]
  $sql.Add("\set ON_ERROR_STOP on")
  if ($Clean) { $sql.Add("drop schema if exists $schemaId cascade;") }
  $sql.Add("create schema if not exists $schemaId;")
  $sql.Add("set search_path to $schemaId, public;")
  $sql.Add($schemaBody)

  foreach ($copy in $copyFiles) {
    $path = Format-CopyPath (Join-Path $exportsDir $copy.file)
    $sql.Add("\copy $($copy.table) from '$path' with (format csv, header true);")
  }

  $sql.Add("set search_path to $schemaId, public;")
  $sql.Add($viewsBody)
  $sql.Add("select 'fact_rows' as check_name, count(*) as check_value from fact_social_post_performance;")
  $sql.Add("select 'correlation_rows' as check_name, count(*) as check_value from mart_correlation_inputs;")

  Set-Content -LiteralPath $tempSql -Value ($sql -join [Environment]::NewLine) -Encoding UTF8
  & psql $ConnectionString -v ON_ERROR_STOP=1 -f $tempSql
  if ($LASTEXITCODE -ne 0) { throw "psql failed with exit code $LASTEXITCODE." }
} finally {
  if (Test-Path $tempSql) { Remove-Item -LiteralPath $tempSql -Force }
}
