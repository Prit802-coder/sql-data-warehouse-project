/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/



CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

 DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';


        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';


        -- ====================================================
        -- Loading silver.crm_cust_info
        -- ====================================================

        SET @start_time = GETDATE();


    PRINT'>>Truncating Table: Silver.crm_cust_info';
    TRUNCATE TABLE Silver.crm_cust_info
    PRINT'>>Inserting data into Silver.crm_cust_info';

    INSERT INTO silver.crm_cust_info(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)

    SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'N/A'
    End cst_marital_status,
    CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'N/A'
    END cst_gndr,
    cst_create_date
    FROM (
    SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cst_id  ORDER BY cst_create_date DESC) as flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
    )t WHERE flag_last = 1

    SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> -------------';


        -- ====================================================
        -- Loading silver.crm_prd_info
        -- ====================================================

        SET @start_time = GETDATE();


    PRINT'>>Truncating Table: Silver.crm_prd_info';
    TRUNCATE TABLE Silver.crm_prd_info
    PRINT'>>Inserting data into Silver.crm_prd_info';


    IF OBJECT_ID ('silver.crm_prd_info','U') IS NOT NULL
        DROP TABLE silver.crm_prd_info;

    CREATE TABLE silver.crm_prd_info(
        prd_id   INT,
        cat_id NVARCHAR(50),
        prd_key NVARCHAR(50),
        prd_nm NVARCHAR(50),
        prd_cost INT,
        prd_line NVARCHAR(50),
        prd_start_dt DATE,
        prd_end_dt DATE,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    )

    INSERT INTO silver.crm_prd_info(
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )

    select 
    prd_id,

    replace (SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,

    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

    prd_nm,

    isnull(prd_cost,0) as prd_cost,

    CASE 
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'N/A'
    END as prd_line,

    CAST(prd_start_dt as date) as prd_start_dt,
    CAST(LEAd (prd_start_dt) over (partition by prd_key order by prd_start_dt) as date) as prd_end_dt
    from bronze.crm_prd_info

    SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> -------------';


        -- ====================================================
        -- Loading silver.crm_sales_details
        -- ====================================================

        SET @start_time = GETDATE();

    PRINT'>>Truncating Table: Silver.crm_sales_details';
    TRUNCATE TABLE Silver.crm_sales_details
    PRINT'>>Inserting data into Silver.crm_sales_details';


    IF OBJECT_ID ('silver.crm_sales_details','U') IS NOT NULL
        DROP TABLE silver.crm_sales_details;

    CREATE TABLE silver.crm_sales_details(
        sls_ord_num NVARCHAR(50),
        sls_prd_key NVARCHAR(50),
        sls_cust_id INT,
        sls_order_dt DATE,
        sls_ship_dt DATE,
        sls_due_dt DATE,
        sls_sales INT,
        sls_quantity INT,
        sls_price INT,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    INSERT INTO silver.crm_sales_details(
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        TRY_CONVERT(DATE, CAST(sls_order_dt AS VARCHAR(8)), 112)
            AS sls_order_dt,

        TRY_CONVERT(DATE, CAST(sls_ship_dt AS VARCHAR(8)), 112)
            AS sls_ship_dt,

        TRY_CONVERT(DATE, CAST(sls_due_dt AS VARCHAR(8)), 112)
            AS sls_due_dt,

        CASE 
        WHEN sls_sales IS NULL 
          OR sls_sales <= 0
          OR sls_sales != ABS(sls_quantity) * sls_price
        THEN ABS(sls_quantity) * sls_price
        ELSE sls_sales
    END AS sls_sales,

        sls_quantity,

        CASE 
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price

    FROM bronze.crm_sales_details;

    UPDATE silver.crm_sales_details
    SET sls_sales = ABS(sls_quantity) * ABS(sls_price)
    WHERE sls_sales IS NULL
       OR sls_sales <= 0
       OR sls_sales != ABS(sls_quantity) * ABS(sls_price);

       SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';


        -- ====================================================
        -- Loading silver.erp_cust_az12
        -- ====================================================

        SET @start_time = GETDATE();

    PRINT'>>Truncating Table: Silver.erp_cust_az12';
    TRUNCATE TABLE Silver.erp_cust_az12
    PRINT'>>Inserting data into Silver.erp_cust_az12';


    INSERT INTO silver.erp_cust_az12(
        cid,
        bdate,
        gen
    )

    SELECT 
    CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING (cid, 4, LEN(cid))
         ELSE cid
    END as cid,

    CASE WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,

    CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
        ELSE 'N/A'
    END AS gen
    from bronze.erp_cust_az12

    SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> -------------';


        -- ====================================================
        -- Loading silver.erp_loc_a101
        -- ====================================================

        SET @start_time = GETDATE();

    PRINT'>>Truncating Table: Silver.erp_loc_a101';
    TRUNCATE TABLE Silver.erp_loc_a101
    PRINT'>>Inserting data into Silver.erp_loc_a101';

    INSERT INTO silver.erp_loc_a101(
        cid,
        cntry
    )

    SELECT
    REPLACE (cid,'-','') cid,

    CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
        ELSE cntry
    END AS cntry
    FROM bronze.erp_loc_a101 

    SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> -------------';


        -- ====================================================
        -- Loading silver.erp_px_cat_g1v2
        -- ====================================================

        SET @start_time = GETDATE();

    PRINT'>>Truncating Table: Silver.erp_px_cat_g1v2';
    TRUNCATE TABLE Silver.erp_px_cat_g1v2
    PRINT'>>Inserting data into erp_px_cat_g1v2';

    INSERT INTO silver.erp_px_cat_g1v2(
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
    id,
    cat,
    subcat,
    maintenance
    FROM bronze.erp_px_cat_g1v2

    SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> -------------';


        -- ====================================================
        -- COMPLETED
        -- ====================================================

        SET @batch_end_time = GETDATE();

        PRINT '==========================================';

        PRINT 'Loading Silver Layer is Completed';

        PRINT ' - Total Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @batch_start_time,
                    @batch_end_time
                )
                AS NVARCHAR
            )
            + ' seconds';

        PRINT '==========================================';


    END TRY


    BEGIN CATCH

        PRINT '==========================================';

        PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';

        PRINT 'Error Message: ' + ERROR_MESSAGE();

        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS NVARCHAR);

        PRINT 'Error State: '
            + CAST(ERROR_STATE() AS NVARCHAR);

        PRINT 'Error Line: '
            + CAST(ERROR_LINE() AS NVARCHAR);

        PRINT '==========================================';

    END CATCH

END;
GO
