-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항             --
--                                           --
-----------------------------------------------

-- 역할 및 웨어하우스 사용 설정
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'X-SMALL';

-- DB, SCHEMA 생성 및 사용
--CREATE OR REPLACE DATABASE PENTA_DB;
--CREATE OR REPLACE SCHEMA CH_SCHEMA;
USE DATABASE PENTA_DB;
USE SCHEMA CH_SCHEMA;

-----------------------------------------------
--                                           --
--   데이터 Load하기 위한 FILE_FORMAT 생성     --
--                                           --
-----------------------------------------------

CREATE OR REPLACE FILE FORMAT my_csv_load_dynamic_format
    TYPE = 'CSV'
    PARSE_HEADER = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-----------------------------------------------
--                                           --
--         S3와 연결을 위한  STAGE 생성        --
--                                           --
-----------------------------------------------

  
-- External Stage 생성 (CSV)
CREATE OR REPLACE STAGE S3_TO_SNOW_DYNAMIC
    STORAGE_INTEGRATION = PENTA_INTEGRATION
    URL = 's3://jaeyeong-hyundai/snowflake_sample/chan/dynamic/'
    FILE_FORMAT = my_csv_load_dynamic_format;


----------------------------------------------------
--                                                --
--   INFER_SCHEMA를 통해 S3의 파일 메타데이터 인식    --
--                                                --
----------------------------------------------------

-- INFER_SCHEMA test csv
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@S3_TO_SNOW_DYNAMIC/'
      , FILE_FORMAT=>'my_csv_load_dynamic_format'
      )
    );


------------------------------------------------
--                                            --
--    SCHEMA DETECTION을 활용한 Table 생성      --
--                                            --
------------------------------------------------


-- CSV Table 생성
CREATE OR REPLACE TABLE ORIGIN_TEST
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@S3_TO_SNOW_DYNAMIC/'
          , FILE_FORMAT=>'my_csv_load_dynamic_format'
          )
      ));

      
-- TABLE 확인
SELECT * FROM ORIGIN_TEST;
DESC TABLE ORIGIN_TEST;


-----------------------------------------------
--                                           --
--        ORIGIN_TEST COMMENT 설정           --
--                                           --
-----------------------------------------------

-- Table을 생성할 때, COMMENT도 같이 설정하는 명령어
-- CREATE TABLE my_table(my_column string COMMENT 'this is comment3');


-- 이미 생성된 Table의 Column에 직접 COMMENT를 추가하는 명령어
COMMENT ON COLUMN ORIGIN_TEST.ID IS 'Here is a id comment';
COMMENT ON COLUMN ORIGIN_TEST.first_name IS 'Here is a first_name comment';
COMMENT ON COLUMN ORIGIN_TEST.last_name IS 'Here is a last_name comment';
COMMENT ON COLUMN ORIGIN_TEST.email IS 'Here is a email comment';

-- DATA 확인
SELECT * FROM ORIGIN_TEST;

-- COMMENT 확인
DESC TABLE ORIGIN_TEST;


-----------------------------------------------
--                                           --
--             Dynamic Table 생성             --
--                                           --
-----------------------------------------------


-- Dynamic Table 생성
CREATE OR REPLACE DYNAMIC TABLE DTABLETEST
  TARGET_LAG = '1 minutes'
  WAREHOUSE = JAE_WH
  AS
    SELECT * FROM ORIGIN_TEST;


-----------------------------------------------
--                                           --
--             Dynamic Table 확인             --
--                                           --
-----------------------------------------------


SELECT * FROM DTABLETEST;
-- Dynamic Table도 COMMENT는 반영하지 못함.
DESC TABLE DTABLETEST;



------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■ 1. INSERT INTO로 Dynamic Table 반영 확인 ■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------


-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 한 행 삽입            --
--                                           --
-----------------------------------------------


INSERT INTO ORIGIN_TEST (ID, FIRST_NAME, LAST_NAME, EMAIL)
VALUES (1001, 'Sue', 'Storms', 'abc@acb.com');


-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------

SELECT * FROM ORIGIN_TEST;

-----------------------------------------------
--                                           --
--             Dynamic Table 확인             --
--                                           --
-----------------------------------------------

-- 바로 확인했을 때 데이터가 없는 것을 확인
SELECT * FROM DTABLETEST;

-- 약 1분 후... Apply 확인
SELECT * FROM DTABLETEST;


---------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■ 1. INSERT INTO로 Dynamic Table 반영 확인 [完] ■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■ 2. TRUNCATE - Dynamic Table 반영 확인 ■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------


-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 입력한 행 삭제         --
--                                           --
-----------------------------------------------

TRUNCATE TABLE ORIGIN_TEST;

-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------

SELECT * FROM ORIGIN_TEST;

-----------------------------------------------
--                                           --
--             Dynamic Table 확인             --
--                                           --
-----------------------------------------------

-- 바로 확인했을 때 데이터가 없는 것을 확인
SELECT * FROM DTABLETEST;

-- 약 1분 후... Apply 확인
SELECT * FROM DTABLETEST;


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■ 2. TRUNCATE - Dynamic Table 반영 확인 [完] ■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■ 3. COPY INTO로 Dynamic Table 반영 확인 ■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------

-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 COPY INTO           --
--                                           --
-----------------------------------------------

COPY INTO ORIGIN_TEST
    FROM @S3_TO_SNOW_DYNAMIC/dy_01
    FILE_FORMAT = my_csv_load_dynamic_format
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;


-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------

SELECT * FROM ORIGIN_TEST;

-----------------------------------------------
--                                           --
--             Dynamic Table 확인             --
--                                           --
-----------------------------------------------

-- 바로 확인했을 때 데이터가 없는 것을 확인
SELECT * FROM DTABLETEST;

-- 약 1분 후... Apply 확인
SELECT * FROM DTABLETEST;


----------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■ 3. COPY INTO로 Dynamic Table 반영 확인 [完] ■■■■■■■■■■■■■■■■■■■■■■■■■
----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■ 4. Schema Evolution Dynamic Table 반영 확인  ■■■■■■■■■■■■■■■■■■■■■■■■
----------------------------------------------------------------------------------------

-- S3에 기존 데이터보다 Column이 추가된 데이터 적재.

----------------------------------------------------
--                                                --
--   INFER_SCHEMA를 통해 S3의 파일 메타데이터 인식    --
--                                                --
----------------------------------------------------

-- INFER_SCHEMA
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@S3_TO_SNOW_DYNAMIC/'
      , FILE_FORMAT=>'my_csv_load_dynamic_format'
      )
    );


----------------------------------------------------
--                                                --
--             Schema Evolution 활성화             --
--                                                --
----------------------------------------------------


ALTER TABLE ORIGIN_TEST SET ENABLE_SCHEMA_EVOLUTION = TRUE;


-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 COPY INTO           --
--                                           --
-----------------------------------------------


COPY INTO ORIGIN_TEST
    FROM @S3_TO_SNOW_DYNAMIC
    FILE_FORMAT = my_csv_load_dynamic_format
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;


-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------


SELECT * FROM ORIGIN_TEST;


-----------------------------------------------
--                                           --
--             Dynamic Table 확인             --
--                                           --
-----------------------------------------------

-- Schema Evolution 반영 아직 안됨 
SELECT * FROM DTABLETEST;

-- 약 10분 후에도... Schema Evolution 반영 안됨
SELECT * FROM DTABLETEST;

-- Dynamic Table 재생성시 반영되는지 확인
CREATE OR REPLACE DYNAMIC TABLE DTABLETEST
  TARGET_LAG = '1 minutes'
  WAREHOUSE = COMPUTE_WH
  AS
    SELECT * FROM ORIGIN_TEST;

-- 재생성 시, 반영.
SELECT * FROM DTABLETEST;

DROP TABLE DTABLETEST;
DROP TABLE ORIGIN_TEST;
    
---------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■ 4. Schema Evolution Dynamic Table 반영 X  ■■■■■■■■■■■■■■■■■■■■■■
----------------------------------------------------------------------------------


----------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■ 5. Dynamic Table에 Schema Evolution 활성화해보기  ■■■■■■■■■■■■■■■■■■■■■■
----------------------------------------------------------------------------------------

-- Dynamic Table에도 SCHEMA EVOLUTION이 존재하는 지 확인.
CREATE OR REPLACE DYNAMIC TABLE DTABLETEST ENABLE_SCHEMA_EVOLUTION = TRUE
  TARGET_LAG = '1 minutes'
  WAREHOUSE = COMPUTE_WH
  AS
    SELECT * FROM ORIGIN_TEST;

-- 000002 (0A000): Unsupported feature 'ENABLE_SCHEMA_EVOLUTION'.


-----------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 5. 그러한 Option은 없음  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-----------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■ 6. 전체 새로고침 모드로 동작하는 지 확인하기   ■■■■■■■■■■■■■■■■■■■■■■■■■■
----------------------------------------------------------------------------------------

-- ORIGIN 초기화
TRUNCATE TABLE ORIGIN_TEST;
SELECT * FROM ORIGIN_TEST;

-- CSV Table 생성
CREATE OR REPLACE TABLE ORIGIN_TEST ENABLE_SCHEMA_EVOLUTION = TRUE
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@S3_TO_SNOW_DYNAMIC/dy_01.csv'
          , FILE_FORMAT=>'my_csv_load_dynamic_format'
          )
      ));


-----------------------------------------------
--                                           --
--      다시 Column 4개 Table 생성 확인        --
--                                           --
-----------------------------------------------


SELECT * FROM ORIGIN_TEST;


-----------------------------------------------
--                                           --
--   전체 새로고침 모드로 Dynamic Table 생성     --
--                                           --
-----------------------------------------------


CREATE OR REPLACE DYNAMIC TABLE DTABLETEST
  TARGET_LAG = '1 minutes'
  REFRESH_MODE = FULL
  WAREHOUSE = COMPUTE_WH
  AS
    SELECT * FROM ORIGIN_TEST;


-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 한 행 삽입            --
--                                           --
-----------------------------------------------


INSERT INTO ORIGIN_TEST (ID, FIRST_NAME, LAST_NAME, EMAIL)
VALUES (1001, 'Sue', 'Storms', 'abc@acb.com');

-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------

SELECT * FROM ORIGIN_TEST;

-----------------------------------------------
--                                           --
--             Dynamic Table 확인             --
--                                           --
-----------------------------------------------


-- 바로 확인했을 때 데이터가 없는 것을 확인
SELECT * FROM DTABLETEST;

-- 약 1분 후... Apply 확인
SELECT * FROM DTABLETEST;


-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 COPY INTO           --
--                                           --
-----------------------------------------------


COPY INTO ORIGIN_TEST
    FROM @S3_TO_SNOW_DYNAMIC
    FILE_FORMAT = my_csv_load_dynamic_format
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;


-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------

SELECT * FROM ORIGIN_TEST;

-----------------------------------------------
--                                           --
--             Dynamic Table 확인             --
--                                           --
-----------------------------------------------


-- 바로 확인했을 때 데이터가 없는 것을 확인
SELECT * FROM DTABLETEST;

-- 약 1분 후... 적용 안됨 
SELECT * FROM DTABLETEST;


-----------------------------------------------
--                                           --
--     DYNAMIC_TABLE_REFRESH_HISTORY  확인    --
--                                           --
-----------------------------------------------


SELECT
  *
FROM
  TABLE (
    INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY (
      NAME_PREFIX => 'PENTA_DB.CH_SCHEMA.', ERROR_ONLY => TRUE
    )
  )
ORDER BY
  name,
  data_timestamp;

-- SQL compilation error: Dynamic Table 'DTABLETEST' needs to be recreated because a base table changed.
-- 원천 테이블이 열 수가 변경되었으므로 동적 테이블도 재생성해야한다는 에러


---------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■ 6. 전체 새로고침 모드로 동작하는 지 확인 -> 동작 X  ■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 7. Materialized View 라면?   ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------------------------------------------

-- ORIGIN 초기화
TRUNCATE TABLE ORIGIN_TEST;
SELECT * FROM ORIGIN_TEST;

-- CSV Table 생성
CREATE OR REPLACE TABLE ORIGIN_TEST ENABLE_SCHEMA_EVOLUTION = TRUE
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@S3_TO_SNOW_DYNAMIC/dy_01.csv'
          , FILE_FORMAT=>'my_csv_load_dynamic_format'
          )
      ));


-----------------------------------------------
--                                           --
--      다시 Column 4개 Table 생성 확인        --
--                                           --
-----------------------------------------------


SELECT * FROM ORIGIN_TEST;


-----------------------------------------------
--                                           --
--         Materialized View 생성             --
--                                           --
-----------------------------------------------

-- DROP MATERIALIZED VIEW MV;

CREATE MATERIALIZED VIEW MV
    COMMENT='Test view'
    AS
    SELECT * FROM ORIGIN_TEST;

-- MView 확인 
SELECT * FROM MV;

-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 한 행 삽입            --
--                                           --
-----------------------------------------------


INSERT INTO ORIGIN_TEST (ID, FIRST_NAME, LAST_NAME, EMAIL)
VALUES (1001, 'Sue', 'Storms', 'abc@acb.com');


-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------

SELECT * FROM ORIGIN_TEST;

-----------------------------------------------
--                                           --
--           Materialized View 확인           --
--                                           --
-----------------------------------------------


SELECT * FROM MV;


-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 COPY INTO           --
--                                           --
-----------------------------------------------


COPY INTO ORIGIN_TEST
    FROM @S3_TO_SNOW_DYNAMIC
    FILE_FORMAT = my_csv_load_dynamic_format
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;


-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------


SELECT * FROM ORIGIN_TEST;


-----------------------------------------------
--                                           --
--           Materialized View 확인           --
--                                           --
-----------------------------------------------


-- 데이터 자체는 삽입 및 삭제가 되는데, SCHEMA EVOLUTION은 반영되지 않는다.
SELECT * FROM MV;

-- ALTER MATERIALIZED VIEW MV ADD COLUMN IP VARCHAR(255);


----------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 7. Materialized View 라면? 진화 X   ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
----------------------------------------------------------------------------------------------------

DROP TABLE ORIGIN_TEST;
DROP DYNAMIC TABLE DTABLETEST;


----------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ +a. Join 적용 확인   ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
----------------------------------------------------------------------------------------------------

----------------------------------------------------
--                                                --
--   INFER_SCHEMA를 통해 S3의 파일 메타데이터 인식    --
--                                                --
----------------------------------------------------

-- INFER_SCHEMA test csv
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@S3_TO_SNOW_DYNAMIC/dy_cars'
      , FILE_FORMAT=>'my_csv_load_dynamic_format'
      )
    );


------------------------------------------------
--                                            --
--    SCHEMA DETECTION을 활용한 Table 생성      --
--                                            --
------------------------------------------------


-- CSV Table 생성
CREATE OR REPLACE TABLE JOIN_TEST
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@S3_TO_SNOW_DYNAMIC/dy_cars'
          , FILE_FORMAT=>'my_csv_load_dynamic_format'
          )
      ));

-----------------------------------------------
--                                           --
--        ORIGIN_TABLE에 COPY INTO           --
--                                           --
-----------------------------------------------

COPY INTO JOIN_TEST
    FROM @S3_TO_SNOW_DYNAMIC/dy_cars
    FILE_FORMAT = my_csv_load_dynamic_format
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;


-----------------------------------------------
--                                           --
--              ORIGIN_TABLE 확인             --
--                                           --
-----------------------------------------------

SELECT * FROM JOIN_TEST;

-----------------------------------------------
--                                           --
--              Dynamic Table 생성            --
--                                           --
-----------------------------------------------

-- Dynamic Table 생성
CREATE OR REPLACE DYNAMIC TABLE DTABLETEST
  TARGET_LAG = '1 minutes'
  WAREHOUSE = COMPUTE_WH
  AS
    SELECT ORIGIN_TEST.ID, ORIGIN_TEST.FIRST_NAME, ORIGIN_TEST.LAST_NAME, ORIGIN_TEST.EMAIL, JOIN_TEST.CAR
    FROM 
    ORIGIN_TEST FULL OUTER JOIN JOIN_TEST
    ON ORIGIN_TEST.ID = JOIN_TEST.ID;

    
-----------------------------------------------
--                                           --
--             Dynamic Table 확인             --
--                                           --
-----------------------------------------------

-- 바로 확인했을 때 데이터가 없는 것을 확인
SELECT * FROM DTABLETEST;

-- 약 1분 후... Apply 확인
SELECT * FROM DTABLETEST;


DROP TABLE JOIN_TEST;
DROP TABLE DTABLETEST;
DROP TABLE ORIGIN_TEST;


