/*
====================================================================
Quality Checks
====================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schema. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.

====================================================================
*/

-- find duplicate id--
SELECT 
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 

--find unwanted space--
select cst_key from silver.crm_cust_info
where cst_key != trim(cst_key)

select cst_firstname from silver.crm_cust_info
where cst_key != trim(cst_firstname)

select cst_lastname from silver.crm_cust_info
where cst_key != trim(cst_lastname)

--data standardlization and consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info

-- check for unwanted space--
select prd_nm
from silver.crm_prd_info
where prd_nm != trim(prd_nm)

--checks for null or negative numbers--
select prd_cost
from silver.crm_prd_info
where prd_cost < 0 or prd_cost is null

--data standerdlization and consistency--
select distinct prd_line
from silver.crm_prd_info

--check for invalid data orders--
select * from silver.crm_prd_info
where prd_start_dt > prd_end_dt

SELECT * FROM silver.crm_prd_info

--check for invalid dates--
SELECT
NULLIF(sls_due_dt,0) sls_due_dt
from bronze.crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) != 0
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101

-- check for invalid date orders--
SELECT * FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_ship_dt

-- check data consistency: between sales, quantity and price
-- >> sales = quantity * price
-- >> values must not be null, zeros or negative

SELECT * FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0

select * from bronze.erp_cust_az12

-- identify out of range dates--

SELECT 
bdate
from silver.erp_cust_az12
WHERE bdate <'1924-01-01' OR bdate > GETDATE()

-- DATA standardlization and consistency

SELECT DISTINCT gen
FROM silver.erp_cust_az12

select * from silver.erp_loc_a101

--data standerdlization and consistency--
SELECT DISTINCT cntry
FROM silver.erp_loc_a101

select * from bronze.erp_px_cat_g1v2

--check for unwanted spaces-

SELECT 
*
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

--Data standerdlization and consistency--
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2
