/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Purpose:
    Loads data from the Bronze layer into the Silver layer by applying
    data cleansing, validation, standardization, and transformation rules.

Processing Steps:
    1. Load Customer Information
    2. Load Product Information
    3. Load Sales Details
    4. Load ERP Customer Data
    5. Load ERP Location Data
    6. Load ERP Product Categories

Transformation Examples:
    - Remove duplicate customers
    - Trim unwanted spaces
    - Standardize gender values
    - Standardize marital status
    - Extract product category
    - Calculate product end dates
    - Validate sales dates
    - Correct missing sales and prices
    - Standardize country names

Author : Fahad Khan
===============================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    PRINT '>>TRUNCATE TABLE: silver.crm_cust_info'
    TRUNCATE TABLE silver.crm_cust_info
    PRINT '>>Inserting data into: silver.crm_cust_info'
    INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_gndr,cst_material_status,cst_create_date)
    SELECT cst_id,
    cst_key,
    TRIM(cst_firstname) as cst_firstname,
    TRIM(cst_lastname)as cst_lastname,
    CASE WHEN UPPER(TRIM(cst_gndr))='F' then 'Female'
        WHEN UPPER(TRIM(cst_gndr))='M' then 'Male'
        else 'N/A'
        END
    cst_gndr,
    CASE WHEN UPPER(TRIM(cst_material_status))='S' then 'Single'
        WHEN UPPER(TRIM(cst_material_status))='M' then 'Maried'
        else 'N/A'
        END
        cst_material_status,
    cst_create_date
    FROM(
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
    from 
    bronze.crm_cust_info 
    )t WHERE flag_last=1 ;

    ---------------INSERTING INTO PRD INFO -------------------

    PRINT '>>TRUNCATE TABLE: silver.crm_prd_info'
    TRUNCATE TABLE silver.crm_prd_info
    PRINT '>>Inserting data into: silver.crm_prd_info'

    INSERT INTO silver.crm_prd_info(
        prd_id ,
        cat_id ,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
        SUBSTRING(prd_key,7,LEN(prd_key))  AS prd_key,
        prd_nm,
        ISNULL(prd_cost,0) AS prd_cost,
        CASE
            WHEN UPPER(TRIM(prd_line))='M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line))='R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line))='S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line))='T' THEN 'Touring'
            ELSE 'N/A'
        END AS prd_line,
        CAST(prd_start_dt AS DATE),
        DATEADD(
            DAY,
            -1,
            LEAD(CAST(prd_start_dt AS DATE))
            OVER (PARTITION BY prd_key ORDER BY prd_start_dt)
        ) AS prd_end_dt
    FROM bronze.crm_prd_info;




    ------- INSERTING INTO SILVER.SALES_DETAILS------------------- 
    PRINT '>>TRUNCATE TABLE: silver.crm_sales_details'
    TRUNCATE TABLE silver.crm_sales_details
    PRINT '>>Inserting data into: silver.crm_sales_details'

    INSERT INTO silver.crm_sales_details(
        sls_ord_num ,
        sls_prd_key ,
        sls_cust_id ,
        sls_order_dt ,
        sls_ship_dt ,
        sls_due_dt ,
        sls_sales_dt ,
        sls_quantity ,
        sls_price  
    )
    select sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    case when sls_order_dt =0 or len(sls_order_dt)!=8 THen NULL
        else CAST(CAST(sls_order_dt as VARCHAR)as DATE) 
        END
    sls_order_dt,
    case when sls_ship_dt =0 or len(sls_ship_dt)!=8 THen NULL
        else CAST(CAST(sls_ship_dt as VARCHAR)as DATE) 
        END
    sls_ship_dt,
    case when sls_due_dt =0 or len(sls_due_dt)!=8 THen NULL
        else CAST(CAST(sls_due_dt as VARCHAR)as DATE) 
        END
    sls_due_dt,
    CASE WHEN sls_sales_dt IS NULL OR sls_sales_dt<=0 or sls_sales_dt!=sls_quantity* ABS(sls_price)
        THEN sls_quantity*sls_price
        ELSE
        sls_sales_dt
        END
        AS sls_sales,
    sls_quantity,
    CASE WHEN sls_price IS NULL OR sls_price<=0
    THEN sls_sales_dt/NULLIF(sls_quantity,0)
    ELSE sls_price
    END as sls_price_new
    from bronze.crm_sales_details




    ----------_ERP cust az12
    PRINT '>>TRUNCATE TABLE: silver.erp_cust_az12'
    TRUNCATE TABLE silver.erp_cust_az12
    PRINT '>>Inserting data into: silver.erp_cust_az12'

    INSERT INTO silver.erp_cust_az12(CID,bdate,gen)
    SELECT 
    case when cid like 'NAS%' then SUBSTRING(cid,4,LEN(cid))
        else cid
        END as cid_,

        case when  bdate > GETDATE() then null
        else bdate 
        END as bdate_,

        case when UPPER(TRIM(gen)) IN ('F','FEMALE') then 'Female'
            when UPPER(TRIM(gen)) IN ('M','MALE') then 'Male'
            else gen
            END as gen_
        FROM bronze.erp_cust_az12





    --------------INSERT ERP A1010 ---------------
    PRINT '>>TRUNCATE TABLE: silver.erp_loc_a101'
    TRUNCATE TABLE silver.erp_loc_a101
    PRINT '>>Inserting data into: silver.erp_loc_a101'

    INSERT INTO silver.erp_loc_a101(cid,cntry)
    SELECT REPLACE(cid,'-','') cid ,
    CASE WHEN TRIM(cntry) ='DE' then 'Germany'
        WHEN TRIM(cntry) In ('US','USA') then 'United States'
        WHEN TRIM(cntry) ='' OR cntry IS NULL THEN 'N/A'
        else cntry
        END as cntry_
    from bronze.erp_loc_a101;





    -----------------------INSERTING INTO EPR PX CAT G1V2 ---------------------


    PRINT '>>TRUNCATE TABLE: silver.erp_px_cat_g1v2'
    TRUNCATE TABLE silver.erp_px_cat_g1v2
    PRINT '>>Inserting data into: silver.erp_px_cat_g1v2'
    INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
    SELECT id,
    cat,
    subcat,
    maintenance from bronze.erp_px_cat_g1v2;

END
GO
EXEC silver.load_silver;
