use project;
SELECT * FROM project.sales;
-- top 10 product with higest revenue--
SELECT `Product Id`,`Sub Category`, SUM(Quantity * `List Price`) AS Revenue FROM Sales
GROUP BY `Product Id`,`Sub Category` ORDER BY Revenue DESC LIMIT 10;


-- Top 5 highest selling product in each region
WITH ProductRevenue AS (SELECT Region, `Product Id`, SUM(Quantity * `List Price`) AS Revenue FROM Sales GROUP BY Region, `Product Id`),
RankedProducts AS (SELECT Region, `Product Id`, Revenue, RANK() OVER (PARTITION BY Region ORDER BY Revenue DESC) AS Ranked FROM ProductRevenue)
SELECT Region,`Product Id`, Revenue, Ranked FROM RankedProducts WHERE Ranked <= 5 ORDER BY Region, Ranked;


-- month over month growth comparison for 2022 and 2023 sales. Eg : jan 2022 vs jan 2023
-- Step 1: Extract the year and month from the order date and calculate the total sales
WITH MonthlySales AS (SELECT YEAR(`Order Date`) AS Year, MONTH(`Order Date`) AS Month,
SUM(Quantity * `List Price`) AS TotalSales FROM Sales GROUP BY YEAR(`Order Date`), MONTH(`Order Date`)),

-- Step 2: Filter the data for the years 2022 and 2023
FilteredSales AS (SELECT Year, Month, TotalSales FROM MonthlySales WHERE Year IN (2022, 2023))

-- Step 3: Join the 2022 and 2023 data for each month
SELECT s2022.Month, s2022.TotalSales AS Sales_2022, s2023.TotalSales AS Sales_2023,
(s2023.TotalSales - s2022.TotalSales) / NULLIF(s2022.TotalSales, 0) * 100 AS Growth_Percentage
FROM FilteredSales s2022
LEFT JOIN FilteredSales s2023 ON s2022.Month = s2023.Month AND s2022.Year = 2022 AND s2023.Year = 2023
ORDER BY s2022.Month;


-- category which month have highest sales
WITH MonthlyCategorySales AS (SELECT Category,EXTRACT(YEAR FROM `Order Date`) AS Year,
EXTRACT(MONTH FROM `Order Date`) AS Month,SUM(`Quantity` * `List Price`) AS Revenue
FROM Sales GROUP BY Category, EXTRACT(YEAR FROM `Order Date`), EXTRACT(MONTH FROM `Order Date`)),
RankedCategorySales AS (SELECT Category, Year, Month, Revenue, RANK() OVER (PARTITION BY Category ORDER BY Revenue DESC) AS RankED
FROM MonthlyCategorySales)
SELECT Category,Year,Month,Revenue FROM RankedCategorySales WHERE RankED = 1 ORDER BY Category;


-- category have the highest growth by profit in 2023 in compare with 2022
-- Step 1: Aggregate profit by category for each year
WITH AnnualCategoryProfit AS (SELECT Category,
EXTRACT(YEAR FROM `Order Date`) AS Year,
SUM(`List Price`-`cost price`) AS TotalProfit FROM Sales
WHERE EXTRACT(YEAR FROM `Order Date`) IN (2022, 2023)
GROUP BY Category,EXTRACT(YEAR FROM `Order Date`)),

-- Step 2: Separate profit data for 2022 and 2023
Profit2022 AS (
    SELECT Category,TotalProfit AS Profit2022
    FROM AnnualCategoryProfit WHERE Year = 2022),

Profit2023 AS (SELECT Category,TotalProfit AS Profit2023
FROM AnnualCategoryProfit WHERE Year = 2023)

-- Step 3: Join the profit data for 2022 and 2023 and calculate growth
SELECT p2022.Category,p2022.Profit2022,p2023.Profit2023,
    ((p2023.Profit2023 - p2022.Profit2022) / p2022.Profit2022) * 100 AS GrowthPercentage
FROM Profit2022 p2022 JOIN Profit2023 p2023 ON p2022.Category = p2023.Category
ORDER BY GrowthPercentage DESC LIMIT 1;