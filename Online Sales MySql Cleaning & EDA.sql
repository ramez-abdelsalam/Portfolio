-- ------------------------------------------------------- Online Sales Dataset Cleaning & EDA
-- -------------- OUTLINE
-- 1- Data Cleaning
	-- 1-1 Duplicates Inspection & Removal
	-- 1-2 Typo Mistakes Inspection & fixing
    -- 1-3 Correcting Data Types
    -- 1-4 CustomerID Column Trimming
    -- 1-5 Turning Negative Values into Positive
    -- 1-6 Reshaping Category Column
    -- 1-7 Reducing Discount Column Decimals
    -- 1-8 Filling Empty Cells
-- 2- Fearure Engineering
	-- 2-1 Creating New Columns
    -- 2-2 Creating New Tables for Some Distinct Values
    -- 2-3 Deleting The Unnecessary Columns
-- 3- Exploratory Data Analysis
	-- 3-1 Product Peformance
    -- 3-2 Sales Trends
    -- 3-3 Customer Analysis
    -- 3-4 Return Analysis
-- 4- Data Findings
-- 5- Implications






-- Before moving to steps I will make duplicate table to do steps on to avoid any loss to the original data.
CREATE TABLE online_sales_2    -- creating a duplicate
LIKE online_sales_dataset;

INSERT INTO online_sales_2   -- accommodating same data to the new table
SELECT * FROM online_sales_dataset;



-- ------------------------------------------------------- 1- Dataset Cleaning 
-- ------------ 1-1 Duplicates Inspection & Removal

SELECT *,  -- This is to group similar rows unique rows takes value 1, duplicate row takes a value of 2 or higher
row_number() OVER(PARTITION BY InvoiceNo, StockCode, `Description`, Quantity, InvoiceDate, UnitPrice, CustomerID, Country) AS row_num
FROM online_sales_2;

WITH cte AS  -- This is to display if any row has a highr row_num that 1 (duplicate)
(
SELECT *,
row_number() OVER(PARTITION BY InvoiceNo, StockCode, `Description`, Quantity, InvoiceDate, UnitPrice, CustomerID, Country) AS row_num
FROM online_sales_2
) 
SELECT * FROM cte
WHERE row_num > 1 ;



-- ------------ 1-2 Typo Mistakes Inspection & fixing
-- Method is by looking for distinct values in every text column

SELECT DISTINCT `Description` FROM online_sales_2;
SELECT DISTINCT Country FROM online_sales_2;
SELECT DISTINCT PaymentMethod FROM online_sales_2;
SELECT DISTINCT Category FROM online_sales_2;
SELECT DISTINCT SalesChannel FROM online_sales_2;
SELECT DISTINCT ReturnStatus FROM online_sales_2;
SELECT DISTINCT ShipmentProvider FROM online_sales_2;
SELECT DISTINCT WarehouseLocation FROM online_sales_2;  -- Nulss Found
SELECT DISTINCT OrderPriority FROM online_sales_2;



-- ------------ 1-3 Correcting Data Types
ALTER TABLE online_sales_2
MODIFY COLUMN InvoiceNo text,
MODIFY COLUMN CustomerID text,
MODIFY COLUMN InvoiceDate datetime;




-- ------------ 1-4 CustomerID Column Trimming
UPDATE online_sales_2 
SET CustomerID = REPLACE (CustomerID, '.0', '');



-- ------------ 1-5 Turning Negative Values into Positive
-- I noticed Quantity and UnitPrice columns has a negative values

SELECT count(*) FROM online_sales_2 WHERE Quantity < 0;  -- 2489 negative value
SELECT count(*) FROM online_sales_2 WHERE UnitPrice < 0;  -- 1493 negative value

UPDATE online_sales_2
	SET 
    Quantity = abs(Quantity),
    UnitPrice = abs(UnitPrice);



-- ------------ 1-6 Reassigning Category Column
-- Same item was classified as different categories.
SELECT `Description`, Category, COUNT(Category) FROM online_sales_2 WHERE `Description` = 'HeadPhones' GROUP BY Category;
-- HeadPhones classified as electronics 917 time and other categories over 3500 times

UPDATE online_sales_2
	SET Category = 
	CASE
		WHEN `Description` = 'T-shirt' THEN 'Apparel'
        WHEN `Description` = 'Office Chair' THEN 'Furniture'
        WHEN `Description` IN ('Notebook', 'Blue Pen') THEN 'Stationary'
        WHEN `Description` IN ('Wireless Mouse', 'USB Cable', 'Headphones') THEN 'Electronics'
        WHEN `Description` IN ('Backpack', 'Desk Lamp', 'Wall Clock', 'White Mug') THEN 'Accessories'
	END;
        
SELECT `Description`, Category, COUNT(Category) FROM online_sales_2 WHERE `Description` = 'HeadPhones' GROUP BY Category;  -- rerun to confirm



-- ------------ 1-7 Reducing Discount Column Decimals
UPDATE online_sales_2
	SET Discount = round(Discount, 2);



-- ------------ 1-8 Filling Empty Cells
-- 3 columns has nulls, CustomerID, ShippingCost and WarehouseLocation.
-- Firstly, for ShippingCost & WarehouseLocation, I will invistigate if nulls has a relation with any other column before filling.
-- I will replace CustomerID empty cells with 'Unknown' and with NULL for ShippingCost and WarehouseLocation.

UPDATE online_sales_2
	SET CustomerID = 'Unknown'
    WHERE CustomerID = '';
    
UPDATE online_sales_2
	SET ShippingCost = NULL
    WHERE ShippingCost = '';
    
UPDATE online_sales_2
	SET WarehouseLocation = NULL
    WHERE WarehouseLocation = '';

SELECT DISTINCT SalesChannel, count(SalesChannel) AS count FROM online_sales_2 WHERE ShippingCost = '' GROUP BY SalesChannel ORDER BY count DESC;
SELECT DISTINCT PaymentMethod, count(PaymentMethod) AS count FROM online_sales_2 WHERE ShippingCost = '' GROUP BY PaymentMethod ORDER BY count DESC;
SELECT DISTINCT ReturnStatus, count(ReturnStatus) AS count FROM online_sales_2 WHERE ShippingCost = '' GROUP BY ReturnStatus ORDER BY count DESC;  -- 248 Returned, 2241 Not Returned
SELECT DISTINCT Country, count(Country) AS count FROM online_sales_2 WHERE ShippingCost = '' GROUP BY Country ORDER BY count DESC;
SELECT DISTINCT WarehouseLocation, count(WarehouseLocation) AS count FROM online_sales_2 WHERE ShippingCost = '' GROUP BY WarehouseLocation ORDER BY count DESC;
-- Normal distribution and no relation except for ReturnStatus nearly 10% Returned to 90% Not Returned

SELECT DISTINCT SalesChannel, count(SalesChannel) AS count FROM online_sales_2 WHERE WarehouseLocation = '' GROUP BY SalesChannel ORDER BY count DESC;
SELECT DISTINCT PaymentMethod, count(PaymentMethod) AS count FROM online_sales_2 WHERE WarehouseLocation = '' GROUP BY PaymentMethod ORDER BY count DESC;
SELECT DISTINCT Country, count(Country) AS count FROM online_sales_2 WHERE WarehouseLocation = '' GROUP BY Country ORDER BY count DESC;
SELECT DISTINCT ReturnStatus, count(ReturnStatus) AS count FROM online_sales_2 WHERE WarehouseLocation = '' GROUP BY ReturnStatus ORDER BY count DESC; -- 342 Returned, 3143 Not Returned
-- Normal distribution and no relation except ReturnStatus, nearly 10% Returned to 90% Not Returned.
-- If this ratio is close to ratio within the original data, ther will not be a relation.

SELECT DISTINCT ReturnStatus, count(ReturnStatus) AS count FROM online_sales_2 GROUP BY ReturnStatus ORDER BY count DESC; -- 342 Returned, 3143 Not Returned
-- 4894 Returned to 44888 Not Returned which is nearly the same ratio.
-- No relation found between nulls and any other column

-- Secondly, I will look at ShippingCost & WarehouseLocation distribution to choose a method for replacing nulls.
SELECT DISTINCT ShippingCost, count(ShippingCost) AS count FROM online_sales_2 GROUP BY ShippingCost ORDER BY count DESC; -- Normal Distribution
SELECT DISTINCT WarehouseLocation, count(WarehouseLocation) AS count FROM online_sales_2 GROUP BY WarehouseLocation ORDER BY count DESC; -- Normal Distribution


-- As both columns has normal distribution, I will use the forward fill method to fill the nulls
-- Forward fill has no predefined function like in python so it requires a long procedure

-- 1- creating a new column row_num to use as an index
ALTER TABLE online_sales_2 ADD COLUMN row_num INT;
SET @row_number = 0; 
UPDATE online_sales_2 SET row_num = (@row_number := @row_number + 1) ORDER BY invoicedate;

-- 2- Creating a common table expression to group null cell with the nearest non null cell above
WITH cte1 AS 
(
	SELECT ShippingCost, row_num, COUNT(ShippingCost) OVER (ORDER BY row_num) AS nulls_grouped
    FROM online_sales_2
),  -- 3- Creating another CTE to make a column with ShippingCost nulls filled
cte2 AS 
(
	SELECT row_num, ShippingCost, nulls_grouped, 
    FIRST_VALUE(ShippingCost) OVER (PARTITION BY nulls_grouped ORDER BY row_num) AS new_shippingcost
    FROM cte1
)  -- 4- Using a join to update online_sales_2 from the new filled column created as a cte (cte2)
UPDATE online_sales_2
	JOIN cte2 
    ON online_sales_2.row_num = cte2.row_num
SET online_sales_2.ShippingCost = cte2.new_shippingcost
WHERE online_sales_2.ShippingCost IS NULL;  -- Notice that the three steps are in one query without ;
    
-- 5- Doing same procedure for WarehouseLocation nulls
WITH cte1 AS
(
	SELECT WarehouseLocation, row_num, COUNT(WarehouseLocation) OVER (ORDER BY row_num) AS nulls_grouped
    FROM online_sales_2
),
cte2 AS
(
	SELECT WarehouseLocation, row_num, nulls_grouped,
    FIRST_VALUE (WarehouseLocation) OVER (PARTITION BY nulls_grouped ORDER BY row_num) AS new_warehouse_location
    FROM cte1
)
UPDATE online_sales_2
	JOIN cte2 
    ON online_sales_2.row_num = cte2.row_num
SET online_sales_2.WarehouseLocation = cte2.new_warehouse_location
WHERE online_sales_2.WarehouseLocation IS NULL;




-- ------------------------------------------------------- 2- Feature Engineering
-- ------------ 2-1 Creating New Columns
-- Here I will create a new columns contaning numbers related to a distinct value of anothe column to minimize memory usage.

-- Creating the columns
ALTER TABLE online_sales_2 
ADD COLUMN (
	DescriptionIndex text,
    CountryIndex text,
    PaymentMethodIndex text,
    CategoryIndex text,
    SalesChannelIndex text,
    ReturnStatusIndex text,
    ShipmentProviderIndex text,
    WarehouseLocationIndex text,
    OrderPriorityIndex text
);


-- Accommodating the values to the columns
UPDATE online_sales_2
SET DescriptionIndex = 
	CASE
		WHEN `Description` = 'Backpack' THEN '1'
        WHEN `Description` = 'Blue Pen' THEN '2'
        WHEN `Description` = 'Desk Lamp' THEN '3'
        WHEN `Description` = 'Headphones' THEN '4'
        WHEN `Description` = 'Notebook' THEN '5'
        WHEN `Description` = 'Office Chair' THEN '6'
        WHEN `Description` = 'T-shirt' THEN '7'
        WHEN `Description` = 'USB Cable' THEN '8'
        WHEN `Description` = 'Wall Clock' THEN '9'
        WHEN `Description` = 'White Mug' THEN '10'
        WHEN `Description` = 'Wireless Mouse' THEN '11'
	END;

UPDATE online_sales_2
SET CountryIndex = 
	CASE
		WHEN Country = 'Australia' THEN '1'
        WHEN Country = 'Belgium' THEN '2'
        WHEN Country = 'France' THEN '3'
        WHEN Country = 'Germany' THEN '4'
        WHEN Country = 'Italy' THEN '5'
        WHEN Country = 'Netherlands' THEN '6'
        WHEN Country = 'Norway' THEN '7'
        WHEN Country = 'Portugal' THEN '8'
        WHEN Country = 'Spain' THEN '9'
        WHEN Country = 'Sweden' THEN '10'
        WHEN Country = 'United Kingdom' THEN '11'
        WHEN Country = 'United States' THEN '12'
	END;

UPDATE online_sales_2
SET PaymentMethodIndex = 
	CASE
		WHEN PaymentMethod = 'bank Transfer' THEN '1'
        WHEN PaymentMethod = 'Credit Card' THEN '2'
        WHEN PaymentMethod = 'paypall' THEN '3'
	END;
    
UPDATE online_sales_2
SET CategoryIndex = 
	CASE
		WHEN Category = 'Accessories' THEN '1'
        WHEN Category = 'Apparel' THEN '2'
        WHEN Category = 'Electronics' THEN '3'
        WHEN Category = 'Furniture' THEN '4'
        WHEN Category = 'Stationary' THEN '5'
	END;    
    
UPDATE online_sales_2
SET SalesChannelIndex = 
	CASE
		WHEN SalesChannel = 'In-store' THEN '1'
        WHEN SalesChannel = 'Online' THEN '2'
	END;

UPDATE online_sales_2
SET ReturnStatusIndex = 
	CASE
		WHEN ReturnStatus = 'Returned' THEN '1'
        ELSE '0'
	END;

UPDATE online_sales_2
SET ShipmentproviderIndex = 
	CASE
		WHEN Shipmentprovider = 'DHL' THEN '1'
        WHEN Shipmentprovider = 'FedEx' THEN '2'
        WHEN Shipmentprovider = 'Royal mail' THEN '3'
        WHEN Shipmentprovider = 'UPS' THEN '4'
	END;        
    
UPDATE online_sales_2
SET WarehouseLocationIndex = 
	CASE
		WHEN WarehouseLocation = 'Amsterdam' THEN '1'
        WHEN WarehouseLocation = 'Berlin' THEN '2'
        WHEN WarehouseLocation = 'London' THEN '3'
        WHEN WarehouseLocation = 'paris' THEN '4'
        WHEN WarehouseLocation = 'Rome' THEN '5'
	END;

UPDATE online_sales_2
SET orderpriorityIndex = 
	CASE
		WHEN OrderPriority = 'High' THEN '1'
        WHEN OrderPriority = 'medium' THEN '2'
        ELSE '3'
	END;



-- ------------ 2-2 Creating New Tables
-- Here i will create new tables of distinct values like countries that i can use later using joins

CREATE TABLE `description` (
	DescriptionIndex text,
    `Description` text)
AS
SELECT DISTINCT descriptionIndex, `Description` FROM online_sales_2;

CREATE TABLE country (
	CountryIndex text,
    Country text) 
AS
SELECT DISTINCT CountryIndex , Country FROM online_sales_2;

CREATE TABLE payment_method (
	PaymentMethodIndex text,
    PaymentMethod text )
AS SELECT DISTINCT PaymentMethodIndex , PaymentMethod FROM online_sales_2;

CREATE TABLE categories (
  CategoryIndex text,
  Category text
) AS
SELECT DISTINCT CategoryIndex, Category FROM online_sales_2;

CREATE TABLE sales_channel (
	SalesChannelIndex TEXT,
    SalesChannel TEXT)
AS
SELECT DISTINCT SalesChannelIndex, SalesChannel FROM online_sales_2;

CREATE TABLE return_status (
	ReturnStatusIndex text,
    ReturnStatus text)
AS
SELECT DISTINCT ReturnStatusIndex, ReturnStatus FROM online_sales_2;

CREATE TABLE shipment_provider (
	ShipmentProviderIndex TEXT,
    ShipmentProvider TEXT)
AS
SELECT DISTINCT ShipmentProviderIndex, ShipmentProvider FROM online_sales_2;

CREATE TABLE warehouse_location (
	WarehouseLocationIndex TEXT,
    WarehouseLocation TEXT)
AS
SELECT DISTINCT WarehouselocationIndex, WarehouseLocation FROM online_sales_2;

CREATE TABLE order_priority (
	OrderPriorityIndex text,
    OrderPriority text)
AS
SELECT DISTINCT OrderPriorityIndex, OrderPriority FROM online_sales_2;



-- ------------ 2-3 Dleting The Unnecessary Columns
-- Deleting those columns while keeping the indexes columns will minimize data usage

ALTER TABLE online_sales_2 
DROP COLUMN `Description`,
DROP COLUMN Country,
DROP COLUMN paymentMethod,
DROP COLUMN Category,
DROP COLUMN SalesChannel,
DROP COLUMN ReturnStatus,
DROP COLUMN ShipmentProvider,
DROP COLUMN WarehouseLocation,
DROP COLUMN row_num,
DROP COLUMN OrderPriority;






-- ------------------------------------------------------- 3- Exploratory Data Analysis
-- ------------ 3-1 Product Performance

-- 1- How many units did each product sell? Including Rolling_total
WITH cte1 AS
(
SELECT `Description`, SUM(Quantity) AS Quantity_sold
FROM online_sales_2
JOIN `description`
	ON online_sales_2.DescriptionIndex = description.descriptionIndex
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Not Returned'
GROUP BY `Description`
ORDER BY Quantity_sold ASC
)
SELECT *, 
SUM(Quantity_sold) OVER (ORDER BY Quantity_sold ASC) AS Rolling_total
FROM cte1;

-- 2- How much revenue did each product generate? including Rolling_total
WITH cte2 AS
(
SELECT `Description`, round (SUM(Quantity * (Unitprice - Discount)) ,1) AS Revenue_generated
FROM online_sales_2
JOIN `description`
	ON online_sales_2.DescriptionIndex = `description`.descriptionIndex
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Not Returned'
GROUP BY `Description`
ORDER BY Revenue_generated ASC
)
SELECT *,
ROUND( SUM(Revenue_generated) OVER (ORDER BY Revenue_generated ASC),1) AS Rolling_total
FROM cte2;

-- 3- What is the products average price and total orders made?
SELECT `Description`, ROUND(AVG(UnitPrice),2) AS Item_avg_price , COUNT(InvoiceNo) AS Item_total_orders
FROM online_sales_2
JOIN `description`
	ON online_sales_2.DescriptionIndex = `description`.DescriptionIndex
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Not Returned'
GROUP BY `Description`
ORDER BY Item_total_orders ASC;


-- All product performance details in one query.
WITH product_performance AS
(
SELECT `Description`,
	ROUND(AVG(UnitPrice),2) AS Item_avg_price,
    COUNT(InvoiceNo) Item_total_orders,
    SUM(Quantity) AS Quantity_sold,
    ROUND (SUM(Quantity * (Unitprice - Discount)) ,1) AS Revenue_generated
FROM online_sales_2
JOIN `description`
	ON online_sales_2.DescriptionIndex = `description`.DescriptionIndex
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Not Returned'
GROUP BY `Description`
ORDER BY Revenue_generated ASC
)
SELECT `Description`, Item_avg_price, Item_total_orders, Quantity_sold,
	SUM(Quantity_sold) OVER (ORDER BY Quantity_sold ASC) AS Quantity_Rolling_total,
    Revenue_generated,
    ROUND( SUM(Revenue_generated) OVER (ORDER BY Revenue_generated ASC),1) AS Revenue_Rolling_total
FROM product_performance;
	


-- ------------ 3-2 Sales Trends
-- 1- Is there any purchasing pattern during day hours
SELECT HOUR(InvoiceDate) AS Day_hours, COUNT(InvoiceNo) AS Total_orders, SUM(Quantity) AS Total_quantity
FROM online_sales_2
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Not Returned'
GROUP BY HOUR(InvoiceDate)
ORDER BY HOUR(InvoiceDate) ASC;
 
-- 2- Purchasing patterns during week days
SELECT DAYNAME(InvoiceDate) AS Week_days, COUNT(InvoiceNo) AS Total_orders, SUM(Quantity) AS Total_quantity
FROM online_sales_2
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Not Returned'
GROUP BY DAYNAME(InvoiceDate)
ORDER BY DAYNAME(InvoiceDate) ASC;

-- 3- Purchasing patterns grouped by month and year
SELECT 
    MONTH(InvoiceDate) AS Month_number,
    MONTHNAME(InvoiceDate) AS Month_name,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2020 THEN InvoiceNo END) AS `2020 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2021 THEN InvoiceNo END) AS `2021 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2022 THEN InvoiceNo END) AS `2022 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2023 THEN InvoiceNo END) AS `2023 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2024 THEN InvoiceNo END) AS `2024 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2025 THEN InvoiceNo END) AS `2025 orders`
FROM online_sales_2
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Not Returned'
GROUP BY 
    Month_number, Month_name
ORDER BY 
    FIELD(Month_name, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

-- 
SELECT QUARTER(Invoicedate) AS `quarter`,
	COUNT(CASE WHEN YEAR(InvoiceDate) = 2020 THEN InvoiceNo END) AS `2020 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2021 THEN InvoiceNo END) AS `2021 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2022 THEN InvoiceNo END) AS `2022 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2023 THEN InvoiceNo END) AS `2023 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2024 THEN InvoiceNo END) AS `2024 orders`,
    COUNT(CASE WHEN YEAR(InvoiceDate) = 2025 THEN InvoiceNo END) AS `2025 orders`
FROM online_sales_2
GROUP BY `quarter`;




-- ------------ 3-3 Customer Analysis
--  Customer Distribution between countries, sales channels and payment preferences including rolling total for every distribution

WITH customer_analysis AS
(
SELECT Country, COUNT(CustomerID) Customer_count,
COUNT(CASE WHEN SalesChannel = 'In-store' THEN CustomerID END) AS `In-store Customers`,
COUNT(CASE WHEN SalesChannel = 'Online' THEN CustomerID END) AS `Online Customers`,
COUNT(CASE WHEN PaymentMethod = 'Credit Card' THEN CustomerID END) AS `Credit Card Payment Preference`,
COUNT(CASE WHEN PaymentMethod = 'paypall' THEN CustomerID END) AS `Paypall Payment Preference`,
COUNT(CASE WHEN PaymentMethod = 'Bank Transfer' THEN CustomerID END) AS `Bank Transfer Payment Preference`
FROM online_sales_2
JOIN country
	ON online_sales_2.CountryIndex = country.CountryIndex
JOIN sales_channel
	ON online_sales_2.SalesChannelIndex = sales_channel.SalesChannelIndex
JOIN payment_method
	ON online_sales_2.PaymentMethodIndex = payment_method.PaymentMethodIndex
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Not Returned'
GROUP BY Country
ORDER BY Customer_count ASC
)
SELECT Country, Customer_count,
SUM(Customer_count) OVER (ORDER BY Customer_count ) AS `Customer Count Rolling Total`,
`In-store Customers`,
SUM(`In-store Customers`) OVER (ORDER BY Customer_count) AS `In-store Customers Rolling Total`,
`Online Customers`,
SUM(`Online Customers`) OVER (ORDER BY Customer_count) AS `Online Customers Rolling Total`,
`Credit Card Payment preference`,
SUM(`Credit Card Payment preference`) OVER (ORDER BY Customer_count) AS `Credit Card Payment preference Rolling Total`,
`Paypall Payment Preference`,
SUM(`Paypall Payment Preference`) OVER (ORDER BY Customer_count) AS `Paypall Payment Preference Rolling Total`,
`Bank Transfer Payment Preference`,
SUM(`Bank Transfer Payment Preference`) OVER (ORDER BY Customer_count) AS `Bank Transfer Payment Preference Rolling total`
FROM customer_analysis;





-- ------------ 3-4 Returned Products Analysis

-- What is the count of the returned orders? & What is the returned items percentage of the total orders?
SELECT COUNT(CASE WHEN ReturnStatus = 'Returned' THEN InvoiceNo END) AS Returned_items_count,
CONCAT(ROUND((COUNT(CASE WHEN ReturnStatus = 'Returned' THEN InvoiceNo END) / COUNT(InvoiceNo) *100),1), '%') AS `Returned Items Percentage`
FROM online_sales_2
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex;
-- 4894 returned orders, 9.8% of the total orders
-- Despite being low return rate, It should be investigated to ensure there are no potential issues of different channels.

-- 1- Investigating items returns may inflect that a product has manufacturing proplems.
SELECT `Description`, COUNT(InvoiceNo) AS Returned_items_count
FROM online_sales_2
JOIN `description`
	ON online_sales_2.DescriptionIndex = description.descriptionIndex
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Returned'
GROUP BY `Description`
ORDER BY Returned_items_count; -- No spickes in count indicates no potential issues with products

-- 2- Investigating shippment providers for potential delays, inappropriate behaviour or damages,
SELECT ShipmentProvider, COUNT(InvoiceNo) AS Returned_items_count
FROM online_sales_2
JOIN shipment_provider
	ON online_sales_2.ShipmentProviderIndex = shipment_provider.ShipmentProviderIndex
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Returned'
GROUP BY ShipmentProvider
ORDER BY Returned_items_count; -- No signs of potential issues

-- 3- Ivestigating warehouse for potential storing or packaging damaging
SELECT WarehouseLocation, COUNT(InvoiceNo) AS Returned_items_count
FROM online_sales_2
JOIN warehouse_location
	ON online_sales_2.WarehouseLocationIndex = warehouse_location.WarehouselocationIndex
JOIN return_status
	ON online_sales_2.ReturnStatusIndex = return_status.ReturnStatusIndex
WHERE ReturnStatus = 'Returned'
GROUP BY WarehouseLocation
ORDER BY Returned_items_count;  -- No signs of storing or packaging damages






-- ------------------------------------------------------- 4- Data Findings
-- Product Performance :-
-- All products performed the same when it comes to quantity sold and revenue generated despite being different in sizes, usage and production cost, reason is the same average price for all products.

-- Sales Trends :-
-- Visualizing the count of purchases against day hours, days, weeks, month and quarter did not show any signs of purchasing trends, all purchasing patterns are stable.

-- Customer Analysis :-
-- Customers are evenly distributed between the 12 countries within the data,   
-- No customer preference for payment method nor sales channel.

-- Return Analysis :-
-- No certain warehouse damaged items with an increased rate before shipping as returned items are evenly distributed between warehouses.
-- No product was returned at a noticeable higher rate than other products, that means no production flaws that made a certain product defective.
-- Returned items are distributed even between shipping providers, hence no signs of a certain shipping provider delivering products with damages nor the behaviour of shipping employees is inappropriate.





-- ------------------------------------------------------- 5- Implications
-- Product Performance :-
-- The uniform performance despite the differences between products implies that pricing strategy is the key
-- and it suggests that the average price being the same might be a key driving equal performance across diverse products.
-- Pricing strategy should be investigated to decide whether same pricing is more effective toward the best performance or the differentiated pricing based on product characteristics.

-- Sales Trends :-
-- Stable purchasing patterns across time frames suggests a stable customers behaviour,
-- which indicates a mature market where consumer habits are not affected with external factors.

-- Customer Analysis :-
-- Even distribution across the 12 countries suggests the wide geographical reach, it may implies a strong global distributing brand.
-- The equal preference between sales channels and payment methods implies the success of making different options of payments and sales channels of an equal value, liability and accessibility.

-- Return Analysis :-
-- The even distribution of the returned items implies a high level in production quality,
-- robust quality control and handling at warehouses and a reliable shipping providers with consistency in shipping services with no underperforming.



-- 				!!!The overall result that distribution is stable in all aspects might suggest that data is generated in a controlled environment or represents a distributer 
-- 									with high standards in operations and a robust efficiency beside a stable long term contracts.``
