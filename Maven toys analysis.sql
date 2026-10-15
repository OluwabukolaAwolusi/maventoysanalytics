-- =========================================================
-- MAVEN TOYS - SALES & INVENTORY ANALYSIS
-- Author: Oluwabukola Awolusi
-- DB: maven_toys | MySQL 9.0 | 800K rows | 1.09M units
-- =========================================================

-- STEP 0: CREATE DATABASE
DROP DATABASE IF EXISTS maven_toys;
CREATE DATABASE maven_toys;
USE maven_toys;

-- STEP 1: CREATE TABLES
-- Cost/Price as VARCHAR first to clean $ and ,

CREATE TABLE toy_products (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(255),
    Product_Category VARCHAR(100),
    Product_Cost VARCHAR(50),
    Product_Price VARCHAR(50)
);

CREATE TABLE toy_stores (
    Store_ID INT PRIMARY KEY,
    Store_Name VARCHAR(255),
    Store_City VARCHAR(100),
    Store_Location VARCHAR(100),
    Store_Region VARCHAR(100),
    Store_Open_Date DATE
);

CREATE TABLE toy_sales (
    Sale_ID INT PRIMARY KEY,
    Date DATE,
    Store_ID INT,
    Product_ID INT,
    Units INT
);

CREATE TABLE toy_inventory (
    Store_ID INT,
    Product_ID INT,
    Stock_On_Hand INT,
    PRIMARY KEY (Store_ID, Product_ID)
);

-- STEP 2: DATA LOAD
-- Small CSVs: Wizard -> products, stores, inventory
-- Large CSV: sales_new.csv (800K+) -> LOAD DATA INFILE
-- File path: C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/

SET FOREIGN_KEY_CHECKS=0;
SET UNIQUE_CHECKS=0;

LOAD DATA INFILE 
'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/sales_new.csv'
INTO TABLE toy_sales
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Sale_ID, Date, Store_ID, Product_ID, Units);

SET UNIQUE_CHECKS=1;
SET FOREIGN_KEY_CHECKS=1;

-- STEP 3: FOREIGN KEYS & INDEXES (after load)

ALTER TABLE toy_sales 
ADD CONSTRAINT fk_sales_store 
FOREIGN KEY (Store_ID) REFERENCES toy_stores(Store_ID);

ALTER TABLE toy_sales 
ADD CONSTRAINT fk_sales_product 
FOREIGN KEY (Product_ID) REFERENCES toy_products(Product_ID);

ALTER TABLE toy_inventory 
ADD CONSTRAINT fk_inv_store 
FOREIGN KEY (Store_ID) REFERENCES toy_stores(Store_ID);

ALTER TABLE toy_inventory 
ADD CONSTRAINT fk_inv_product 
FOREIGN KEY (Product_ID) REFERENCES toy_products(Product_ID);

CREATE INDEX idx_sales_store_date 
ON toy_sales(Store_ID, Date);

CREATE INDEX idx_sales_product 
ON toy_sales(Product_ID);

CREATE INDEX idx_inventory_stock 
ON toy_inventory(Stock_On_Hand);

SELECT COUNT(*) AS total_transactions 
FROM toy_sales;

-- STEP 4: DATA CLEANING
-- Price/Cost had $ and commas -> wrong profit in Power BI

SET SQL_SAFE_UPDATES = 0;

UPDATE toy_products 
SET Product_Cost = REPLACE(Product_Cost, '$', '');

UPDATE toy_products 
SET Product_Cost = REPLACE(Product_Cost, ',', '');

UPDATE toy_products 
SET Product_Price = REPLACE(Product_Price, '$', '');

UPDATE toy_products 
SET Product_Price = REPLACE(Product_Price, ',', '');

ALTER TABLE toy_products 
MODIFY Product_Cost DECIMAL(10,2),
MODIFY Product_Price DECIMAL(10,2);

SET SQL_SAFE_UPDATES = 1;

-- STEP 5: VIEWS FOR POWER BI

-- daily_profit: For monthly & daily trend
CREATE VIEW daily_profit AS 
SELECT 
    Date,
    SUM(tsa.Units * (tpr.Product_Price - tpr.Product_Cost)) 
        AS total_profit,
    SUM(tsa.Units * tpr.Product_Price) 
        AS total_revenue,
    SUM(tsa.Units) AS total_units
FROM toy_products tpr
JOIN toy_sales tsa 
    ON tpr.Product_ID = tsa.Product_ID
GROUP BY Date;

-- store_performance: By location type
CREATE VIEW store_performance AS
SELECT 
    tst.Store_Name, 
    tst.Store_Location, 
    tst.Store_City,
    SUM(tsa.Units * (tpr.Product_Price - tpr.Product_Cost)) 
        AS total_profit,
    SUM(tsa.Units * tpr.Product_Price) 
        AS total_revenue,
    SUM(tsa.Units) AS total_units
FROM toy_stores tst
JOIN toy_sales tsa 
    ON tst.Store_ID = tsa.Store_ID
JOIN toy_products tpr 
    ON tpr.Product_ID = tsa.Product_ID
GROUP BY 
    tst.Store_Name, 
    tst.Store_Location, 
    tst.Store_City;

-- STEP 6: ANALYSIS (16 QUESTIONS)

-- Q1: Category by profit & units
SELECT 
    Product_Category,
    SUM(tsa.Units) AS total_units,
    SUM(tsa.Units * (Product_Price - Product_Cost)) 
        AS total_profit
FROM toy_products tpr
JOIN toy_sales tsa 
    ON tpr.Product_ID = tsa.Product_ID
GROUP BY Product_Category
ORDER BY total_units DESC;

-- Q2: Toys top by profit, Art & Crafts top by volume (325K units)

-- Q3: Top products by units
SELECT 
    Product_ID, 
    Product_Name, 
    Product_Category,
    SUM(tsa.Units) AS total_units,
    SUM(tsa.Units * (Product_Price - Product_Cost)) 
        AS total_profit
FROM toy_products tpr
JOIN toy_sales tsa 
    ON tpr.Product_ID = tsa.Product_ID
GROUP BY Product_ID, Product_Name, Product_Category
ORDER BY total_units DESC 
LIMIT 10;

-- Q4: Best product in each category
WITH highest_product_category AS (
    SELECT 
        Product_ID, 
        Product_Name, 
        Product_Category,
        SUM(tsa.Units) AS total_units,
        DENSE_RANK() OVER (
            PARTITION BY Product_Category 
            ORDER BY SUM(tsa.Units) DESC
        ) AS product_rank
    FROM toy_products tpr
    JOIN toy_sales tsa 
        ON tpr.Product_ID = tsa.Product_ID
    GROUP BY Product_ID, Product_Name, Product_Category
)
SELECT * 
FROM highest_product_category 
WHERE product_rank = 1
ORDER BY total_units DESC;

-- Q5 & Q6: #1 product each day + count days as #1
WITH ranked AS (
    SELECT 
        Date, 
        Product_Name,
        SUM(tsa.Units * (Product_Price - Product_Cost)) 
            AS total_profit,
        DENSE_RANK() OVER (
            PARTITION BY Date 
            ORDER BY SUM(tsa.Units * (Product_Price - Product_Cost)) DESC
        ) AS rnk
    FROM toy_products tpr
    JOIN toy_sales tsa 
        ON tpr.Product_ID = tsa.Product_ID
    GROUP BY Date, Product_Name
)
SELECT 
    Product_Name, 
    COUNT(*) AS days_as_number_1
FROM ranked 
WHERE rnk = 1
GROUP BY Product_Name
ORDER BY days_as_number_1 DESC;
-- Colorbuds ~475 / 638 days

-- Q7: Location performance
-- Airport avg 126K vs Downtown 77K (+62%)
SELECT 
    Store_Location,
    COUNT(*) AS stores,
    ROUND(AVG(total_profit),2) AS avg_profit,
    SUM(total_profit) AS total_profit
FROM store_performance
GROUP BY Store_Location
ORDER BY avg_profit DESC;

-- Q8: Airport top products
-- Colorbuds 11K = portable impulse buy
SELECT 
    Store_Location, 
    Product_Name, 
    SUM(Units) AS units 
FROM toy_sales
JOIN toy_products USING(Product_ID)
JOIN toy_stores USING(Store_ID)
WHERE Store_Location = 'Airport'
GROUP BY Store_Location, Product_Name
ORDER BY units DESC 
LIMIT 5;

-- Q9: Monthly performance
SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS month,
    SUM(total_profit) AS monthly_profit
FROM daily_profit
GROUP BY month
ORDER BY monthly_profit DESC;

-- Q10: Best vs worst days
-- Best $16,379 vs Worst $3,013 (5.4x gap)
SELECT * 
FROM daily_profit 
ORDER BY total_profit DESC 
LIMIT 5;

SELECT * 
FROM daily_profit 
ORDER BY total_profit ASC 
LIMIT 5;

-- Q11: Monthly growth with LAG
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(Date, '%Y-%m') AS ym,
        SUM(Units * Product_Price) AS revenue
    FROM toy_sales
    JOIN toy_products USING(Product_ID)
    GROUP BY ym
)
SELECT 
    ym,
    revenue,
    LAG(revenue) OVER (ORDER BY ym) AS prev_month,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY ym)) / 
        LAG(revenue) OVER (ORDER BY ym) * 100, 2
    ) AS growth_pct
FROM monthly_sales
ORDER BY ym;

-- Q12 & Q13: Critical reorder - high profit, low stock
WITH store_product_stats AS (
    SELECT 
        tst.Store_Location, 
        tst.Store_Name, 
        tpr.Product_Name,
        SUM(tsa.Units * (Product_Price - Product_Cost)) 
            AS total_profit,
        SUM(tsa.Units) AS units_sold
    FROM toy_sales tsa
    JOIN toy_products tpr 
        ON tsa.Product_ID = tpr.Product_ID
    JOIN toy_stores tst 
        ON tst.Store_ID = tsa.Store_ID
    GROUP BY Store_Location, Store_Name, Product_Name
),
inventory AS (
    SELECT 
        tst.Store_Location, 
        tst.Store_Name, 
        tpr.Product_Name,
        SUM(tinv.Stock_On_Hand) AS available_stock
    FROM toy_inventory tinv
    JOIN toy_products tpr 
        ON tinv.Product_ID = tpr.Product_ID
    JOIN toy_stores tst 
        ON tst.Store_ID = tinv.Store_ID
    GROUP BY Store_Location, Store_Name, Product_Name
)
SELECT s.*, i.available_stock
FROM store_product_stats s
LEFT JOIN inventory i 
    USING(Store_Location, Store_Name, Product_Name)
WHERE i.available_stock IS NOT NULL
ORDER BY total_profit DESC 
LIMIT 10;

-- Q14: Check if any product sold at loss (0 rows = healthy)
SELECT 
    Product_ID, 
    Product_Name, 
    Product_Cost, 
    Product_Price
FROM toy_products
WHERE Product_Cost > Product_Price;

-- Q15: Dead stock - in stock but never sold there
-- Only 15 units total
SELECT 
    tst.Store_Name, 
    tst.Store_Location, 
    tpr.Product_Name,
    SUM(tinv.Stock_On_Hand) AS stock_never_sold_here
FROM toy_inventory tinv
JOIN toy_products tpr 
    ON tinv.Product_ID = tpr.Product_ID
JOIN toy_stores tst 
    ON tst.Store_ID = tinv.Store_ID
LEFT JOIN toy_sales tsa 
    ON tsa.Product_ID = tinv.Product_ID 
    AND tsa.Store_ID = tinv.Store_ID
WHERE tsa.Sale_ID IS NULL 
  AND tinv.Stock_On_Hand > 0
GROUP BY Store_Name, Store_Location, Product_Name;

-- Q16: FIXED OVERSTOCK - High stock but low sales
WITH sales_agg AS (
    SELECT 
        Store_ID, 
        Product_ID, 
        SUM(Units) AS units_sold
    FROM toy_sales
    GROUP BY Store_ID, Product_ID
),
inventory_agg AS (
    SELECT 
        Store_ID, 
        Product_ID, 
        SUM(Stock_On_Hand) AS available_stock
    FROM toy_inventory
    GROUP BY Store_ID, Product_ID
)
SELECT 
    tst.Store_Name,
    tst.Store_Location,
    tpr.Product_Name,
    tpr.Product_Price,
    s.units_sold,
    i.available_stock,
    ROUND(
        i.available_stock / NULLIF(s.units_sold,0), 2
    ) AS stock_to_sales_ratio,
    ROUND(
        i.available_stock * tpr.Product_Price, 2
    ) AS overstock_value
FROM sales_agg s
JOIN inventory_agg i USING(Store_ID, Product_ID)
JOIN toy_stores tst ON tst.Store_ID = s.Store_ID
JOIN toy_products tpr ON tpr.Product_ID = s.Product_ID
WHERE i.available_stock > 100
ORDER BY i.available_stock DESC
LIMIT 10;

/*
RESULT - Q16:
- Largest single product in any store is 139 units
  (Dinosaur Figures - Airport)
- Slowest: Airport Dinosaur Figures
  139 on hand vs 169 sold over 21 months
  Ratio 0.82, $2,083 locked
- Fastest: Downtown Glass Marbles
  5,120 sold vs 110 remaining
  Ratio 0.02, reorder needed
- Insight: No massive overstock
  Total $60.70K in Power BI is many small leftovers
  (110-139 units each) across stores
  Inventory is well-controlled
  Real risk is stockout
  Action Figure 6.5 days and Colorbuds 4.6 days left
*/
