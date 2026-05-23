/*
Grocery Supermarket Sales SQL Portfolio
Step 00: create SQL Server database, schemas, raw tables, and indexes.
*/

if db_id(N'GrocerySupermarketSalesPortfolio') is null
    create database GrocerySupermarketSalesPortfolio;
go

use GrocerySupermarketSalesPortfolio;
go

if schema_id(N'raw') is null
    exec(N'create schema raw;');
if schema_id(N'mart') is null
    exec(N'create schema mart;');
if schema_id(N'audit') is null
    exec(N'create schema audit;');
go

set nocount on;

if object_id(N'raw.categories', N'U') is null
create table raw.categories (
    CategoryID int not null primary key,
    CategoryName nvarchar(100) not null
);

if object_id(N'raw.countries', N'U') is null
create table raw.countries (
    CountryID int not null primary key,
    CountryName nvarchar(150) not null,
    CountryCode nvarchar(20) null
);

if object_id(N'raw.cities', N'U') is null
create table raw.cities (
    CityID int not null primary key,
    CityName nvarchar(150) not null,
    Zipcode nvarchar(30) null,
    CountryID int not null
);

if object_id(N'raw.customers', N'U') is null
create table raw.customers (
    CustomerID int not null primary key,
    FirstName nvarchar(100) null,
    MiddleInitial nvarchar(20) null,
    LastName nvarchar(100) null,
    CityID int null,
    Address nvarchar(255) null
);

if object_id(N'raw.employees', N'U') is null
create table raw.employees (
    EmployeeID int not null primary key,
    FirstName nvarchar(100) null,
    MiddleInitial nvarchar(20) null,
    LastName nvarchar(100) null,
    BirthDate date null,
    Gender nvarchar(30) null,
    CityID int null,
    HireDate date null
);

if object_id(N'raw.products', N'U') is null
create table raw.products (
    ProductID int not null primary key,
    ProductName nvarchar(255) not null,
    Price decimal(18, 4) not null,
    CategoryID int null,
    Class nvarchar(50) null,
    ModifyDate datetime2 null,
    Resistant nvarchar(50) null,
    IsAllergic nvarchar(50) null,
    VitalityDays decimal(18, 1) null
);

if object_id(N'raw.sales', N'U') is null
create table raw.sales (
    SalesID bigint not null primary key,
    SalesPersonID int null,
    CustomerID int null,
    ProductID int null,
    Quantity int null,
    Discount decimal(9, 4) null,
    TotalPrice decimal(18, 4) null,
    SalesDate nvarchar(50) null,
    TransactionNumber nvarchar(100) null
);

if not exists (select 1 from sys.indexes where object_id = object_id(N'raw.sales') and name = N'ix_sales_product')
    create index ix_sales_product on raw.sales (ProductID);
if not exists (select 1 from sys.indexes where object_id = object_id(N'raw.sales') and name = N'ix_sales_customer')
    create index ix_sales_customer on raw.sales (CustomerID);
if not exists (select 1 from sys.indexes where object_id = object_id(N'raw.sales') and name = N'ix_sales_employee')
    create index ix_sales_employee on raw.sales (SalesPersonID);
if not exists (select 1 from sys.indexes where object_id = object_id(N'raw.sales') and name = N'ix_sales_transaction')
    create index ix_sales_transaction on raw.sales (TransactionNumber);
if not exists (select 1 from sys.indexes where object_id = object_id(N'raw.sales') and name = N'ix_sales_date')
    create index ix_sales_date on raw.sales (SalesDate);
if not exists (select 1 from sys.indexes where object_id = object_id(N'raw.products') and name = N'ix_products_category')
    create index ix_products_category on raw.products (CategoryID);
if not exists (select 1 from sys.indexes where object_id = object_id(N'raw.customers') and name = N'ix_customers_city')
    create index ix_customers_city on raw.customers (CityID);
if not exists (select 1 from sys.indexes where object_id = object_id(N'raw.cities') and name = N'ix_cities_country')
    create index ix_cities_country on raw.cities (CountryID);
go
