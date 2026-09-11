# CSV → Azure SQL Pipeline

**Tech:** Azure Data Factory + ADLS Gen2 + Azure SQL + Power BI

```
sales.csv
    ↓
ADLS Gen2
    ↓
Azure Data Factory
    ↓
Copy Activity
    ↓
Azure SQL
    ↓
Power BI
```

Unlike the local PySpark project, this one is built on real Azure
resources, so this repo holds the **infrastructure-as-code** (ADF entity
JSON + SQL DDL) and sample data — you deploy it into your own Azure
subscription rather than run it locally. Everything here is written to
match exactly what ADF Studio's Git integration exports, so you can point
an ADF Git-connected factory at this repo and it will pick these up as
real linked services / datasets / pipelines / triggers.

## Project structure

```
csv_to_azuresql_pipeline/
├── data/                         # sample CSVs to upload to ADLS
│   ├── customers.csv
│   ├── products.csv
│   └── orders.csv
├── sql/
│   └── create_tables.sql         # Azure SQL DDL (run before the pipeline)
├── adf/
│   ├── linkedService/
│   │   ├── LS_ADLS_Gen2.json
│   │   └── LS_AzureSqlDatabase.json
│   ├── dataset/
│   │   ├── DS_ADLS_Customers.json    # basic, one dataset per file
│   │   ├── DS_ADLS_Products.json
│   │   ├── DS_ADLS_Orders.json
│   │   ├── DS_SQL_Customers.json
│   │   ├── DS_SQL_Products.json
│   │   ├── DS_SQL_Orders.json
│   │   ├── DS_ADLS_CSV_Generic.json  # bonus: parameterized dataset
│   │   └── DS_SQL_Table_Generic.json # bonus: parameterized dataset
│   ├── pipeline/
│   │   ├── PL_CSV_to_AzureSQL.json          # basic: 3 explicit Copy Activities
│   │   └── PL_CSV_to_AzureSQL_Dynamic.json  # bonus: ForEach + parameters
│   └── trigger/
│       └── TR_Daily_CSV_Load.json
├── powerbi/
│   └── dax_measures.md           # dashboard build guide + DAX measures
└── README.md
```

## Build steps (Azure Portal)

### 1. Create resources
- Resource Group
- **ADLS Gen2** storage account with hierarchical namespace enabled
  - Create a container named `sales-pipeline`, then a folder inside it
    named `raw`
- **Azure SQL Database** (Basic/Serverless tier is enough for this)
  - Under the SQL **server's** networking settings, enable
    *"Allow Azure services and resources to access this server"* so ADF
    (and later Power BI) can connect
- **Azure Data Factory** instance

### 2. Upload the sample data
Upload `data/customers.csv`, `data/products.csv`, `data/orders.csv` into
`sales-pipeline/raw/` in ADLS (Storage Explorer, Azure Portal upload, or
`az storage fs file upload`).

### 3. Create the SQL tables
Run `sql/create_tables.sql` against your Azure SQL Database (Query editor
in the portal, SSMS, or Azure Data Studio) to create `Customers`,
`Products`, and `Orders` with the right columns and foreign keys.

### 4. Wire up ADF
Easiest path — connect ADF Studio to this repo via **Manage → Git
configuration** and it will pick up everything under `adf/` automatically.
Otherwise, recreate manually in this order (each step depends on the one
before it):
1. **Linked Services**: `LS_ADLS_Gen2`, `LS_AzureSqlDatabase` — fill in
   your real storage account name / SQL server name / credentials in the
   ADF UI (the JSON in this repo uses placeholders on purpose — never
   commit real connection strings or keys; use Azure Key Vault in a real
   deployment).
2. **Datasets**: the six `DS_*` datasets pointing at those linked services.
3. **Pipeline**: `PL_CSV_to_AzureSQL` — three Copy Activities. Note
   `Copy_Orders` depends on `Copy_Customers` and `Copy_Products` succeeding
   first, since `Orders` has foreign keys into both.
4. **Trigger**: `TR_Daily_CSV_Load` — starts `Stopped`; switch it to
   `Started` in the ADF UI once you're happy with a manual test run.

Run the pipeline once manually (**Debug**, or **Add trigger → Trigger
now**) and check **Monitor** in ADF Studio to confirm all three Copy
Activities succeeded and see rows-read/rows-written counts.

### 5. Build the Power BI dashboard
See `powerbi/dax_measures.md` for the full walkthrough. In short: connect
Power BI Desktop to the Azure SQL Database, import the three tables, add
the DAX measures, and build four visuals — **Total Sales**, **Total
Orders**, **Sales by Product**, **Sales by Month**.

## ADF concepts covered here

| Concept | Where |
|---|---|
| **Linked Service** | `adf/linkedService/*.json` — the connection info to ADLS and Azure SQL |
| **Dataset** | `adf/dataset/*.json` — the shape/location of data within a linked service |
| **Pipeline** | `adf/pipeline/PL_CSV_to_AzureSQL.json` — orchestrates the activities |
| **Copy Activity** | Each `Copy_*` activity — moves data from an ADLS dataset to a SQL dataset |
| **Integration Runtime** | `AutoResolveIntegrationRuntime`, referenced in both linked services |
| **Trigger** | `adf/trigger/TR_Daily_CSV_Load.json` — daily schedule trigger |
| **Parameters** | `PL_CSV_to_AzureSQL_Dynamic.json` + `DS_ADLS_CSV_Generic.json` / `DS_SQL_Table_Generic.json` — one reusable Copy Activity parameterized by file/table name, looped with `ForEach` |
| **Monitoring** | Not a file — use the **Monitor** tab in ADF Studio after running the pipeline to see run history, activity durations, and row counts |

The bonus `PL_CSV_to_AzureSQL_Dynamic` pipeline is optional — it does the
same job as the basic pipeline but shows how you'd scale this pattern to
50 tables without adding 50 Copy Activities: one `ForEach` over an array
parameter, driving one parameterized Copy Activity.

## Notes on the sample data

`data/orders.csv` spans January–April 2024 across multiple products and
customers specifically so the Power BI "Sales by Product" and "Sales by
Month" visuals have something meaningful to show. `customer_id` and
`product_id` values in `orders.csv` match the keys in `customers.csv` and
`products.csv` so the SQL foreign keys and Power BI relationships resolve
cleanly.
