param(
  [string]$BaseUrl = "http://localhost:3001",
  [string]$Username,
  [string]$Password,
  [string]$DatabaseName = "Social Media Analytics",
  [int]$DashboardId = 0
)

$ErrorActionPreference = "Stop"

function Invoke-Mb {
  param([string]$Method, [string]$Path, [object]$Body = $null, [hashtable]$Headers = @{})
  $args = @{ Uri = "$BaseUrl$Path"; Method = $Method; Headers = $Headers }
  if ($null -ne $Body) {
    $args.ContentType = "application/json"
    $args.Body = ($Body | ConvertTo-Json -Depth 30 -Compress)
  }
  Invoke-RestMethod @args
}

function Get-FieldId {
  param([string]$TableName, [string]$FieldName)
  $table = $script:Metadata.tables | Where-Object { $_.name -eq $TableName } | Select-Object -First 1
  if (-not $table) { throw "Table '$TableName' not found in Metabase metadata." }
  $field = $table.fields | Where-Object { $_.name -eq $FieldName } | Select-Object -First 1
  if (-not $field) { throw "Field '$FieldName' not found on '$TableName'." }
  $field.id
}

function New-FieldTag {
  param([string]$Name, [string]$DisplayName, [string]$TableName, [string]$FieldName)
  @{
    id             = "${Name}_tag"
    name           = $Name
    "display-name" = $DisplayName
    type           = "dimension"
    dimension      = @("field", (Get-FieldId -TableName $TableName -FieldName $FieldName), $null)
    "widget-type"  = "string/="
  }
}

function New-NativeCard {
  param([string]$Name, [string]$Description, [string]$Display, [string]$Query, [hashtable]$Tags = @{}, [hashtable]$Viz = @{})
  Invoke-Mb -Method Post -Path "/api/card" -Headers $script:Auth -Body @{
    name                   = $Name
    description            = $Description
    display                = $Display
    collection_id          = $script:CollectionId
    visualization_settings = $Viz
    dataset_query          = @{
      type     = "native"
      database = $script:DatabaseId
      native   = @{ query = $Query; "template-tags" = $Tags }
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

$session = Invoke-Mb -Method Post -Path "/api/session" -Body @{ username = $Username; password = $Password }
$script:Auth = @{ "X-Metabase-Session" = $session.id }
$databases = Invoke-Mb -Method Get -Path "/api/database" -Headers $script:Auth
$db = $databases.data | Where-Object { $_.name -eq $DatabaseName } | Select-Object -First 1
if (-not $db) { throw "Database '$DatabaseName' not found in Metabase." }
$script:DatabaseId = $db.id
$script:Metadata = Invoke-Mb -Method Get -Path "/api/database/$($script:DatabaseId)/metadata" -Headers $script:Auth
$collection = (Invoke-Mb -Method Get -Path "/api/collection" -Headers $script:Auth) | Where-Object { $_.name -eq "Social Media Marketing Portfolio" } | Select-Object -First 1
if (-not $collection) { $collection = Invoke-Mb -Method Post -Path "/api/collection" -Headers $script:Auth -Body @{ name = "Social Media Marketing Portfolio"; color = "#509EE3" } }
$script:CollectionId = $collection.id

$dashboard = if ($DashboardId -gt 0) {
  [pscustomobject]@{ id = $DashboardId; name = "Social Media Marketing Performance"; description = "Answer what content wins, where it wins, when to publish, and how paid vs organic differs." }
} else {
  Invoke-Mb -Method Post -Path "/api/dashboard" -Headers $script:Auth -Body @{
    name          = "Social Media Marketing Performance"
    description   = "Answer what content wins, where it wins, when to publish, and how paid vs organic differs."
    collection_id = $script:CollectionId
  }
}

$parameters = @(
  @{ id = "platform_filter"; name = "Platform"; slug = "platform"; type = "string/="; "widget-type" = "string/="; sectionId = "dashboard"; default = $null; isMultiSelect = $true; values_query_type = "list" },
  @{ id = "region_filter"; name = "Region"; slug = "region"; type = "string/="; "widget-type" = "string/="; sectionId = "dashboard"; default = $null; isMultiSelect = $true; values_query_type = "list" },
  @{ id = "content_type_filter"; name = "Content Type"; slug = "content_type"; type = "string/="; "widget-type" = "string/="; sectionId = "dashboard"; default = $null; isMultiSelect = $true; values_query_type = "list" },
  @{ id = "content_category_filter"; name = "Content Category"; slug = "content_category"; type = "string/="; "widget-type" = "string/="; sectionId = "dashboard"; default = $null; isMultiSelect = $true; values_query_type = "list" }
)

$cards = @(
  @{ n = "How to Answer the Core Business Question"; desc = "Use this guide first. It maps each chart to the business decision it supports."; d = "table"; r = 0; c = 0; x = 24; y = 9; f = @{}; q = @"
select 1 as sort_order, '1. Platform Overview + Views by Platform' as chart_group, 'Use these first to see which platforms win on total engagement and total views.' as why_it_matters, 'Allocate channel effort toward the platforms that combine volume with sustainable reach.' as how_to_use
union all
select 2, '2. Post Type + Regional Category charts', 'These explain which combinations of format and theme work best in each market.', 'Choose the right format and category per region instead of copying one global content mix.'
union all
select 3, '3. Posting Hour + Posting Day charts', 'These answer when to post for the highest average engagement rate.', 'Use them to set publishing schedules by platform.'
union all
select 4, '4. Hashtag charts', 'These show which hashtags drive impressions and which drive clicks.', 'Use them to separate awareness hashtags from traffic-driving hashtags.'
union all
select 5, '5. Organic vs Sponsored + Trackable Post Detail', 'These compare paid versus organic reach and help inspect outlier posts.', 'Use them to decide when paid support is justified and which specific posts deserve replication.'
order by sort_order
"@; v = @{} },
  @{ n = "Which Platform Generates the Most Engagement?"; desc = "Start here to identify the strongest platform by total engagement."; d = "bar"; r = 9; c = 0; x = 12; y = 10; f = @{}; q = "select platform, total_engagement from vw_sm_platform_overview order by total_engagement desc"; v = (Viz-Bar @('platform') @('total_engagement')) },
  @{ n = "Which Platform Generates the Most Views?"; desc = "Compare total views to check whether the engagement leader is also the visibility leader."; d = "bar"; r = 9; c = 12; x = 12; y = 10; f = @{}; q = "select platform, total_views from vw_sm_platform_overview order by total_views desc"; v = (Viz-Bar @('platform') @('total_views')) },
  @{ n = "Which Post Types Win on Each Platform?"; desc = "Compare post types within each platform to decide the best format mix."; d = "bar"; r = 19; c = 0; x = 12; y = 10; f = @{ content_type = @{ table = 'vw_sm_platform_post_type_performance'; field = 'content_type'; display = 'Content Type' } }; q = "select platform, post_type, total_engagement from vw_sm_platform_post_type_performance where 1=1 [[and {{content_type}}]] order by platform, post_type"; v = (Viz-Bar @('platform','post_type') @('total_engagement') 'stacked') },
  @{ n = "Which Categories Perform Best by Region?"; desc = "Use this to localize content strategy instead of using one global category mix."; d = "bar"; r = 19; c = 12; x = 12; y = 10; f = @{ region = @{ table = 'vw_sm_region_category_performance'; field = 'region'; display = 'Region' }; content_category = @{ table = 'vw_sm_region_category_performance'; field = 'content_category'; display = 'Content Category' } }; q = "select region, content_category, total_engagement from vw_sm_region_category_performance where 1=1 [[and {{region}}]] [[and {{content_category}}]] order by total_engagement desc"; v = (Viz-Bar @('region','content_category') @('total_engagement') 'stacked') },
  @{ n = "What Is the Best Posting Hour by Platform?"; desc = "Use average engagement rate by hour to schedule posts more effectively."; d = "line"; r = 29; c = 0; x = 12; y = 10; f = @{ platform = @{ table = 'vw_sm_posting_hour_performance'; field = 'platform'; display = 'Platform' } }; q = "select post_hour, platform, avg_engagement_rate from vw_sm_posting_hour_performance where 1=1 [[and {{platform}}]] order by post_hour, platform"; v = @{ "graph.dimensions" = @("post_hour","platform"); "graph.metrics" = @("avg_engagement_rate") } },
  @{ n = "What Is the Best Posting Day by Platform?"; desc = "Use this to decide the weekly publishing cadence for each platform."; d = "line"; r = 29; c = 12; x = 12; y = 10; f = @{ platform = @{ table = 'vw_sm_posting_day_performance'; field = 'platform'; display = 'Platform' } }; q = "select published_day_of_week, platform, avg_engagement_rate from vw_sm_posting_day_performance where 1=1 [[and {{platform}}]] order by published_day_sort, platform"; v = @{ "graph.dimensions" = @("published_day_of_week","platform"); "graph.metrics" = @("avg_engagement_rate") } },
  @{ n = "Which Hashtags Drive the Most Impressions?"; desc = "Use this for awareness-oriented hashtag choices."; d = "bar"; r = 39; c = 0; x = 12; y = 10; f = @{}; q = "select main_hashtag, total_impressions from vw_sm_hashtag_effectiveness order by total_impressions desc limit 10"; v = (Viz-Bar @('main_hashtag') @('total_impressions')) },
  @{ n = "Which Hashtags Drive the Most Clicks?"; desc = "Use this for traffic-oriented hashtag choices on click-trackable content."; d = "bar"; r = 39; c = 12; x = 12; y = 10; f = @{}; q = "select main_hashtag, total_clicks from vw_sm_hashtag_effectiveness where total_clicks is not null order by total_clicks desc limit 10"; v = (Viz-Bar @('main_hashtag') @('total_clicks')) },
  @{ n = "Which Regions Prefer Video or Live Streams?"; desc = "Compare regional video demand to decide where heavier video investment is justified."; d = "bar"; r = 49; c = 0; x = 12; y = 10; f = @{ region = @{ table = 'vw_sm_video_live_region_interest'; field = 'region'; display = 'Region' } }; q = "select region, platform, total_video_views from vw_sm_video_live_region_interest where 1=1 [[and {{region}}]] order by total_video_views desc"; v = (Viz-Bar @('region','platform') @('total_video_views') 'stacked') },
  @{ n = "How Do Organic and Sponsored Posts Compare on Reach?"; desc = "Compare paid and organic reach to see where promotion actually changes distribution."; d = "bar"; r = 49; c = 12; x = 12; y = 10; f = @{ platform = @{ table = 'vw_sm_organic_vs_sponsored'; field = 'platform'; display = 'Platform' } }; q = "select content_type, platform, total_impressions from vw_sm_organic_vs_sponsored where 1=1 [[and {{platform}}]] order by total_impressions desc"; v = (Viz-Bar @('content_type','platform') @('total_impressions') 'stacked') },
  @{ n = "Key Insights and Suggested Actions"; desc = "Use this section as the executive takeaway: what happened and what to do next."; d = "table"; r = 59; c = 0; x = 24; y = 10; f = @{}; q = @"
with top_engagement_platform as (
  select platform, total_engagement, row_number() over (order by total_engagement desc) as rn
  from vw_sm_platform_overview
),
top_views_platform as (
  select platform, total_views, row_number() over (order by total_views desc) as rn
  from vw_sm_platform_overview
),
best_hour as (
  select platform, post_hour, avg_engagement_rate, row_number() over (partition by platform order by avg_engagement_rate desc, post_hour) as rn
  from vw_sm_posting_hour_performance
  where posts >= 50
),
best_hashtag as (
  select main_hashtag, total_clicks, row_number() over (order by total_clicks desc nulls last) as rn
  from vw_sm_hashtag_effectiveness
),
paid_vs_org as (
  select content_type, sum(total_impressions) as total_impressions, round(avg(avg_engagement_rate), 4) as avg_engagement_rate
  from vw_sm_organic_vs_sponsored
  group by content_type
)
select 1 as priority,
  'Platform focus' as topic,
  'Highest engagement platform: ' || (select platform from top_engagement_platform where rn = 1) || '. Highest views platform: ' || (select platform from top_views_platform where rn = 1) || '.' as insight,
  'Prioritize the engagement leader for community activity, then use the views leader for reach-heavy campaigns.' as recommendation
union all
select 2,
  'Publishing timing',
  'Best high-volume posting hour example: ' || (select platform || ' at ' || post_hour || ':00' from best_hour where rn = 1 order by avg_engagement_rate desc limit 1) || '.' ,
  'Use the posting-time charts to set a platform-specific schedule instead of one universal posting slot.'
union all
select 3,
  'Hashtag strategy',
  'Top click-driving hashtag: ' || coalesce((select main_hashtag from best_hashtag where rn = 1), 'No click hashtag available') || '.' ,
  'Use the clicks chart for traffic campaigns and the impressions chart for awareness campaigns.'
union all
select 4,
  'Paid vs organic',
  'Organic and sponsored should be compared separately because their reach profiles differ materially across platforms.',
  'Promote only the formats and themes that already perform well organically, then validate incremental lift.'
union all
select 5,
  'Regional adaptation',
  'Regional performance differs by content category and by video intensity.',
  'Localize content themes by region and use the video-region chart to decide where richer media investment is worth it.'
order by priority
"@; v = @{} },
  @{ n = "Trackable Post Detail for Outlier Investigation"; desc = "Use this table after the charts to inspect specific posts behind spikes in clicks or CTR."; d = "table"; r = 69; c = 0; x = 24; y = 12; f = @{ platform = @{ table = 'vw_sm_post_detail'; field = 'platform'; display = 'Platform' }; region = @{ table = 'vw_sm_post_detail'; field = 'region'; display = 'Region' }; content_type = @{ table = 'vw_sm_post_detail'; field = 'content_type'; display = 'Content Type' }; content_category = @{ table = 'vw_sm_post_detail'; field = 'content_category'; display = 'Content Category' } }; q = "select platform, region, content_type, content_category, post_type, main_hashtag, post_date, engagement, views, impressions, clicks, click_through_rate from vw_sm_post_detail where is_click_trackable is true [[and {{platform}}]] [[and {{region}}]] [[and {{content_type}}]] [[and {{content_category}}]] order by post_date desc limit 100"; v = @{} }
)

$dashcards = @()
$tempId = -1
foreach ($spec in $cards) {
  $tags = @{}
  foreach ($name in $spec.f.Keys) {
    $def = $spec.f[$name]
    $tags[$name] = New-FieldTag -Name $name -DisplayName $def.display -TableName $def.table -FieldName $def.field
  }
  $card = New-NativeCard -Name $spec.n -Description $spec.desc -Display $spec.d -Query $spec.q -Tags $tags -Viz $spec.v
  $dashcards += @{
    id                     = $tempId
    card_id                = $card.id
    row                    = $spec.r
    col                    = $spec.c
    size_x                 = $spec.x
    size_y                 = $spec.y
    parameter_mappings     = (New-ParamMappings -CardId $card.id -Tags @($spec.f.Keys))
    visualization_settings = New-Object PSObject
  }
  $tempId -= 1
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

$public = Invoke-Mb -Method Post -Path "/api/dashboard/$($dashboard.id)/public_link" -Headers $script:Auth
[pscustomobject]@{
  dashboard_id  = $dashboard.id
  dashboard_url = "$BaseUrl/dashboard/$($dashboard.id)"
  public_url    = "$BaseUrl/public/dashboard/$($public.uuid)"
  database_id   = $script:DatabaseId
  card_count    = $cards.Count
} | ConvertTo-Json -Depth 4
