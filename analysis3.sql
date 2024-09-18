use `coffee_sales`;

SELECT 
    customers.*,
    COALESCE(geo.city, uszips2.city) AS city,
    COALESCE(geo.state, uszips2.state_name) AS state
FROM 
    customers
LEFT JOIN 
    `geo-data` as geo ON customers.postcode = geo.zipcode
LEFT JOIN 
    uszips2 ON customers.postcode = uszips2.zip;
    
    
SELECT COUNT(*)
FROM customers
LEFT JOIN `geo-data` ON customers.postcode = `geo-data`.zipcode
WHERE `geo-data`.zipcode IS NULL AND customers.Country='United States';

SELECT COUNT(*)
FROM customers
LEFT JOIN uszips2 ON customers.postcode = uszips2.zip
WHERE uszips2.zip IS NULL AND customers.Country='United States';

SELECT * 
FROM customers
INNER JOIN zip
ON customers.Postcode=zip.`Official Code ZIP Code`
OR customers.Postcode=zip.`Official Name ZIP Code`;

SELECT *
FROM customers
LEFT JOIN zip ON customers.Postcode=zip.`Official Code ZIP Code`
OR customers.Postcode=zip.`Official Name ZIP Code`
WHERE zip.`Official Code ZIP Code` IS NULL AND zip.`Official Name ZIP Code` IS NULL AND customers.Country='United States';


SELECT 
    DISTINCT c.`Customer ID`,
    c.`Customer Name`,
    c.City,
    c.Postcode,
    c.`Loyalty Card`,
    COALESCE(zip_locale.`PHYSICAL CITY`, uszips2.city) AS city,
    COALESCE(zip_locale.`PHYSICAL STATE`, uszips2.state_id) AS state
FROM 
    customers AS c
LEFT JOIN 
    zip_locale ON c.postcode = zip_locale.`DELIVERY ZIPCODE`
LEFT JOIN 
    uszips2 ON c.postcode = uszips2.zip
WHERE c.Country='United States' AND zip_locale.`DELIVERY ZIPCODE` IS NULL AND uszips2.zip IS NULL;
-- GROUP BY c.`Customer ID`, c.`Customer Name`, c.City, c.Postcode;

SELECT 
    DISTINCT c.`Customer ID`,
    c.`Customer Name`,
    c.City AS `Original_City`,
    c.Postcode,
    c.`Loyalty Card`,
    COALESCE(zip_locale.`PHYSICAL CITY`, uszips2.city) AS Mapped_City,
    COALESCE(zip_locale.`PHYSICAL STATE`, uszips2.state_id) AS Mapped_State
FROM 
    customers AS c
LEFT JOIN 
    zip_locale ON CAST(c.Postcode AS CHAR) = CAST(zip_locale.`DELIVERY ZIPCODE` AS CHAR)
LEFT JOIN 
    uszips2 ON CAST(c.Postcode AS CHAR) = CAST(uszips2.zip AS CHAR)
WHERE 
    c.Country = 'United States';
    
WITH mapped_data AS (
    SELECT 
        DISTINCT c.`Customer ID`,
        c.`Customer Name`,
        c.City AS `Original_City`,
        c.Postcode,
        c.`Loyalty Card`,
        COALESCE(zip_locale.`PHYSICAL CITY`, uszips2.city, geo.city) AS `Mapped_City`,
        COALESCE(zip_locale.`PHYSICAL STATE`, uszips2.state_id, geo.state_abbr) AS `Mapped_State`
    FROM 
        customers AS c
    LEFT JOIN 
        zip_locale ON CAST(c.Postcode AS CHAR) = CAST(zip_locale.`DELIVERY ZIPCODE` AS CHAR)
    LEFT JOIN 
        uszips2 ON CAST(c.Postcode AS CHAR) = CAST(uszips2.zip AS CHAR)
	LEFT JOIN 
        `geo-data` AS geo ON CAST(c.Postcode AS CHAR) = CAST(geo.zipcode AS CHAR)
    WHERE 
        c.Country = 'United States'
)
SELECT *
FROM mapped_data
WHERE `Original_City` = `Mapped_City`;


WITH mapped_data AS (
    SELECT 
        DISTINCT c.`Customer ID`,
        c.`Customer Name`,
        c.City AS `Original_City`,
        c.Postcode,
        c.`Loyalty Card`,
        COALESCE(zip_locale.`PHYSICAL CITY`, uszips2.city, geo.city, additional_zip.City) AS `Mapped_City`,
        COALESCE(zip_locale.`PHYSICAL STATE`, uszips2.state_id, geo.state_abbr, additional_zip.State) AS `Mapped_State`
    FROM 
        customers AS c
    LEFT JOIN 
        zip_locale ON CAST(c.Postcode AS CHAR) = CAST(zip_locale.`DELIVERY ZIPCODE` AS CHAR)
    LEFT JOIN 
        uszips2 ON CAST(c.Postcode AS CHAR) = CAST(uszips2.zip AS CHAR)
	LEFT JOIN 
        additional_zip ON CAST(c.Postcode AS CHAR) = CAST(additional_zip.Postcode AS CHAR)
	LEFT JOIN 
        `geo-data` AS geo ON CAST(c.Postcode AS CHAR) = CAST(geo.zipcode AS CHAR)
    WHERE 
        c.Country = 'United States'
)
SELECT *
FROM mapped_data
WHERE `Mapped_State` IS NULL;

-- Check for missing postcodes in each table
SELECT DISTINCT c.Postcode, c.City
FROM customers AS c
LEFT JOIN zip_locale ON CAST(c.Postcode AS CHAR) = CAST(zip_locale.`DELIVERY ZIPCODE` AS CHAR)
LEFT JOIN uszips2 ON CAST(c.Postcode AS CHAR) = CAST(uszips2.zip AS CHAR)
LEFT JOIN `geo-data` AS geo ON CAST(c.Postcode AS CHAR) = CAST(geo.zipcode AS CHAR)
WHERE c.Country = 'United States' AND zip_locale.`DELIVERY ZIPCODE` IS NULL AND uszips2.zip IS NULL AND geo.zipcode IS NULL;

SELECT DISTINCT c.Postcode, c.City
FROM customers AS c
LEFT JOIN zip_locale ON CAST(c.Postcode AS CHAR) = CAST(zip_locale.`DELIVERY ZIPCODE` AS CHAR)
LEFT JOIN uszips2 ON CAST(c.Postcode AS CHAR) = CAST(uszips2.zip AS CHAR)
LEFT JOIN `geo-data` AS geo ON CAST(c.Postcode AS CHAR) = CAST(geo.zipcode AS CHAR)
WHERE c.Country = 'United States' AND zip_locale.`DELIVERY ZIPCODE` IS NULL AND uszips2.zip IS NULL AND geo.zipcode IS NULL;

-- Double check again
WITH mapped_data AS (
    SELECT 
        DISTINCT c.`Customer ID`,
        c.`Customer Name`,
        c.City AS `Original_City`,
        c.Postcode,
        c.`Loyalty Card`,
        COALESCE(zip_locale.`PHYSICAL CITY`, uszips2.city, additional_zip.City) AS `Mapped_City`,
        COALESCE(zip_locale.`PHYSICAL STATE`, uszips2.state_id, additional_zip.State) AS `Mapped_State`
    FROM 
        customers AS c
    LEFT JOIN 
        zip_locale ON CAST(c.Postcode AS CHAR) = CAST(zip_locale.`DELIVERY ZIPCODE` AS CHAR)
    LEFT JOIN 
        uszips2 ON CAST(c.Postcode AS CHAR) = CAST(uszips2.zip AS CHAR)
	LEFT JOIN 
        additional_zip ON CAST(c.Postcode AS CHAR) = CAST(additional_zip.Postcode AS CHAR)
    WHERE 
        c.Country = 'United States'
)
SELECT *
FROM mapped_data
WHERE `Mapped_State` IS NULL;

-- Create customers table with states
-- Create a new table based on the customers table structure
CREATE TABLE customers_with_states AS
WITH mapped_data AS (
    SELECT 
        DISTINCT c.`Customer ID`,
        c.`Customer Name`,
        c.City AS `Original_City`,
        c.Postcode,
        COALESCE(zip_locale.`PHYSICAL CITY`, uszips2.city, additional_zip.City) AS `Mapped_City`,
        COALESCE(zip_locale.`PHYSICAL STATE`, uszips2.state_id, additional_zip.State) AS `Mapped_State`,
        c.`Loyalty Card`
    FROM 
        customers AS c
    LEFT JOIN 
        zip_locale ON CAST(c.Postcode AS CHAR) = CAST(zip_locale.`DELIVERY ZIPCODE` AS CHAR)
    LEFT JOIN 
        uszips2 ON CAST(c.Postcode AS CHAR) = CAST(uszips2.zip AS CHAR)
    LEFT JOIN 
        additional_zip ON CAST(c.Postcode AS CHAR) = CAST(additional_zip.Postcode AS CHAR)
    WHERE 
        c.Country = 'United States'
)
SELECT 
    `Customer ID`,
    `Customer Name`,
    Postcode,
    `Mapped_City` AS City,
    `Mapped_State` AS State,
    `Loyalty Card`
FROM mapped_data
WHERE `Original_City` = `Mapped_City`;