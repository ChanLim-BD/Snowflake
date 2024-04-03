-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항             --
--                                           --
-----------------------------------------------

USE ROLE ACCOUNTADMIN;
CREATE DATABASE CDC_TEST;
CREATE SCHEMA CDC_SCHEMA;


-- Snowflake 계정이 위치한 AWS Virtual Network(VNet)의 IDs을 검색합니다.
SELECT SYSTEM$GET_SNOWFLAKE_PLATFORM_INFO();


-- Snowflake에서 클라우드 저장소 Integration 만들기
CREATE OR REPLACE STORAGE INTEGRATION cdc_test
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{---}:role/chan-snowflake-role'
  STORAGE_ALLOWED_LOCATIONS = ('*');
  --[ STORAGE_BLOCKED_LOCATIONS = ('s3://<bucket>/<path>/', 's3://<bucket>/<path>/') ];

  
-- Snowflake 계정에 대한 AWS IAM 사용자 검색
DESC INTEGRATION cdc_test;


-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항 [完]        --
--                                           --
-----------------------------------------------



-----------------------------------------------
--                                           --
--        File Format PARQUET 버전 생성        --
--                                           --
-----------------------------------------------

CREATE OR REPLACE FILE FORMAT my_parquet_format
  TYPE = PARQUET
  COMPRESSION = NONE;


-----------------------------------------------
--                                           --
--             External Stage 생성            --
--                                           --
-----------------------------------------------


CREATE OR REPLACE STAGE cdc_prac
    STORAGE_INTEGRATION = cdc_test
    URL = 's3://chan-cdc-test/cdc-prac/'
    FILE_FORMAT = my_parquet_format;


----------------------------------------------
--                                          --
--              최종 테이블 (예상)            -- 
--                                           --
----------------------------------------------

CREATE OR REPLACE TABLE CDC_TEST.CDC_SCHEMA.RESULT_CDC
(	
   CD_KEY             VARCHAR(30)  NOT NULL
   , PARENT_CD        VARCHAR(8)
   , CD               VARCHAR(8)
   , LVL              INTEGER
   , SORT             INTEGER
   , USE_YN           VARCHAR(1)
   , CD_NM            VARCHAR(100) 
   , CD_NM_ENG        VARCHAR(100)
   , CD_NM_CHN        VARCHAR(100) 
   , CD_NM_JPN        VARCHAR(100)
   , CD_NM_ETC        VARCHAR(100)
   , RMK              VARCHAR(1000)
   , ERP_PARENT_CD    VARCHAR(24)
   , ERP_TABLE        VARCHAR(24)
   , VAL1             VARCHAR(100)
   , VAL2             VARCHAR(100)
   , VAL3             VARCHAR(100)
   , VAL4             VARCHAR(100)
   , VAL5             VARCHAR(100)
   , VAL6             VARCHAR(100)
   , VAL7             VARCHAR(100)
   , VAL8             VARCHAR(100)
   , VAL9             VARCHAR(100)
   , VAL10            VARCHAR(100)
   , PRIMARY KEY (CD_KEY)
);

SELECT * FROM RESULT_CDC;

-----------------------------------------------
--                                           --
--       Table 생성 (Schema Detection)        --
--                                           --
-----------------------------------------------


SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@cdc_prac/'
      , FILE_FORMAT=>'my_parquet_format'
      )
    );
    

CREATE OR REPLACE TABLE CDC_PRAC_DB
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@cdc_prac/'
          , FILE_FORMAT=>'my_parquet_format'
          )
      ));

-----------------------------------------------
--                                           --
--           COPY INTO 테스트 [완]             --
--                                           --
-----------------------------------------------

COPY INTO CDC_PRAC_DB
    FROM @cdc_prac
    FILE_FORMAT = my_parquet_format
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

    
-----------------------------------------------
--                                           --
--               PIPE 테스트 [완]             --
--                                           --
-----------------------------------------------

    
CREATE OR REPLACE PIPE CDC_TEST.CDC_SCHEMA.CDC_PIPE 
    AUTO_INGEST = false as
    COPY INTO CDC_TEST.CDC_SCHEMA.CDC_PRAC_DB
    FROM @cdc_prac
    FILE_FORMAT = my_parquet_format
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- 즉각 테스트를 위한 REFRESH
SHOW PIPES;
ALTER PIPE CDC_TEST.CDC_SCHEMA.CDC_PIPE REFRESH;


-----------------------------------------------
--                                           --
--           데이터 적재 확인 [완]             --
--                                           --
-----------------------------------------------


SELECT TRANSACTIONS, TRANSACTION_ID, STREAM_POSITION, CD_KEY, PARENT_CD, CD, LVL, CD_NM  FROM CDC_PRAC_DB;
SELECT TRANSACTIONS, TRANSACTION_ID, STREAM_POSITION, CD_KEY, PARENT_CD, CD, LVL, CD_NM  FROM CDC_PRAC_DB ORDER BY TRANSACTION_ID DESC;

SELECT * FROM CDC_PRAC_DB;


-----------------------------------------------
--                                           --
--    변경 사항을 순서대로 번호 붙이는 Query      --
--          (1번이 가장 최신 트랜잭션)           --
--                                           --
-----------------------------------------------


SELECT T1.TRANSACTIONS ,T1.CD_NM
        , ROW_NUMBER() OVER(PARTITION BY T1.CD_KEY
                                        ORDER BY T1.TRANSACTION_ID DESC) AS RNUM
FROM CDC_PRAC_DB T1
WHERE CD_KEY = 'A011000'
ORDER BY RNUM;


-----------------------------------------------
--                                           --
--        최신 변경 사항만 가져오는 SQL         --
--                                           --
-----------------------------------------------

SELECT T2.CD_KEY, T2.TRANSACTIONS, T2.RNUM
	     FROM (
                SELECT T1.*
                		, ROW_NUMBER() OVER(PARTITION BY T1.CD_KEY
                										ORDER BY T1.TRANSACTION_ID DESC) AS RNUM
                FROM CDC_PRAC_DB T1
			   ) T2
		WHERE T2.RNUM = 1 AND T2.CD_KEY = 'A011000';


-----------------------------------------------
--                                           --
--    최신 변경 사항만 반영하는 Dynamic Table    --
--                                           --
-----------------------------------------------


CREATE OR REPLACE DYNAMIC TABLE CDC_TEST.CDC_SCHEMA.DT_RESULT
  TARGET_LAG = '1 minutes'
  WAREHOUSE = COMPUTE_WH
  AS
    SELECT T2.*
	     FROM (
                SELECT T1.*
                		, ROW_NUMBER() OVER(PARTITION BY T1.CD_KEY
                										ORDER BY T1.TRANSACTION_ID DESC) AS RNUM
                FROM CDC_PRAC_DB T1
			   ) T2
		WHERE T2.RNUM = 1 AND TRANSACTIONS != 'DELETE';


SELECT * FROM DT_RESULT;
SELECT * FROM DT_RESULT WHERE CD_KEY = 'A011000';


--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆ 번외 ☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

-----------------------------------------------
--                                           --
--           MERGE INTO 시도해보기             --
--                                           --
-----------------------------------------------

MERGE
 INTO CDC_TEST.CDC_SCHEMA.RESULT_CDC T
USING (
        SELECT T2.*
	     FROM (
                SELECT T1.*
                		, ROW_NUMBER() OVER(PARTITION BY T1.CD_KEY
                										ORDER BY T1.TRANSACTION_ID DESC) AS RNUM
                FROM CDC_PRAC_DB T1
			   ) T2
		WHERE T2.RNUM = 1 
	   ) S
   ON T.CD_KEY    = S.CD_KEY     
WHEN MATCHED AND (S.TRANSACTIONS = 'INSERT' OR S.TRANSACTIONS = 'UPDATE') THEN
    UPDATE SET   T.CD_KEY         = S.CD_KEY 
               , T.PARENT_CD      = S.PARENT_CD   
               , T.CD             = S.CD   
               , T.LVL            = S.LVL   
               , T.SORT           = S.SORT   
               , T.USE_YN         = S.USE_YN   
               , T.CD_NM          = S.CD_NM    
               , T.CD_NM_ENG      = S.CD_NM_ENG   
               , T.CD_NM_CHN      = S.CD_NM_CHN   
               , T.CD_NM_JPN      = S.CD_NM_JPN   
               , T.CD_NM_ETC      = S.CD_NM_ETC  
               , T.RMK            = S.RMK   
               , T.ERP_PARENT_CD  = S.ERP_PARENT_CD   
               , T.ERP_TABLE      = S.ERP_TABLE   
               , T.VAL1           = S.VAL1   
               , T.VAL2           = S.VAL2   
               , T.VAL3           = S.VAL3  
               , T.VAL4           = S.VAL4  
               , T.VAL5           = S.VAL5   
               , T.VAL6           = S.VAL6  
               , T.VAL7           = S.VAL7   
               , T.VAL8           = S.VAL8   
               , T.VAL9           = S.VAL9  
               , T.VAL10          = S.VAL10
WHEN MATCHED AND S.TRANSACTIONS = 'DELETE' THEN
	DELETE
WHEN NOT MATCHED AND (S.TRANSACTIONS = 'INSERT' OR S.TRANSACTIONS = 'UPDATE') THEN
    INSERT (
              CD_KEY 
            , PARENT_CD   
            , CD   
            , LVL   
            , SORT   
            , USE_YN   
            , CD_NM    
            , CD_NM_ENG   
            , CD_NM_CHN   
            , CD_NM_JPN   
            , CD_NM_ETC  
            , RMK   
            , ERP_PARENT_CD   
            , ERP_TABLE   
            , VAL1   
            , VAL2   
            , VAL3  
            , VAL4  
            , VAL5   
            , VAL6  
            , VAL7   
            , VAL8   
            , VAL9  
            , VAL10
    )
    VALUES (
              S.CD_KEY 
            , S.PARENT_CD   
            , S.CD   
            , S.LVL   
            , S.SORT   
            , S.USE_YN   
            , S.CD_NM    
            , S.CD_NM_ENG   
            , S.CD_NM_CHN   
            , S.CD_NM_JPN   
            , S.CD_NM_ETC  
            , S.RMK   
            , S.ERP_PARENT_CD   
            , S.ERP_TABLE   
            , S.VAL1   
            , S.VAL2   
            , S.VAL3  
            , S.VAL4  
            , S.VAL5   
            , S.VAL6  
            , S.VAL7   
            , S.VAL8   
            , S.VAL9  
            , S.VAL10
    )
;

SELECT * 
FROM RESULT_CDC;

TRUNCATE TABLE RESULT_CDC;
TRUNCATE TABLE CDC_PRAC_DB;