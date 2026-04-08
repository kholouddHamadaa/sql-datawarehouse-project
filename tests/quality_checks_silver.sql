/*
Quality Checks
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.
*/
-- Checking 'silver.crm_cust_info'
SELECT cst_id , COUNT(*) FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1
  
  
  
  SELECT *
FROM (
SELECT * ,
ROW_NUMBER () OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info 
where cst_id IS NOT NULL
) t
WHERE flag_last != 1


SELECT cst_gndr
FROM silver.crm_cust_info 
WHERE cst_gndr != TRIM(cst_gndr)


-- Data Standrization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info 

-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================
-- Check for Nulls and Duplicates in Primary Key
SELECT prd_id ,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1


--check if everything is matching
--filters out unmatched data after applying transformation
SELECT 
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-' ,'_') as cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

FROM bronze.crm_prd_info

WHERE 
REPLACE(SUBSTRING(prd_key,1,5),'-' ,'_')  NOT IN 
(SELECT id FROM bronze.erp_px_cat_g1v2)

--check for unwanted spaces
SELECT prd_nm
 FROM bronze.crm_prd_info
WHERE  prd_nm != TRIM(prd_nm)

--check for NULLS or Negative numbers
SELECT prd_cost 
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standrization and Consistency 
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

--Check Invalid Date Orders
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt --End Date Must be earlier than Start Date

-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================
--check integeraity of those columns (bec sls_prd_key join crm_prd_info with crm_sales_details)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)

--check for integerity(bec cst_id join crm_cust_info with crm_sales_details)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)

--check for invalid dates
SELECT sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt < 0

--check for invalid dates
SELECT NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <=0

--check for invalid dates
SELECT NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) !=8 
OR sls_order_dt > 20500101-- check for outliers by validating boundries of data range
OR sls_order_dt < 19000101
-- try this for all dates

--check for invalid dates
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

--check data consistency: between sales , quantity, price
--> sales = quatity * price
--> values must not be negative , zeros ,nulls
SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_quantity IS NULL OR sls_sales IS NULL OR sls_price IS NULL
OR sls_quantity <0 OR sls_sales <0  OR sls_price <0 
ORDER BY sls_sales ,sls_price , sls_quantity

-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================
--check integeratiy
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
ELSE cid
END NOT IN (SELECT cst_key FROM silver.crm_cust_info)

--identify out of range dates
SELECT bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1920-01-01' OR bdate >GETDATE() --to get the current date

-- Data standrization and consistency
SELECT DISTINCT gen
FROM bronze.erp_cust_az12

-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================
--check integerity
SELECT 
REPLACE(cid,'-','') cid,
Cntry

FROM bronze.erp_loc_a101

--Data standrization and consistency
SELECT DISTINCT CASE WHEN TRIM(cntry) ='DE' THEN 'Germany'
WHEN TRIM(cntry) IN ('US' , 'USA') THEN 'United States'
WHEN TRIM(cntry) =' ' OR cntry IS NULL THEN 'n/a'
ELSE cntry
END AS cntry
FROM bronze.erp_loc_a101
ORDER BY cntry

-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ===================================================================
--check for unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat!= TRIM(cat) OR subcat!= TRIM(subcat) OR maintenance!= TRIM(maintenance)

--Data Standrization and consistency
SELECT DISTINCT cat 
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT subcat 
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT maintenance 
FROM bronze.erp_px_cat_g1v2
