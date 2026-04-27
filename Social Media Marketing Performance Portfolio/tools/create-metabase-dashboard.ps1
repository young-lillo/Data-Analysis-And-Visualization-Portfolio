param(
  [string]$BaseUrl = "http://localhost:3001",
  [string]$Username,
  [string]$Password,
  [string]$DatabaseName = "Social Media Analytics",
  [int]$DatabaseId = 0,
  [int]$CollectionId = 0,
  [string]$SqlSchema = "",
  [int]$DashboardId = 0,
  [int]$SyncWaitSeconds = 180,
  [switch]$SkipHashtagFilter,
  [switch]$NoDashboardFilters,
  [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

function Invoke-Mb {
  param([string]$Method, [string]$Path, [object]$Body = $null, [hashtable]$Headers = @{})
  $args = @{ Uri = "$BaseUrl$Path"; Method = $Method; Headers = $Headers }
  if ($null -ne $Body) {
    $args.ContentType = "application/json"
    $args.Body = ($Body | ConvertTo-Json -Depth 30 -Compress)
  }
  try {
    Invoke-RestMethod @args
  } catch {
    $detail = ""
    if ($_.Exception.Response) {
      try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $detail = $reader.ReadToEnd()
      } catch {
        $detail = $_.Exception.Message
      }
    }
    throw "Metabase API call failed: $Method $Path. $($_.Exception.Message) $detail"
  }
}

function Format-SqlIdentifier {
  param([string]$Name)
  '"' + ($Name -replace '"', '""') + '"'
}

function Format-NativeQuery {
  param([string]$Query)
  if ($script:NoDashboardFiltersResolved) {
    $Query = [regex]::Replace($Query, '\s*\[\[and\s+\{\{[A-Za-z0-9_]+\}\}\]\]', '')
  } elseif ($script:SkipHashtagFilterResolved) {
    $Query = [regex]::Replace($Query, '\s*\[\[and\s+\{\{main_hashtag\}\}\]\]', '')
  }
  if ([string]::IsNullOrWhiteSpace($SqlSchema)) { return $Query }

  $qualifiedFact = (Format-SqlIdentifier $SqlSchema) + "." + (Format-SqlIdentifier "fact_social_post_performance")
  [regex]::Replace($Query, '(?<![A-Za-z0-9_".])fact_social_post_performance(?![A-Za-z0-9_])', $qualifiedFact)
}

function Get-MetadataTable {
  param([string]$TableName)
  $tables = $script:Metadata.tables | Where-Object { $_.name -eq $TableName }
  if (-not [string]::IsNullOrWhiteSpace($SqlSchema)) {
    $tables | Where-Object { $_.schema -eq $SqlSchema } | Select-Object -First 1
  } else {
    $tables | Select-Object -First 1
  }
}

function Wait-MetadataTable {
  param([string]$TableName)
  $deadline = (Get-Date).AddSeconds($SyncWaitSeconds)
  do {
    $script:Metadata = Invoke-Mb -Method Get -Path "/api/database/$($script:DatabaseId)/metadata" -Headers $script:Auth
    $table = Get-MetadataTable -TableName $TableName
    if ($table) { return $table }
    if ((Get-Date) -lt $deadline) { Start-Sleep -Seconds 5 }
  } while ((Get-Date) -lt $deadline)

  $available = $script:Metadata.tables |
    Select-Object -First 12 @{ Name = "full_name"; Expression = { if ($_.schema) { "$($_.schema).$($_.name)" } else { $_.name } } } |
    ForEach-Object { $_.full_name }
  $schemaHint = if ([string]::IsNullOrWhiteSpace($SqlSchema)) { "no schema filter was passed" } else { "schema '$SqlSchema' was requested" }
  throw "Table '$TableName' not found in Metabase metadata after waiting $SyncWaitSeconds seconds ($schemaHint, database id $script:DatabaseId). In Metabase Admin > Databases, verify database id $script:DatabaseId points to the Supabase project, include schema '$SqlSchema' in schema sync settings, then run Sync database schema. Sample tables visible to Metabase: $($available -join ', ')"
}

function Test-MetadataField {
  param([string]$TableName, [string]$FieldName)
  $table = Get-MetadataTable -TableName $TableName
  if (-not $table) { return $false }
  $null -ne ($table.fields | Where-Object { $_.name -eq $FieldName } | Select-Object -First 1)
}

function Get-FieldId {
  param([string]$TableName, [string]$FieldName)
  $table = Get-MetadataTable -TableName $TableName
  if (-not $table) { $table = Wait-MetadataTable -TableName $TableName }
  $field = $table.fields | Where-Object { $_.name -eq $FieldName } | Select-Object -First 1
  if (-not $field) { throw "Field '$FieldName' not found on '$TableName'." }
  $field.id
}

function New-FieldTag {
  param(
    [string]$Name,
    [string]$DisplayName,
    [string]$TableName,
    [string]$FieldName,
    [string]$WidgetType = "string/="
  )
  @{
    id             = "${Name}_tag"
    name           = $Name
    "display-name" = $DisplayName
    type           = "dimension"
    dimension      = @("field", (Get-FieldId -TableName $TableName -FieldName $FieldName), $null)
    "widget-type"  = $WidgetType
  }
}

function New-NativeCard {
  param([string]$Name, [string]$Description, [string]$Display, [string]$Query, [hashtable]$Tags = @{}, [hashtable]$Viz = @{})
  $formattedQuery = Format-NativeQuery -Query $Query
  Invoke-Mb -Method Post -Path "/api/card" -Headers $script:Auth -Body @{
    name                   = $Name
    description            = $Description
    display                = $Display
    collection_id          = $script:CollectionId
    visualization_settings = $Viz
    dataset_query          = @{
      type     = "native"
      database = $script:DatabaseId
      native   = @{ query = $formattedQuery; "template-tags" = $Tags }
    }
  }
}

function New-ParamMappings {
  param([int]$CardId, [string[]]$Tags)
  $maps = @()
  foreach ($tag in $Tags) {
    $maps += @{ parameter_id = "${tag}_filter"; card_id = $CardId; target = @("dimension", @("template-tag", $tag)) }
  }
  ,$maps
}

function Viz-Bar([string[]]$Dimensions, [string[]]$Metrics, [string]$Stack = $null) {
  $viz = @{ "graph.dimensions" = $Dimensions; "graph.metrics" = $Metrics }
  if ($Stack) { $viz["stackable.stack_type"] = $Stack }
  $viz
}

function New-DashboardParameter {
  param(
    [string]$Name,
    [string]$DisplayName,
    [string]$TableName,
    [string]$FieldName,
    [int]$SourceCardId,
    [int]$Position
  )
  @{
    id                   = "${Name}_filter"
    name                 = $DisplayName
    slug                 = $Name
    type                 = "string/="
    "widget-type"        = "string/="
    sectionId            = "string"
    position             = $Position
    default              = $null
    required             = $false
    isMultiSelect        = $true
    values_query_type    = "list"
    values_source_type   = "card"
    values_source_config = @{
      card_id     = $SourceCardId
      value_field = @("field", (Get-FieldId -TableName $TableName -FieldName $FieldName), @{ "base-type" = "type/Text" })
    }
  }
}

function New-DateDashboardParameter {
  param([string]$Name, [string]$DisplayName, [int]$Position)
  @{
    id        = "${Name}_filter"
    name      = $DisplayName
    slug      = $Name
    type      = "date/all-options"
    sectionId = "date"
    position  = $Position
    required  = $false
  }
}

function Select-Filters {
  param([string[]]$Names)
  $filters = @{}
  foreach ($name in $Names) {
    $filters[$name] = $script:FilterCatalog[$name]
  }
  $filters
}

function Get-ResponseData {
  param([object]$Response)
  if ($null -ne $Response.data) { return @($Response.data) }
  @($Response)
}

function Get-CollectionItems {
  param([int]$CollectionId)
  $items = @()
  foreach ($path in @("/api/collection/$CollectionId/items", "/api/collection/$CollectionId/items?archived=false")) {
    try {
      $items += Get-ResponseData (Invoke-Mb -Method Get -Path $path -Headers $script:Auth)
    } catch {
      Write-Warning "Could not list collection items from $path`: $($_.Exception.Message)"
    }
  }
  $items
}

function Find-CollectionDashboard {
  param([string]$Name)
  $item = Get-CollectionItems -CollectionId $script:CollectionId |
    Where-Object { $_.name -eq $Name -and ($_.model -eq "dashboard" -or $_.type -eq "dashboard" -or $_.model_type -eq "dashboard") } |
    Select-Object -First 1
  if (-not $item) { return $null }
  if ($item.model_id) { return [int]$item.model_id }
  [int]$item.id
}

function Archive-Card {
  param([int]$CardId)
  if ($CardId -le 0) { return }
  try {
    Invoke-Mb -Method Put -Path "/api/card/$CardId" -Headers $script:Auth -Body @{ archived = $true } | Out-Null
  } catch {
    Write-Warning "Could not archive card $CardId`: $($_.Exception.Message)"
  }
}

function Clear-DashboardCards {
  param([int]$DashboardId)
  try {
    $existingDashboard = Invoke-Mb -Method Get -Path "/api/dashboard/$DashboardId" -Headers $script:Auth
    foreach ($dashcard in @($existingDashboard.dashcards)) {
      if ($dashcard.card_id) { Archive-Card -CardId ([int]$dashcard.card_id) }
      elseif ($dashcard.card.id) { Archive-Card -CardId ([int]$dashcard.card.id) }
    }
    Invoke-Mb -Method Put -Path "/api/dashboard/$DashboardId" -Headers $script:Auth -Body @{
      name               = $existingDashboard.name
      description        = $existingDashboard.description
      collection_id      = $script:CollectionId
      tabs               = @()
      parameters         = @()
      dashcards          = @()
      auto_apply_filters = $true
    } | Out-Null
  } catch {
    Write-Warning "Could not clear existing dashboard $DashboardId`: $($_.Exception.Message)"
  }
}

function Archive-CollectionCardsByName {
  param([string[]]$Names)
  $nameSet = @{}
  foreach ($name in $Names) { $nameSet[$name] = $true }
  foreach ($item in Get-CollectionItems -CollectionId $script:CollectionId) {
    $isCard = ($item.model -eq "card" -or $item.type -eq "card" -or $item.model_type -eq "card" -or $item.model -eq "dataset")
    if (-not $isCard -or -not $nameSet.ContainsKey($item.name)) { continue }
    $cardId = if ($item.model_id) { [int]$item.model_id } else { [int]$item.id }
    Archive-Card -CardId $cardId
  }
}

$session = Invoke-Mb -Method Post -Path "/api/session" -Body @{ username = $Username; password = $Password }
$script:Auth = @{ "X-Metabase-Session" = $session.id }
$databases = Invoke-Mb -Method Get -Path "/api/database" -Headers $script:Auth
if ($DatabaseId -gt 0) {
  $db = $databases.data | Where-Object { $_.id -eq $DatabaseId } | Select-Object -First 1
  if (-not $db) { throw "Database id '$DatabaseId' not found in Metabase." }
  $script:DatabaseId = $DatabaseId
} else {
  $db = $databases.data | Where-Object { $_.name -eq $DatabaseName } | Select-Object -First 1
  if (-not $db) { throw "Database '$DatabaseName' not found in Metabase." }
  $script:DatabaseId = $db.id
}
try {
  Invoke-Mb -Method Post -Path "/api/database/$($script:DatabaseId)/sync_schema" -Headers $script:Auth | Out-Null
} catch {
  Write-Warning "Could not trigger Metabase schema sync: $($_.Exception.Message)"
}
$script:Metadata = Invoke-Mb -Method Get -Path "/api/database/$($script:DatabaseId)/metadata" -Headers $script:Auth
$factTable = Wait-MetadataTable -TableName "fact_social_post_performance"
$script:NoDashboardFiltersResolved = [bool]$NoDashboardFilters
if (-not $script:NoDashboardFiltersResolved -and @($factTable.fields).Count -eq 0) {
  $script:NoDashboardFiltersResolved = $true
  Write-Warning "Metabase metadata for fact_social_post_performance has no fields. Creating dashboard without dashboard filters. Run a full Metabase schema sync, then re-run without -NoDashboardFilters to add filters."
}
$script:SkipHashtagFilterResolved = [bool]$SkipHashtagFilter
if (-not $script:NoDashboardFiltersResolved -and -not $script:SkipHashtagFilterResolved -and -not (Test-MetadataField -TableName "fact_social_post_performance" -FieldName "main_hashtag")) {
  $script:SkipHashtagFilterResolved = $true
  Write-Warning "Metabase metadata for fact_social_post_performance does not expose main_hashtag. Creating dashboard without the Hashtag filter. Re-run after a full Metabase schema sync to add it."
}
if ($CollectionId -gt 0) {
  $script:CollectionId = $CollectionId
} else {
  $collection = (Invoke-Mb -Method Get -Path "/api/collection" -Headers $script:Auth) | Where-Object { $_.name -eq "Social Media Marketing Portfolio" } | Select-Object -First 1
  if (-not $collection) { $collection = Invoke-Mb -Method Post -Path "/api/collection" -Headers $script:Auth -Body @{ name = "Social Media Marketing Portfolio"; color = "#509EE3" } }
  $script:CollectionId = $collection.id
}

$dashboardName = "Social Media Marketing Performance"
$dashboardDescription = "Answer what content wins, where it wins, when to publish, and how paid vs organic differs."
$existingDashboardId = if ($DashboardId -gt 0) { $DashboardId } else { Find-CollectionDashboard -Name $dashboardName }
$dashboard = if ($existingDashboardId -gt 0) {
  [pscustomobject]@{ id = $existingDashboardId; name = $dashboardName; description = $dashboardDescription }
} else {
  Invoke-Mb -Method Post -Path "/api/dashboard" -Headers $script:Auth -Body @{
    name          = $dashboardName
    description   = $dashboardDescription
    collection_id = $script:CollectionId
  }
}

$parameters = @()

$script:FilterCatalog = @{
  post_date        = @{ table = 'fact_social_post_performance'; field = 'post_date'; display = 'Date Range'; widget = 'date/all-options' }
  platform         = @{ table = 'fact_social_post_performance'; field = 'platform'; display = 'Platform' }
  country          = @{ table = 'fact_social_post_performance'; field = 'country'; display = 'Country' }
  content_category = @{ table = 'fact_social_post_performance'; field = 'content_category'; display = 'Content Category' }
  post_type        = @{ table = 'fact_social_post_performance'; field = 'post_type'; display = 'Post Type' }
  promotion_type   = @{ table = 'fact_social_post_performance'; field = 'promotion_type'; display = 'Promotion Type' }
  main_hashtag     = @{ table = 'fact_social_post_performance'; field = 'main_hashtag'; display = 'Hashtag' }
}

$AllFilters = if ($script:NoDashboardFiltersResolved) {
  @()
} elseif ($script:SkipHashtagFilterResolved) {
  @('post_date','platform','country','content_category','post_type','promotion_type')
} else {
  @('post_date','platform','country','content_category','post_type','promotion_type','main_hashtag')
}
$CoreFilters = if ($script:NoDashboardFiltersResolved) {
  @()
} else {
  @('post_date','platform','country','content_category','post_type','promotion_type')
}

$cards = @(
  @{ n = "Posts"; desc = "Total post records in the selected filters."; d = "scalar"; r = 0; c = 0; x = 4; y = 3; f = (Select-Filters $AllFilters); q = "select count(*) as posts from fact_social_post_performance where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]"; v = @{} },
  @{ n = "Total Engagement"; desc = "Total engagement in the selected filters."; d = "scalar"; r = 0; c = 4; x = 4; y = 3; f = (Select-Filters $AllFilters); q = "select sum(engagement) as total_engagement from fact_social_post_performance where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]"; v = @{} },
  @{ n = "Total Views"; desc = "Total views in the selected filters."; d = "scalar"; r = 0; c = 8; x = 4; y = 3; f = (Select-Filters $AllFilters); q = "select sum(views) as total_views from fact_social_post_performance where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]"; v = @{} },
  @{ n = "Total Impressions"; desc = "Total impressions in the selected filters."; d = "scalar"; r = 0; c = 12; x = 4; y = 3; f = (Select-Filters $AllFilters); q = "select sum(impressions) as total_impressions from fact_social_post_performance where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]"; v = @{} },
  @{ n = "Avg Engagement Rate"; desc = "Average engagement rate in the selected filters."; d = "scalar"; r = 0; c = 16; x = 4; y = 3; f = (Select-Filters $AllFilters); q = "select round(avg(engagement_rate), 4) as avg_engagement_rate from fact_social_post_performance where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]"; v = @{} },
  @{ n = "Avg CTR"; desc = "Average CTR on click-trackable records in the selected filters."; d = "scalar"; r = 0; c = 20; x = 4; y = 3; f = (Select-Filters $AllFilters); q = "select round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr from fact_social_post_performance where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]"; v = @{} },
  @{ n = "Executive Overview - Analytical Roadmap"; desc = "Maps dashboard sections to the analytical objectives in the project plan."; d = "table"; r = 3; c = 0; x = 24; y = 8; f = @{}; q = @"
select 1 as sort_order, 'Executive Overview' as section, 'Scope, KPI totals, trackable CTR caveat' as decision_use
union all select 2, 'Platform And Format Performance', 'Choose channel allocation and production format mix'
union all select 3, 'Regional Content Strategy', 'Localize content categories by region and country'
union all select 4, 'Metric Optimization', 'Compare metric volatility and inspect outliers'
union all select 5, 'Posting Time Optimization', 'Pick day and hour posting windows by platform'
union all select 6, 'Hashtag Growth Analysis', 'Separate awareness hashtags from traffic hashtags'
union all select 7, 'Video And Live-Stream Trends', 'Decide where richer media investment is justified'
union all select 8, 'Correlation And Driver View', 'Identify directional drivers without claiming causality'
union all select 9, 'Organic Versus Paid', 'Compare reach and efficiency before recommending spend'
union all select 10, 'Strategic Recommendations', 'Convert evidence into planning actions'
order by sort_order
"@; v = @{} },
  @{ n = "Platform Leaderboard - Volume And Efficiency"; desc = "Bar chart for comparing platform engagement volume."; d = "bar"; r = 11; c = 0; x = 12; y = 9; f = (Select-Filters $AllFilters); q = @"
select platform, sum(engagement) as total_engagement
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
group by platform
order by total_engagement desc
"@; v = (Viz-Bar @('platform') @('total_engagement')) },
  @{ n = "Views Versus Engagement By Platform"; desc = "Separates visibility leadership from interaction leadership."; d = "scatter"; r = 13; c = 12; x = 12; y = 9; f = (Select-Filters $AllFilters); q = @"
select platform, sum(views) as total_views, sum(engagement) as total_engagement, round(avg(engagement_rate), 4) as avg_engagement_rate
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
group by platform
order by total_views desc
"@; v = @{ "graph.dimensions" = @("total_views"); "graph.metrics" = @("total_engagement") } },
  @{ n = "Post Type Performance By Platform"; desc = "Compares post formats within each platform."; d = "bar"; r = 22; c = 0; x = 12; y = 9; f = (Select-Filters $CoreFilters); q = @"
select platform, post_type, sum(engagement) as total_engagement
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by platform, post_type
order by platform, total_engagement desc
"@; v = (Viz-Bar @('platform','post_type') @('total_engagement') 'stacked') },
  @{ n = "Post Type Efficiency By Platform"; desc = "Bar chart comparing average engagement rate by format and platform."; d = "bar"; r = 22; c = 12; x = 12; y = 9; f = (Select-Filters $CoreFilters); q = @"
select platform, post_type, round(avg(engagement_rate), 4) as avg_engagement_rate
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by platform, post_type
having count(*) >= 5
order by avg_engagement_rate desc nulls last
"@; v = (Viz-Bar @('platform','post_type') @('avg_engagement_rate')) },
  @{ n = "Region By Content Category Matrix"; desc = "Identifies content categories that work best by geography."; d = "bar"; r = 31; c = 0; x = 12; y = 10; f = (Select-Filters $CoreFilters); q = @"
select region, content_category, sum(engagement) as total_engagement
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by region, content_category
order by region, total_engagement desc
"@; v = (Viz-Bar @('region','content_category') @('total_engagement') 'stacked') },
  @{ n = "Regional Category Lift Versus Baseline"; desc = "Bar chart showing category lift by region."; d = "bar"; r = 31; c = 12; x = 12; y = 10; f = (Select-Filters $CoreFilters); q = @"
with filtered as (
  select * from fact_social_post_performance
  where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
), baseline as (
  select avg(engagement_rate) as baseline_engagement_rate from filtered
)
select region, content_category, round(avg(engagement_rate) - baseline.baseline_engagement_rate, 4) as engagement_rate_lift
from filtered cross join baseline
group by region, content_category, baseline.baseline_engagement_rate
having count(*) >= 5
order by engagement_rate_lift desc nulls last
limit 50
"@; v = (Viz-Bar @('region','content_category') @('engagement_rate_lift')) },
  @{ n = "Regional CTR And Engagement Comparison"; desc = "Scatter chart comparing CTR and engagement rate by country/platform."; d = "scatter"; r = 41; c = 0; x = 12; y = 9; f = (Select-Filters $CoreFilters); q = @"
select country || ' - ' || platform as segment, round(avg(click_through_rate) filter (where is_click_trackable), 4) as avg_ctr, round(avg(engagement_rate), 4) as avg_engagement_rate
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by region, country, platform
order by avg_ctr desc nulls last
"@; v = @{ "graph.dimensions" = @("avg_ctr"); "graph.metrics" = @("avg_engagement_rate") } },
  @{ n = "Metric Optimization And Outlier Posts"; desc = "Scatter chart for high-efficiency posts using engagement rate and CTR."; d = "scatter"; r = 41; c = 12; x = 12; y = 9; f = (Select-Filters $AllFilters); q = @"
select post_row_id, round(engagement_rate, 4) as engagement_rate, round(click_through_rate, 4) as ctr, impressions
from fact_social_post_performance
where impressions > 0 and is_click_trackable is true [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
order by impressions desc
limit 250
"@; v = @{ "graph.dimensions" = @("engagement_rate"); "graph.metrics" = @("ctr") } },
  @{ n = "Day And Hour Engagement Heatmap"; desc = "Line chart showing engagement-rate pattern by posting hour and day."; d = "line"; r = 50; c = 0; x = 12; y = 10; f = (Select-Filters $CoreFilters); q = @"
select post_hour, published_day_of_week, min(published_day_sort) as published_day_sort, round(avg(engagement_rate), 4) as avg_engagement_rate
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by published_day_of_week, published_day_sort, post_hour
having count(*) >= 5
order by published_day_sort, post_hour
"@; v = @{ "graph.dimensions" = @("post_hour","published_day_of_week"); "graph.metrics" = @("avg_engagement_rate") } },
  @{ n = "Best Posting Hour By Platform"; desc = "Ranks high-sample hours for publishing recommendations."; d = "line"; r = 50; c = 12; x = 12; y = 10; f = (Select-Filters $CoreFilters); q = @"
select post_hour, platform, round(avg(engagement_rate), 4) as avg_engagement_rate
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by post_hour, platform
having count(*) >= 5
order by post_hour, platform
"@; v = @{ "graph.dimensions" = @("post_hour","platform"); "graph.metrics" = @("avg_engagement_rate") } },
  @{ n = "Hashtag Growth Leaderboard"; desc = "Bar chart ranking hashtags by impressions."; d = "bar"; r = 60; c = 0; x = 12; y = 10; f = (Select-Filters $AllFilters); q = @"
select main_hashtag, sum(impressions) as total_impressions
from fact_social_post_performance
where main_hashtag is not null [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
group by main_hashtag
having count(*) >= 10
order by total_impressions desc
limit 50
"@; v = (Viz-Bar @('main_hashtag') @('total_impressions')) },
  @{ n = "Top Hashtags By Impressions"; desc = "Awareness-oriented hashtag choices."; d = "bar"; r = 60; c = 12; x = 12; y = 10; f = (Select-Filters $AllFilters); q = @"
select main_hashtag, sum(impressions) as total_impressions
from fact_social_post_performance
where main_hashtag is not null [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
group by main_hashtag
having count(*) >= 10
order by total_impressions desc
limit 12
"@; v = (Viz-Bar @('main_hashtag') @('total_impressions')) },
  @{ n = "Video And Live Stream Interest By Region"; desc = "Compares regional demand for video and live-stream content."; d = "bar"; r = 70; c = 0; x = 12; y = 10; f = (Select-Filters $CoreFilters); q = @"
select region, platform, sum(video_views) as total_video_views, sum(live_stream_views) as total_live_stream_views
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by region, platform
order by total_video_views desc
"@; v = (Viz-Bar @('region','platform') @('total_video_views') 'stacked') },
  @{ n = "Video Versus Non-Video Performance"; desc = "Bar chart comparing video and non-video engagement rate."; d = "bar"; r = 70; c = 12; x = 12; y = 10; f = (Select-Filters $CoreFilters); q = @"
select platform, case when is_video_post then 'Video' else 'Non-video' end as media_group, round(avg(engagement_rate), 4) as avg_engagement_rate
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by platform, media_group
having count(*) >= 5
order by platform, avg_engagement_rate desc nulls last
"@; v = (Viz-Bar @('platform','media_group') @('avg_engagement_rate')) },
  @{ n = "Correlation Summary"; desc = "Directional numeric relationships; correlation does not prove causation."; d = "table"; r = 80; c = 0; x = 12; y = 9; f = (Select-Filters $AllFilters); q = @"
with filtered as (
  select * from fact_social_post_performance
  where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
)
select 'views vs engagement' as relationship, round(corr(views, engagement)::numeric, 4) as correlation, count(*) as rows_used from filtered
union all select 'impressions vs engagement', round(corr(impressions, engagement)::numeric, 4), count(*) from filtered
union all select 'clicks vs engagement', round(corr(clicks, engagement)::numeric, 4), count(clicks) from filtered where clicks is not null
union all select 'CTR vs engagement rate', round(corr(click_through_rate, engagement_rate)::numeric, 4), count(click_through_rate) from filtered where click_through_rate is not null
union all select 'posting hour vs engagement rate', round(corr(post_hour, engagement_rate)::numeric, 4), count(*) from filtered
union all select 'video views vs engagement', round(corr(video_views, engagement)::numeric, 4), count(*) from filtered
"@; v = @{} },
  @{ n = "How to Read Correlation Summary"; desc = "Plain-English guide for interpreting the correlation table."; d = "table"; r = 89; c = 0; x = 12; y = 6; f = @{}; q = @"
select 'correlation' as metric, 'A score from -1 to 1 that summarizes how two numeric metrics move together.' as meaning, 'Closer to 1 means they tend to increase together; close to 0 means no clear linear relationship; closer to -1 means one tends to decrease as the other increases.' as how_to_interpret, 'Correlation is directional evidence only. It does not prove one metric caused another.' as caveat
union all
select 'rows_used', 'Number of rows included in that correlation calculation.', 'Use this to judge whether the relationship has enough sample support.', 'CTR and clicks use fewer rows because many posts are not click-trackable.'
union all
select 'relationship', 'The two metrics being compared, such as views vs engagement.', 'Read each row as a separate analytical question.', 'Compare relationships within the same filtered dashboard context.'
"@; v = @{} },
  @{ n = "Categorical Driver Lift"; desc = "Bar chart comparing driver lift against baseline."; d = "bar"; r = 80; c = 12; x = 12; y = 9; f = (Select-Filters $AllFilters); q = @"
with filtered as (
  select * from fact_social_post_performance
  where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
), baseline as (select avg(engagement_rate) as base_rate from filtered),
drivers as (
  select 'platform' as driver_type, platform as driver_value, count(*) as posts, avg(engagement_rate) as avg_engagement_rate from filtered group by platform
  union all select 'content_category', content_category, count(*), avg(engagement_rate) from filtered group by content_category
  union all select 'post_type', post_type, count(*), avg(engagement_rate) from filtered group by post_type
  union all select 'promotion_type', promotion_type, count(*), avg(engagement_rate) from filtered group by promotion_type
  union all select 'posting_day', published_day_of_week, count(*), avg(engagement_rate) from filtered group by published_day_of_week
)
select driver_type || ': ' || driver_value as driver, round(avg_engagement_rate - base_rate, 4) as engagement_rate_lift
from drivers cross join baseline
where posts >= 10
order by engagement_rate_lift desc nulls last
limit 60
"@; v = (Viz-Bar @('driver') @('engagement_rate_lift')) },
  @{ n = "Organic Versus Paid Performance"; desc = "Bar chart comparing paid and organic engagement rate by platform."; d = "bar"; r = 95; c = 0; x = 12; y = 9; f = (Select-Filters $CoreFilters); q = @"
select promotion_type, platform, round(avg(engagement_rate), 4) as avg_engagement_rate
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by promotion_type, platform
order by platform, promotion_type
"@; v = (Viz-Bar @('platform','promotion_type') @('avg_engagement_rate')) },
  @{ n = "Paid Versus Organic Reach By Platform"; desc = "Shows where promotion changes distribution volume."; d = "bar"; r = 95; c = 12; x = 12; y = 9; f = (Select-Filters $CoreFilters); q = @"
select platform, promotion_type, sum(impressions) as total_impressions
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]]
group by platform, promotion_type
order by platform, promotion_type
"@; v = (Viz-Bar @('platform','promotion_type') @('total_impressions') 'stacked') },
  @{ n = "Strategic Recommendations"; desc = "Evidence-linked actions for content planning, regional strategy, timing, and paid support."; d = "table"; r = 104; c = 0; x = 24; y = 10; f = (Select-Filters $AllFilters); q = @"
with filtered as (
  select * from fact_social_post_performance
  where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
), top_platform as (
  select platform, sum(engagement) as total_engagement from filtered group by platform order by total_engagement desc limit 1
), top_format as (
  select post_type, round(avg(engagement_rate), 4) as avg_engagement_rate from filtered group by post_type having count(*) >= 10 order by avg_engagement_rate desc limit 1
), top_hashtag as (
  select main_hashtag, sum(impressions) as total_impressions from filtered where main_hashtag is not null group by main_hashtag having count(*) >= 10 order by total_impressions desc limit 1
), top_time as (
  select published_day_of_week, post_hour, round(avg(engagement_rate), 4) as avg_engagement_rate from filtered group by published_day_of_week, post_hour having count(*) >= 5 order by avg_engagement_rate desc limit 1
)
select 'Platform allocation' as finding, 'Top engagement platform is ' || coalesce((select platform from top_platform), 'n/a') as evidence, 'Concentrate community-led activity where interaction is already strongest.' as business_implication, 'Prioritize experiments and publishing cadence on this platform, then compare with views leadership.' as recommended_action, 'Platform totals are not causal and depend on posting volume.' as risk_or_caveat
union all select 'Format investment', 'Best sampled format by engagement rate is ' || coalesce((select post_type from top_format), 'n/a'), 'Production effort should follow efficient formats, not only high-volume formats.', 'Shift creative production toward the format leader and monitor CTR impact.', 'Requires minimum sample size and platform-specific review.'
union all select 'Timing window', 'Best sampled time is ' || coalesce((select published_day_of_week || ' ' || post_hour || ':00' from top_time), 'n/a'), 'Posting schedule can improve interaction without new budget.', 'Use the timing heatmap as the first content calendar draft.', 'Timezone is inherited from source timestamp assumptions.'
union all select 'Hashtag strategy', 'Top awareness hashtag is ' || coalesce((select main_hashtag from top_hashtag), 'n/a'), 'Separate awareness tags from click-driving tags.', 'Reuse top awareness tags for reach campaigns and test CTR tags separately.', 'Only one main hashtag is available per row.'
union all select 'Paid support', 'Paid and organic are compared by reach, CTR, and efficiency in section 9.', 'Promotion should support proven content rather than compensate for weak content.', 'Promote formats and regions that already show organic efficiency.', 'Incremental lift is not directly measured in this dataset.'
"@; v = @{} },
  @{ n = "Post Detail Drilldown"; desc = "Detailed post-level table used for filter values and outlier investigation."; d = "table"; r = 114; c = 0; x = 24; y = 12; f = (Select-Filters $AllFilters); q = @"
select platform, region, country, scope_segment, promotion_type, content_category, post_type, main_hashtag, post_date, engagement, views, impressions, clicks, click_through_rate, engagement_rate, video_views, live_stream_views
from fact_social_post_performance
where 1=1 [[and {{post_date}}]] [[and {{platform}}]] [[and {{country}}]] [[and {{content_category}}]] [[and {{post_type}}]] [[and {{promotion_type}}]] [[and {{main_hashtag}}]]
order by post_date desc, engagement desc
limit 250
"@; v = @{} }
)

if (-not $SkipCleanup) {
  Clear-DashboardCards -DashboardId ([int]$dashboard.id)
  Archive-CollectionCardsByName -Names @($cards | ForEach-Object { $_.n })
}

$dashcards = @()
$tempId = -1
$script:FilterValueSourceCardId = $null
foreach ($spec in $cards) {
  $tags = @{}
  if (-not $script:NoDashboardFiltersResolved) {
    foreach ($name in $spec.f.Keys) {
      $def = $spec.f[$name]
      $widgetType = if ($def.widget) { $def.widget } else { "string/=" }
      $tags[$name] = New-FieldTag -Name $name -DisplayName $def.display -TableName $def.table -FieldName $def.field -WidgetType $widgetType
    }
  }
  $card = New-NativeCard -Name $spec.n -Description $spec.desc -Display $spec.d -Query $spec.q -Tags $tags -Viz $spec.v
  if ($spec.n -eq "Post Detail Drilldown") {
    $script:FilterValueSourceCardId = $card.id
  }
  $dashcard = @{
    id                     = $tempId
    card_id                = $card.id
    row                    = $spec.r
    col                    = $spec.c
    size_x                 = $spec.x
    size_y                 = $spec.y
    visualization_settings = New-Object PSObject
  }
  if (-not $script:NoDashboardFiltersResolved) {
    $dashcard.parameter_mappings = New-ParamMappings -CardId $card.id -Tags @($spec.f.Keys)
  }
  $dashcards += $dashcard
  $tempId -= 1
}

if (-not $script:NoDashboardFiltersResolved -and -not $script:FilterValueSourceCardId) {
  throw "Could not find the value-source card for dashboard dropdown filters."
}

$parameters = @()
if (-not $script:NoDashboardFiltersResolved) {
  $parameters = @(
    (New-DateDashboardParameter -Name "post_date" -DisplayName "Date Range" -Position 0),
    (New-DashboardParameter -Name "platform" -DisplayName "Platform" -TableName "fact_social_post_performance" -FieldName "platform" -SourceCardId $script:FilterValueSourceCardId -Position 1),
    (New-DashboardParameter -Name "country" -DisplayName "Country" -TableName "fact_social_post_performance" -FieldName "country" -SourceCardId $script:FilterValueSourceCardId -Position 2),
    (New-DashboardParameter -Name "content_category" -DisplayName "Content Category" -TableName "fact_social_post_performance" -FieldName "content_category" -SourceCardId $script:FilterValueSourceCardId -Position 3),
    (New-DashboardParameter -Name "post_type" -DisplayName "Post Type" -TableName "fact_social_post_performance" -FieldName "post_type" -SourceCardId $script:FilterValueSourceCardId -Position 4),
    (New-DashboardParameter -Name "promotion_type" -DisplayName "Promotion Type" -TableName "fact_social_post_performance" -FieldName "promotion_type" -SourceCardId $script:FilterValueSourceCardId -Position 5)
  )
  if (-not $script:SkipHashtagFilterResolved) {
    $parameters += (New-DashboardParameter -Name "main_hashtag" -DisplayName "Hashtag" -TableName "fact_social_post_performance" -FieldName "main_hashtag" -SourceCardId $script:FilterValueSourceCardId -Position 6)
  }
}

Invoke-Mb -Method Put -Path "/api/dashboard/$($dashboard.id)" -Headers $script:Auth -Body @{
  name               = $dashboard.name
  description        = $dashboard.description
  collection_id      = $script:CollectionId
  tabs               = @()
  parameters         = $parameters
  dashcards          = $dashcards
  auto_apply_filters = $true
} | Out-Null

$publicUrl = $null
try {
  $public = Invoke-Mb -Method Post -Path "/api/dashboard/$($dashboard.id)/public_link" -Headers $script:Auth
  $publicUrl = "$BaseUrl/public/dashboard/$($public.uuid)"
} catch {
  Write-Warning "Could not create public dashboard link: $($_.Exception.Message)"
}

[pscustomobject]@{
  dashboard_id  = $dashboard.id
  dashboard_url = "$BaseUrl/dashboard/$($dashboard.id)"
  public_url    = $publicUrl
  database_id   = $script:DatabaseId
  card_count    = $cards.Count
} | ConvertTo-Json -Depth 4

