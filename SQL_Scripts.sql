-- Step 1: Create Database
CREATE DATABASE dominos_data;

-- Step 2: Connect to the Database
-- (Use psql or your preferred client to connect)

-- Step 3: Create Tables
-- Table for Sales Target
CREATE TABLE sales_target (
    pizza VARCHAR(100),
    sales_target INTEGER
);

-- Table for Sales Data

CREATE TABLE sales_data (
    sn INTEGER,
    date DATE,
    branch VARCHAR(50),
    pizza_sold VARCHAR(50),
    category VARCHAR(50),
    price NUMERIC,
    quantity INTEGER,
    timevalue TIME,
    time_range VARCHAR(50)
);


-- Table for Branch Data
CREATE TABLE branch_data (
    branch VARCHAR(50) PRIMARY KEY,
    longitude NUMERIC,
    latitude NUMERIC,
    manager VARCHAR(100)
);

-- Table for Daily Sales Target
CREATE TABLE daily_sales_target (
    day VARCHAR(20),
    target INTEGER
);

-- Step 4: Load Data into Tables
-- used the GUI interface

-- Step 5: Data Cleaning

-- a) Remove Duplicate Records
DELETE FROM sales_data
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM sales_data
    GROUP BY date, branch, pizza_sold, category, price, quantity, timevalue
);

-- b) Handle Missing Values
-- Replace missing branch data
UPDATE sales_data
SET branch = 'Unknown'
WHERE branch IS NULL;

-- Replace missing sales_target values
UPDATE sales_target
SET sales_target = 0
WHERE sales_target IS NULL;

-- c) Normalize Time Ranges
UPDATE sales_data
SET time_range = CASE
    WHEN timevalue BETWEEN '00:00:00' AND '06:00:00' THEN 'Midnight to Morning'
    WHEN timevalue BETWEEN '06:00:01' AND '12:00:00' THEN 'Morning to Afternoon'
    WHEN timevalue BETWEEN '12:00:01' AND '18:00:00' THEN 'Afternoon to Evening'
    ELSE 'Evening to Midnight'
END;

-- d) Add a Total Sales Column
ALTER TABLE sales_data ADD COLUMN total_sales NUMERIC;

UPDATE sales_data
SET total_sales = price * quantity;

-- e) Create Branch-Level Performance Table
CREATE TABLE branch_performance AS
SELECT
    branch,
    SUM(total_sales) AS total_sales,
    COUNT(*) AS transactions
FROM sales_data
GROUP BY branch;

-- Step 6: Reporting

-- a) Daily Sales Summary
SELECT
    date,
    SUM(total_sales) AS total_sales,
    COUNT(*) AS total_transactions
FROM sales_data
GROUP BY date
ORDER BY date;

-- b) Top-Selling Pizzas
SELECT
    pizza_sold,
    SUM(quantity) AS total_quantity,
    SUM(total_sales) AS total_sales
FROM sales_data
GROUP BY pizza_sold
ORDER BY total_sales DESC
LIMIT 5;

-- c) Branch-Level Insights
SELECT
    b.branch,
    b.manager,
    bp.total_sales,
    bp.transactions,
    b.longitude,
    b.latitude
FROM branch_data b
JOIN branch_performance bp ON b.branch = bp.branch
ORDER BY bp.total_sales DESC;

-- d) Daily Target Achievement
SELECT
    sd.date,
    sd.branch,
    SUM(sd.total_sales) AS total_sales,
    dst.target,
    CASE
        WHEN SUM(sd.total_sales) >= dst.target THEN 'Achieved'
        ELSE 'Not Achieved'
    END AS target_status
FROM sales_data sd
JOIN daily_sales_target dst ON TO_CHAR(sd.date, 'Day') = dst.day
GROUP BY sd.date, sd.branch, dst.target
ORDER BY sd.date;

-- Step 7: Export Results
-- Export branch performance to a CSV file


-- Export cleaned sales data to a CSV file
COPY (SELECT * FROM sales_data) TO '/path/to/output/cleaned_sales_data.csv' WITH CSV HEADER;

