/*
===============================================================================
 Project : Data Warehouse using Medallion Architecture
 Layer   : Bronze
 Purpose :
    - Create Bronze layer tables.
    - Store raw data exactly as received from source systems.
    - Create a stored procedure to load CSV files into Bronze tables.
    - Measure execution time for each load and the overall batch.

 Author  : Fahad Khan
===============================================================================
*/

-- ============================================================================
-- Create Bronze Tables
-- ============================================================================

-- Customer Information Table
CREATE TABLE bronze.crm_cust_info(
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_material_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
);

-- Product Information Table
CREATE TABLE bronze.crm_prd_info(
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt DATETIME
);

-- Sales Details Table
CREATE TABLE bronze.crm_sales_details(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales_dt INT,
    sls_quantity INT,
    sls_price INT
);

-- ERP Customer Location Table
CREATE TABLE bronze.erp_loc_a101(
    cid NVARCHAR(50),
    cntry NVARCHAR(50)
);

-- ERP Customer Information Table
CREATE TABLE bronze.erp_cust_az12(
    cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR(50)
);

-- ERP Product Category Table
CREATE TABLE bronze.erp_px_cat_g1v2(
    id VARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50)
);

GO

-- ============================================================================
-- Stored Procedure: bronze.load_bronze
--
-- Purpose:
--     Loads raw CSV files into Bronze layer tables.
--
-- Process:
--     1. Truncate existing Bronze tables.
--     2. Bulk load CSV files.
--     3. Record execution time for each table.
--     4. Record total batch execution time.
--     5. Handle any loading errors.
-- ============================================================================

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    -- Variables used for execution time tracking
    DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time DATETIME;

    BEGIN TRY

        -- Start overall batch timer
        SET @batch_start_time = GETDATE();

        PRINT '===================================================';
        PRINT 'LOADING BRONZE LAYER';
        PRINT '===================================================';

        PRINT '----------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '----------------------------------------------------';

        ------------------------------------------------------------------------
        -- Load Customer Information
        ------------------------------------------------------------------------

        PRINT '>> Truncating table: bronze.crm_cust_info ';
        TRUNCATE TABLE bronze.crm_cust_info;

        SET @start_time = GETDATE();

        PRINT 'INSERTING DATA INTO : bronze.crm_cust_info';

        BULK INSERT bronze.crm_cust_info
        FROM '/var/opt/mssql/dataset/source_crm/cust_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0A',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';

        PRINT '___________ ___ __ __ _ __ __ _ _ _ _ _ _____ _ _ ___ _____________________________';

        ------------------------------------------------------------------------
        -- Load Product Information
        ------------------------------------------------------------------------

        PRINT '>> Truncating table: bronze.crm_prd_info';

        TRUNCATE TABLE bronze.crm_prd_info;

        SET @start_time = GETDATE();

        PRINT 'INSERTING DATA INTO : bronze.crm_prd_info';

        BULK INSERT bronze.crm_prd_info
        FROM '/var/opt/mssql/dataset/source_crm/prd_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0A',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';

        PRINT '___________ ___ __ __ _ __ __ _ _ _ _ _____ _ _ ___ _____________________________';

        ------------------------------------------------------------------------
        -- Load Sales Details
        ------------------------------------------------------------------------

        PRINT '>> Truncating table: crm_sales_details';

        TRUNCATE TABLE bronze.crm_sales_details;

        SET @start_time = GETDATE();

        PRINT 'INSERTING DATA INTO : bronze.crm_sales_details';

        BULK INSERT bronze.crm_sales_details
        FROM '/var/opt/mssql/dataset/source_crm/sales_details.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0A',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';

        PRINT '___________ ___ __ __ _ __ __ _ _ _ _ _____ _ _ ___ _____________________________';

        ------------------------------------------------------------------------
        -- Display Total Batch Execution Time
        ------------------------------------------------------------------------

        SET @batch_end_time = GETDATE();

        PRINT 'Total Batch Load Duration : '
              + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR)
              + ' seconds';

        PRINT '___________ ___ __ __ _ __ __ _ _ _ _ _____ _ _ ___ _____________________________';

    END TRY

    BEGIN CATCH

        ------------------------------------------------------------------------
        -- Error Handling
        ------------------------------------------------------------------------

        PRINT '======================================================';
        PRINT 'Error occurred during loading Bronze Layer';
        PRINT 'Error Message: ' + ERROR_MESSAGE();

    END CATCH

END;
GO

-- ============================================================================
-- Execute Bronze Layer Load Procedure
-- ============================================================================

EXECUTE bronze.load_bronze;
GO
