/*
===============================================================================
DDL Script: Create Silver Layer Tables
===============================================================================
Script Purpose:
    This script creates all tables required for the Silver layer of the
    Data Warehouse.

    The Silver layer stores cleansed, standardized, and transformed data
    received from the Bronze layer before it is loaded into the Gold layer
    for reporting and analytics.

Tables Created:
    • silver.crm_cust_info
    • silver.crm_prd_info
    • silver.crm_sales_details
    • silver.erp_loc_a101
    • silver.erp_cust_az12
    • silver.erp_px_cat_g1v2

Notes:
    - Existing tables are dropped before being recreated.
    - dwh_create_date stores the timestamp when each record is loaded into
      the Silver layer.
===============================================================================
*/


/*=============================================================================
    Create Customer Information Table
=============================================================================*/

IF OBJECT_ID('silver.crm_cust_info','U') IS NOT NULL
DROP TABLE silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info(
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_material_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE,

    -- Timestamp indicating when the record was loaded into the Silver layer
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);



/*=============================================================================
    Create Product Information Table
=============================================================================*/

IF OBJECT_ID('silver.crm_prd_info','U') IS NOT NULL
DROP TABLE silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info
(
    prd_id INT,
    cat_id NVARCHAR(50),
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE
);



/*=============================================================================
    Create Sales Details Table
=============================================================================*/

IF OBJECT_ID('silver.crm_sales_details','U') IS NOT NULL
DROP TABLE silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details
(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt DATE,
    sls_ship_dt DATE,
    sls_due_dt DATE,
    sls_sales_dt INT,
    sls_quantity INT,
    sls_price INT,

    -- Timestamp indicating when the record was loaded into the Silver layer
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);



/*=============================================================================
    Create ERP Location Table
=============================================================================*/

IF OBJECT_ID('silver.erp_loc_a101','U') IS NOT NULL
DROP TABLE silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101
(
    cid NVARCHAR(50),
    cntry NVARCHAR(50),

    -- Timestamp indicating when the record was loaded into the Silver layer
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);



/*=============================================================================
    Create ERP Customer Table
=============================================================================*/

IF OBJECT_ID('silver.erp_cust_az12','U') IS NOT NULL
DROP TABLE silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12
(
    cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR(50),

    -- Timestamp indicating when the record was loaded into the Silver layer
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);



/*=============================================================================
    Create ERP Product Category Table
=============================================================================*/

IF OBJECT_ID('silver.erp_px_cat_g1v2','U') IS NOT NULL
DROP TABLE silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2
(
    id VARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50),

    -- Timestamp indicating when the record was loaded into the Silver layer
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
