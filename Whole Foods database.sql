
-- WARNING ----------------------------------------------------------------- --
-- -------------- DO NOT USE CTRL+B TO ADJUST THE LINES! ------------------- --
-- ------------------------------------------------------------------------- --
use bos_fmban_sql_analysis;
-- Table with the summatory of diet preferences by product, depending if the product if by Whole foods market or other brands
 WITH dietary_preferences as (
-- Temporary table that will allow to sum the columns normalized
With normalized_database as (
-- temporary table with duplicated records EXCLUDED
(WITH products_database as ((SELECT * FROM bos_fmban_sql_analysis.bfmban_data WHERE ID NOT IN 
(
-- Table with the IDs that are related to DUPLICATED RECORDS --
	#To see the whole information of these records and verify it, copy and paste this query and change only the first 'ID' for '*'
#Duplicated records = entries that share the same ID and brand, have the almost same name of the product (Salad 1 = Salad 01), and share category or subcategory.
(SELECT ID from 
-- Table that shows the records for every entry which ID is in more than 1 entry.Ex, two products that share ID but not necesarly are the same product, are included.
(SELECT * from bos_fmban_sql_analysis.bfmban_data as bd1 
-- Join to only display the entries with IDs that are not unique within records
right join 
(SELECT ID from 
-- Table that counts the number of times an  ID appears in the database records
(SELECT ID, COUNT(ID) as n_id from bos_fmban_sql_analysis.bfmban_data as db
group by ID
)
 as duplicates
 #specifying that the duplicated IDs are those in more than 1 record
 where n_id>1
)
as bd2
USING(ID)
)
as d1
-- Self join to compare the records that have duplicated IDs to identify if they share almost the same information to be considered a duplicated record
inner join 
-- Table that shows the records for every entry which ID is in more than 1 entry.Ex, two products that share ID but not necesarly are the same product, are included.
(SELECT * from bos_fmban_sql_analysis.bfmban_data as bd1 
-- Join to only display the entries with IDs that are not unique within records
right join 
(SELECT ID from 
-- Table that counts the number of times an  ID appears in the database records
(SELECT ID, COUNT(ID) as n_id from bos_fmban_sql_analysis.bfmban_data as db
group by ID
)
 as duplicates
 #specifying that the duplicated IDs are those in more than 1 record
 where n_id>1
)
as bd2
USING(ID)
)
as d2
using(ID)
#Conditioning the join to especify that the duplicated records have same ID, name of product
where (d1.ID=d2.ID AND d1.NAME_OF_PRODUCT=d2.NAME_OF_PRODUCT AND(d1.CATEGORY<>d2.CATEGORY OR d1.SUBCATEGORY<>d2.SUBCATEGORY) AND d1.BRAND=d2.BRAND) or 
(d1.ID=d2.ID AND d1.NAME_OF_PRODUCT<>d2.NAME_OF_PRODUCT AND(d1.CATEGORY<>d2.CATEGORY OR d1.SUBCATEGORY<>d2.SUBCATEGORY) and d1.BRAND=d2.BRAND)
-- DUPLICATED RECORDS FINISH HERE--
)
)
)
)

-- Selecting relevant data for the analysis
select data_entry_order as `ID`, ID as `PRODUCT LABEL`,
#creating column to separate whole foods market from other brands
CASE when BRAND LIKE '365%' OR BRAND LIKE '%WHOLE%' OR BRAND LIKE '%ALLEGRO%' THEN 'WHOLE FOODS MARKET' ELSE 'OTHER' END AS BRAND,
REGULAR_PRICE,
#Normalizing the field Category
CASE WHEN CATEGORY LIKE 'BREAD%BAKERY' THEN 'BREAD ROLLS AND BAKERY' WHEN CATEGORY LIKE '%DAIRY%' THEN 'DAIRY AND EGGS' WHEN CATEGORY LIKE '%FROZEN%' THEN 'FROZEN FOOD' WHEN CATEGORY LIKE '%SNACKS%' THEN 'SNACKS CHIPS SALSAS AND DIPS' WHEN CATEGORY LIKE 'BEAUTY' THEN 'BEAUTY' WHEN CATEGORY LIKE 'BEVERAGES' THEN 'BEVERAGES'  WHEN CATEGORY LIKE 'BODY CARE' THEN 'BODY CARE' WHEN CATEGORY LIKE 'DESSERTS' THEN 'DESSERTS'  WHEN CATEGORY LIKE 'FLORAL' THEN 'FLORAL' WHEN CATEGORY LIKE 'LIFESTYLE' THEN 'LIFESTYLE' WHEN CATEGORY LIKE 'MEAT' THEN 'MEAT'  WHEN CATEGORY LIKE 'PANTRY ESSENTIALS' THEN 'PANTRY ESSENTIALS' WHEN CATEGORY LIKE 'PREPARED FOODS' THEN 'PREPARED FOODS' WHEN CATEGORY LIKE 'PRODUCE' THEN 'PRODUCE' WHEN CATEGORY LIKE 'SEAFOOD' THEN 'SEAFOOD' WHEN CATEGORY LIKE 'SUPPLEMENTS' THEN 'SUPPLEMENTS' WHEN CATEGORY LIKE 'WINE BEER SPIRITS' THEN 'WINE BEER SPIRITS' ELSE 'NO REGISTERED' END AS CATEGORY,
#Normalizing the dietary preferences
CASE WHEN ALCOHOLIC>=1 THEN 1 ELSE 0 END AS ALCOHOLIC,
CASE WHEN DAIRYFREE>=1 THEN 1 ELSE 0 END AS DAIRYFREE,
CASE WHEN VEGAN>1 THEN 1 ELSE 0 END AS VEGAN,
CASE WHEN VEGETARIAN>=1 THEN 1 ELSE 0 END AS VEGETARIAN,
CASE WHEN LOWSODIUM>=1 THEN 1 ELSE 0 END AS LOWSODIUM,
CASE WHEN PALEOFRIENDLY>=1 THEN 1 ELSE 0 END AS PALEOFRIENDLY,
CASE WHEN SUGARCONSCIOUS>=1 THEN 1 ELSE 0 END AS SUGARCONSCIOUS,
CASE WHEN WHOLE_FOODS_DIET>=1 THEN 1 ELSE 0 END AS WHOLE_FOODS_DIET,
CASE WHEN KETOFRIENDLY>=1 THEN 1 ELSE 0 END AS KETOFRIENDLY,
CASE WHEN KOSHER>=1 THEN 1 ELSE 0 END AS KOSHER,
CASE WHEN LOWFAT>=1 THEN 1 ELSE 0 END AS LOWFAT,
CASE WHEN ORGANIC>=1 THEN 1 ELSE 0 END AS ORGANIC,
CASE WHEN GLUTENFREE>=1 THEN 1 ELSE 0 END AS GLUTERFREE,
CASE WHEN ENGINE_2>=1 THEN 1 ELSE 0 END AS ENGINE_2
from products_database)
)
-- Bringing all the columns except for the dietary preferences to make a unique column with the count
select ID, `PRODUCT LABEL`, BRAND, REGULAR_PRICE, CATEGORY, 
-- Column counting the dietary preferences if the brand is Whole Foods
-- sums the dietary preferences 
case when BRAND='WHOLE FOODS MARKET' THEN 
-- sums the dietary preferences 
#If the brand is different, the value will be 99 to don't get mixed with the products that have 0 diets. No alcohol because it is not a dietary preference
(DAIRYFREE+VEGAN+VEGETARIAN+LOWSODIUM+PALEOFRIENDLY+SUGARCONSCIOUS+WHOLE_FOODS_DIET+KETOFRIENDLY+KOSHER+LOWFAT+ORGANIC+GLUTERFREE+ENGINE_2) ELSE 99 END AS `WF BRANDS DIERTARY PREFERENCE`,
-- Column counting the dietary preferences if the brand is NOT Whole Foods
case when BRAND='OTHER' THEN 
-- sums the dietary preferences 
#If the brand is different, the value will be 99 to don't get mixed with the products that have 0 diets. No alcohol because it is not a dietary preference
(DAIRYFREE+VEGAN+VEGETARIAN+LOWSODIUM+PALEOFRIENDLY+SUGARCONSCIOUS+WHOLE_FOODS_DIET+KETOFRIENDLY+KOSHER+LOWFAT+ORGANIC+GLUTERFREE+ENGINE_2) ELSE 99 END AS `OTHER BRANDS DIERTARY PREFERENCE`
from normalized_database)

-- Table showing the average of diets by category for WF and other brands, and determining if there is or not representation of WF across categories.
#There is representation if WF average is equal or higher than others'
select WF.CATEGORY, FORMAT(WF.`Avg dietary preferences in WF`,0) AS `Avg dietary preferences in WF`, FORMAT(OB.`Avg dietary preferences in other brands`,0) AS `Avg dietary preferences in other brands`, 
-- Creating column that shows if WF is or not represented in the category
case when (FORMAT(WF.`Avg dietary preferences in WF`,0) >= FORMAT(OB.`Avg dietary preferences in other brands`,0)) AND (FORMAT(WF.`Avg dietary preferences in WF`,0)<> 0) then 'YES' ELSE 'NO' END AS `REPRESENTATION OF WHOLE FOODS MARKET`
FROM
-- Table calculating the average of diets by category for MF, excluding entries where there is a 99 because they are not WF brands. 
#Note here that it is including records with 0 dietary preferences
(SELECT CATEGORY, AVG(`WF BRANDS DIERTARY PREFERENCE`) as `Avg dietary preferences in WF` from dietary_preferences
where `WF BRANDS DIERTARY PREFERENCE`<>99
group by CATEGORY
) 
as WF
join
-- Table calculating the average of diets by category for OTHER brands, excluding entries where there is a 99 because they are not OTHER brands. 
#Note here that it is including records with 0 dietary preferences
(SELECT CATEGORY, AVG(`OTHER BRANDS DIERTARY PREFERENCE`) as `Avg dietary preferences in other brands` FROM dietary_preferences
where `OTHER BRANDS DIERTARY PREFERENCE`<>99
group by CATEGORY
) 
as OB
on WF.CATEGORY=OB.CATEGORY
;

