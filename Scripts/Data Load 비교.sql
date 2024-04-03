USE WAREHOUSE JAE_WH;
USE DATABASE PENTA_DB;
USE SCHEMA JAE_SCHEMA;

-----------------------------------------------------------------------------------
--     원본 파일 개당 사이즈 : 100 MB
-----------------------------------------------------------------------------------

-- 1. Data Load
--  ㄴ S3 파일 개수 : 1,233개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 100 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : X-SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 53m 54s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'X-SMALL';

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_100
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;


-- 2. Data Load
--  ㄴ S3 파일 개수 : 1,233개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 100 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : SMALL
--  ㄴ 적재 후 사이즈 :
--  ㄴ 적재 속도 : 27m 3s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_100;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_100
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 3. Data Load
--  ㄴ S3 파일 개수 : 1,233개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 100 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : MEDIUM
--  ㄴ 적재 후 사이즈 :
--  ㄴ 적재 속도 : 13m 42s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_100;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_100
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 4. Data Load
--  ㄴ S3 파일 개수 : 1,233개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 100 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : LARGE
--  ㄴ 적재 후 사이즈 :
--  ㄴ 적재 속도 : 7m 11s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'LARGE';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_100;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_100
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;


-----------------------------------------------------------------------------------
--     원본 파일 개당 사이즈 : 150 MB
-----------------------------------------------------------------------------------
-- 1. Data Load
--  ㄴ S3 파일 개수 : 812개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 150 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : X-SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 54m 6s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'X-SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_150;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_150
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_150/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 2. Data Load
--  ㄴ S3 파일 개수 : 812개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 150 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 27m 15s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_150;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_150
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_150/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 3. Data Load
--  ㄴ S3 파일 개수 : 812개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 150 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : MEDIUM
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 13m 52s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_150;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_150
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_150/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 4. Data Load
--  ㄴ S3 파일 개수 : 812개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 150 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : LARGE
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 7m 13s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_150;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_150
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_150/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;


-----------------------------------------------------------------------------------
--     원본 파일 개당 사이즈 : 200 MB
-----------------------------------------------------------------------------------
-- 1. Data Load
--  ㄴ S3 파일 개수 : 619개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 200 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : X-SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 53m 27s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'X-SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_200;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_200
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_200/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 2. Data Load
--  ㄴ S3 파일 개수 : 619개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 200 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 27m 12s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_200;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_200
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_200/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;


-- 3. Data Load
--  ㄴ S3 파일 개수 : 619개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 200 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : MEDIUM
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 13m 54s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_200;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_200
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_200/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 4. Data Load
--  ㄴ S3 파일 개수 : 619개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 200 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : LARGE
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 7m 48s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'LARGE';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_200;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_200
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_200/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;



-----------------------------------------------------------------------------------
--     원본 파일 개당 사이즈 : 400MB
-----------------------------------------------------------------------------------
-- 1. Data Load
--  ㄴ S3 파일 개수 : 344개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 400 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : X-SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 54m 28s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'X-SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_400;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_400
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_400/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 2. Data Load
--  ㄴ S3 파일 개수 : 344개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 400 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 27m 16s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_400;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_400
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_400/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 3. Data Load
--  ㄴ S3 파일 개수 : 344개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 400 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : MEDIUM
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 14m 14s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_400;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_400
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_400/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 4. Data Load
--  ㄴ S3 파일 개수 : 344개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 400 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : LARGE
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 7m 42s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'LARGE';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_400;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_400
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_400/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-----------------------------------------------------------------------------------
--     원본 파일 개당 사이즈 : 1024MB (1GB)
-----------------------------------------------------------------------------------
-- 1. Data Load
--  ㄴ S3 파일 개수 : 220개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 1024 MB (1GB)
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : X-SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 54m 48s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'X-SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_1024;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_1024
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_1024/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 2. Data Load
--  ㄴ S3 파일 개수 : 220개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 1024 MB (1GB)
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : SMALL
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 28m 6s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'SMALL';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_1024;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_1024
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_1024/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 3. Data Load
--  ㄴ S3 파일 개수 : 344개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 400 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : MEDIUM
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 15m 54s
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'MEDIUM';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_1024;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_1024
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_1024/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;

-- 4. Data Load
--  ㄴ S3 파일 개수 : 344개
--  ㄴ 원본 파일 전체 사이즈 : 121 GB
--  ㄴ 원본 파일 개당 사이즈 : 400 MB
--
-- 데이터 적재 후 정보
--  ㄴ Warehouse Size : LARGE
--  ㄴ 적재 후 사이즈 : 73.2 GB
--  ㄴ 적재 속도 : 
ALTER WAREHOUSE JAE_WH SET WAREHOUSE_SIZE = 'LARGE';

TRUNCATE TABLE JAE_SCHEMA.WEB_RETURNS_PARQUET_1024;

COPY INTO JAE_SCHEMA.WEB_RETURNS_PARQUET_1024
FROM @JAE_SCHEMA.EXT_STA_ROT/snowflake_sample/jaeyeong/web_returns_parquet_1024/
FILE_FORMAT = (
    TYPE = 'PARQUET'
    COMPRESSION = 'SNAPPY'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
;




