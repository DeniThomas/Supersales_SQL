CREATE DATABASE superstore;
USE superstore;
CREATE TABLE sales_data (
    Row_ID INT PRIMARY KEY,
    Order_ID VARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(100),
    State VARCHAR(100),
    Postal_Code INT,
    Region VARCHAR(50),
    Product_ID VARCHAR(50),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales FLOAT
);
SHOW VARIABLES LIKE 'secure_file_priv';
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Superstore Sales Dataset.csv'
INTO TABLE sales_data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@Row_ID, @Order_ID, @Order_Date, @Ship_Date, @Ship_Mode, @Customer_ID, @Customer_Name, @Segment, 
@Country, @City, @State, @Postal_Code, @Region, @Product_ID, @Category, @Sub_Category, @Product_Name, @Sales)
SET 
    Row_ID = @Row_ID,
    Order_ID = @Order_ID,
    Order_Date = STR_TO_DATE(@Order_Date, '%d/%m/%Y'),
    Ship_Date = STR_TO_DATE(@Ship_Date, '%d/%m/%Y'),
    Ship_Mode = @Ship_Mode,
    Customer_ID = @Customer_ID,
    Customer_Name = @Customer_Name,
    Segment = @Segment,
    Country = @Country,
    City = @City,
    State = @State,
    Postal_Code = NULLIF(@Postal_Code, ''),  -- Convert empty Postal_Code to NULL
    Region = @Region,
    Product_ID = @Product_ID,
    Category = @Category,
    Sub_Category = @Sub_Category,
    Product_Name = @Product_Name,
    Sales = @Sales;
    SELECT * FROM sales_data LIMIT 10;
    ALTER TABLE sales_data MODIFY COLUMN Postal_Code VARCHAR(10);

SELECT COUNT(*) FROM sales_data;
SELECT * FROM sales_data LIMIT 10;
SELECT COUNT(*) FROM sales_data;
SELECT 
    COUNT(*) AS Missing_Order_IDs
FROM sales_data 
WHERE Order_ID IS NULL;
SELECT 
    COUNT(*) AS Missing_Customer_Names
FROM sales_data 
WHERE Customer_Name IS NULL;
SELECT MIN(Order_Date), MAX(Order_Date), MIN(Ship_Date), MAX(Ship_Date) FROM sales_data;
SELECT Order_ID, Product_ID, COUNT(*) 
FROM sales_data 
GROUP BY Order_ID, Product_ID
HAVING COUNT(*) > 1;
SELECT DISTINCT Postal_Code FROM sales_data ORDER BY Postal_Code;

SET SQL_SAFE_UPDATES = 0;

-- Step 1: Create a temporary table to store the Row_IDs to be deleted
CREATE TEMPORARY TABLE temp_ids AS 
SELECT Row_ID 
FROM sales_data 
WHERE Row_ID NOT IN (
    SELECT MIN(Row_ID) 
    FROM sales_data 
    GROUP BY Order_ID, Product_ID
);

-- Step 2: Delete using the temporary table
DELETE FROM sales_data 
WHERE Row_ID IN (SELECT Row_ID FROM temp_ids);

-- Step 3: Drop the temporary table
DROP TEMPORARY TABLE temp_ids;

SET SQL_SAFE_UPDATES = 1;
CREATE INDEX idx_order_product ON sales_data(Order_ID, Product_ID);
SELECT * FROM sales_data WHERE Sales NOT REGEXP '^[0-9]+(\.[0-9]+)?$';
SELECT YEAR(Order_Date) AS Year, SUM(Sales) AS Total_Sales 
FROM sales_data 
GROUP BY Year 
ORDER BY Year;

-- Find the top-selling products per year:
SELECT YEAR(Order_Date) AS Year, Product_Name, SUM(Sales) AS Total_Sales
FROM sales_data
GROUP BY Year, Product_Name
ORDER BY Year, Total_Sales DESC
LIMIT 10;

-- Identify the most profitable customer segments:
SELECT Segment, SUM(Sales) AS Total_Sales
FROM sales_data
GROUP BY Segment
ORDER BY Total_Sales DESC;

-- Find out which products drive the most sales in each segment:
SELECT Segment, Product_Name, SUM(Sales) AS Total_Sales
FROM sales_data
GROUP BY Segment, Product_Name
ORDER BY Segment, Total_Sales DESC
LIMIT 10;

DESC sales_data;
ALTER TABLE sales_data ADD COLUMN Profit FLOAT;
SHOW COLUMNS FROM sales_data;

SHOW COLUMNS FROM sales_data LIKE 'Profit';
SELECT Profit FROM sales_data LIMIT 10;

SET SQL_SAFE_UPDATES = 0;
UPDATE sales_data SET Profit = Sales * 0.2;
SET SQL_SAFE_UPDATES = 1;

-- Check Data Integrity--Ensure all numeric columns (Sales, Profit, etc.) have valid values.
SELECT * FROM sales_data WHERE Sales IS NULL OR Sales < 0;
SELECT * FROM sales_data WHERE Profit IS NULL OR Profit < 0;

-- Find the average shipping time per segment:
SELECT Segment, AVG(DATEDIFF(Ship_Date, Order_Date)) AS Avg_Shipping_Days
FROM sales_data
GROUP BY Segment;

-- Identify Best and Worst Performing States
SELECT State, SUM(Sales) AS Total_Sales 
FROM sales_data 
GROUP BY State 
ORDER BY Total_Sales DESC
LIMIT 10;

-- Find the most profitable products:
SELECT Product_Name, SUM(Profit) AS Total_Profit
FROM sales_data
GROUP BY Product_Name
ORDER BY Total_Profit DESC
LIMIT 10;

-- Aggregated Views -sales by year
CREATE VIEW sales_by_year AS
SELECT YEAR(Order_Date) AS Year, SUM(Sales) AS Total_Sales, SUM(Profit) AS Total_Profit
FROM sales_data
GROUP BY Year;

-- Sales by Segment
CREATE VIEW sales_by_segment AS
SELECT Segment, SUM(Sales) AS Total_Sales, SUM(Profit) AS Total_Profit
FROM sales_data
GROUP BY Segment;

-- Top-Selling Products
CREATE VIEW top_products AS
SELECT Product_Name, SUM(Sales) AS Total_Sales, SUM(Profit) AS Total_Profit
FROM sales_data
GROUP BY Product_Name
ORDER BY Total_Sales DESC
LIMIT 10;


