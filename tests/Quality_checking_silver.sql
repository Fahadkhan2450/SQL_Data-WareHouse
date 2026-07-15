/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Purpose:
    Load cleaned and validated data from the Bronze layer into the Silver layer.

Data Quality Checks Performed:
    ✓ Remove duplicate customer records.
    ✓ Keep only the latest customer record.
    ✓ Trim leading and trailing spaces.
    ✓ Standardize gender values.
    ✓ Standardize marital status values.
    ✓ Standardize product line values.
    ✓ Extract Category ID and Product Key.
    ✓ Replace NULL product costs with 0.
    ✓ Calculate product end dates using LEAD().
    ✓ Validate order, ship and due dates.
    ✓ Replace invalid dates with NULL.
    ✓ Recalculate incorrect sales amounts.
    ✓ Calculate missing or invalid prices.
    ✓ Remove unwanted prefixes from Customer IDs.
    ✓ Remove invalid future birth dates.
    ✓ Standardize country names.
    ✓ Replace missing country values with 'N/A'.
    ✓ Load standardized product category information.

Source Layer : Bronze
Target Layer : Silver


Author : Fahad Khan
===============================================================================
*/-CHECK for nulls and duplicates for primary key


SELECT cst_id,
count(cst_id)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*)>1

SELECT * from 
bronze.crm_cust_info
WHERE cst_id=29466

SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
from 
bronze.crm_cust_info
WHERE cst_id=29466

SELECT * 
FROM(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
from 
bronze.crm_cust_info 
)t WHERE flag_last=1 AND cst_id=29483;


--check spaces 

SELECT *
FROM bronze.crm_cust_info
WHERE cst_lastname=TRIM(cst_lastname)

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname=TRIM(cst_lastname)



SELECT cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname)as cst_lastname,
cst_material_status,
cst_gndr,
cst_create_date
FROM(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
from 
bronze.crm_cust_info 
)t WHERE flag_last=1 ;


--data standardization & conssistency for gender

SELECT distinct(cst_gndr)
FROM bronze.crm_cust_info

SELECT cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname)as cst_lastname,
CASE WHEN UPPER(TRIM(cst_gndr))='F' then 'Female'
    WHEN UPPER(TRIM(cst_gndr))='M' then 'Male'
    else 'N/A'
    END
cst_gndr,
cst_create_date
FROM(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
from 
bronze.crm_cust_info 
)t WHERE flag_last=1 ;



--data standardization & conssistency for gender
SELECT distinct(cst_material_status)
FROM bronze.crm_cust_info

SELECT cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname)as cst_lastname,
CASE WHEN UPPER(TRIM(cst_gndr))='F' then 'Female'
    WHEN UPPER(TRIM(cst_gndr))='M' then 'Male'
    else 'N/A'
    END
cst_gender,
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



---------------------------------------   inserting into silver Layer     -------------------------------------


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

--check null or duplicates
SELECT cst_id,
count(cst_id) as cnt_cst_id
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*)>1 

--check spaces

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname=TRIM(cst_firstname)

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname=TRIM(cst_lastname)


--data standardization and consistency

SELECT distinct(cst_material_status)
FROM silver.crm_cust_info


------ crm_prd_info Table ----------------

SELECT * from 
bronze.crm_prd_info;

--check for null or duplicate values

SELECT prd_id,COUNT(prd_id)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(prd_id)>1



--- checking for extra space ------

SELECT prd_key FROM
bronze.crm_prd_info
WHERE prd_key!=TRIM(prd_key)

SELECT prd_nm FROM
bronze.crm_prd_info
WHERE prd_nm!=TRIM(prd_nm)

SELECT prd_id ,
prd_key,
replace(SUBSTRING(prd_key,1,5) ,'-','_')as cat_id,
REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as l_cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt FROM
bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key,1,5) ,'-','_')  NOT IN
(select distinct id from bronze.erp_px_cat_g1v2)


SELECT prd_id ,
prd_key,
replace(SUBSTRING(prd_key,1,5) ,'-','_')as cat_id,
REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as l_cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt FROM
bronze.crm_prd_info;

--- check for unwanted spaces 

select prd_nm
from bronze.crm_prd_info
WHERE prd_nm!=TRIM(prd_nm)




---check for nulls and negative values


SELECT * FROM bronze.crm_prd_info

SELECT prd_cost FROM
bronze.crm_prd_info
WHERE prd_cost = 0

SELECT prd_id ,
prd_key,
replace(SUBSTRING(prd_key,1,5) ,'-','_')as cat_id,
REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as l_cat_id,
prd_nm,
ISNULL(prd_cost,0) as prd_cost,
prd_line,
prd_start_dt,
prd_end_dt FROM
bronze.crm_prd_info;


-- Data standardization and consistency

SELECT distinct prd_line FROM
bronze.crm_prd_info


SELECT prd_id ,
prd_key,
replace(SUBSTRING(prd_key,1,5) ,'-','_')as cat_id,
REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as l_cat_id,
prd_nm,
ISNULL(prd_cost,0) as prd_cost,
CASE when UPPER(TRIM(prd_line)) = 'M' then 'Mountain'
     when UPPER(TRIM(prd_line)) = 'R' then 'Road'
    when UPPER(TRIM(prd_line)) = 'S' then 'Other Sales'
    when UPPER(TRIM(prd_line)) = 'T' then 'Touring'
    else 'N/A'
    END as 
prd_line,
prd_start_dt,
prd_end_dt FROM
bronze.crm_prd_info;


SELECT * FROM bronze.crm_prd_info
WHERE prd_start_dt >prd_end_dt

SELECT prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,

LEAD (prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test

FROM bronze.crm_prd_info
WHERE prd_key in ('AC-HE-HL-U509-R','AC-HE-HL-U509');



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


SELECT prd_nm FROM
silver.crm_prd_info
WHERE prd_nm!=TRIM(prd_nm)


SELECT prd_id,COUNT(prd_id)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(prd_id)>1


SELECT * FROM silver.crm_prd_info

--check for invalid dates

SELECT prd_start_dt,prd_end_dt FROM silver.crm_prd_info;




----------------------------------- Sales Details --------------------------------------


select * from 
bronze.crm_sales_details
WHERE sls_prd_key  not in (select prd_key from silver.crm_prd_info)


SELECT * FROM bronze.crm_prd_info

SELECT * FROM silver.crm_prd_info


----- Check for Invalid dates


SELECT sls_due_dt  from bronze.crm_sales_details
WHERE sls_due_dt <1

SELECT sls_order_dt  from bronze.crm_sales_details
WHERE sls_due_dt <1 or len(sls_order_dt)!=8 or sls_order_dt>20500101


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
sls_sales_dt,
sls_quantity,
sls_price
from bronze.crm_sales_details


SELECT sls_sales_dt,
sls_quantity,
sls_price ,
CASE WHEN sls_sales_dt IS NULL OR sls_sales_dt<=0 or sls_sales_dt!=sls_quantity* ABS(sls_price)
    THEN sls_quantity*sls_price
    ELSE
    sls_sales_dt
    END
    AS sls_sales,

 CASE WHEN sls_price IS NULL OR sls_price<=0
 THEN sls_sales_dt/NULLIF(sls_quantity,0)
 ELSE sls_price
 END as sls_price_new   
from bronze.crm_sales_details
WHERE sls_sales_dt!=sls_price*sls_quantity
OR sls_sales_dt is NULL or sls_quantity is NULL or sls_price is NULL
OR sls_sales_dt <= 0 or sls_quantity <=0 or sls_price <=0
ORDER BY sls_sales_dt,sls_quantity,sls_price



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




---CHECKING silver layer DATA HEALTH-------


SELECT sls_sales_dt,
sls_quantity,
sls_price   
from silver.crm_sales_details
WHERE sls_sales_dt!=sls_price*sls_quantity
OR sls_sales_dt is NULL or sls_quantity is NULL or sls_price is NULL
OR sls_sales_dt <= 0 or sls_quantity <=0 or sls_price <=0
ORDER BY sls_sales_dt,sls_quantity,sls_price




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
   




SELECT   case when UPPER(TRIM(gen)) IN ('F','FEMALE') then 'Female'
         when UPPER(TRIM(gen)) IN ('M','MALE') then 'Male'
         else gen
         END as gen_
     FROM bronze.erp_cust_az12
     GROUP by gen;





--------QUALITY CHECK------------


SELECT DISTINCT gen FROM silver.erp_cust_az12;





-----------ERP loc a101 Table -----------


SELECT REPLACE(cid,'-','') cid from bronze.erp_loc_a101
WHERE REPLACE(cid,'-','')  NOT IN
(SELECT cst_key FROM silver.crm_cust_info);


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


SELECT cid from bronze.erp_loc_a101;




SELECT * FROM silver.crm_cust_info;








--------------------- ERP PX CAT G1V2 ---------------------



SELECT id,
cat,
subcat,
maintenance from bronze.erp_px_cat_g1v2;

SELECT * from silver.crm_prd_info;


--unwanted spaces------


SELECT * FROM
bronze.erp_px_cat_g1v2
WHERE cat !=TRIM(cat) or subcat !=TRIM(subcat);


-------DATA STANDARDIZATION AND CONSISTENCY --------


SELECT  distinct subcat FROM bronze.erp_px_cat_g1v2;



-----------------------INSERTING INTO EPR PX CAT G1V2 ---------------------


PRINT '>>TRUNCATE TABLE: silver.erp_px_cat_g1v2'
TRUNCATE TABLE silver.erp_px_cat_g1v2
PRINT '>>Inserting data into: silver.erp_px_cat_g1v2'
INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
SELECT id,
cat,
subcat,
maintenance from bronze.erp_px_cat_g1v2;

SELECT * from silver.crm_prd_info;
