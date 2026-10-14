##  Maven Toys Sales Analysis
 800K+ sales rows with 50 stores and 30K stock.
$14.44M total revenue | $4.01M total profit | 27.79% margin | 1M units | 30K stock left

## 📊 Live Dashboard
Access the published interactive dashboard here:
**[👉 Click to View Power BI Report](https://app.powerbi.com/links/d03eQr4TnX?ctid=5fe78ac1-1afe-4009-aa04-a71efb4a5042&pbi_source=linkShare)**

Features:
- Sales by Store Location & City
- Profit & Revenue by Product Category
- Time-series trend analysis
- Best & worst performing products


Three Page Story
# 1. Executive Overview - The Airport Story
<img width="1002" height="550" alt="image" src="https://github.com/user-attachments/assets/dd3eed8b-f8c4-4942-beae-fe2f4cad1078" />

**What this page proves:**

Toys $1.08M (26.98%) + Electronics $1.10M (24.95%) = 51% profit from 2 categories. Not 5.
Airport stores: 6% of stores but 9.4% of profit. Avg profit/store: Airport $126K vs Downtown $77K = 62% more profitable per store.
In 2022: $7.48M revenue -> $2M profit (26.7%) vs 2023: $6.96M -> $2M (28.7%) = +2% margin with $520K less revenue. Pricing power, not sales growth.

# 2. Inventory Risk - Where Money gets stuck
<img width="1012" height="547" alt="image" src="https://github.com/user-attachments/assets/eb3ba1c7-a1ee-4ce2-a070-94b923d8d6ae" />

Meaures created: Days_of_Stock_Left = DIVIDE([total_stock], [Avg Daily Sales], 0)
UNDERSTOCK (left table red): 776 units in Ciudad de Mexico 2 will stockout in 6.65 days avg. Worst: Lego Bricks 2 units left = 0.33 days = CRITICAL. Reorder now.
OVERSTOCK (right charts): $12.07K overstock value in Ciudad de Mexico 2 alone. Teddy Bear 20 units 57 days + Playfoam 10 units 74 days = OVERSTOCK -> 50% discount & stop reorder
Key insight: High stock != overstock. Dinosaur Figures 400+ days = overstock. Colorbuds high stock + 4 days coverage = understock because it sells fast.
# 3. Sales & Product Performance - Friday & Colorbuds
<img width="1019" height="546" alt="image" src="https://github.com/user-attachments/assets/24aa279c-f60a-46e3-8f87-8de2d00263c0" />

**Sales Performance
What this page proves:
Friday is king: $770,739 total profit (20% of all profit). Airport + Downtown = 65% of Friday $2.86M. Action: Double staff Friday at Airport/Downtown
Colorbuds sells more: $835K profit (21% of total). #1 product for 475 out of 638 days. Only 35 days another product beats it. Peaks Saturday $134K. Stock Sat for Colorbuds.
Volume trap: PlayDoh Can high units but low profit.

**Top 10 Highest Unit: Colorbuds, PlayDoh Can, Barrel O' Slime etc - shows what moves, not just what profits

MySQL Engineering 
Dataset were loaded into the created tables using data import wizard
while load data infile method was used to load dataset for toy sales 
because it contains over 800,000 dataset and using import data wizard will
make data import vey slow.

SET FOREIGN_KEY_CHECKS=0; SET UNIQUE_CHECKS=0;
LOAD DATA INFILE 'C:/ProgramData/MySQL/.../sales_new.csv'
INTO TABLE toy_sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

**cleaning - Product_Cost had $12.99 and 1,234.56 causing profit = 0:

SET SQL_SAFE_UPDATES=0;
UPDATE toy_products 
SET Product_Cost = REPLACE(REPLACE(Product_Cost,'$',''),',',''),
    Product_Price = REPLACE(REPLACE(Product_Price,'$',''),',','');
ALTER TABLE toy_products MODIFY Product_Cost DECIMAL(10,2);
Indexes for performance:

CREATE INDEX idx_sales_store_date ON toy_sales(Store_ID, Date);
CREATE INDEX idx_sales_product ON toy_sales(Product_ID);

**Power BI DAX** 
- Total_profit = SUMX(toy_sales, Units * (Product_Price - Product_Cost))
Margin = DIVIDE([Total_profit], [total_revenue])
- Days_of_Stock = DIVIDE([total_stock], [Avg Daily Sales], 0)
- Overstock Risk = SUMX
('maven_toys toy_inventory', 'maven_toys toy_inventory'[Stock_On_Hand_in_stores]
* 
RELATED('maven_toys toy_products'[Product_Price]))

- Understock Risk = 
IF([total_stock]=0 && [Total_units]>0, "CRITICAL - Stockout - LOST SALES",
IF([Days of Stock Left] < 7, "CRITICAL - Reorder NOW",
IF([Days of Stock Left] < 14, "WARNING - Reorder Soon",
IF([Days of Stock Left] > 50, "OVERSTOCK - Discount & Stop Order",
"Healthy"))))
- Avg Daily Sales = DIVIDE([Total_units], 365)

**Bookmarks: 2022 Performance ($7.48M / 26.7%) | 2023 Performance ($6.96M / 28.7%) | All View(2022,& 2023) ($14.44M / 27.79%)**

 Questions Answered in SQL
All in maven_toys_full.sql:

- Monthly trend - DATE_FORMAT + AVG daily profit
- Best vs Worst Day - $16,379 (2023-04-30) = 5.4x $3,013 (2022-09-12). Top 5 = Fri/Sat/Sun + Holiday, Bottom 5 = Mon-Wed, 3 Mondays
- Store Location - Airport 126K avg vs Downtown 77K = 62% more. If open 1 more Airport = +$48K vs Downtown
- Why Airport wins - Top 5 products all small, portable, impulse: Colorbuds 11K units - ideal for flight entertainment, no Lego/Nerf - too big for luggage
- #1 Product Each Day - DENSE_RANK() OVER (PARTITION BY Date ORDER BY profit DESC)
Days as #1 - Colorbuds 475 days #1 out of 638
- #1 Per Category - Art & Crafts: PlayDoh Can 103K, Electronics: Colorbuds 104K overall #1, Games: Deck Of Cards 84K, Sports: Splash Balls 60K, Toys: Lego Bricks 59K
- Category Profit vs Volume - Toys $1.07M #1 profit, Art & Crafts 325K #1 volume but $2.31/unit = trap
- Stock Risk - NTILE(4) - Q1 = lowest stock urgent reorder, 6 of top 10 critical = Action Figure 0 stock, Puebla 3 lost $9,210
- Loss Check - WHERE Product_Cost > Product_Price = 0 rows = healthy pricing, no loss products
- Dead Stock - LEFT JOIN sales WHERE Sale_ID IS NULL AND Stock > 0 = 15 units truly dead vs 289K Deck Of Cards overstock in Mexico City 2 that HAS sold but too much
- Days of Stock Left - Most actionable for operations team


# How to Run 
- MySQL 9.0 Workbench: Open maven_toys
- Run All
Power BI: Open powerbi/Maven_Toys.pbix
Data source: Maven Toys Kaggle - https://www.kaggle.com/datasets/mysarahmadbhat/toy-sales - 4 CSVs: products, stores, sales 800K, inventory
