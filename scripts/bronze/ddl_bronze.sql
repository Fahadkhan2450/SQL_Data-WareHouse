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
