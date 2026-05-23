/*
Step 01: load raw CSV files with SQL Server BULK INSERT.

Set @dataset_root to the local folder containing the seven source CSV files.
*/

use GrocerySupermarketSalesPortfolio;
go

set nocount on;

declare @dataset_root nvarchar(4000) =
    N'<absolute-path-to-this-project>\source-data';

declare @sql nvarchar(max);
declare @index_sql nvarchar(max);

declare @disabled_sales_indexes table (
    IndexName sysname primary key
);

declare @files table (
    SchemaName sysname,
    TableName sysname,
    FileName nvarchar(255)
);

insert into @files (SchemaName, TableName, FileName)
values
    (N'raw', N'categories', N'categories.csv'),
    (N'raw', N'countries', N'countries.csv'),
    (N'raw', N'cities', N'cities.csv'),
    (N'raw', N'customers', N'customers.csv'),
    (N'raw', N'employees', N'employees.csv'),
    (N'raw', N'products', N'products.csv'),
    (N'raw', N'sales', N'sales.csv');

insert into @disabled_sales_indexes (IndexName)
select name
from sys.indexes
where object_id = object_id(N'raw.sales')
    and type_desc = N'NONCLUSTERED'
    and is_primary_key = 0
    and is_unique_constraint = 0
    and is_disabled = 0;

declare load_cursor cursor local fast_forward for
    select SchemaName, TableName, FileName
    from @files;

declare @schema_name sysname;
declare @table_name sysname;
declare @file_name nvarchar(255);
declare @qualified_table_name nvarchar(517);
declare @file_path nvarchar(4000);

begin try
    select @index_sql = string_agg(
        cast(N'alter index ' + quotename(IndexName) + N' on raw.sales disable;' as nvarchar(max)),
        char(10)
    )
    from @disabled_sales_indexes;

    if @index_sql is not null
        exec sys.sp_executesql @index_sql;

    open load_cursor;
    fetch next from load_cursor into @schema_name, @table_name, @file_name;

    while @@fetch_status = 0
    begin
        set @qualified_table_name = quotename(@schema_name) + N'.' + quotename(@table_name);
        set @file_path = replace(@dataset_root + N'\' + @file_name, N'''', N'''''');

        set @sql = N'truncate table ' + @qualified_table_name + N';
bulk insert ' + @qualified_table_name + N'
from ''' + @file_path + N'''
with (
    format = ''CSV'',
    firstrow = 2,
    fieldquote = ''"'',
    rowterminator = ''0x0a'',
    tablock,
    codepage = ''65001''
);';

        print @sql;
        exec sys.sp_executesql @sql;

        fetch next from load_cursor into @schema_name, @table_name, @file_name;
    end

    close load_cursor;
    deallocate load_cursor;
end try
begin catch
    if cursor_status('local', 'load_cursor') >= 0
        close load_cursor;

    if cursor_status('local', 'load_cursor') > -3
        deallocate load_cursor;

    select @index_sql = string_agg(
        cast(N'alter index ' + quotename(IndexName) + N' on raw.sales rebuild;' as nvarchar(max)),
        char(10)
    )
    from @disabled_sales_indexes;

    if @index_sql is not null
        exec sys.sp_executesql @index_sql;

    throw;
end catch;

select @index_sql = string_agg(
    cast(N'alter index ' + quotename(IndexName) + N' on raw.sales rebuild;' as nvarchar(max)),
    char(10)
)
from @disabled_sales_indexes;

if @index_sql is not null
    exec sys.sp_executesql @index_sql;
go

select
    'categories' as TableName,
    count(*) as [RowCount]
from raw.categories
union all
select 'countries', count(*) from raw.countries
union all
select 'cities', count(*) from raw.cities
union all
select 'customers', count(*) from raw.customers
union all
select 'employees', count(*) from raw.employees
union all
select 'products', count(*) from raw.products
union all
select 'sales', count(*) from raw.sales;
go
