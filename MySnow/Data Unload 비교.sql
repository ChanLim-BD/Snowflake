SELECT *
  FROM INFORMATION_SCHEMA.TABLE_STORAGE_METRICS
 WHERE TABLE_NAME = 'WEB_RETURNS_PARQUET_150';

USE DATABASE PENTA_DB;
USE SCHEMA JAE_SCHEMA;
USE WAREHOUSE COMPUTE_WH;

-- WEB_RETURNS 테이블 데이터 개수
--  ㄴ Data Count : 1,440,040,970 (약, 14억 건)
--  ㄴ File Size : 73.1 GB
SELECT COUNT(*)
  FROM JAE_SCHEMA.WEB_RETURNS
;


-- 1. Data Unloading
-- ㄴ Warehouse Size : X-SMALL
-- ㄴ Data Format : PARQUET
-- ㄴ Data Max File Size : 100MB
-- ㄴ Compression : True
--
-- Input Bytes : 130,417,623,147 Bytes (121 GB)
COPY INTO 's3://jaeyeong-hyundai/snowflake_sample/jaeyeong/web_returns/'
FROM JAE_SCHEMA.WEB_RETURNS_BAK
STORAGE_INTEGRATION = PENTA_INTEGRATION
FILE_FORMAT = (
    TYPE               = 'PARQUET'
    COMPRESSION        = 'SNAPPY'
)
HEADER = TRUE
MAX_FILE_SIZE = 104857600
;


-- 2. Data Unloading
-- ㄴ Warehouse Size : X-SMALL
-- ㄴ Data Format : PARQUET
-- ㄴ Data Max File Size : 200MB
-- ㄴ Compression : True
--
-- Input Bytes : 130,811,396,211 Bytes (121 GB)
COPY INTO 's3://jaeyeong-hyundai/snowflake_sample/jaeyeong/web_returns_parquet_200/'
FROM JAE_SCHEMA.WEB_RETURNS_BAK
STORAGE_INTEGRATION = PENTA_INTEGRATION
FILE_FORMAT = (
    TYPE               = 'PARQUET'
    COMPRESSION        = 'SNAPPY'
)
HEADER = TRUE
MAX_FILE_SIZE = 209715200
;


-- 3. Data Unloading
-- ㄴ Warehouse Size : X-SMALL
-- ㄴ Data Format : PARQUET
-- ㄴ Data Max File Size : 150MB
-- ㄴ Compression : True
--
-- Input Bytes : 130,811,396,211 Bytes (121 GB)
COPY INTO 's3://jaeyeong-hyundai/snowflake_sample/jaeyeong/web_returns_parquet_150/'
FROM JAE_SCHEMA.WEB_RETURNS_BAK
STORAGE_INTEGRATION = PENTA_INTEGRATION
FILE_FORMAT = (
    TYPE               = 'PARQUET'
    COMPRESSION        = 'SNAPPY'
)
HEADER = TRUE
MAX_FILE_SIZE = 157286400
;


-- 4. Data Unloading
-- ㄴ Warehouse Size : X-SMALL
-- ㄴ Data Format : PARQUET
-- ㄴ Data Max File Size : 400MB
-- ㄴ Compression : True
--
-- Input Bytes : 130,811,396,211 Bytes (121 GB)
COPY INTO 's3://jaeyeong-hyundai/snowflake_sample/jaeyeong/web_returns_parquet_400/'
FROM JAE_SCHEMA.WEB_RETURNS_BAK
STORAGE_INTEGRATION = PENTA_INTEGRATION
FILE_FORMAT = (
    TYPE               = 'PARQUET'
    COMPRESSION        = 'SNAPPY'
)
HEADER = TRUE
MAX_FILE_SIZE = 419430400 
;

-- 5. Data Unloading
-- ㄴ Warehouse Size : X-SMALL
-- ㄴ Data Format : PARQUET
-- ㄴ Data Max File Size : 1024MB (1 GB)
-- ㄴ Compression : True
--
-- Input Bytes : 130,811,396,211 Bytes (121 GB)
COPY INTO 's3://jaeyeong-hyundai/snowflake_sample/jaeyeong/web_returns_parquet_1024/'
FROM JAE_SCHEMA.WEB_RETURNS_BAK
STORAGE_INTEGRATION = PENTA_INTEGRATION
FILE_FORMAT = (
    TYPE               = 'PARQUET'
    COMPRESSION        = 'SNAPPY'
)
HEADER = TRUE
MAX_FILE_SIZE = 1073741824 
;


----------------------------------------------------------------------------------------------------------------
-- 비압축 진행
----------------------------------------------------------------------------------------------------------------

-- 1. Data Unloading
-- ㄴ Data Format : PARQUET
-- ㄴ Data Max File Size : 100MB
-- ㄴ Compression : None
--
-- Input Bytes :
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

COPY INTO 's3://jaeyeong-hyundai/snowflake_sample/jaeyeong/web_returns_parquet_100_non/'
FROM JAE_SCHEMA.WEB_RETURNS_BAK
STORAGE_INTEGRATION = PENTA_INTEGRATION
FILE_FORMAT = (
    TYPE        = 'PARQUET'
    COMPRESSION = NONE
)
HEADER = TRUE
MAX_FILE_SIZE = 104857600 
;





