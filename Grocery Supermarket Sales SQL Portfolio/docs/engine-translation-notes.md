# Engine Translation Notes

The portfolio SQL is written for SQL Server. These notes show how to adapt the core logic to MySQL or BigQuery.

## Date Month Bucket

SQL Server:

```sql
convert(char(7), SalesDate, 120)
```

MySQL:

```sql
date_format(SalesDate, '%Y-%m')
```

BigQuery:

```sql
format_date('%Y-%m', date(SalesDate))
```

## Top N

SQL Server:

```sql
select top (5) *
from mart.vw_product_performance
order by NetRevenue desc;
```

MySQL and BigQuery:

```sql
select *
from mart.vw_product_performance
order by NetRevenue desc
limit 5;
```

## Safe Division

SQL Server and MySQL:

```sql
NetRevenue / nullif(UnitsSold, 0)
```

BigQuery:

```sql
safe_divide(NetRevenue, UnitsSold)
```

## String Concatenation

SQL Server:

```sql
concat(FirstName, ' ', LastName)
```

MySQL and BigQuery also support `concat`, but null-handling may differ by engine and should be tested.

## CSV Loading

SQL Server uses `BULK INSERT`.

MySQL can use `LOAD DATA INFILE`.

BigQuery can load CSV files through external tables, Cloud Storage load jobs, or the BigQuery UI.

