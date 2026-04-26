param(
  [string]$BaseUrl = "https://data.youngllilo.works",
  [string]$Username,
  [string]$Password,
  [int]$DatabaseId = 2,
  [int]$CollectionId = 6,
  [int]$DashboardId = 0
)

$ErrorActionPreference = "Stop"

function Invoke-Mb {
  param([string]$Method, [string]$Path, [object]$Body = $null)
  $args = @{ Uri = "$BaseUrl$Path"; Method = $Method; Headers = $script:Auth }
  if ($null -ne $Body) {
    $args.ContentType = "application/json"
    $args.Body = ($Body | ConvertTo-Json -Depth 80 -Compress)
  }
  Invoke-RestMethod @args
}

function Get-FieldId {
  param([object]$Metadata, [string]$Table, [string]$Field)
  $tableObj = $Metadata.tables | Where-Object { $_.schema -eq "airbnb" -and $_.name -eq $Table } | Select-Object -First 1
  if (-not $tableObj) { throw "Cannot find table airbnb.$Table. Sync Metabase database schema first." }
  $fieldObj = $tableObj.fields | Where-Object { $_.name -eq $Field } | Select-Object -First 1
  if (-not $fieldObj) { throw "Cannot find field airbnb.$Table.$Field." }
  [int]$fieldObj.id
}

function New-FieldTag {
  param([string]$Name, [string]$DisplayName, [int]$FieldId)
  @{
    id = $Name
    name = $Name
    "display-name" = $DisplayName
    type = "dimension"
    dimension = @("field", $FieldId, $null)
    "widget-type" = "category"
  }
}

function New-Card {
  param([hashtable]$Spec, [hashtable]$Tags)
  $body = @{
    name = $Spec.Name
    description = $Spec.Description
    display = $Spec.Display
    collection_id = $CollectionId
    visualization_settings = $Spec.Viz
    dataset_query = @{
      type = "native"
      database = $DatabaseId
      native = @{ query = $Spec.Query; "template-tags" = $Tags }
    }
  }
  Invoke-Mb -Method Post -Path "/api/card" -Body $body
}

function Tags-ForSpec {
  param([hashtable]$Spec, [object]$Metadata)
  $tags = @{}
  if ($Spec.CityTable) {
    $tags.city = New-FieldTag -Name "city" -DisplayName "City" -FieldId (Get-FieldId $Metadata $Spec.CityTable "city")
  }
  if ($Spec.RoomTypeTable) {
    $tags.room_type = New-FieldTag -Name "room_type" -DisplayName "Room Type" -FieldId (Get-FieldId $Metadata $Spec.RoomTypeTable "room_type")
  }
  $tags
}

function Viz-Bar($X, $Y) { @{ "graph.dimensions" = @($X); "graph.metrics" = @($Y) } }
function Viz-StackedBar($X, $Series, $Y) { @{ "graph.dimensions" = @($X, $Series); "graph.metrics" = @($Y); "stackable.stack_type" = "stacked" } }
function Viz-Line($X, $Series, $Y) { @{ "graph.dimensions" = @($X, $Series); "graph.metrics" = @($Y) } }

function Heat-Format($Columns, $Min, $Max, $Colors) {
  $Columns | ForEach-Object {
    @{ type = "range"; columns = @($_); operator = "="; value = ""; min_type = "custom"; max_type = "custom"; min_value = $Min; max_value = $Max; color = "#509EE3"; colors = $Colors; highlight_row = $false }
  }
}

if (-not $Username -or -not $Password) {
  throw "Provide -Username and -Password for Metabase."
}

$script:Auth = @{}
$session = Invoke-Mb -Method Post -Path "/api/session" -Body @{ username = $Username; password = $Password }
$script:Auth = @{ "X-Metabase-Session" = $session.id }
$metadata = Invoke-Mb -Method Get -Path "/api/database/$DatabaseId/metadata"

$cityValues = @("Bangkok", "Cape Town", "Hong Kong", "Istanbul", "Mexico City", "New York", "Paris", "Rio de Janeiro", "Rome", "Sydney")
$roomValues = @("Entire place", "Hotel room", "Private room", "Shared room")

$tabs = @(
  @{ id = -1; name = "Market Landscape" },
  @{ id = -2; name = "Price Formula" },
  @{ id = -3; name = "Tourism Pulse" },
  @{ id = -4; name = "Value For Money" }
)

$cards = @(
  @{ Name="Blueprint - Total Listings KPI"; Display="scalar"; Tab=-1; Row=0; Col=0; SizeX=4; SizeY=2; CityTable="mart_room_type_mix"; RoomTypeTable="mart_room_type_mix"; Viz=@{}; Query="select sum(listing_count) as total_listings from airbnb.mart_room_type_mix where 1=1 [[and {{city}}]] [[and {{room_type}}]]" },
  @{ Name="Blueprint - Active Cities KPI"; Display="scalar"; Tab=-1; Row=0; Col=4; SizeX=5; SizeY=2; CityTable="mart_room_type_mix"; RoomTypeTable="mart_room_type_mix"; Viz=@{}; Query="select count(distinct city) as active_cities from airbnb.mart_room_type_mix where 1=1 [[and {{city}}]] [[and {{room_type}}]]" },
  @{ Name="Blueprint - Median USD Price KPI"; Display="scalar"; Tab=-1; Row=0; Col=9; SizeX=5; SizeY=2; CityTable="mart_price_distribution_city_room"; RoomTypeTable="mart_price_distribution_city_room"; Viz=@{}; Query="select round(percentile_cont(0.5) within group (order by median_price_usd)::numeric, 2) as median_city_price_usd from airbnb.mart_price_distribution_city_room where 1=1 [[and {{city}}]] [[and {{room_type}}]]" },
  @{ Name="Blueprint - Review Records KPI"; Display="scalar"; Tab=-1; Row=0; Col=14; SizeX=5; SizeY=2; CityTable="mart_city_market_landscape"; Viz=@{}; Query="select sum(review_count) as review_records from airbnb.mart_city_market_landscape where 1=1 [[and {{city}}]]" },
  @{ Name="Blueprint - Average Rating KPI"; Display="scalar"; Tab=-1; Row=0; Col=19; SizeX=5; SizeY=2; CityTable="mart_city_market_landscape"; Viz=@{}; Query="select round(avg(avg_rating), 2) as average_rating from airbnb.mart_city_market_landscape where 1=1 [[and {{city}}]]" },
  @{ Name="Blueprint - Listings by City"; Display="bar"; Tab=-1; Row=2; Col=0; SizeX=12; SizeY=9; CityTable="mart_room_type_mix"; RoomTypeTable="mart_room_type_mix"; Viz=(Viz-Bar "city" "listing_count"); Query="select city, sum(listing_count) as listing_count from airbnb.mart_room_type_mix where 1=1 [[and {{city}}]] [[and {{room_type}}]] group by city order by listing_count desc" },
  @{ Name="Blueprint - Room Type Mix by City (Stacked Bar)"; Display="bar"; Tab=-1; Row=2; Col=12; SizeX=12; SizeY=9; CityTable="mart_room_type_mix"; RoomTypeTable="mart_room_type_mix"; Viz=(Viz-StackedBar "city" "room_type" "listing_count"); Query="select city, room_type, listing_count from airbnb.mart_room_type_mix where 1=1 [[and {{city}}]] [[and {{room_type}}]] order by city, room_type" },
  @{ Name="Blueprint - USD Price Distribution by City and Room Type"; Display="table"; Tab=-1; Row=11; Col=0; SizeX=12; SizeY=10; CityTable="mart_price_distribution_city_room"; RoomTypeTable="mart_price_distribution_city_room"; Viz=@{}; Query="select city, room_type, listing_count, p25_price_usd, median_price_usd, p75_price_usd from airbnb.mart_price_distribution_city_room where 1=1 [[and {{city}}]] [[and {{room_type}}]] order by city, room_type" },
  @{ Name="Blueprint - Listing Density Pin Map"; Display="map"; Tab=-1; Row=11; Col=12; SizeX=12; SizeY=10; CityTable="mart_listing_density_map"; Viz=@{ "map.type"="pin"; "map.latitude_column"="latitude"; "map.longitude_column"="longitude"; "map.metric_column"="listing_count"; "map.marker_size"="listing_count" }; Query="select city, latitude, longitude, listing_count from airbnb.mart_listing_density_map where 1=1 [[and {{city}}]] order by listing_count desc limit 2000" },

  @{ Name="Blueprint - Correlation Heatmap Table"; Display="table"; Tab=-2; Row=0; Col=0; SizeX=12; SizeY=8; Viz=@{ "table.column_formatting"=(Heat-Format @("pearson_with_price_usd") -0.2 0.2 @("#ED6E6E", "#FFFFFF", "#84BB4C")) }; Query="select driver, n, pearson_with_price_usd from airbnb.mart_price_driver_correlations order by abs(pearson_with_price_usd) desc" },
  @{ Name="Blueprint - Driver Ranking"; Display="bar"; Tab=-2; Row=0; Col=12; SizeX=12; SizeY=8; Viz=(Viz-Bar "driver" "driver_strength"); Query="select driver, abs(pearson_with_price_usd) as driver_strength from airbnb.mart_price_driver_correlations order by driver_strength desc" },
  @{ Name="Blueprint - Superhost Median Price Difference Heatmap"; Display="table"; Tab=-2; Row=8; Col=0; SizeX=24; SizeY=13; CityTable="mart_superhost_premium"; RoomTypeTable="mart_superhost_premium"; Viz=@{ "table.column_formatting"=(Heat-Format @("entire_place", "hotel_room", "private_room", "shared_room") -300 300 @("#ED6E6E", "#FFFFFF", "#84BB4C")) }; Query="select city, max(premium_usd) filter (where room_type = 'Entire place') as entire_place, max(premium_usd) filter (where room_type = 'Hotel room') as hotel_room, max(premium_usd) filter (where room_type = 'Private room') as private_room, max(premium_usd) filter (where room_type = 'Shared room') as shared_room from airbnb.mart_superhost_premium where premium_usd is not null [[and {{city}}]] [[and {{room_type}}]] group by city order by city" },
  @{ Name="Blueprint - Amenity Price Premium Flags"; Display="bar"; Tab=-2; Row=21; Col=0; SizeX=24; SizeY=8; Viz=(Viz-Bar "amenity" "avg_price_premium_usd"); Query="select amenity, listing_count, avg_price_premium_usd from airbnb.mart_amenity_price_premium where avg_price_premium_usd is not null order by avg_price_premium_usd desc" },

  @{ Name="Blueprint - Monthly Review Trend by City"; Display="line"; Tab=-3; Row=0; Col=0; SizeX=24; SizeY=8; CityTable="mart_monthly_tourism_pulse"; Viz=(Viz-Line "review_month" "city" "review_count"); Query="select city, review_month, review_count from airbnb.mart_monthly_tourism_pulse where 1=1 [[and {{city}}]] order by city, review_month" },
  @{ Name="Blueprint - Seasonality Heatmap City by Month"; Display="table"; Tab=-3; Row=8; Col=0; SizeX=13; SizeY=10; CityTable="mart_seasonality_heatmap"; Viz=@{ "table.column_formatting"=(Heat-Format @("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec") 0 30000 @("#F7FBFF", "#6BAED6", "#08306B")) }; Query="select city, max(avg_review_count) filter (where month_number = '01') as jan, max(avg_review_count) filter (where month_number = '02') as feb, max(avg_review_count) filter (where month_number = '03') as mar, max(avg_review_count) filter (where month_number = '04') as apr, max(avg_review_count) filter (where month_number = '05') as may, max(avg_review_count) filter (where month_number = '06') as jun, max(avg_review_count) filter (where month_number = '07') as jul, max(avg_review_count) filter (where month_number = '08') as aug, max(avg_review_count) filter (where month_number = '09') as sep, max(avg_review_count) filter (where month_number = '10') as oct, max(avg_review_count) filter (where month_number = '11') as nov, max(avg_review_count) filter (where month_number = '12') as dec from airbnb.mart_seasonality_heatmap where 1=1 [[and {{city}}]] group by city order by city" },
  @{ Name="Blueprint - Monthly Reviews vs 2019 Baseline"; Display="line"; Tab=-3; Row=8; Col=13; SizeX=11; SizeY=10; CityTable="mart_monthly_tourism_pulse"; Viz=(Viz-Line "review_month" "series" "value"); Query="with filtered as (select * from airbnb.mart_monthly_tourism_pulse where review_month >= '2019-01' [[and {{city}}]]) select city || ' monthly reviews' as series, (review_month || '-01')::date as review_month, review_count::numeric as value from filtered union all select city || ' 2019 baseline' as series, (review_month || '-01')::date as review_month, baseline_2019_avg::numeric as value from filtered where baseline_2019_avg is not null order by series, review_month" },
  @{ Name="Blueprint - Peak and Stagnation Callouts"; Display="table"; Tab=-3; Row=18; Col=0; SizeX=24; SizeY=8; CityTable="mart_tourism_peak_stagnation_callouts"; Viz=@{}; Query="select city, callout_type, review_month, review_count, recovery_index from airbnb.mart_tourism_peak_stagnation_callouts where 1=1 [[and {{city}}]] order by city, callout_type" },

  @{ Name="Blueprint - City Ranking by Value Index"; Display="bar"; Tab=-4; Row=0; Col=0; SizeX=12; SizeY=8; CityTable="mart_value_for_money_city"; Viz=(Viz-Bar "city" "value_index"); Query="select city, value_index, median_price_usd, avg_rating from airbnb.mart_value_for_money_city where 1=1 [[and {{city}}]] order by value_index desc" },
  @{ Name="Blueprint - Median USD Price vs Review Score Scatter"; Display="scatter"; Tab=-4; Row=0; Col=12; SizeX=12; SizeY=8; CityTable="mart_city_market_landscape"; Viz=@{ "scatter.x_column"="median_price_usd"; "scatter.y_column"="avg_rating"; "scatter.bubble"="listing_count" }; Query="select city, median_price_usd, avg_rating, listing_count from airbnb.mart_city_market_landscape where 1=1 [[and {{city}}]] order by city" },
  @{ Name="Blueprint - Best City Room Segments for Travelers"; Display="table"; Tab=-4; Row=8; Col=0; SizeX=12; SizeY=10; CityTable="mart_city_room_value_segments"; RoomTypeTable="mart_city_room_value_segments"; Viz=@{}; Query="select city, room_type, listing_count, median_price_usd, avg_rating, value_index from airbnb.mart_city_room_value_segments where 1=1 [[and {{city}}]] [[and {{room_type}}]] order by value_index desc limit 25" },
  @{ Name="Blueprint - High Value Neighbourhood Drilldown"; Display="table"; Tab=-4; Row=8; Col=12; SizeX=12; SizeY=10; CityTable="mart_neighbourhood_value_drilldown"; Viz=@{}; Query="select city, neighbourhood, listing_count, median_price_usd, avg_rating from airbnb.mart_neighbourhood_value_drilldown where 1=1 [[and {{city}}]] order by avg_rating desc, median_price_usd asc limit 50" }
)

$dashboardName = "Airbnb Global Listings & Reviews Analytics"
$dashboardDescription = "Market landscape, price drivers, tourism pulse, COVID recovery, and value-for-money analytics for Airbnb listings and reviews."

if ($DashboardId -gt 0) {
  $dashboard = Invoke-Mb -Method Get -Path "/api/dashboard/$DashboardId"
} else {
  $dashboard = Invoke-Mb -Method Post -Path "/api/dashboard" -Body @{ name = $dashboardName; description = $dashboardDescription; collection_id = $CollectionId }
}

$dashcards = @()
$counter = -100
foreach ($spec in $cards) {
  $tags = Tags-ForSpec $spec $metadata
  $card = New-Card $spec $tags
  $parameterMappings = [System.Collections.Generic.List[object]]::new()
  if ($spec.CityTable) {
    $parameterMappings.Add(@{ parameter_id = "city_filter"; target = @("dimension", @("template-tag", "city")) })
  }
  if ($spec.RoomTypeTable) {
    $parameterMappings.Add(@{ parameter_id = "room_type_filter"; target = @("dimension", @("template-tag", "room_type")) })
  }
  $dashcards += @{
    id = $counter
    card_id = $card.id
    row = $spec.Row
    col = $spec.Col
    size_x = $spec.SizeX
    size_y = $spec.SizeY
    dashboard_tab_id = $spec.Tab
    parameter_mappings = $parameterMappings
    visualization_settings = @{}
  }
  $counter -= 1
}

$parameters = @(
  @{ id = "city_filter"; type = "string/="; name = "City"; slug = "city"; sectionId = "string"; values_source_type = "static-list"; values_source_config = @{ values = $cityValues }; isMultiSelect = $true },
  @{ id = "room_type_filter"; type = "string/="; name = "Room Type"; slug = "room_type"; sectionId = "string"; values_source_type = "static-list"; values_source_config = @{ values = $roomValues }; isMultiSelect = $true }
)

$payload = @{
  name = $dashboardName
  description = $dashboardDescription
  parameters = $parameters
  width = "fixed"
  tabs = $tabs
  dashcards = $dashcards
}

Invoke-Mb -Method Put -Path "/api/dashboard/$($dashboard.id)" -Body $payload | Out-Null

Write-Host "Created/updated dashboard:"
Write-Host "$BaseUrl/dashboard/$($dashboard.id)"
Write-Host "Cards created: $($cards.Count)"
