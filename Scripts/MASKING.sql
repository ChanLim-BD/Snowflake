-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항             --
--                                           --
-----------------------------------------------

USE WAREHOUSE COMPUTE_WH;
USE DATABASE HYUNDAI_DB;
USE SCHEMA PENTA_SCHEMA;


-----------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ User, Role 생성 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
--                                           실 프로젝트에서는 생성해야 한다.
------------------------------------------------------------------------------------------------------------------


-----------------------------------------------
--                                           --
--                  사용자 생성                --
--                                           --
-----------------------------------------------


-- CREATE USER MASK 
-- PASSWORD='mask'
-- MUST_CHANGE_PASSWORD = TRUE
-- DEFAULT_ROLE = PBI_ROLE;

-- SHOW USERS;

-- DESC USER MASK;

-- DROP USER MASK;


-----------------------------------------------
--                                           --
--                  역할  생성                --
--                                           --
-----------------------------------------------


CREATE ROLE PBI_ROLE;                                                           -- PBI ROLE 생성
GRANT USAGE ON DATABASE HYUNDAI_DB TO ROLE PBI_ROLE;                            -- PBI ROLE에게 DB 활용 권한 부여
GRANT USAGE ON SCHEMA PENTA_SCHEMA TO ROLE PBI_ROLE;                            -- PBI ROLE에게 SCHEMA 활용 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE TO ROLE PBI_ROLE;                   -- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST1 TO ROLE PBI_ROLE;              -- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST2 TO ROLE PBI_ROLE;              -- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON ALL TABLES IN SCHEMA HYUNDAI_DB.PENTA_SCHEMA TO ROLE PBI_ROLE;  -- PBI ROLE에게 특정 스키마 내의 모든 테이블 조회 권한 부여
GRANT SELECT ON FUTURE TABLES IN DATABASE HYUNDAI_DB TO ROLE PBI_ROLE;          -- PBI ROLE에게 미래의 대한 테이블 조회 권한 부여
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE PBI_ROLE;                         -- PBI ROLE에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE PBI_ROLE;                           -- PBI ROLE에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여

-- 사용자에게 생성한 Role 부여
GRANT ROLE PBI_ROLE TO USER PENTA_02;
-- GRANT ROLE PBI_ROLE TO USER MASK;

-- 사용자에게 생성한 Role 회수
REVOKE ROLE PBI_ROLE FROM USER PENTA_02;
-- REVOKE ROLE PBI_ROLE FROM USER MASK;

GRANT ROLE PBI_ROLE TO ROLE ACCOUNTADMIN;
REVOKE ROLE PBI_ROLE FROM ROLE ACCOUNTADMIN;

-- 현재 Role 확인
SELECT CURRENT_ROLE();
-- SELECT CURRENT_DATABASE();
-- SELECT CURRENT_SCHEMA();


-- 역할 부여 확인하는 두 Queries
SHOW GRANTS TO ROLE ACCOUNTADMIN;
SHOW GRANTS OF ROLE PBI_ROLE;

SHOW ROLES;

------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE 생성 : DPTS_PCH_CD를 마스킹할 예정 ■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------


CREATE OR REPLACE TABLE OG_TABLE AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;


------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ TEST를 위한 DYNAMIC TABLEs 생성 : DPTS_PCH_CD를 마스킹할 예정 ■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------


CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST1
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE;



CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST2
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE;


SELECT * FROM MASKING_TEST1;
SELECT * FROM MASKING_TEST2;


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE 생성 : DPTS_PCH_CD를 마스킹할 예정 ■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------

-- 현재 사용자의 역할에 PBI_ROLE이 없다면, 마스킹 적용 
CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;

    
-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
CREATE OR REPLACE MASKING POLICY TEST2 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;


-- 마스킹 정책 확인
DESC MASKING POLICY TEST1;
SHOW MASKING POLICIES IN SCHEMA PENTA_SCHEMA;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD SET MASKING POLICY TEST1;
ALTER TABLE IF EXISTS MASKING_TEST2 MODIFY COLUMN DPTS_PCH_CD SET MASKING POLICY TEST2;


-- 역할 변경
USE ROLE PBI_ROLE;


-- 현재 사용자의 역할에 PBI_ROLE이 없다면, 마스킹 적용 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;


-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST2;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- 현재 사용자의 역할에 PBI_ROLE이 없다면, 마스킹 적용 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;


-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST2;


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ 데이터를 삽입해도 마스킹 정책이 그대로 유지되는지 확인하기 ■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------

-- 테이블에 데이터 삽입하는 쿼리.
-- INSERT INTO OG_TABLE 
--     SELECT * FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1 
--     WHERE LENGTH(t1.dpts_pch_cd) = 6
--     LIMIT 1;

INSERT INTO OG_TABLE (DPTS_PCH_CD, DPTS_PCH_NM, BCD_LEN) VALUES ('999998', '안녕인', NULL);

SELECT * FROM OG_TABLE WHERE DPTS_PCH_CD = '999998';


-- Dynamic Table Refresh
ALTER DYNAMIC TABLE MASKING_TEST1 REFRESH;
ALTER DYNAMIC TABLE MASKING_TEST2 REFRESH;


-- 역할 변경
USE ROLE PBI_ROLE;


-- 현재 사용자의 역할에 PBI_ROLE이 없다면, 마스킹 적용 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;


-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST2;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


--------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ 데이터를 삽입해도 마스킹 정책이 그대로 유지되는지 확인하기 [完] ■■■■■■■■■■■■■■■■■
--------------------------------------------------------------------------------------




------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE_PC : 오리진에서 정책 적용하면 DT에도 적용될까? ■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------
--                                                                     --
--              오리진 생성 후 정책 적용 -> Dynamic Table 확인             --
--                                                                     --
-------------------------------------------------------------------------


-- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE_PC TO ROLE PBI_ROLE;   


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;

    
-- Table 확인
SELECT * FROM OG_TABLE_PC;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC MODIFY COLUMN DPTS_PCH_CD SET MASKING POLICY TEST2;


-- 역할 변경
USE ROLE PBI_ROLE;


-- 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM OG_TABLE_PC;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- Dynamic Table 생성 
CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST3
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE_PC;


-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger INITIAL at data_timestamp 1713250826808 because of the error: 
-- SQL compilation error: Target table failed to refresh: 
-- SQL compilation error: Dynamic Table 'MASKING_TEST3' needs to be recreated because a base table changed.


-------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------
--                                                                     --
--              오리진 생성 후 정책 적용 -> Dynamic Table 확인             --
--                                      REFRESH_MODE = FULL            --
-------------------------------------------------------------------------


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;

    
-- Table 확인
SELECT * FROM OG_TABLE_PC;


-- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE_PC TO ROLE PBI_ROLE;   


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC MODIFY COLUMN DPTS_PCH_CD SET MASKING POLICY TEST2;


-- 역할 변경
USE ROLE PBI_ROLE;


-- 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM OG_TABLE_PC;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- Dynamic Table 생성 
CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST3
TARGET_LAG = '1 hours'
REFRESH_MODE = FULL
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE_PC;


-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger INITIAL at data_timestamp 1713251963336 because of the error: 
-- SQL compilation error: 
-- Target table failed to refresh: 
-- SQL compilation error: 
-- Dynamic Table 'MASKING_TEST3' needs to be recreated because a base table changed.


-------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------
--                                                                     --
--            오리진, DT 생성 후 -> 오리진에 정책 적용 -> Refresh           --
--                                                                     --
-------------------------------------------------------------------------


-- Table Drop
DROP TABLE OG_TABLE_PC;


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;

    
-- Dynamic Table 생성 
CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST3
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE_PC;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC MODIFY COLUMN DPTS_PCH_CD SET MASKING POLICY TEST2;


-- 새로고침 시도
ALTER DYNAMIC TABLE MASKING_TEST3 REFRESH;


-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger MANUAL at data_timestamp 1713250979771 because of the error: SQL compilation error: 
-- Target table failed to refresh: SQL execution error: 
-- Dynamic table 'HYUNDAI_DB.PENTA_SCHEMA.MASKING_TEST3' is no longer incrementalizable because of reason 
-- 'Dynamic Tables only support 'FULL' refresh mode for sources with 'MASKING POLICY'. 
-- Either remove the policy from 'HYUNDAI_DB.PENTA_SCHEMA.OG_TABLE_PC' or recreate the Dynamic Table.'. 
-- Please recreate the dynamic table.


-------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------
--                                                                     --
--            오리진, DT 생성 후 -> 오리진에 정책 적용 -> Refresh           --
--                                             REFRESH_MODE = FULL     --
-------------------------------------------------------------------------

-- Table Drop
DROP TABLE OG_TABLE_PC;
DROP TABLE MASKING_TEST3;


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC2 AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;

    
-- Dynamic Table 생성 HYUNDAI_DB.PENTA_SCHEMA
CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST3
TARGET_LAG = '1 hours'
REFRESH_MODE = FULL
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE_PC;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC MODIFY COLUMN DPTS_PCH_CD SET MASKING POLICY TEST2;


-- 새로고침 시도
ALTER DYNAMIC TABLE MASKING_TEST3 REFRESH;


-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger MANUAL at data_timestamp 1713251825545 because of the error: 
-- SQL compilation error: 
-- Target table failed to refresh: 
-- SQL compilation error: 
-- Dynamic Table 'MASKING_TEST3' needs to be recreated because a base table changed.


------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE_PC : 오리진에서 정책 적용하면 DT에도 적용될까? ■■■■■■■■■■■■■■■■■■■
--■■■■■■■■■■■■■■■■                              X                               ■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------------


