"""Build dashboard-ready marts for the FMCG Power BI portfolio project."""

from __future__ import annotations

import csv
import json
from collections import Counter, defaultdict
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[3]
EXPORTS_DIR = PROJECT_ROOT / "docs" / "assets" / "exports"
DATASET_DIR = PROJECT_ROOT / "source-data"


def decimal_value(value: str) -> Decimal:
    try:
        return Decimal(str(value or "0").strip())
    except InvalidOperation:
        return Decimal("0")


def month_value(value: str) -> str:
    try:
        return datetime.fromisoformat(value.strip()).strftime("%Y-%m")
    except ValueError:
        return "Unknown"


def read_lookup(file_name: str, key: str) -> dict[str, dict[str, str]]:
    with (DATASET_DIR / file_name).open("r", encoding="utf-8-sig", newline="") as handle:
        return {row[key]: row for row in csv.DictReader(handle)}


def write_csv(file_name: str, rows: list[dict], fieldnames: list[str]) -> None:
    with (EXPORTS_DIR / file_name).open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def money(value: Decimal) -> str:
    return f"{value.quantize(Decimal('0.01'))}"


def ratio(value: Decimal) -> str:
    return f"{value.quantize(Decimal('0.0001'))}"


def safe_divide(numerator: Decimal, denominator: Decimal) -> Decimal:
    return Decimal("0") if denominator == 0 else numerator / denominator


def main() -> None:
    EXPORTS_DIR.mkdir(parents=True, exist_ok=True)
    categories = read_lookup("categories.csv", "CategoryID")
    cities = read_lookup("cities.csv", "CityID")
    countries = read_lookup("countries.csv", "CountryID")
    customers = read_lookup("customers.csv", "CustomerID")
    employees = read_lookup("employees.csv", "EmployeeID")
    products = read_lookup("products.csv", "ProductID")

    source_counts = {
        "categories": len(categories),
        "cities": len(cities),
        "countries": len(countries),
        "customers": len(customers),
        "employees": len(employees),
        "products": len(products),
        "sales": 0,
    }
    data_quality = Counter(blank_sales_date=0, zero_total_price=0)
    monthly_category = defaultdict(lambda: Counter(units=0) | {"net": Decimal("0"), "gross": Decimal("0")})
    product_perf = defaultdict(lambda: Counter(units=0, lines=0) | {"net": Decimal("0"), "gross": Decimal("0")})
    customer_perf = defaultdict(lambda: Counter(units=0, lines=0) | {"net": Decimal("0"), "invoice_set": set()})
    employee_perf = defaultdict(lambda: Counter(invoices=0, units=0) | {"net": Decimal("0"), "invoice_set": set()})
    geo_market = defaultdict(lambda: Counter(units=0) | {"net": Decimal("0"), "customers": set(), "invoices": set()})
    invoice_perf = defaultdict(lambda: Counter(units=0, lines=0) | {"net": Decimal("0"), "customer_id": ""})
    class_perf = defaultdict(lambda: Counter(units=0, lines=0) | {"net": Decimal("0"), "gross": Decimal("0")})
    monthly_total = defaultdict(Decimal)
    invoice_customer_seen = set()
    revenue_diff_sample = []
    totals = Counter(units=0)
    totals.update({"net": Decimal("0"), "gross": Decimal("0")})

    with (DATASET_DIR / "sales.csv").open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            source_counts["sales"] += 1
            product = products.get(row["ProductID"], {})
            customer = customers.get(row["CustomerID"], {})
            city = cities.get(customer.get("CityID", ""), {})
            country = countries.get(city.get("CountryID", ""), {})
            quantity = decimal_value(row["Quantity"])
            price = decimal_value(product.get("Price", "0"))
            discount = decimal_value(row["Discount"])
            gross = quantity * price
            source_total_price = decimal_value(row["TotalPrice"])
            discount_net = gross * (Decimal("1") - discount)
            net = source_total_price if source_total_price else discount_net
            sales_month = month_value(row["SalesDate"])
            if sales_month == "Unknown":
                data_quality["blank_sales_date"] += 1
            if source_total_price == 0:
                data_quality["zero_total_price"] += 1
            invoice_id = row["TransactionNumber"]
            category_id = product.get("CategoryID", "")
            class_name = product.get("Class", "Unknown") or "Unknown"

            totals["units"] += int(quantity)
            totals["net"] += net
            totals["gross"] += gross
            monthly_total[sales_month] += net

            category_key = (sales_month, category_id)
            monthly_category[category_key]["units"] += int(quantity)
            monthly_category[category_key]["net"] += net
            monthly_category[category_key]["gross"] += gross

            product_key = row["ProductID"]
            product_perf[product_key]["units"] += int(quantity)
            product_perf[product_key]["lines"] += 1
            product_perf[product_key]["net"] += net
            product_perf[product_key]["gross"] += gross

            customer_key = row["CustomerID"]
            customer_perf[customer_key]["units"] += int(quantity)
            customer_perf[customer_key]["lines"] += 1
            customer_perf[customer_key]["net"] += net
            customer_perf[customer_key]["invoice_set"].add(invoice_id)

            employee_key = (row["SalesPersonID"], sales_month)
            employee_perf[employee_key]["units"] += int(quantity)
            employee_perf[employee_key]["net"] += net
            employee_perf[employee_key]["invoice_set"].add(invoice_id)

            geo_key = (country.get("CountryID", ""), city.get("CityID", ""))
            geo_market[geo_key]["units"] += int(quantity)
            geo_market[geo_key]["net"] += net
            geo_market[geo_key]["customers"].add(row["CustomerID"])
            geo_market[geo_key]["invoices"].add(invoice_id)

            invoice_perf[invoice_id]["units"] += int(quantity)
            invoice_perf[invoice_id]["lines"] += 1
            invoice_perf[invoice_id]["net"] += net
            invoice_perf[invoice_id]["customer_id"] = row["CustomerID"]
            invoice_customer_seen.add((invoice_id, row["CustomerID"]))

            class_perf[class_name]["units"] += int(quantity)
            class_perf[class_name]["lines"] += 1
            class_perf[class_name]["net"] += net
            class_perf[class_name]["gross"] += gross

            if len(revenue_diff_sample) < 25:
                revenue_diff_sample.append(
                    {
                        "sales_id": row["SalesID"],
                        "gross_estimate": money(gross),
                        "discount": str(discount),
                        "discount_formula_net": money(discount_net),
                        "source_total_price": money(source_total_price),
                        "selected_net_revenue": money(net),
                        "source_difference": money(source_total_price - discount_net),
                    }
                )

    write_monthly_category(monthly_category, monthly_total, categories)
    write_product_performance(product_perf, products, categories)
    write_customer_segments(customer_perf, customers)
    write_employee_performance(employee_perf, employees, monthly_total)
    write_geo_market(geo_market, cities, countries)
    write_class_performance(class_perf)
    write_executive_kpis(source_counts, totals, invoice_perf, customer_perf, invoice_customer_seen)
    write_summary(source_counts, totals, invoice_perf, customer_perf, revenue_diff_sample, data_quality)


def write_monthly_category(rows, monthly_total, categories):
    output = []
    previous = {}
    for (month, category_id), values in sorted(rows.items()):
        net = values["net"]
        prior = previous.get(category_id, Decimal("0"))
        output.append(
            {
                "SalesMonth": month,
                "CategoryID": category_id,
                "CategoryName": categories.get(category_id, {}).get("CategoryName", ""),
                "NetRevenue": money(net),
                "GrossRevenueEstimate": money(values["gross"]),
                "UnitsSold": values["units"],
                "CategoryShare": ratio(safe_divide(net, monthly_total[month])),
                "MoMRevenueChange": money(net - prior) if prior else "",
                "MoMRevenueChangePct": ratio(safe_divide(net - prior, prior)) if prior else "",
            }
        )
        previous[category_id] = net
    write_csv("mart-monthly-category-revenue.csv", output, list(output[0].keys()))


def write_product_performance(rows, products, categories):
    ranked = sorted(rows.items(), key=lambda item: item[1]["net"], reverse=True)
    output = []
    for desc_rank, (product_id, values) in enumerate(ranked, start=1):
        product = products.get(product_id, {})
        category = categories.get(product.get("CategoryID", ""), {})
        output.append(
            {
                "ProductID": product_id,
                "ProductName": product.get("ProductName", ""),
                "CategoryName": category.get("CategoryName", ""),
                "Class": product.get("Class", ""),
                "NetRevenue": money(values["net"]),
                "GrossRevenueEstimate": money(values["gross"]),
                "UnitsSold": values["units"],
                "RevenuePerUnit": money(safe_divide(values["net"], Decimal(values["units"]))),
                "RevenueRankDesc": desc_rank,
                "RevenueRankAsc": len(ranked) - desc_rank + 1,
            }
        )
    write_csv("mart-product-performance.csv", output, list(output[0].keys()))


def write_customer_segments(rows, customers):
    output = []
    for customer_id, values in rows.items():
        invoice_count = len(values["invoice_set"])
        customer = customers.get(customer_id, {})
        output.append(
            {
                "CustomerID": customer_id,
                "CustomerName": " ".join(filter(None, [customer.get("FirstName"), customer.get("LastName")])),
                "InvoiceCount": invoice_count,
                "CustomerType": "Repeat Customer" if invoice_count >= 2 else "One-time Buyer",
                "NetRevenue": money(values["net"]),
                "AverageOrderValue": money(safe_divide(values["net"], Decimal(invoice_count))),
                "AverageBasketSize": ratio(safe_divide(Decimal(values["units"]), Decimal(invoice_count))),
                "UnitsSold": values["units"],
            }
        )
    write_csv("mart-customer-segments.csv", output, list(output[0].keys()))


def write_employee_performance(rows, employees, monthly_total):
    output = []
    for (employee_id, month), values in sorted(rows.items()):
        employee = employees.get(employee_id, {})
        output.append(
            {
                "EmployeeID": employee_id,
                "EmployeeName": " ".join(filter(None, [employee.get("FirstName"), employee.get("LastName")])),
                "SalesMonth": month,
                "NetRevenue": money(values["net"]),
                "InvoiceCount": len(values["invoice_set"]),
                "UnitsSold": values["units"],
                "MonthlyContributionShare": ratio(safe_divide(values["net"], monthly_total[month])),
            }
        )
    write_csv("mart-employee-performance.csv", output, list(output[0].keys()))


def write_geo_market(rows, cities, countries):
    output = []
    for (country_id, city_id), values in sorted(rows.items()):
        output.append(
            {
                "CountryID": country_id,
                "CountryName": countries.get(country_id, {}).get("CountryName", ""),
                "CityID": city_id,
                "CityName": cities.get(city_id, {}).get("CityName", ""),
                "NetRevenue": money(values["net"]),
                "UnitsSold": values["units"],
                "CustomerCount": len(values["customers"]),
                "InvoiceCount": len(values["invoices"]),
            }
        )
    write_csv("mart-geo-market.csv", output, list(output[0].keys()))


def write_class_performance(rows):
    output = [
        {
            "Class": class_name,
            "NetRevenue": money(values["net"]),
            "GrossRevenueEstimate": money(values["gross"]),
            "UnitsSold": values["units"],
            "LineCount": values["lines"],
            "RevenuePerUnit": money(safe_divide(values["net"], Decimal(values["units"]))),
        }
        for class_name, values in sorted(rows.items())
    ]
    write_csv("mart-class-performance.csv", output, list(output[0].keys()))


def write_executive_kpis(source_counts, totals, invoice_perf, customer_perf, invoice_customer_seen):
    invoice_count = len(invoice_perf)
    customer_count = len(customer_perf)
    repeat_customers = sum(1 for row in customer_perf.values() if len(row["invoice_set"]) >= 2)
    rows = [
        {
            "NetRevenue": money(totals["net"]),
            "GrossRevenueEstimate": money(totals["gross"]),
            "UnitsSold": totals["units"],
            "SalesLineCount": source_counts["sales"],
            "InvoiceCount": invoice_count,
            "CustomerCount": customer_count,
            "RepeatCustomerCount": repeat_customers,
            "OneTimeBuyerCount": customer_count - repeat_customers,
            "RepeatCustomerRatio": ratio(safe_divide(Decimal(repeat_customers), Decimal(customer_count))),
            "AverageOrderValue": money(safe_divide(totals["net"], Decimal(invoice_count))),
            "AverageBasketSize": ratio(safe_divide(Decimal(totals["units"]), Decimal(invoice_count))),
            "InvoiceCustomerPairCount": len(invoice_customer_seen),
        }
    ]
    write_csv("mart-executive-kpis.csv", rows, list(rows[0].keys()))


def write_summary(source_counts, totals, invoice_perf, customer_perf, revenue_diff_sample, data_quality):
    summary = {
        "dataset_path": str(DATASET_DIR.relative_to(PROJECT_ROOT)),
        "source_counts": source_counts,
        "net_revenue_total": money(totals["net"]),
        "gross_revenue_estimate_total": money(totals["gross"]),
        "units_sold": totals["units"],
        "invoice_count": len(invoice_perf),
        "customer_count_with_sales": len(customer_perf),
        "data_quality": dict(data_quality),
        "revenue_formula_check_sample": revenue_diff_sample,
        "generated_files": sorted(path.name for path in EXPORTS_DIR.glob("mart-*.csv")),
    }
    (EXPORTS_DIR / "data-preparation-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
