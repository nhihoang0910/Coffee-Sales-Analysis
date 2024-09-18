SHOW databases;
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

SELECT Country, COUNT(`Customer ID`) AS num_customers FROM customers WHERE `Loyalty Card`='Yes' GROUP BY Country ORDER BY Country;
-- US (380) > Ireland (80) > UK (27)
SELECT Country, COUNT(`Customer ID`) AS num_customers FROM customers GROUP BY Country ORDER BY num_customers DESC;
-- US (782) > Ireland (150) > UK (68)
-- Can calculate % for each country
SELECT City, COUNT(`Customer ID`) AS num_customers FROM customers WHERE `Loyalty Card`='Yes' AND Country='United States' GROUP BY City ORDER BY num_customers DESC;
-- Washington (16 customers)
SELECT City, COUNT(`Customer ID`) AS num_customers FROM customers WHERE Country='United States' GROUP BY City ORDER BY num_customers DESC;
-- Washington (27)

SELECT * FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2019;
SELECT customers.Country AS Country, SUM(Quantity) as total_orders FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2019 GROUP BY customers.Country;
-- US(685) > Ireland (123) > UK(106)
SELECT customers.Country AS Country, SUM(Quantity) as total_orders FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2020 GROUP BY customers.Country;
-- US(784)> Ireland (129) > UK (88)
SELECT customers.Country AS Country, SUM(Quantity) as total_orders FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2021 GROUP BY customers.Country;
-- US (907) > Ireland (189) > UK (47)
SELECT customers.Country AS Country, SUM(Quantity) as total_orders FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2022 GROUP BY customers.Country;
-- US (434) > Ireland (96) > UK (13)
SELECT * FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2022 ORDER BY orders.`Order Date` DESC;
SELECT * FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2021 ORDER BY orders.`Order Date` DESC;
SELECT * FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2020 ORDER BY orders.`Order Date` DESC;
SELECT * FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID` AND orders.`Order Date`=2019 ORDER BY orders.`Order Date` DESC;
-- Orders in 2022 are significant lower because data only has until mid Aug

SELECT * FROM customers INNER JOIN orders WHERE customers.`Customer ID`=orders.`Customer ID`;

SELECT customers.City, SUM(orders.Quantity) AS total_ord
FROM customers INNER JOIN orders 
WHERE customers.`Customer ID`=orders.`Customer ID`
GROUP BY customers.City
ORDER BY total_ord DESC;
-- Washington has the most orders from 2019-2022 (90 orders)

SELECT * FROM (
SELECT customers.City, SUM(orders.Quantity) AS total_ord
FROM customers INNER JOIN orders 
WHERE customers.`Customer ID`=orders.`Customer ID`
GROUP BY customers.City) AS agg_tb
WHERE total_ord>=30;
-- To export to tableau

-- Create a table with all customers with loyalty card
CREATE TABLE loyalty_card 
AS SELECT * FROM customers
WHERE `Loyalty Card`='Yes';

SELECT City, COUNT(*) as total FROM loyalty_card GROUP BY City ORDER BY total DESC;

SELECT loyalty_card.City, SUM(orders.Quantity) AS total_ord
FROM loyalty_card INNER JOIN orders 
WHERE loyalty_card.`Customer ID`=orders.`Customer ID`
GROUP BY loyalty_card.City
ORDER BY total_ord DESC;

SELECT customers.City, SUM(orders.Quantity) AS total_ord
FROM customers INNER JOIN orders 
WHERE customers.`Customer ID`=orders.`Customer ID` AND customers.`Loyalty Card`='Yes'
GROUP BY customers.City
ORDER BY total_ord DESC;
-- Washington has 43 orders from 16 customers in loyalty program. 

SELECT customers.City, SUM(orders.Quantity) AS total_ord
FROM customers INNER JOIN orders 
WHERE customers.`Customer ID`=orders.`Customer ID` AND customers.`Loyalty Card`='No'
GROUP BY customers.City
ORDER BY total_ord DESC;
-- Washington has 47 orders from 11 customers not in loyalty program. 

SELECT customers.Country, SUM(orders.Quantity) AS total_ord
FROM customers INNER JOIN orders 
WHERE customers.`Customer ID`=orders.`Customer ID` AND customers.`Loyalty Card`='Yes'
GROUP BY customers.Country
ORDER BY total_ord DESC;

SELECT customers.Country, SUM(orders.Quantity) AS total_ord
FROM customers INNER JOIN orders 
WHERE customers.`Customer ID`=orders.`Customer ID` AND customers.`Loyalty Card`='No'
GROUP BY customers.Country
ORDER BY total_ord DESC;
-- People not in the loyalty program made more orders. Even though the difference for each country might not be that big

SELECT * FROM customers WHERE City = 'Washington' AND `Loyalty Card`='Yes';

SELECT orders.`Product ID`, SUM(Quantity) AS total_quantity
FROM orders INNER JOIN customers 
WHERE orders.`Customer ID`=customers.`Customer ID`
AND customers.City = 'Washington' AND customers.`Loyalty Card`='Yes'
GROUP BY orders.`Product ID`
ORDER BY total_quantity DESC;
-- L-D-0.5 was most ordered in Washington for customers with loyalty cards
-- L-L-0.2 was least ordered

SELECT orders.`Product ID`, SUM(orders.Quantity) AS total_quantity, products.Profit 
FROM orders INNER JOIN products 
WHERE orders.`Product ID` = products.`Product ID`
	AND orders.`Product ID` IN 
		(SELECT orders.`Product ID`
		FROM orders INNER JOIN customers 
		WHERE orders.`Customer ID`=customers.`Customer ID`
		AND customers.City = 'Washington' AND customers.`Loyalty Card`='Yes')
GROUP BY orders.`Product ID`, products.Profit;

SELECT `Product ID`, total_quantity, Profit, (total_quantity*Profit) AS total_profit
FROM 
	(SELECT orders.`Product ID`, SUM(orders.Quantity) AS total_quantity, products.Profit 
	FROM orders INNER JOIN products 
	WHERE orders.`Product ID` = products.`Product ID`
	AND orders.`Product ID` IN (SELECT orders.`Product ID`
	FROM orders INNER JOIN customers 
	WHERE orders.`Customer ID`=customers.`Customer ID` AND customers.`Loyalty Card`='Yes')
	GROUP BY orders.`Product ID`, products.Profit) AS loyalty_WS
ORDER BY total_profit DESC;
-- E-M-2.5 generated highest profit in Washington

SELECT `Product ID`, total_quantity, Profit, (total_quantity*Profit) AS total_profit
FROM 
	(SELECT orders.`Product ID`, SUM(orders.Quantity) AS total_quantity, products.Profit 
	FROM orders INNER JOIN products 
	WHERE orders.`Product ID` = products.`Product ID`
	AND orders.`Product ID` IN (SELECT orders.`Product ID`
	FROM orders INNER JOIN customers 
	WHERE orders.`Customer ID`=customers.`Customer ID`
	AND customers.City = 'Washington' AND customers.`Loyalty Card`='Yes')
	GROUP BY orders.`Product ID`, products.Profit) AS loyalty_WS
ORDER BY total_profit DESC;
-- E-M-2.5 generated highest profit in Washington

SELECT `Product ID`, `Coffee Type`, `Roast Type`, SUM(Quantity) AS total 
FROM (
SELECT orders.`Order ID`, orders.`Order Date`, orders.`Customer ID`, orders.`Product ID`,
orders.Quantity, `Coffee Type`, `Roast Type`,Size, `Unit Price`, `Price per 100g`, Profit
FROM orders INNER JOIN products WHERE orders.`Product ID`= products.`Product ID`) AS agg_table
GROUP BY `Product ID`, `Coffee Type`, `Roast Type`
ORDER BY total DESC;


SELECT COUNT(DISTINCT `Product ID`) FROM products;

SELECT products.`Product ID`, products.`Coffee Type`, products.`Roast Type`, 
products.Profit, orders.Quantity, (products.Profit*orders.Quantity) AS total_profit
FROM products INNER JOIN orders 
WHERE products.`Product ID` = orders.`Product ID`
ORDER BY total_profit DESC;

SELECT products.`Product ID`, products.`Coffee Type`, products.`Roast Type`,
SUM(orders.Quantity) AS total_qty, products.Profit
FROM products INNER JOIN orders 
WHERE products.`Product ID` = orders.`Product ID`
GROUP BY products.`Product ID`, products.`Coffee Type`, products.`Roast Type`, products.Profit;

SELECT `Product ID`, `Coffee Type`, `Roast Type`, total_qty, Profit,
(total_qty*Profit) AS total_profit
FROM (SELECT products.`Product ID`, products.`Coffee Type`, products.`Roast Type`, 
SUM(orders.Quantity) AS total_qty, products.Profit
FROM products INNER JOIN orders 
WHERE products.`Product ID` = orders.`Product ID`
GROUP BY products.`Product ID`, products.`Coffee Type`, products.`Roast Type`, products.Profit) AS agg_table
ORDER BY total_profit DESC;
-- L-D-2.5 dark roast generated the most profit
-- R-M-0.2 medium roast generated the least profit
-- The difference was large

SELECT `Product ID`, `Coffee Type`, `Roast Type`, total_qty, Profit,
(total_qty*Profit) AS total_profit
FROM (SELECT products.`Product ID`, products.`Coffee Type`, products.`Roast Type`, 
SUM(orders.Quantity) AS total_qty, products.Profit
FROM products INNER JOIN orders 
WHERE products.`Product ID` = orders.`Product ID`
GROUP BY products.`Product ID`, products.`Coffee Type`, products.`Roast Type`, products.Profit) AS agg_table
ORDER BY total_qty DESC;
-- R-L-0.2 was the most ordered
-- L-M-2.5 was the least ordered

SELECT * FROM products ORDER BY `Price per 100g` DESC;
-- The product brought highest profit didn't have highest price per 100g

SELECT `Customer ID`, `Customer Name`, City
FROM customers
WHERE `Loyalty Card`='Yes';

-- Find number of orders of each product in each city for customers with loyalty card
SELECT orders.`Product ID`,  customers.City, orders.Quantity
FROM orders INNER JOIN customers
WHERE orders.`Customer ID`=customers.`Customer ID`
AND customers.`Customer ID` IN (SELECT `Customer ID`
FROM customers
WHERE `Loyalty Card`='Yes')
ORDER BY Quantity DESC;


SELECT `Product ID`, City, SUM(Quantity) AS total_quantity
FROM (SELECT orders.`Product ID`,  customers.City, orders.Quantity
FROM orders INNER JOIN customers
WHERE orders.`Customer ID`=customers.`Customer ID`
AND customers.`Customer ID` IN (SELECT `Customer ID`
FROM customers
WHERE `Loyalty Card`='Yes')) AS agg_table
GROUP BY `Product ID`, City
ORDER BY total_quantity DESC;

-- Find which city had the most orders and what coffee bean was ordered there for customers with loyalty cards
SELECT `Product ID`, City, SUM(Quantity) AS total_quantity
FROM (SELECT orders.`Product ID`,  customers.City, orders.Quantity
FROM orders INNER JOIN customers
WHERE orders.`Customer ID`=customers.`Customer ID`
AND customers.`Customer ID` IN (SELECT `Customer ID`
FROM customers
WHERE `Loyalty Card`='Yes')) AS agg_table
GROUP BY City, `Product ID`
ORDER BY total_quantity DESC;
-- Lansing (US), E-D-0.5, 10

SELECT MONTH(`Order Date`), SUM(Quantity) AS total_quantity
FROM orders
WHERE YEAR(`Order Date`) < 2022
GROUP BY MONTH(`Order Date`);
-- Excluding 2022 because it only had until august
-- Highest order in March

SELECT MONTH(`Order Date`), SUM(Quantity) AS total_quantity
FROM orders INNER JOIN customers 
WHERE orders.`Customer ID`=customers.`Customer ID`
AND YEAR(`Order Date`) < 2022
AND `Loyalty Card`='Yes'
GROUP BY MONTH(`Order Date`);
-- Peak in November

SELECT MONTH(`Order Date`), SUM(Quantity) AS total_quantity
FROM orders INNER JOIN customers 
WHERE orders.`Customer ID`=customers.`Customer ID`
AND YEAR(`Order Date`)=2019
AND `Loyalty Card`='Yes'
GROUP BY MONTH(`Order Date`);
-- In 2019, orders peaked at April with customers with loyalty card
-- Lowest: Aug & Oct (22)

SELECT MONTH(`Order Date`), SUM(Quantity) AS total_quantity
FROM orders INNER JOIN customers 
WHERE orders.`Customer ID`=customers.`Customer ID`
AND YEAR(`Order Date`)=2019
AND `Loyalty Card`='Yes'
AND City='Washington'
GROUP BY MONTH(`Order Date`);
-- only in March, April


SELECT MONTH(`Order Date`), SUM(Quantity) AS total_quantity
FROM orders INNER JOIN customers 
WHERE orders.`Customer ID`=customers.`Customer ID`
AND YEAR(`Order Date`)=2020
AND `Loyalty Card`='Yes'
GROUP BY MONTH(`Order Date`);
-- Lowest: August
-- Peak: October

SELECT MONTH(`Order Date`), SUM(Quantity) AS total_quantity
FROM orders INNER JOIN customers 
WHERE orders.`Customer ID`=customers.`Customer ID`
AND YEAR(`Order Date`)=2020
AND `Loyalty Card`='Yes'
AND City='Washington'
GROUP BY MONTH(`Order Date`);
-- Peak: Jun

SELECT MONTH(`Order Date`), SUM(Quantity) AS total_quantity
FROM orders INNER JOIN customers 
WHERE orders.`Customer ID`=customers.`Customer ID`
AND YEAR(`Order Date`)=2021
AND `Loyalty Card`='Yes'
GROUP BY MONTH(`Order Date`);
-- Lowest: July
-- Peak: Nov