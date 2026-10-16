# Maven Toys - Sales & Inventory Performance Analysis
**Revenue: $14.44M | Profit: $4.01M | 800K Transactions | 1.09M Units Sold | 50 Stores | 21 Months**

This project analyzes 800K sales transactions to identify profit drivers, store performance, and inventory risk using MySQL 9.0 and Power BI.

## Business Problem
Maven Toys has 50+ stores across Mexico but profit margin dropped from 29.27% to 26.20%.

I looked into the sales and inventory data to figure out what's really happening:

1.  Which categories actually make money? Toys made $1.07M profit, but Art & Crafts sold the most units (325K) — why the difference in margin?
2.  Why do Airport stores make 62% more per store than Downtown? I checked top products there — Colorbuds sold 11K units, looks like an impulse buy for travelers.
3.  When do we sell the most? Best day hit $16,379, worst was $3,013 — that's a 5.4x gap. Is it weekends or holidays driving it?
4.  Are we too dependent on one product? Colorbuds was the #1 seller for 475 out of 638 days.
5.  Where is our inventory at risk? From Power BI (overstock = >90 days stock left):
    - Fast movers (no overstock value): Action Figure and Colorbuds have <10 days left, so they don't show in overstock — need urgent reorder before stockout
    - Highest overstock value: Dinosaur 13K — 2,272 units available vs 29,012 sold, ~$13K locked because it has >90 days stock in some stores
    - Second highest units: Deck of Cards — 2,738 units available, >90 days stock
    - Transfer opportunity: Glass Marbles — 37,518 sold with only 795 left overall, but $736 overstock value in some stores where it has >90 days left — should be transferred to locations where it sells faster

I built this in MySQL and Power BI to give the team a clear dashboard for reorder vs transfer decisions.

## Dashboard Preview
### 1. Business At A Glance
![Business](https://github.com/user-attachments/assets/7a2830b2-44cb-44c1-8d89-75ccdff13cf7)

KPI cards, profit by category, avg profit per store by location, monthly trend with seasonality (Peak: Dec 2022 $0.88M).

### 2. Inventory Risk
![Inventory](https://github.com/user-attachments/assets/43cdcae4-af60-41da-9d7a-fcc7d65cb556)
Overstock $60.70K by definition >90 days left, inventory value $410.24K, 17.4 days left average.

### 3. Sales & Product Performance
![Sales](https://github.com/user-attachments/assets/fd8f6b4c-0cb4-4667-b8d3-af80843dc9c7)
Top 10 by profit, profit by weekday, day/location performance.

## Key Findings
**1. Profit Concentration:** Toys $1.08M (26.89%) + Electronics 24.95% = 51% of profit. Art & Crafts leads by volume (325K units). Lowest profit: Sports & Outdoors $505K on 169K units.

**2. Location Performance:** Airport stores = 6% of stores but 9.4% of profit. Avg profit per Airport store $126K vs $77K Downtown (+62%). Top Airport product Colorbuds (11K units) = impulse purchases.

**3. Product & Day:** Colorbuds $835K (21% total), #1 for 475/638 days. Best day Friday $770K (20%). 2022: $7.48M revenue at 29.27% margin vs 2023: $6.96M at 26.20% - 3% margin drop despite lower revenue. 

**4. Inventory Risk — (Overstock = >90 Days Stock Left)**
*Power BI Overview:* Overstock $60.70K, inventory value $410.24K, 17.4 days left average.

*MySQL Deep-Dive to validate Power BI:*

- **Highest Overstock Value:** Dinosaur 13K — 2,272 units available vs 29,012 sold. ~$13K locked. Has >90 days stock in several stores.
- **Highest Units:** Deck of Cards - 2,738 units available, also >90 days stock. Second biggest overstock.
- **Transfer Opportunity (Misplaced Fast Mover):** Glass Marbles — 37,518 sold vs 795 remaining overall (ratio 0.02, very fast). But $736 overstock value in some stores where it has >90 days left. Means stock is in wrong location.
- **Health:** No single store has massive overstock. Overstock is distributed — inventory is well-controlled.
- **Risk:** Main risk is stockout, not overstock. Action Figure and Colorbuds have <10 days left and 0 overstock value because they sell too fast (<90 days) — need urgent reorder.

## Recommendations

**1. Reorder Immediately (Stockout Risk — 0 Overstock Value):**
Action Figure, Colorbuds, Barrel O' Slime, Dino Egg, Splash Balls. These are Top 10 by profit but have <10 days stock left and therefore don't appear in overstock (>90 days). Buy new stock now or lose $40K+ profit.

**2. Transfer, Don't Buy (Highest Overstock):**
- Dinosaur 13K: Move 2,272 units from stores where it has >90 days left to stores where Dinosaur category sells faster. Frees ~$13K without new purchase.
- Deck of Cards (2,738 units): Move to Commercial and Downtown stores where there is critical need for reorder — ideal for impulse buys and bundle promotions.
- Glass Marbles (795 units, $736 overstock): Transfer from stores where it has >90 days left to locations where it sells faster. Overall it is fast (37,518 sold), just misplaced.

**3. Location Strategy:**
Push Colorbuds and small toys to Airport stores (11K units sold, impulse buy behavior). Shift large toys like Dinosaur from Airport to Residential location where families shop.

**4. Margin Fix:**
Review PlayDoh and Art & Crafts — high volume (325K units) but low margin. Either increase price by 5-10% or bundle with Toys (high margin) to lift margin back to 29%.

## Conclusion

The business problem is not just margin drop from 29.27% to 26.20%. It's two inventory problems:

1.  We are about to stockout on our most profitable products (Action Figure, Colorbuds) because they sell in <10 days and have 0 overstock value by our >90 days rule.
2.  We have $60.70K locked in slow locations — mainly Dinosaur 13K (2,272 units, $13K) and Deck of Cards (2,738 units), plus misplaced Glass Marbles (37,518 sold / 795 left).

Solution built in MySQL and Power BI: Reorder fast movers now, and transfer overstock from >90 days stores to fast-selling locations. This frees capital and prevents lost sales without spending extra.


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
