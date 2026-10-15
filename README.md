# Maven Toys - Sales & Inventory Performance Analysis
**Revenue: $14.44M | Profit: $4.01M | 800K Transactions | 1.09M Units Sold | 50 Stores | 21 Months**

This project analyzes 800K sales transactions to identify profit drivers, store performance, and inventory risk using MySQL 9.0 and Power BI.

### Business Problem
Identify why margin dropped from 29.27% to 26.20% and where inventory risk is concentrated.

## Dashboard Preview
### 1. Business At A Glance
![Business](https://github.com/user-attachments/assets/7a2830b2-44cb-44c1-8d89-75ccdff13cf7)

KPI cards, profit by category, avg profit per store by location, monthly trend with seasonality (Peak: Dec 2022 $0.88M).

### 2. Inventory Risk

![Inventory](https://github.com/user-attachments/assets/43cdcae4-af60-41da-9d7a-fcc7d65cb556)
Overstock value by location, stock health, critical reorder table.

### 3. Sales & Product Performance
![Sales](https://github.com/user-attachments/assets/fd8f6b4c-0cb4-4667-b8d3-af80843dc9c7)
Top 10 by profit, profit by weekday, day/location performance.

## Key Findings
**1. Profit Concentration:** Toys $1.08M (26.89%) + Electronics 24.95% = 51% of profit. Art & Crafts leads by volume (325K units). Lowest profit: Sports & Outdoors $505K on 169K units.

**2. Location Performance:** Airport stores = 6% of stores but 9.4% of profit. Avg profit per Airport store $126K vs $77K Downtown (+62%). Top Airport product Colorbuds (11K units) = impulse purchases.

**3. Product & Day:** Colorbuds $835K (21% total), #1 for 475/638 days. Best day Friday $770K (20%). 2022: $7.48M revenue at 29.27% margin vs 2023: $6.96M at 26.20% - 3% margin drop despite lower revenue. PlayDoh Can top 2 by units but outside top 10 by profit = low margin.

**4. Inventory Risk**
*Power BI Overview:* Overstock $60.70K, inventory value $410.24K, 17.4 days left.

*MySQL Deep-Dive (Granular analysis to validate dashboard):*
This detailed breakdown was done in MySQL Workbench to check overstock at product and store level.

The largest single product in any one store is 139 units (Dinosaur Figures - Airport). There is no concentrated overstock in one product.
[MySQL Overstock Fix](https://github.com/user-attachments/assets/71a3c6fd-c258-4f38-9739-961ddd3687b0)

- **Slowest-moving:** Airport Dinosaur Figures - 139 units on hand in Airport vs 169 units sold over 21 months. Ratio 0.82, value locked $2,083.
- **Fastest-moving:** Downtown Glass Marbles - 5,120 units sold vs 110 units remaining in Downtown. Ratio 0.02, reorder required.
- **Health:** Overstock is distributed across many products holding 110-139 units each in different stores. This shows inventory is well-controlled.
- **Risk:** The main risk is stockout, not overstock. Action Figure has 6.5 days and Colorbuds has 4.6 days of stock left across all locations.

## Data Model
- `toy_products` (35 products, 5 categories)
- `toy_stores` (50 stores)
- `toy_sales` (800K rows)
- `toy_inventory` (current stock)

**Views:** `daily_profit`, `store_performance`

**Relationships (Reverse Engineered):**
![Relationships](https://github.com/user-attachments/assets/b3ea88e9-4f0f-43af-a916-f640e1cf9c97)
toy_sales.Store_ID -> toy_stores.Store_ID
toy_sales.Product_ID -> toy_products.Product_ID
toy_inventory.Store_ID -> toy_stores.Store_ID
toy_inventory.Product_ID -> toy_products.Product_ID

## Data Engineering
Sales file 800K rows  - Import Wizard too slow. Used LOAD DATA INFILE.
Data quality: Product_Price/Cost were VARCHAR with $. Fixed in MySQL:
```sql
UPDATE toy_products SET Product_Price = REPLACE(Product_Price, '$', '');
ALTER TABLE toy_products MODIFY Product_Price DECIMAL(10,2);
CREATE INDEX idx_sales_store_date ON toy_sales(Store_ID, Date);
```

## How to Run
MySQL: Import small CSVs via Wizard. For sales_new.csv, place in `C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/` and run LOAD DATA INFILE.

Power BI: Open `Maven_Toys.pbix` > Refresh

**Live Dashboard:** [View Interactive Dashboard on Power BI](https://app.powerbi.com/links/d03eQr4TnX?ctid=5fe78ac1-1afe-4009-aa04-a71efb4a5042&pbi_source=linkShare)

## Files
- `maven_toys_project.sql` - 16 queries + optimized overstock fix
- `Maven_Toys.pbix`
- `/images` - screenshots

Data: [Kaggle - Toy Sales](https://www.kaggle.com/datasets/mysarahmadbhat/toy-sales)

## Author
Oluwabukola Awolusi - Data Analyst | [LinkedIn - Oluwabukola Awolusi](https://www.linkedin.com/in/oluwabukola-awolusi-926072364)
