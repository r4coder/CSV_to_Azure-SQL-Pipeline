/* ============================================================
   CSV -> Azure SQL Pipeline
   Run this in Azure SQL Database (via SSMS / Azure Data Studio /
   the Query editor in the Azure Portal) BEFORE running the ADF
   pipeline, so the Copy Activity has tables to land data into.
   ============================================================ */

-- Drop in dependency order if re-running
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
GO

CREATE TABLE dbo.Customers (
    customer_id     VARCHAR(10)     NOT NULL PRIMARY KEY,
    customer_name   NVARCHAR(100)   NOT NULL,
    email           NVARCHAR(150)   NULL,
    region          NVARCHAR(50)    NULL,
    signup_date     DATE            NULL
);
GO

CREATE TABLE dbo.Products (
    product_id      VARCHAR(10)     NOT NULL PRIMARY KEY,
    product_name    NVARCHAR(100)   NOT NULL,
    category        NVARCHAR(50)    NULL,
    unit_price      DECIMAL(10,2)   NOT NULL
);
GO

CREATE TABLE dbo.Orders (
    order_id        INT             NOT NULL PRIMARY KEY,
    customer_id     VARCHAR(10)     NOT NULL,
    product_id      VARCHAR(10)     NOT NULL,
    order_date      DATE            NOT NULL,
    quantity        INT             NOT NULL,
    total_amount    DECIMAL(10,2)   NOT NULL,
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id),
    CONSTRAINT FK_Orders_Products  FOREIGN KEY (product_id)  REFERENCES dbo.Products(product_id)
);
GO

/* ------------------------------------------------------------
   Quick sanity-check queries once the ADF pipeline has run
   ------------------------------------------------------------ */
-- SELECT COUNT(*) AS customer_count FROM dbo.Customers;
-- SELECT COUNT(*) AS product_count  FROM dbo.Products;
-- SELECT COUNT(*) AS order_count    FROM dbo.Orders;

-- Total Sales
-- SELECT SUM(total_amount) AS total_sales FROM dbo.Orders;

-- Sales by Product
-- SELECT p.product_name, SUM(o.total_amount) AS sales
-- FROM dbo.Orders o
-- JOIN dbo.Products p ON o.product_id = p.product_id
-- GROUP BY p.product_name
-- ORDER BY sales DESC;

-- Sales by Month
-- SELECT FORMAT(order_date, 'yyyy-MM') AS sale_month, SUM(total_amount) AS sales
-- FROM dbo.Orders
-- GROUP BY FORMAT(order_date, 'yyyy-MM')
-- ORDER BY sale_month;
