USE fmban_sql_analysis;

-- Checking the average price per serving of products in each subcategory to get a feeling for the data and which products are expensive/cheap
SELECT subcategory, category,
		AVG(price / (totalsecondarysize / servingsize)) AS avg_price_per_serving_1, -- sometimes results differ between using totalsize and totalsecondarysize because of different units
		AVG(price / (totalsize / servingsize)) AS avg_price_per_serving_2			-- and since case statements don't work with group by, both are displayed. The value that is not null or is smaller is the right one to use
FROM fmban_data
WHERE price NOT LIKE '%.%' -- Filtering out price that has not been multiplied by 100
AND ((secondarysizeunits = servingsizeunits) OR (totalsizeunits = servingsizeunits)) -- Filtering out shifted rows by checking whether the units are still in the right column
GROUP BY subcategory, category -- grouping by subcategory to get an average price per subcategory
LIMIT 100;



-- calculating the price per serving for all products and categorizing them as healthy/unhealthy according to the definition
SELECT 
    category,
    subcategory,
    CASE													-- Case to use secondarysize to calculate the servings per product when servingsizeunits and secondarysizeunits match
		WHEN
			servingsizeunits = secondarysizeunits
        THEN
            (price / (totalsecondarysize / servingsize))	-- Price per serving calculated by calculating servings per product and then price per serving
		ELSE												-- use totalsize to calculate the servings per product when servingsizeunits and secondarysizeunits do not match
			(price / (totalsize / servingsize))				-- Price per serving calculated by calculating servings per product and then price per serving
		END AS price_per_serving,							
    servingsize,
    totalsecondarysize,
    totalsize,
    CASE   													-- Case to determine healthy products/unhealthy products
        WHEN
            (sugarconscious = 1 AND lowsodium = 1 AND lowfat = 1)	-- When product is sugarconscious has lowsodium and has lowfat then it should be healthy according to the criteria
        THEN
            'healthy'
        ELSE 'unhealthy'											-- If at least one of them is not fulfilled it should be declared as unhealthy
    END AS healthy_food_check
FROM
    fmban_data
WHERE	price NOT LIKE '%.%'	-- Filtering out price that has not been multiplied by 100										
		AND ((secondarysizeunits = servingsizeunits) OR (totalsizeunits = servingsizeunits)) -- Filtering out shifted rows by checking whether the units are still in the right column
        AND category NOT LIKE 'beverages' 	-- Filtering out all beverages as only food should be considered
        AND category NOT LIKE 'beer'		-- Filtering out all beers as only food should be considered
        AND category NOT LIKE 'wine'		-- Filtering out all wines as only food should be considered
;
-- Result is exported to excel for t-test

-- to check results in excel the mean for both healthy and unhealthy is calculated in sql as well, first the query for healthy:
SELECT (AVG(price_per_serving)/100) AS avg_price_healthy FROM(
    SELECT CASE													-- Case to use secondarysize to calculate the servings per product when servingsizeunits and secondarysizeunits match
		WHEN servingsizeunits = secondarysizeunits
        THEN (price / (totalsecondarysize / servingsize))	-- Price per serving calculated by calculating servings per product and then price per serving
		ELSE												-- use totalsize to calculate the servings per product when servingsizeunits and secondarysizeunits do not match
			(price / (totalsize / servingsize))				-- Price per serving calculated by calculating servings per product and then price per serving
		END AS price_per_serving
		FROM
			fmban_data
		WHERE	price NOT LIKE '%.%'	-- Filtering out price that has not been multiplied by 100										
				AND ((secondarysizeunits = servingsizeunits) OR (totalsizeunits = servingsizeunits)) -- Filtering out shifted rows by checking whether the units are still in the right column
				AND category NOT LIKE 'beverages' 	-- Filtering out all beverages as only food should be considered
				AND category NOT LIKE 'beer'		-- Filtering out all beers as only food should be considered
				AND category NOT LIKE 'wine'
                AND (sugarconscious = 1 AND lowsodium = 1 AND lowfat = 1)	-- When product is sugarconscious has lowsodium and has lowfat then it should be healthy according to the criteria
		) AS dat1		-- Filtering out all wines as only food should be considered
;
-- the average price of healthy products is appr $1.65

-- query for the average price of unhealthy products:
SELECT (AVG(price_per_serving)/100) AS avg_price_unhealthy FROM(
    SELECT CASE													-- Case to use secondarysize to calculate the servings per product when servingsizeunits and secondarysizeunits match
		WHEN servingsizeunits = secondarysizeunits
        THEN (price / (totalsecondarysize / servingsize))	-- Price per serving calculated by calculating servings per product and then price per serving
		ELSE												-- use totalsize to calculate the servings per product when servingsizeunits and secondarysizeunits do not match
			(price / (totalsize / servingsize))				-- Price per serving calculated by calculating servings per product and then price per serving
		END AS price_per_serving
		FROM
			fmban_data
		WHERE	price NOT LIKE '%.%'	-- Filtering out price that has not been multiplied by 100										
				AND ((secondarysizeunits = servingsizeunits) OR (totalsizeunits = servingsizeunits)) -- Filtering out shifted rows by checking whether the units are still in the right column
				AND category NOT LIKE 'beverages' 	-- Filtering out all beverages as only food should be considered
				AND category NOT LIKE 'beer'		-- Filtering out all beers as only food should be considered
				AND category NOT LIKE 'wine'
                AND (sugarconscious = 0 OR lowsodium = 0 OR lowfat = 0)	-- When product does not fulfill at least one of the criteria it is unhealthy
		) AS dat2		-- Filtering out all wines as only food should be considered
;
-- the average price of unhealthy products is appr $3.86
-- both average prices match the t-test results

-- Now the total count of all healthy/unhealthy products is conducted in the same manner. Count healthy products:
SELECT COUNT(price_per_serving) AS count_healthy FROM(
    SELECT CASE													-- Case to use secondarysize to calculate the servings per product when servingsizeunits and secondarysizeunits match
		WHEN servingsizeunits = secondarysizeunits
        THEN (price / (totalsecondarysize / servingsize))	-- Price per serving calculated by calculating servings per product and then price per serving
		ELSE												-- use totalsize to calculate the servings per product when servingsizeunits and secondarysizeunits do not match
			(price / (totalsize / servingsize))				-- Price per serving calculated by calculating servings per product and then price per serving
		END AS price_per_serving
		FROM
			fmban_data
		WHERE	price NOT LIKE '%.%'	-- Filtering out price that has not been multiplied by 100										
				AND ((secondarysizeunits = servingsizeunits) OR (totalsizeunits = servingsizeunits)) -- Filtering out shifted rows by checking whether the units are still in the right column
				AND category NOT LIKE 'beverages' 	-- Filtering out all beverages as only food should be considered
				AND category NOT LIKE 'beer'		-- Filtering out all beers as only food should be considered
				AND category NOT LIKE 'wine'
                AND (sugarconscious = 1 AND lowsodium = 1 AND lowfat = 1)	-- When product is sugarconscious has lowsodium and has lowfat then it should be healthy according to the criteria
		) AS dat1		-- Filtering out all wines as only food should be considered
;
-- the dataset contains 17 healthy products after filtering


-- Count unhealthy products:
SELECT COUNT(price_per_serving) AS count_unhealthy FROM(
    SELECT CASE													-- Case to use secondarysize to calculate the servings per product when servingsizeunits and secondarysizeunits match
		WHEN servingsizeunits = secondarysizeunits
        THEN (price / (totalsecondarysize / servingsize))	-- Price per serving calculated by calculating servings per product and then price per serving
		ELSE												-- use totalsize to calculate the servings per product when servingsizeunits and secondarysizeunits do not match
			(price / (totalsize / servingsize))				-- Price per serving calculated by calculating servings per product and then price per serving
		END AS price_per_serving
		FROM
			fmban_data
		WHERE	price NOT LIKE '%.%'	-- Filtering out price that has not been multiplied by 100										
				AND ((secondarysizeunits = servingsizeunits) OR (totalsizeunits = servingsizeunits)) -- Filtering out shifted rows by checking whether the units are still in the right column
				AND category NOT LIKE 'beverages' 	-- Filtering out all beverages as only food should be considered
				AND category NOT LIKE 'beer'		-- Filtering out all beers as only food should be considered
				AND category NOT LIKE 'wine'
                AND (sugarconscious = 0 OR lowsodium = 0 OR lowfat = 0)	-- When product does not fulfill at least one of the criteria it is unhealthy
		) AS dat2		-- Filtering out all wines as only food should be considered
;
-- the dataset contains 176 unhealthy products after filtering



-- now to check the healthiness of drinks alcoholic and non_alcoholic drinks are compared 
SELECT 
	price,		-- since a lot of the data has not been converted in the price column these values in this case are not filtered out but instead cleaned manually before doing the t-test
	category,
    subcategory,
	(price / (totalsize / servingsize))	AS price_per_serving,							
    servingsize,
    totalsecondarysize,
    totalsize,
    abv,
    CASE   													-- Case to determine healthy products/unhealthy products
        WHEN
            (abv > 0)	-- When product has an alcohol by volume greater than 0 (aka when it contains alcohol) it is unhealthy
        THEN
            'unhealthy'
        ELSE 'healthy'											-- all products without alcohol are considered healthy
    END AS healthy_drink_check
FROM
    fmban_data
WHERE (category LIKE 'beverages' OR category LIKE 'beer' OR category LIKE 'wine') -- filtering only for drinks
;

-- Results are exported to excel for t-test analysis


-- Again, to check results in excel the mean for both healthy and unhealthy is calculated in sql as well, first the query for healthy:
SELECT AVG ((price / (totalsize / servingsize)))/100 AS avg_price_healthy
FROM
    fmban_data
WHERE (category LIKE 'beverages' OR category LIKE 'beer' OR category LIKE 'wine') -- filtering only for drinks
AND (abv = 0 OR abv IS NULL) -- healthy drinks with abv = 0
;
-- the average price of healthy drinks is appr $2.53

-- Unhealthy products average price:
SELECT AVG ((price / (totalsize / servingsize)))/100 AS avg_price_healthy
FROM
    fmban_data
WHERE (category LIKE 'beverages' OR category LIKE 'beer' OR category LIKE 'wine') -- filtering only for drinks
AND (abv > 0) -- unhealthy drinks with abv > 0
;
-- the average price of healthy drinks is appr $3.40
-- both average prices match the t-test results


-- Again, now the total count of all healthy/unhealthy drinks is conducted in the same manner. Count healthy products:
SELECT COUNT((price / (totalsize / servingsize))) AS avg_price_healthy
FROM
    fmban_data
WHERE (category LIKE 'beverages' OR category LIKE 'beer' OR category LIKE 'wine') -- filtering only for drinks
AND (abv = 0 OR abv IS NULL) -- healthy drinks with abv = 0
;
-- there are 22 healthy drinks in the dataset


SELECT COUNT((price / (totalsize / servingsize))) AS avg_price_healthy
FROM
    fmban_data
WHERE (category LIKE 'beverages' OR category LIKE 'beer' OR category LIKE 'wine') -- filtering only for drinks
AND (abv > 0) -- unhealthy drinks with abv > 0
;
-- there are 27 unhealthy drinks in the dataset
