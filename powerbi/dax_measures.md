# Power BI Dashboard — Sales Overview

Connect Power BI Desktop to Azure SQL (`Get Data → Azure → Azure SQL Database`),
point it at the server/database from `LS_AzureSqlDatabase`, and import
`dbo.Customers`, `dbo.Products`, and `dbo.Orders`.

## 1. Model relationships

Power BI should auto-detect these from the foreign keys, but verify in
**Model view**:

| From             | To                | Cardinality |
|------------------|-------------------|-------------|
| Orders[customer_id] | Customers[customer_id] | Many-to-one |
| Orders[product_id]  | Products[product_id]   | Many-to-one |

## 2. Date table (needed for clean "Sales by Month")

`Orders.order_date` alone works for a simple bar chart, but for proper
month sorting/filtering add a dedicated Date table:

```dax
DateTable =
CALENDAR ( MIN ( Orders[order_date] ), MAX ( Orders[order_date] ) )
```

Then add columns:

```dax
MonthName = FORMAT ( DateTable[Date], "MMM YYYY" )
MonthSort = YEAR ( DateTable[Date] ) * 100 + MONTH ( DateTable[Date] )
```

Sort `MonthName` by `MonthSort` (Column tool → Sort by Column), and relate
`DateTable[Date]` (1) → `Orders[order_date]` (many).

## 3. Measures

Create these in a new table (right-click model → **New Table**, name it
`_Measures`, or just add them to `Orders`):

```dax
Total Sales =
SUM ( Orders[total_amount] )

Total Orders =
DISTINCTCOUNT ( Orders[order_id] )

Total Quantity Sold =
SUM ( Orders[quantity] )

Average Order Value =
DIVIDE ( [Total Sales], [Total Orders] )
```

## 4. The four dashboard visuals

| Visual | Type | Fields |
|---|---|---|
| **Total Sales** | Card | `[Total Sales]` |
| **Total Orders** | Card | `[Total Orders]` |
| **Sales by Product** | Bar chart | Axis: `Products[product_name]`, Value: `[Total Sales]` |
| **Sales by Month** | Line or column chart | Axis: `DateTable[MonthName]` (sorted by `MonthSort`), Value: `[Total Sales]` |

Optional extras once the basics work:
- A slicer on `Customers[region]` to filter the whole page.
- A table visual of `Products[category]` × `[Total Sales]` as a quick
  category breakdown.

## 5. Refresh

- **Manual**: Home → Refresh in Power BI Desktop after the ADF pipeline runs.
- **Scheduled** (once published to the Power BI Service): Dataset settings →
  Scheduled refresh, set to run shortly after `TR_Daily_CSV_Load` completes
  (e.g. 07:00 UTC if the trigger runs at 06:00 UTC) so the numbers reflect
  that day's load. Requires an on-premises data gateway only if Azure SQL
  firewall rules block the Power BI Service — usually not needed if
  "Allow Azure services" is enabled on the SQL server.
