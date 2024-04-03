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
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::992382800329:role/chan-snowflake-role'
  STORAGE_ALLOWED_LOCATIONS = ('*');
  --[ STORAGE_BLOCKED_LOCATIONS = ('s3://<bucket>/<path>/', 's3://<bucket>/<path>/') ];

  
-- Snowflake 계정에 대한 AWS IAM 사용자 검색
DESC INTEGRATION cdc_test;


-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항 [完]        --
--                                           --
-----------------------------------------------

----------------------------------------------
--                                          --
--                 결과 테이블                -- 
--                                           --
----------------------------------------------

CREATE OR REPLACE TABLE CDC_TEST.CDC_SCHEMA.RESULT_CDC_EXT
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


-----------------------------------------------
--                                           --
--             External Table 생성            --
--              test용 외부 테이블             --
--                                           --
-----------------------------------------------


CREATE OR REPLACE EXTERNAL TABLE CDC_TEST.CDC_SCHEMA.CDC_PRAC_DB_EXT
(
	  TRANSACTIONS      VARCHAR       AS (VALUE:TRANSACTIONS::STRING)
	, TRANSACTION_ID    VARCHAR       AS (VALUE:TRANSACTION_ID::VARCHAR)
    , ROW_NUM           NUMBER        AS METADATA$FILE_ROW_NUMBER
    , CD_KEY            VARCHAR       AS (VALUE:CD_KEY::VARCHAR)
    , PARENT_CD         VARCHAR       AS (VALUE:PARENT_CD::VARCHAR)
    , CD                VARCHAR       AS (VALUE:CD::VARCHAR)
    , LVL               NUMBER        AS (VALUE:LVL::INTEGER)
    , SORT              NUMBER        AS (VALUE:SORT::INTEGER)
    , USE_YN            VARCHAR       AS (VALUE:USE_YN::VARCHAR)
    , CD_NM             VARCHAR       AS (VALUE:CD_NM::VARCHAR)
    , CD_NM_ENG         VARCHAR       AS (VALUE:CD_NM_ENG::VARCHAR)
    , CD_NM_CHN         VARCHAR       AS (VALUE:CD_NM_CHN::VARCHAR)
    , CD_NM_JPN         VARCHAR       AS (VALUE:CD_NM_JPN::VARCHAR)
    , CD_NM_ETC         VARCHAR       AS (VALUE:CD_NM_ETC::VARCHAR)
    , RMK               VARCHAR       AS (VALUE:RMK::VARCHAR)
    , ERP_PARENT_CD     VARCHAR       AS (VALUE:ERP_PARENT_CD::VARCHAR)
    , ERP_TABLE         VARCHAR       AS (VALUE:ERP_TABLE::VARCHAR)
    , VAL1              VARCHAR       AS (VALUE:VAL1::VARCHAR)
    , VAL2              VARCHAR       AS (VALUE:VAL2::VARCHAR)
    , VAL3              VARCHAR       AS (VALUE:VAL3::VARCHAR)
    , VAL4              VARCHAR       AS (VALUE:VAL4::VARCHAR)
    , VAL5              VARCHAR       AS (VALUE:VAL5::VARCHAR)
    , VAL6              VARCHAR       AS (VALUE:VAL6::VARCHAR)
    , VAL7              VARCHAR       AS (VALUE:VAL7::VARCHAR)
    , VAL8              VARCHAR       AS (VALUE:VAL8::VARCHAR)
    , VAL9              VARCHAR       AS (VALUE:VAL9::VARCHAR)
    , VAL10             VARCHAR       AS (VALUE:VAL10::VARCHAR)
)
LOCATION          = @cdc_prac/
AUTO_REFRESH      = FALSE
REFRESH_ON_CREATE = FALSE
FILE_FORMAT       = my_parquet_format
;


-----------------------------------------------
--                                           --
--                  STREAM 생성              --
--          (1번이 가장 최신 트랜잭션)           --
--                                           --
-----------------------------------------------


CREATE OR REPLACE STREAM EXT_STREAM
	ON EXTERNAL TABLE CDC_PRAC_DB_EXT	
	INSERT_ONLY = TRUE
;


-----------------------------------------------
--                                           --
--                  STREAM 생성              --
--        EXTERNAL TABLE 수동 새로고침          --
--                                           --
-----------------------------------------------


ALTER EXTERNAL TABLE CDC_TEST.CDC_SCHEMA.CDC_PRAC_DB_EXT REFRESH;


-----------------------------------------------
--                                            --
--                  STREAM 확인                --
--                                            --
-----------------------------------------------


SELECT * FROM CDC_PRAC_DB_EXT;


-----------------------------------------------
--                                           --
--           데이터 적재 확인 [완]             --
--                                           --
-----------------------------------------------


SELECT * FROM RESULT_CDC;


-----------------------------------------------
--                                           --
--    변경 사항을 순서대로 번호 붙이는 Query      --
--          (1번이 가장 최신 트랜잭션)           --
--                                           --
-----------------------------------------------

SELECT T1.TRANSACTIONS ,T1.CD_NM
        , ROW_NUMBER() OVER(PARTITION BY T1.CD_KEY
                                        ORDER BY T1.TRANSACTION_ID DESC) AS RNUM
FROM EXT_STREAM T1
WHERE CD_KEY = 'A011000'
ORDER BY RNUM;


-----------------------------------------------
--                                           --
--           MERGE INTO 시도해보기             --
--                                           --
-----------------------------------------------



MERGE
 INTO CDC_TEST.CDC_SCHEMA.RESULT_CDC_EXT T
USING (
        SELECT T2.*
	     FROM (
                SELECT T1.*
                		, ROW_NUMBER() OVER(PARTITION BY T1.CD_KEY
                										ORDER BY T1.TRANSACTION_ID DESC) AS RNUM
                FROM EXT_STREAM T1
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


SELECT * FROM RESULT_CDC;