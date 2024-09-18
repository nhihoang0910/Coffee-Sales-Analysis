SHOW DATABASES;
USE coffee;
SHOW TABLES;
DESCRIBE coffee_qlty;

SELECT *
FROM coffee_qlty;

SELECT *,  ROW_NUMBER() OVER (
PARTITION BY REC_ID) AS row_num
FROM coffee_qlty;

CREATE TABLE ara_qlty
AS SELECT * FROM coffee_qlty
WHERE Species='Arabica' AND `Processing.Method`!='';
-- Can't use IS NULL, maybe because of how data is gathered


CREATE TABLE rob_qlty
AS SELECT * FROM coffee_qlty
WHERE Species='Robusta' AND `Processing.Method`!='';


SELECT DISTINCT Variety
FROM rob_qlty;

SELECT DISTINCT Variety
FROM ara_qlty;

ALTER TABLE ara_qlty
DROP COLUMN Acidity, 
DROP COLUMN Body, DROP COLUMN Balance, DROP COLUMN Sweetness, DROP COLUMN Moisture, 
DROP COLUMN Quakers;

SELECT * FROM ara_qlty;

ALTER TABLE rob_qlty
DROP COLUMN Acidity, 
DROP COLUMN Body, DROP COLUMN Balance, DROP COLUMN Sweetness, DROP COLUMN Moisture, 
DROP COLUMN Quakers;

-- ARABICA
-- Remove duplicates
WITH duplicate_cf AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY `Country.of.Origin`, `Harvest.Year`, Expiration, Variety, Color, `Processing.Method`, Aroma, Flavor, Aftertaste, Uniformity, `Clean.Cup`, `Category.One.Defects`, `Category.Two.Defects`) AS row_num FROM ara_qlty
)
SELECT * FROM duplicate_cf WHERE row_num>1;

WITH duplicate_cf AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY `Country.of.Origin`, `Harvest.Year`, Expiration, Variety, Color, `Processing.Method`, Aroma, Flavor, Aftertaste, Uniformity, `Clean.Cup`, `Category.One.Defects`, `Category.Two.Defects`) AS row_num FROM ara_qlty
)
DELETE FROM duplicate_cf WHERE row_num>1;

CREATE TABLE `ara_qlty2` (
  `REC_ID` int DEFAULT NULL,
  `Species` text,
  `Continent.of.Origin` text,
  `Country.of.Origin` text,
  `Harvest.Year` bigint DEFAULT NULL,
  `Expiration` text,
  `Variety` text,
  `Color` text,
  `Processing.Method` text,
  `Aroma` double DEFAULT NULL,
  `Flavor` double DEFAULT NULL,
  `Aftertaste` double DEFAULT NULL,
  `Uniformity` double DEFAULT NULL,
  `Clean.Cup` double DEFAULT NULL,
  `Category.One.Defects` int DEFAULT NULL,
  `Category.Two.Defects` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM ara_qlty2 ORDER BY REC_ID;

INSERT INTO ara_qlty2
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY `Country.of.Origin`, `Harvest.Year`, Expiration, Variety, Color, 
`Processing.Method`, Aroma, Flavor, Aftertaste, Uniformity, `Clean.Cup`, `Category.One.Defects`, `Category.Two.Defects`) 
AS row_num FROM ara_qlty;

DELETE
FROM ara_qlty2 
WHERE row_num>1;

SELECT *
FROM ara_qlty2 
WHERE row_num>1;

SELECT COUNT(ara_qlty2.REC_ID) FROM ara_qlty2 INNER JOIN ara_qlty WHERE ara_qlty.REC_ID=ara_qlty2.REC_ID;
SELECT COUNT(REC_ID) FROM ara_qlty2;
SELECT COUNT(REC_ID) FROM ara_qlty;

-- EDA

SELECT `Country.of.Origin`, COUNT(*) AS num_production FROM ara_qlty GROUP BY `Country.of.Origin` ORDER BY num_production DESC;
SELECT `Country.of.Origin`, COUNT(*) AS num_production FROM ara_qlty2 GROUP BY `Country.of.Origin`ORDER BY num_production DESC;
-- Mexico has the highest production. India, Cote dlvoire, Papua New Guinea, Rwanda, Ecuador, Burundi. Zambia all have 1

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, COUNT(*) AS num FROM ara_qlty2 WHERE `Country.of.Origin`='Mexico' GROUP BY Variety, Color, `Processing.Method` ORDER BY Variety;
SELECT COUNT(*) FROM ara_qlty2 WHERE `Country.of.Origin`='Mexico' AND Variety='Typica' AND Color = 'Green';
-- Variety 'Typica' with green color and 'Washed/Wet' as processing method has the highest number of production = 74 
-- 3 times as much as the second highest number of production - Bourbon, Green, Wash/Wet = 23
-- Which processing method is the most common 
SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, COUNT(*) AS num FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY `Country.of.Origin`;

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MAX(Aroma) AS max_aroma FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY max_aroma DESC;
-- Ethiopia, Green , Washed/Wet has highest aroma = 8.75

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MIN(Aroma) AS min_aroma FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY min_aroma;
-- Colombia, Caturra, Green, Washed/Wet has lowest aroma = 5.08

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MAX(Flavor) AS max_flavor FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY max_flavor DESC;
-- Ethiopia, variety blank, green, Washed/Wet max flavor = 8.83

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MIN(Flavor) AS min_flavor FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY min_flavor;
-- Guatemala, Bourbon, Green, Washed/Wet, 6.08

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MAX(Aftertaste) AS max_aft FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY max_aft DESC;
-- Ethiopia, blank, Green, Washed/Wet, 8.67

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MIN(Aftertaste) AS min_aft FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY min_aft;
-- Guatemala, Bourbon,  Green, Washed/Wet, 6.17

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MAX(Uniformity) AS max_unf FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY max_unf DESC;
-- Brazil, Bourbon, Blue-Green, Semi-washed/semi-pulped, 10

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MIN(Uniformity) AS min_unf FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY min_unf;
-- Brazil, empty, Green, Natural/Dry, 6

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MAX(`Clean.Cup`) AS max_cc FROM ara_qlty2 GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY max_cc DESC;
-- Brazil, Bourbon, blue-green, semi-washed/semi-pulped, 10

SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MAX(`Clean.Cup`) AS max_cc FROM ara_qlty GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY max_cc DESC, `Country.of.Origin`;


SELECT `Country.of.Origin`,Variety, Color, `Processing.Method`, MIN(`Clean.Cup`) AS min_cc FROM ara_qlty GROUP BY `Country.of.Origin`,Variety, Color, `Processing.Method` ORDER BY min_cc;
-- Mexico, Bourbon, none, Washed/Wet, 0

SELECT * FROM ara_qlty2 ORDER BY REC_ID;
