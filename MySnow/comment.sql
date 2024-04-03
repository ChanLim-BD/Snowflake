-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항             --
--                                           --
-----------------------------------------------

-- 역할 및 웨어하우스 사용 설정
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- DB, SCHEMA 생성 및 사용
--CREATE OR REPLACE DATABASE PENTA_DB;
--CREATE OR REPLACE SCHEMA CH_SCHEMA;
USE DATABASE PENTA_DB;
USE SCHEMA CH_SCHEMA;


-----------------------------------------------
--                                           --
--        COMMENT_TEST Table  생성            --
--                                           --
-----------------------------------------------

-- SAMPLE DATA TABLE 복사
-- Snowflake 샘플 데이터를 활용
CREATE TABLE PENTA_DB.CH_SCHEMA.COMMENT_TEST AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION;

-- TABLE 및 DATA 복사 확인
SELECT * FROM COMMENT_TEST;


-----------------------------------------------
--                                           --
--        COMMENT_TEST COMMENT 설정           --
--                                           --
-----------------------------------------------

-- Table을 생성할 때, COMMENT도 같이 설정하는 명령어
-- CREATE TABLE my_table(my_column string COMMENT 'this is comment3');


-- 이미 생성된 Table의 Column에 직접 COMMENT를 추가하는 명령어
COMMENT ON COLUMN COMMENT_TEST.N_NATIONKEY IS 'Here is a nation_key comment';
COMMENT ON COLUMN COMMENT_TEST.N_NAME IS 'Here is a name comment';
COMMENT ON COLUMN COMMENT_TEST.N_REGIONKEY IS 'Here is a region_key comment';
COMMENT ON COLUMN COMMENT_TEST.N_COMMENT IS 'Here is a comment comment';


-- COMMENT 확인
DESC TABLE COMMENT_TEST;


-------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■ 1. COMMENT가 포함된 Table에서 S3로 언로딩 후, 다시 Snowflake로 로딩했을 떄  ■■■■■■■■■■■■■■■■■■■■■■--
-------------------------------------------------------------------------------------------------------------


-----------------------------------------------
--                                           --
--   데이터 Unload를 위한 FILE_FORMAT 생성     --
--                                           --
-----------------------------------------------


-- FILE FORMAT 생성 (CSV)
CREATE OR REPLACE FILE FORMAT my_csv_unload_format
  TYPE = 'CSV'
  FIELD_DELIMITER = '|';


-----------------------------------------------
--                                           --
--         S3와 연결을 위한  STAGE 생성        --
--                                           --
-----------------------------------------------

  
-- External Stage 생성 (CSV)
CREATE OR REPLACE STAGE SNOW_TO_S3_COMMENT
    STORAGE_INTEGRATION = PENTA_INTEGRATION
    URL = 's3://jaeyeong-hyundai/snowflake_sample/chan/comment/'
    FILE_FORMAT = my_csv_unload_format;


-----------------------------------------------
--                                           --
--              S3로 데이터 Unload            --
--                                           --
-----------------------------------------------

-- S3로 데이터 Unload
COPY INTO @SNOW_TO_S3_COMMENT FROM COMMENT_TEST HEADER = TRUE;


-- STAGE 데이터 확인하기
LIST @SNOW_TO_S3_COMMENT;



-----------------------------------------------
--                                           --
--   데이터 Load하기 위한 FILE_FORMAT 생성     --
--                                           --
-----------------------------------------------

CREATE OR REPLACE FILE FORMAT my_csv_load_format
    TYPE = 'CSV'
    COMPRESSION = 'GZIP'
    FIELD_DELIMITER = '|'
    PARSE_HEADER = TRUE;


-----------------------------------------------
--                                           --
--         S3와 연결을 위한  STAGE 생성        --
--                                           --
-----------------------------------------------

  
-- External Stage 생성 (CSV)
CREATE OR REPLACE STAGE S3_TO_SNOW_COMMENT
    STORAGE_INTEGRATION = PENTA_INTEGRATION
    URL = 's3://jaeyeong-hyundai/snowflake_sample/chan/comment/'
    FILE_FORMAT = my_csv_load_format;


----------------------------------------------------
--                                                --
--   INFER_SCHEMA를 통해 S3의 파일 메타데이터 인식    --
--                                                --
----------------------------------------------------

-- INFER_SCHEMA test csv
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@S3_TO_SNOW_COMMENT/'
      , FILE_FORMAT=>'my_csv_load_format'
      )
    );

-- Table 생성 전에 ARRAY_AGG(object_construct(*)) 과정 확인용
SELECT ARRAY_AGG(object_construct(*))
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@S3_TO_SNOW_COMMENT/'
      , FILE_FORMAT=>'my_csv_load_format'
      )
    );


------------------------------------------------
--                                            --
--    SCHEMA DETECTION을 활용한 Table 생성      --
--                                            --
------------------------------------------------



-- CSV Table 생성
CREATE OR REPLACE TABLE RECEIVE_COMMENT
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@S3_TO_SNOW_COMMENT/'
          , FILE_FORMAT=>'my_csv_load_format'
          )
      ));



-- Table 생성 확인      
SELECT * FROM RECEIVE_COMMENT;

------------------------------------------------
--                                            --
--     Table에 S3에 적재된 데이터 COPY INTO     --
--                                            --
------------------------------------------------


COPY INTO RECEIVE_COMMENT
  FROM @S3_TO_SNOW_COMMENT
  FILE_FORMAT = my_csv_load_format
  MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Table 데이터 적재 확인      
SELECT * FROM RECEIVE_COMMENT;


-- COMMENT 확인
DESC TABLE RECEIVE_COMMENT;


-------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 1. COMMENT까지 로딩되지 않는다.  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■-
-------------------------------------------------------------------------------------------------------------

DROP TABLE RECEIVE_COMMENT;

-------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■ 2. COMMENT를 포함한 메타데이터를 CSV 파일로 저장 후 언로딩 및 로딩  ■■■■■■■■■■■■■■■■■■■■■■■■■■--
-------------------------------------------------------------------------------------------------------------

----------------------------------------------------
--                                                --
--      COMMENT를 가져오기 위한  메타데이터 인식      --
--                                                --
----------------------------------------------------

-- 메타데이터 출력 명령어
SELECT
    column_name,
    data_type,
    comment
FROM
    information_schema.columns
WHERE
    table_schema = 'CH_SCHEMA'       -- 스키마 이름을 여기에 입력하세요
    AND table_name = 'COMMENT_TEST'; -- 테이블 이름을 여기에 입력하세요


----------------------------------------------------
--                                                --
--         COMMENT 메타데이터 S3에 언로딩            --
--                                                --
----------------------------------------------------

-- 메타데이터도 언로딩하기
COPY INTO @SNOW_TO_S3_COMMENT/meta 
FROM (
    SELECT
        column_name,
        data_type,
        comment
    FROM
        information_schema.columns
    WHERE
        table_schema = 'CH_SCHEMA'      -- 스키마 이름을 여기에 입력하세요
        AND table_name = 'COMMENT_TEST' -- 테이블 이름을 여기에 입력하세요
)
HEADER = TRUE
FILE_FORMAT = my_csv_unload_format;


------------------------------------------------
--                                            --
--    SCHEMA DETECTION을 활용한 Table 생성      --
--                                            --
------------------------------------------------


-- Data Table 스키마 감지
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@S3_TO_SNOW_COMMENT/data'
      , FILE_FORMAT=>'my_csv_load_format'
      )
    );

-- Metadata Table 스키마 감지
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@S3_TO_SNOW_COMMENT/meta'
      , FILE_FORMAT=>'my_csv_load_format'
      )
    );


-- Commnet Table 생성
CREATE OR REPLACE TABLE RECEIVE_COMMENT
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@S3_TO_SNOW_COMMENT/data'
          , FILE_FORMAT=>'my_csv_load_format'
          )
      ));


-- Comment Metadata Table 생성
CREATE OR REPLACE TABLE RECEIVE_COMMENT_META
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@S3_TO_SNOW_COMMENT/meta'
          , FILE_FORMAT=>'my_csv_load_format'
          )
      ));


------------------------------------------------
--                                            --
--     Table에 S3에 적재된 데이터 COPY INTO     --
--                                            --
------------------------------------------------


-- 데이터 테이블 삽입 
COPY INTO RECEIVE_COMMENT
    FROM @S3_TO_SNOW_COMMENT/data
    FILE_FORMAT = my_csv_load_format
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- 메타데이터 테이블 삽입 
COPY INTO RECEIVE_COMMENT_META
    FROM @S3_TO_SNOW_COMMENT/meta
    FILE_FORMAT = my_csv_load_format
  MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
  
-- 확인 
SELECT * FROM RECEIVE_COMMENT;
SELECT * FROM RECEIVE_COMMENT_META;


------------------------------------------------
--                                            --
--             COMMENT 회복 시도               --
--                                            --
------------------------------------------------


-- 메타데이터 테이블에서 특정 열의 COMMENT SELECT
SELECT comment FROM RECEIVE_COMMENT_META WHERE COLUMN_NAME = 'N_NATIONKEY';

-- 실패
ALTER TABLE RECEIVE_COMMENT
MODIFY COLUMN N_NATIONKEY COMMENT '<string_literal>';

-- 실패
COMMENT ON COLUMN RECEIVE_COMMENT.N_NATIONKEY IS '<string_literal>';


-- '<string_literal>' 부분은 SELECT로 지정할 수 없다. 즉, 일일이 입력해서 COMMENT를 수동으로 지정해야한다.


-- COMMENT 확인 
DESC TABLE RECEIVE_COMMENT;


-------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■ 2. COMMENT를 포함한 메타데이터를 CSV 파일로 저장 후 언로딩 및 로딩 정리 ■■■■■■■■■■■■■■■■■■■■■■■■■--
-------------------------------------------------------------------------------------------------------------

-- Table의 메타데이터로 COMMENT를 언로딩 및 로딩할 수 있다.
-- 다만, S3로부터 로딩한 메타데이터를 활용해서 Table에 순차적으로 적용하는 방법이 없다.
-- 즉, 일일이 수동으로 열마다 저장해야한다.