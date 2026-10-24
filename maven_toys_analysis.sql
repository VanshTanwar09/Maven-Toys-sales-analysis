USE maven_toys_db;

-- QUERY 1: Financial KPI Summary (Revenue, Cost, Profit & Margin %)
SELECT 
    ROUND(SUM(s.Units * p.Product_Price), 2) AS Total_Revenue,
    ROUND(SUM(s.Units * p.Product_Cost), 2) AS Total_Cost,
    ROUND(SUM(s.Units * (p.Product_Price - p.Product_Cost)), 2) AS Total_Profit,
    ROUND(
        (SUM(s.Units * (p.Product_Price - p.Product_Cost)) / SUM(s.Units * p.Product_Price)) * 100, 
        2
    ) AS Profit_Margin_Pct
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID;

-- QUERY 2: Product Category Performance & Rank (Window Function)
SELECT 
    p.Product_Category,
    SUM(s.Units) AS Units_Sold,
    ROUND(SUM(s.Units * p.Product_Price), 2) AS Revenue,
    ROUND(SUM(s.Units * (p.Product_Price - p.Product_Cost)), 2) AS Total_Profit,
    DENSE_RANK() OVER (ORDER BY SUM(s.Units * (p.Product_Price - p.Product_Cost)) DESC) AS Profit_Rank
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY p.Product_Category;

-- QUERY 3: Month-over-Month Revenue Growth (CTE + LAG)
WITH MonthlySales AS (
    SELECT 
        DATE_FORMAT(s.Date, '%Y-%m') AS Sales_Month,
        ROUND(SUM(s.Units * p.Product_Price), 2) AS Revenue
    FROM sales s
    JOIN products p ON s.Product_ID = p.Product_ID
    GROUP BY DATE_FORMAT(s.Date, '%Y-%m')
)
SELECT 
    Sales_Month,
    Revenue,
    LAG(Revenue, 1) OVER (ORDER BY Sales_Month) AS Prev_Month_Revenue,
    ROUND(
        ((Revenue - LAG(Revenue, 1) OVER (ORDER BY Sales_Month)) 
         / NULLIF(LAG(Revenue, 1) OVER (ORDER BY Sales_Month), 0)) * 100, 
        2
    ) AS MoM_Growth_Pct
FROM MonthlySales
ORDER BY Sales_Month;

-- QUERY 4: Store Location Performance
SELECT 
    st.Store_Location,
    COUNT(DISTINCT st.Store_ID) AS Total_Stores,
    ROUND(SUM(s.Units * p.Product_Price), 2) AS Total_Revenue,
    ROUND(SUM(s.Units * (p.Product_Price - p.Product_Cost)), 2) AS Total_Profit,
    ROUND(SUM(s.Units * p.Product_Price) / COUNT(DISTINCT st.Store_ID), 2) AS Avg_Revenue_Per_Store
FROM sales s
JOIN stores st ON s.Store_ID = st.Store_ID
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY st.Store_Location
ORDER BY Total_Revenue DESC;

-- QUERY 5: Inventory Risk (Stockouts on High-Demand Products)
SELECT 
    st.Store_Name,
    p.Product_Name,
    p.Product_Category,
    inv.Stock_On_Hand,
    SUM(s.Units) AS Lifetime_Units_Sold
FROM inventory inv
JOIN products p ON inv.Product_ID = p.Product_ID
JOIN stores st ON inv.Store_ID = st.Store_ID
JOIN sales s ON inv.Product_ID = s.Product_ID AND inv.Store_ID = s.Store_ID
WHERE inv.Stock_On_Hand = 0
GROUP BY st.Store_Name, p.Product_Name, p.Product_Category, inv.Stock_On_Hand
ORDER BY Lifetime_Units_Sold DESC
LIMIT 10;