/*
===============================================================================
Project Name : Retail Sales Analysis using MySQL
Author       : Vinay Kumar Kallepilli
Tools Used   : MySQL
Dataset      : orders.csv, order_details.csv, sales_target.csv

Description:
This project analyzes retail sales data using MySQL to identify
sales trends, customer purchasing behavior, product performance,
geographical performance, and target achievement by answering
real-world business questions.

SQL Concepts Used:
- Joins
- Aggregate Functions
- GROUP BY
- CASE WHEN
- Common Table Expressions (CTEs)
- Subqueries
- Window Functions
- Date Functions
===============================================================================
*/
/*===============================================================================
TABLE OF CONTENTS
===============================================================================

1. Data Preparation
2. Sales Performance Analysis
3. Customer Analysis
4. Product & Category Analysis
5. Geographic Analysis
6. Target vs Actual Analysis

===============================================================================*/
/*
===============================================================================
1. DATA PREPARATION
===============================================================================
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Rename columns for better readability and SQL standards.
-- (Skip this block if columns are already renamed — check with DESCRIBE first)
-- ---------------------------------------------------------------------------
ALTER TABLE orders
RENAME COLUMN `Order ID` TO order_id,
RENAME COLUMN `Order Date` TO order_date,
RENAME COLUMN CustomerName TO customer_name,
RENAME COLUMN State TO state,
RENAME COLUMN City TO city;

ALTER TABLE order_details
RENAME COLUMN `Order ID` TO order_id,
RENAME COLUMN `Sub-Category` TO sub_category;

ALTER TABLE sales_target
RENAME COLUMN `Month of Order Date` TO month_order_date;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Understand the structure of each table.
-- ---------------------------------------------------------------------------
DESCRIBE orders;
DESCRIBE order_details;
DESCRIBE sales_target;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Count total records available in each table.
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS total_orders FROM orders;
SELECT COUNT(*) AS total_order_details FROM order_details;
SELECT COUNT(*) AS total_target_records FROM sales_target;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify NULL values in Orders table.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*) - COUNT(order_id) AS order_id_nulls,
    COUNT(*) - COUNT(order_date) AS order_date_nulls,
    COUNT(*) - COUNT(customer_name) AS customer_name_nulls,
    COUNT(*) - COUNT(state) AS state_nulls,
    COUNT(*) - COUNT(city) AS city_nulls
FROM orders;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify NULL values in Order Details table.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)-COUNT(order_id) AS order_id_nulls,
    COUNT(*)-COUNT(amount) AS amount_nulls,
    COUNT(*)-COUNT(profit) AS profit_nulls,
    COUNT(*)-COUNT(quantity) AS quantity_nulls,
    COUNT(*)-COUNT(category) AS category_nulls,
    COUNT(*)-COUNT(sub_category) AS sub_category_nulls
FROM order_details;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify NULL values in Sales Target table.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)-COUNT(month_order_date) AS month_nulls,
    COUNT(*)-COUNT(category) AS category_nulls,
    COUNT(*)-COUNT(target) AS target_nulls
FROM sales_target;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Remove completely blank rows from Orders table.
-- (Raw export contained 60 fully-blank trailing rows — an export artifact,
-- not real records — not caught by standard NULL checks since fields
-- imported as empty strings rather than NULL)
-- ---------------------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

DELETE FROM orders
WHERE order_id = '' OR order_id IS NULL;

SELECT COUNT(*) AS total_orders_after_cleanup FROM orders;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Check duplicate records in Orders table.
-- ---------------------------------------------------------------------------
SELECT
    order_id, order_date, customer_name, state, city,
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id, order_date, customer_name, state, city
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Check duplicate records in Order Details table.
-- ---------------------------------------------------------------------------
SELECT
    order_id, amount, profit, quantity, category, sub_category,
    COUNT(*) AS duplicate_count
FROM order_details
GROUP BY order_id, amount, profit, quantity, category, sub_category
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Check duplicate records in Sales Target table.
-- ---------------------------------------------------------------------------
SELECT
    month_order_date, category, target,
    COUNT(*) AS duplicate_count
FROM sales_target
GROUP BY month_order_date, category, target
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Convert Order Date into DATE format.
-- ---------------------------------------------------------------------------
UPDATE orders
SET order_date = STR_TO_DATE(order_date, '%d-%m-%Y');

ALTER TABLE orders
MODIFY COLUMN order_date DATE;

-- ---------------------------------------------------------------------------
-- Business Requirement:
-- Create additional date attributes to support time-based sales analysis.
-- ---------------------------------------------------------------------------
ALTER TABLE orders
ADD COLUMN order_year INT,
ADD COLUMN order_month VARCHAR(20),
ADD COLUMN order_month_no INT,
ADD COLUMN order_quarter VARCHAR(5),
ADD COLUMN month_year VARCHAR(10);

-- ---------------------------------------------------------------------------
-- Business Requirement:
-- Populate Year, Month, Quarter and Month-Year columns.
-- ---------------------------------------------------------------------------
UPDATE orders
SET
    order_year = YEAR(order_date),
    order_month = MONTHNAME(order_date),
    order_month_no = MONTH(order_date),
    order_quarter = CONCAT('Q', QUARTER(order_date)),
    month_year = DATE_FORMAT(order_date, '%b-%y');
    
    /*
===============================================================================
2. SALES PERFORMANCE ANALYSIS
===============================================================================
*/

/*
-------------------------------------------------------------------------------
2.1 OVERALL BUSINESS KPIs
-------------------------------------------------------------------------------
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the total sales generated by the business.
-- ---------------------------------------------------------------------------
SELECT SUM(amount) AS total_sales FROM order_details;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the total profit earned by the business.
-- ---------------------------------------------------------------------------
SELECT SUM(profit) AS total_profit FROM order_details;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Find the total number of customers.
-- ---------------------------------------------------------------------------
SELECT COUNT(DISTINCT customer_name) AS total_customers FROM orders;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Find the total number of product categories.
-- ---------------------------------------------------------------------------
SELECT COUNT(DISTINCT category) AS total_categories FROM order_details;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the total quantity of products sold.
-- ---------------------------------------------------------------------------
SELECT SUM(quantity) AS total_quantity FROM order_details;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate Total Sales, Total Orders, and Average Order Value together.
-- ---------------------------------------------------------------------------
SELECT
    SUM(od.amount) AS total_sales,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(od.amount) / COUNT(DISTINCT o.order_id), 2) AS average_order_value
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id;

/*
-------------------------------------------------------------------------------
2.2 MONTHLY PERFORMANCE
-------------------------------------------------------------------------------
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total sales for each month.
-- ---------------------------------------------------------------------------
SELECT o.order_year, o.order_month_no,o.month_year,
    SUM(od.amount) AS total_sales FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_year, o.order_month_no, o.month_year
ORDER BY o.order_year, o.order_month_no;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total profit for each month.
-- ---------------------------------------------------------------------------
SELECT
    o.order_year,o.order_month_no,o.month_year,
    SUM(od.profit) AS total_profit FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_year, o.order_month_no, o.month_year
ORDER BY o.order_year, o.order_month_no;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the total number of orders for each month.
-- ---------------------------------------------------------------------------
SELECT order_year,order_month_no,month_year,
    COUNT(order_id) AS total_orders FROM orders
GROUP BY order_year, order_month_no, month_year
ORDER BY order_year, order_month_no;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the monthly Average Order Value.
-- ---------------------------------------------------------------------------
SELECT o.order_year,o.order_month_no,o.month_year,
    ROUND(SUM(od.amount) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_year, o.order_month_no, o.month_year
ORDER BY o.order_year, o.order_month_no;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Compare each month's sales with the previous month using LAG().
-- ---------------------------------------------------------------------------
SELECT month_year,total_sales,
    LAG(total_sales) OVER (ORDER BY order_year, order_month_no) AS previous_month_sales,
    total_sales - LAG(total_sales) OVER (ORDER BY order_year, order_month_no) AS sales_difference
FROM
(SELECT o.order_year,o.order_month_no,o.month_year,
        SUM(od.amount) AS total_sales FROM orders o 
        INNER JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.order_year,o.order_month_no,o.month_year) monthly_sales;


/*
-------------------------------------------------------------------------------
2.3 QUARTERLY PERFORMANCE
-------------------------------------------------------------------------------
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total sales for each quarter.
-- ---------------------------------------------------------------------------
SELECT o.order_year,o.order_quarter,SUM(od.amount) AS total_sales 
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_year, o.order_quarter
ORDER BY o.order_year, o.order_quarter;

/*
-------------------------------------------------------------------------------
2.4 YEARLY PERFORMANCE
-------------------------------------------------------------------------------
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total sales for each year.
-- ---------------------------------------------------------------------------
SELECT o.order_year, SUM(od.amount) AS total_sales
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_year
ORDER BY o.order_year;

/*
-------------------------------------------------------------------------------
2.5 BEST & WORST PERFORMANCE
-------------------------------------------------------------------------------
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the highest performing sales month.
-- ---------------------------------------------------------------------------
SELECT o.month_year,
SUM(od.amount) AS total_sales FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.month_year ORDER BY total_sales DESC LIMIT 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the lowest performing sales month.
-- ---------------------------------------------------------------------------
SELECT o.month_year, SUM(od.amount) AS total_sales
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.month_year ORDER BY total_sales ASC LIMIT 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the highest performing profit month.
-- ---------------------------------------------------------------------------
SELECT o.month_year, 
SUM(od.profit) AS total_profit FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.month_year
ORDER BY total_profit DESC LIMIT 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the lowest performing profit month.
-- ---------------------------------------------------------------------------
SELECT o.month_year,
SUM(od.profit) AS total_profit FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.month_year ORDER BY total_profit ASC LIMIT 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the month with the highest number of orders.
-- ---------------------------------------------------------------------------
SELECT month_year, COUNT(order_id) AS total_orders
FROM orders GROUP BY month_year
ORDER BY total_orders DESC LIMIT 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the month with the lowest number of orders.
-- ---------------------------------------------------------------------------
SELECT month_year, COUNT(order_id) AS total_orders
FROM orders GROUP BY month_year
ORDER BY total_orders ASC LIMIT 1;

/*
===============================================================================
3. CUSTOMER ANALYSIS
===============================================================================
Note:
This dataset does not contain a unique customer_id.
Customer analysis is therefore performed using customer_name as the customer identifier.
===============================================================================
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the top 10 customers based on total sales.
-- ---------------------------------------------------------------------------
SELECT o.customer_name, SUM(od.amount) AS total_sales
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.customer_name ORDER BY total_sales DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the top 10 customers based on total profit.
-- ---------------------------------------------------------------------------
SELECT o.customer_name, SUM(od.profit) AS total_profit
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.customer_name ORDER BY total_profit DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the total number of orders placed by each customer.
-- ---------------------------------------------------------------------------
SELECT customer_name, COUNT(order_id) AS total_orders
FROM orders GROUP BY customer_name ORDER BY total_orders DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify customers who placed more than one order (repeat customers).
-- ---------------------------------------------------------------------------
SELECT customer_name, COUNT(order_id) AS total_orders
FROM orders GROUP BY customer_name HAVING COUNT(order_id) > 1 ORDER BY total_orders DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Rank customers based on total sales using ROW_NUMBER().
-- ---------------------------------------------------------------------------
SELECT customer_name, total_sales, ROW_NUMBER() OVER(ORDER BY total_sales DESC) AS customer_rank
FROM (
    SELECT o.customer_name, SUM(od.amount) AS total_sales
    FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.customer_name
) sales_rank;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify customers whose total sales are above the average customer sales.
-- ---------------------------------------------------------------------------
SELECT
    customer_name,
    total_sales
FROM
( SELECT o.customer_name,SUM(od.amount) AS total_sales FROM orders o 
    INNER JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.customer_name ) customer_sales
WHERE total_sales >
( SELECT AVG(total_sales) FROM
 ( SELECT SUM(od.amount) AS total_sales FROM orders o 
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.customer_name) avg_customer_sales
)

ORDER BY total_sales DESC;

/*
===============================================================================
4. PRODUCT & CATEGORY ANALYSIS
===============================================================================
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total sales for each product category.
-- ---------------------------------------------------------------------------
SELECT category, SUM(amount) AS total_sales
FROM order_details GROUP BY category ORDER BY total_sales DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total profit for each product category.
-- ---------------------------------------------------------------------------
SELECT category, SUM(profit) AS total_profit
FROM order_details GROUP BY category ORDER BY total_profit DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the total quantity sold for each product category.
-- ---------------------------------------------------------------------------
SELECT category, SUM(quantity) AS total_quantity_sold
FROM order_details GROUP BY category ORDER BY total_quantity_sold DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the best-performing product category based on sales.
-- ---------------------------------------------------------------------------
SELECT category, SUM(amount) AS total_sales
FROM order_details GROUP BY category ORDER BY total_sales DESC LIMIT 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the best-performing product category based on profit.
-- ---------------------------------------------------------------------------
SELECT category, SUM(profit) AS total_profit
FROM order_details GROUP BY category ORDER BY total_profit DESC LIMIT 1;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total sales for each sub-category.
-- ---------------------------------------------------------------------------
SELECT sub_category, SUM(amount) AS total_sales
FROM order_details GROUP BY sub_category ORDER BY total_sales DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total profit for each sub-category.
-- ---------------------------------------------------------------------------
SELECT sub_category, SUM(profit) AS total_profit
FROM order_details GROUP BY sub_category ORDER BY total_profit DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the percentage contribution of each category to total sales.
-- ---------------------------------------------------------------------------
SELECT category,
 SUM(amount) AS total_sales,
ROUND(SUM(amount)*100/(SELECT SUM(amount) FROM order_details), 2) AS sales_contribution_percentage
FROM order_details GROUP BY category ORDER BY sales_contribution_percentage DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the profit margin for each product category.
-- ---------------------------------------------------------------------------
SELECT category,
 SUM(amount) AS total_sales, SUM(profit) AS total_profit,
ROUND((SUM(profit)/SUM(amount))*100, 2) AS profit_margin_percentage
FROM order_details GROUP BY category ORDER BY profit_margin_percentage DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the category with the lowest profit margin.
-- ---------------------------------------------------------------------------
SELECT category, 
SUM(amount) AS total_sales, SUM(profit) AS total_profit,
ROUND((SUM(profit)/SUM(amount))*100, 2) AS profit_margin_percentage
FROM order_details GROUP BY category ORDER BY profit_margin_percentage ASC LIMIT 1;
-- ---------------------------------------------------------------------------
-- Business Question:
-- Classify product categories based on total profit.
-- ---------------------------------------------------------------------------
SELECT category, SUM(profit) AS total_profit,
    CASE
        WHEN SUM(profit) >= 10000 THEN 'High Profit'
        WHEN SUM(profit) >= 5000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM order_details GROUP BY category ORDER BY total_profit DESC;
-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify product categories with profit above the average category profit.
-- ---------------------------------------------------------------------------
SELECT category,SUM(profit) AS total_profit
FROM order_details GROUP BY category HAVING SUM(profit) >
( SELECT AVG(category_profit)
    FROM (SELECT SUM(profit) AS category_profit
        FROM order_details GROUP BY category) avg_profit)
ORDER BY total_profit DESC;
-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the average selling price for each product category.
-- ---------------------------------------------------------------------------
SELECT category, ROUND(AVG(amount), 2) AS average_sale_value
FROM order_details GROUP BY category ORDER BY average_sale_value DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the average profit earned per product category.
-- ---------------------------------------------------------------------------
SELECT category, ROUND(AVG(profit), 2) AS average_profit
FROM order_details GROUP BY category ORDER BY average_profit DESC;

/*
===============================================================================
5. GEOGRAPHIC ANALYSIS
===============================================================================
*/

/*
-------------------------------------------------------------------------------
5.1 STATE ANALYSIS
-------------------------------------------------------------------------------
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total sales for each state.
-- ---------------------------------------------------------------------------
SELECT o.state, SUM(od.amount) AS total_sales
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.state ORDER BY total_sales DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total profit for each state.
-- ---------------------------------------------------------------------------
SELECT o.state, SUM(od.profit) AS total_profit
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.state ORDER BY total_profit DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the total number of orders received from each state.
-- ---------------------------------------------------------------------------
SELECT state, COUNT(order_id) AS total_orders
FROM orders GROUP BY state ORDER BY total_orders DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the percentage contribution of each state to total sales.
-- ---------------------------------------------------------------------------
SELECT o.state, SUM(od.amount) AS total_sales,
ROUND(SUM(od.amount)*100/(SELECT SUM(amount) FROM order_details), 2) AS sales_contribution_percentage
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.state ORDER BY sales_contribution_percentage DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the highest performing state based on sales (with its profit shown for context).
-- ---------------------------------------------------------------------------
SELECT o.state, SUM(od.amount) AS total_sales, SUM(od.profit) AS total_profit
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.state ORDER BY total_sales DESC LIMIT 1;

/*-------------------------------------------------------------------------------
5.2 CITY ANALYSIS
-------------------------------------------------------------------------------*/
-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total sales for each city.
-- ---------------------------------------------------------------------------
SELECT o.city, SUM(od.amount) AS total_sales
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.city ORDER BY total_sales DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate total profit for each city.
-- ---------------------------------------------------------------------------
SELECT o.city, SUM(od.profit) AS total_profit
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.city ORDER BY total_profit DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the total number of orders received from each city.
-- ---------------------------------------------------------------------------
SELECT city, COUNT(order_id) AS total_orders
FROM orders GROUP BY city ORDER BY total_orders DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the percentage contribution of each city to total sales.
-- ---------------------------------------------------------------------------
SELECT o.city, SUM(od.amount) AS total_sales,
ROUND(SUM(od.amount)*100/(SELECT SUM(amount) FROM order_details), 2) AS sales_contribution_percentage
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.city ORDER BY sales_contribution_percentage DESC;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify the highest performing city based on sales (with its profit shown for context).
-- ---------------------------------------------------------------------------
SELECT o.city, SUM(od.amount) AS total_sales, SUM(od.profit) AS total_profit
FROM orders o INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.city ORDER BY total_sales DESC LIMIT 1;
/*
===============================================================================
6. TARGET vs ACTUAL ANALYSIS
===============================================================================
*/

-- ---------------------------------------------------------------------------
-- Business Question:
-- Compare monthly actual sales with sales targets for each category.
-- ---------------------------------------------------------------------------
SELECT o.month_year, od.category, SUM(od.amount) AS actual_sales,
 MAX(st.target) AS target_sales
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN sales_target st ON 
st.month_order_date = o.month_year AND st.category = od.category
GROUP BY o.order_year, o.order_month_no, o.month_year, od.category
ORDER BY o.order_year, o.order_month_no, od.category;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate sales variance against target for each month and category.
-- ---------------------------------------------------------------------------
SELECT o.month_year, od.category, SUM(od.amount) AS actual_sales,
 MAX(st.target) AS target_sales,
SUM(od.amount) - MAX(st.target) AS sales_variance
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN sales_target st ON 
st.month_order_date = o.month_year AND st.category = od.category
GROUP BY o.order_year, o.order_month_no, o.month_year, od.category
ORDER BY o.order_year, o.order_month_no, od.category;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Calculate the sales achievement percentage against target.
-- ---------------------------------------------------------------------------
SELECT o.month_year, od.category, SUM(od.amount) AS actual_sales, MAX(st.target) AS target_sales,
ROUND((SUM(od.amount)/MAX(st.target))*100, 2) AS achievement_percentage
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN sales_target st ON 
st.month_order_date = o.month_year AND st.category = od.category
GROUP BY o.order_year, o.order_month_no, o.month_year, od.category
ORDER BY o.order_year, o.order_month_no, od.category;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Identify whether the sales target was achieved.
-- ---------------------------------------------------------------------------
SELECT o.month_year, od.category, SUM(od.amount) AS actual_sales,
 MAX(st.target) AS target_sales,
CASE WHEN SUM(od.amount) >= MAX(st.target)
 THEN 'Target Achieved' ELSE 'Target Not Achieved' END AS target_status
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN sales_target st ON 
st.month_order_date = o.month_year AND st.category = od.category
GROUP BY o.order_year, o.order_month_no, o.month_year, od.category
ORDER BY o.order_year, o.order_month_no, od.category;

-- ---------------------------------------------------------------------------
-- Business Question:
-- Create a complete Target vs Actual performance report by month and category
-- (combines actual sales, target, variance, achievement %, and status in one query).
-- ---------------------------------------------------------------------------
WITH monthly_sales AS (
    SELECT o.order_year, o.order_month_no, o.month_year, od.category,
    SUM(od.amount) AS actual_sales, MAX(st.target) AS target_sales
    FROM orders o
    INNER JOIN order_details od ON o.order_id = od.order_id
    INNER JOIN sales_target st ON 
    st.month_order_date = o.month_year AND st.category = od.category
    GROUP BY o.order_year, o.order_month_no, o.month_year, od.category
)
SELECT month_year, category, actual_sales, target_sales,
actual_sales - target_sales AS sales_variance,
ROUND((actual_sales/target_sales)*100, 2) AS achievement_percentage,
CASE WHEN actual_sales >= target_sales
 THEN 'Target Achieved' ELSE 'Target Not Achieved' END AS target_status
FROM monthly_sales ORDER BY order_year, order_month_no, category;
