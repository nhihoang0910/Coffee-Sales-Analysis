USE coffee_sales;

-- CHECK DUPLICATES
WITH duplicate_cust AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY `Customer ID`) AS row_num FROM customers
)
SELECT * FROM duplicate_cust WHERE row_num>1;

WITH duplicate_orders AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY `Order ID`, `Order Date`, `Product ID`) AS row_num FROM orders
)
SELECT * FROM duplicate_orders WHERE row_num>1;

SELECT * FROM orders WHERE `Order ID`='NOP-21394-646' AND `Customer ID`='16982-35708-BZ';

WITH duplicate_pd AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY `Product ID`) AS row_num FROM products
)
SELECT * FROM duplicate_pd WHERE row_num>1;

-- CHECK EMPTY CELLS
SELECT * FROM customers WHERE `Customer ID`='';
SELECT * FROM orders WHERE `Order ID`='' OR Quantity IS NULL;
SELECT * FROM products WHERE `Customer ID`='';

-- COUNTRY ANALYSIS
-- 1. NUMBER OF CUSTOMERS BY COUNTRIES
SELECT 
    Country, 
    COUNT(`Customer ID`) AS `Total Customers`,
    SUM(CASE WHEN `Loyalty Card` = 'Yes' THEN 1 ELSE 0 END) AS `Loyal Customers`,
    -- Sums up the values returned by the CASE WHEN statement for each country.
    SUM(CASE WHEN `Loyalty Card` = 'No' THEN 1 ELSE 0 END) AS `Normal Customers`
FROM 
    customers
GROUP BY 
    Country
ORDER BY 
    `Total Customers` DESC;

-- 2. NUMBER OF ORDERS BY COUNTRY
SELECT customers.Country AS Country, SUM(Quantity) as total_orders FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2019 GROUP BY customers.Country;
-- US(685) > Ireland (123) > UK(106)
SELECT customers.Country AS Country, SUM(Quantity) as total_orders FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2020 GROUP BY customers.Country;
-- US(784)> Ireland (129) > UK (88)
SELECT customers.Country AS Country, SUM(Quantity) as total_orders FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2021 GROUP BY customers.Country;
-- US (907) > Ireland (189) > UK (47)
SELECT customers.Country AS Country, SUM(Quantity) as total_orders FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2022 GROUP BY customers.Country;
-- US (434) > Ireland (96) > UK (13)

-- CITY ANALYSIS
-- 3. NUMBER OF CUSTOMERS BY CITY
SELECT City, State, COUNT(*) AS num_customers
FROM US_customers
GROUP BY City, State
ORDER BY num_customers DESC
LIMIT 5;

SELECT 
    City, 
    State,
    COUNT(`Customer ID`) AS `Total Customers`,
    SUM(CASE WHEN `Loyalty Card` = 'Yes' THEN 1 ELSE 0 END) AS `Loyal Customers`,
    -- Sums up the values returned by the CASE WHEN statement for each country.
    SUM(CASE WHEN `Loyalty Card` = 'No' THEN 1 ELSE 0 END) AS `Normal Customers`
FROM 
    US_customers
GROUP BY 
    City, State
ORDER BY 
    `Total Customers` DESC
LIMIT 5;
    
-- US, Washington, DC (27)
SELECT City, State, COUNT(*) AS num_customers
FROM US_customers
WHERE `Loyalty Card` = 'Yes'
GROUP BY City, State
ORDER BY num_customers DESC;
-- US, Washington (16/27)
SELECT City, COUNT(`Customer ID`) AS num_customers FROM customers WHERE Country='United Kingdom' GROUP BY City ORDER BY num_customers DESC;
-- UK, Birmingham (5 customers)
SELECT City, COUNT(`Customer ID`) AS num_customers FROM customers WHERE `Loyalty Card`='Yes' AND Country='United States' GROUP BY City ORDER BY num_customers DESC;
-- UK, London (3/4 )
SELECT City, COUNT(`Customer ID`) AS num_customers FROM customers WHERE Country='Ireland' GROUP BY City ORDER BY num_customers DESC;
-- Ireland, Ballivor, 5 customers
SELECT City, COUNT(`Customer ID`) AS num_customers FROM customers WHERE `Loyalty Card`='Yes' AND Country='Ireland' GROUP BY City ORDER BY num_customers DESC;
-- Ireland, Sandyford, 3/3


-- 4. NUMBER OF ORDERS BY CITIES
SELECT c.City, c.State, SUM(o.Quantity) AS total_ord
FROM US_customers as c INNER JOIN orders as o
WHERE c.`Customer ID`=o.`Customer ID`
GROUP BY c.City, c.State
ORDER BY total_ord DESC;
-- Washington - 90 orders (2019-2022). Still included 2022 for accumulative calculation

SELECT c.City, c.State, c.`Loyalty Card`, SUM(o.Quantity) AS total_ord
FROM US_customers as c INNER JOIN orders as o
WHERE c.`Customer ID`=o.`Customer ID`
GROUP BY c.City, c.State, c.`Loyalty Card`
ORDER BY c.City;
-- Distribution of order with loyalty card

-- 5. PROFIT BY CITIES
CREATE TABLE ords_by_city_US AS
	SELECT c.City, c.State, o.`Product ID`, SUM(o.Quantity) AS total_ord
	FROM US_customers AS c 
	INNER JOIN orders AS o
	WHERE c.`Customer ID`=o.`Customer ID`
	GROUP BY c.City, c.State, o.`Product ID`
	ORDER BY c.City, c.State;
    
SELECT * FROM ords_by_city_US;

-- Total profit for each city
SELECT 
	ords_US.City, ords_US.State, SUM(ords_US.total_ord * pd.Profit) AS `Total Profit`
FROM 
	products AS pd
INNER JOIN 
	ords_by_city_US AS ords_US
	ON 
    pd.`Product ID`=ords_US.`Product ID`
GROUP BY
	ords_US.City, ords_US.State
ORDER BY `Total Profit` DESC;

-- Total profit for each city (taking loyalty card into account)
CREATE TABLE ords_by_city_loyalty AS
SELECT 
    c.City, 
    c.State,
    o.`Product ID`,
    c.`Loyalty Card`,
    SUM(o.Quantity) AS total_orders
FROM 
    US_customers AS c
INNER JOIN 
    orders AS o ON c.`Customer ID` = o.`Customer ID`
GROUP BY 
    c.City, 
    c.State, 
    o.`Product ID`,
    c.`Loyalty Card`
ORDER BY 
    c.City, 
    c.State;

SELECT * FROM ords_by_city_loyalty;
UPDATE ords_by_city_loyalty
SET City=UPPER(City);

SELECT 
    ly.City,
    ly.State,
    ly.`Loyalty Card`,
    SUM(ly.total_orders * pd.Profit) AS total_profit
FROM 
    products AS pd
INNER JOIN 
	ords_by_city_loyalty AS ly
    ON pd.`Product ID` = ly.`Product ID`
GROUP BY 
    ly.City,
    ly.State,
    ly.`Loyalty Card`
ORDER BY 
	total_profit DESC;
-- Export this chart

-- TOP 5 AREAS FOR LOYALTY CUSTOMERS
SELECT 
    c.City, 
    c.State,
    COUNT(DISTINCT c.`Customer ID`) AS total_loyal_customers,
    SUM(o.Quantity) AS total_orders,
    SUM(o.Quantity * pd.Profit) AS total_profit
FROM 
    US_customers AS c
INNER JOIN 
    orders AS o ON c.`Customer ID` = o.`Customer ID`
INNER JOIN 
    products AS pd ON o.`Product ID` = pd.`Product ID`
WHERE 
    c.`Loyalty Card` = 'Yes'
GROUP BY 
    c.City, c.State
ORDER BY 
	 total_loyal_customers DESC, total_profit DESC;

-- PRODUCT ANALYSIS
-- 6. COFFEE TYPES + ROAST TYPE MOST ORDERED BY LOYAL CUSTOMERS OVERALL
SELECT 
	p.`Coffee Type`, p.`Roast Type`, SUM(o.Quantity) AS total_orders
FROM 
	orders as o
INNER JOIN 
	products as p ON p.`Product ID` = o.`Product ID`
INNER JOIN
	US_customers as c ON o.`Customer ID`=c.`Customer ID`
WHERE 
	c.`Loyalty Card`='Yes'
GROUP BY
	p.`Coffee Type`, p.`Roast Type`
ORDER BY 
	total_orders DESC;

-- 7. COFFEE TYPES + ROAST TYPE WITH HIGHEST PROFIT AMONG ALL LOYAL CUSTOMERS 
SELECT 
	p.`Coffee Type`, p.`Roast Type`, SUM(o.Quantity) AS total_orders, SUM(o.Quantity*p.Profit) AS total_profit
FROM 
	orders as o
INNER JOIN 
	products as p ON p.`Product ID` = o.`Product ID`
INNER JOIN
	US_customers as c ON o.`Customer ID`=c.`Customer ID`
WHERE 
	c.`Loyalty Card`='Yes'
GROUP BY
	p.`Coffee Type`, p.`Roast Type`
ORDER BY 
	total_profit DESC;

-- 8. MOST ORDERED PRODUCTS IN TOP 5 CITIES BY NUMBER OF ORDS
-- Step 1: Identify top 5 cities by number of orders + loyalty card
WITH top_cities_by_orders AS (
    SELECT 
        c.City, 
        c.State,
        SUM(o.Quantity) AS total_orders
    FROM 
        US_customers AS c
    INNER JOIN 
        orders AS o ON c.`Customer ID` = o.`Customer ID`
	WHERE 
		c.`Loyalty Card` = 'Yes'
    GROUP BY 
        c.City, c.State
    ORDER BY 
        total_orders DESC
    LIMIT 5
)
-- Step 2: Find the most ordered products in these top cities
SELECT 
    c.City, 
    c.State, 
    pd.`Coffee Type`, 
    pd.`Roast Type`,
    SUM(o.Quantity) AS total_ord
FROM 
    US_customers AS c 
INNER JOIN 
    orders AS o ON c.`Customer ID` = o.`Customer ID`
INNER JOIN 
    products AS pd ON o.`Product ID` = pd.`Product ID`
WHERE 
    (c.City, c.State) IN (SELECT City, State FROM top_cities_by_orders)
GROUP BY 
    c.City, 
    c.State, 
    pd.`Coffee Type`, 
    pd.`Roast Type`
ORDER BY 
    total_ord DESC;

WITH top_cities_by_profit AS (
    SELECT 
        c.City, 
        c.State,
        SUM(o.Quantity) AS total_ord,
        SUM(o.Quantity*p.Profit) AS total_profit
    FROM 
        US_customers AS c
    INNER JOIN 
        orders AS o ON c.`Customer ID` = o.`Customer ID`
	INNER JOIN
		products AS p ON o.`Product ID`=p.`Product ID`
	WHERE 
		c.`Loyalty Card` = 'Yes'
    GROUP BY 
        c.City, c.State
    ORDER BY 
        total_profit DESC
    LIMIT 5
)
SELECT 
    c.City, 
    c.State, 
    p.`Coffee Type`, 
    p.`Roast Type`,
    SUM(o.Quantity*p.Profit) AS `Total Profit`
FROM 
    US_customers AS c 
INNER JOIN 
    orders AS o ON c.`Customer ID` = o.`Customer ID`
INNER JOIN 
    products AS p ON o.`Product ID` = p.`Product ID`
WHERE 
    (c.City, c.State) IN (SELECT City, State FROM top_cities_by_profit)
GROUP BY 
    c.City, 
    c.State, 
    p.`Coffee Type`, 
    p.`Roast Type`
ORDER BY 
    `Total Profit` DESC;
    
-- ORDERS AND PROFIT IN 7 RECOMMENDED AREAS
SELECT 
    c.City,
    p.`Coffee Type`,
    p.`Roast Type`,
    SUM(o.Quantity) AS Total_Orders,
    SUM(o.Quantity * p.Profit) AS Total_Profit
FROM 
    US_customers AS c
JOIN 
    orders AS o ON c.`Customer ID` = o.`Customer ID`
JOIN 
    products AS p ON o.`Product ID` = p.`Product ID`
WHERE 
    c.City IN ('WASHINGTON', 'SACRAMENTO', 'OKLAHOMA CITY', 'NEW YORK CITY', 'CHARLOTTE', 'HOUSTON', 'SAINT LOUIS')
GROUP BY 
    c.City, p.`Coffee Type`, p.`Roast Type`
ORDER BY 
    c.City, Total_Profit DESC, Total_Orders DESC;

-- 9. PURCHASE TIME PATTERN OF LOYAL CUSTOMERS 
SELECT 
    YEAR(o.`Order Date`) AS order_year,
    MONTH(o.`Order Date`) AS order_month,
    COUNT(DISTINCT c.`Customer ID`) AS total_loyal_customers,
    SUM(o.Quantity) AS total_orders,
    SUM(o.Quantity * p.Profit) AS total_profit
FROM 
    US_customers AS c
INNER JOIN 
    orders AS o ON c.`Customer ID` = o.`Customer ID`
INNER JOIN 
    products AS p ON o.`Product ID` = p.`Product ID`
WHERE 
    c.`Loyalty Card` = 'Yes'
    AND YEAR(o.`Order Date`) < 2022
GROUP BY 
    order_year, order_month
ORDER BY 
    order_year, order_month;
    

