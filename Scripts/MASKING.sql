-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항             --
--                                           --
-----------------------------------------------

USE WAREHOUSE COMPUTE_WH;
USE DATABASE HYUNDAI_DB;
USE SCHEMA PENTA_SCHEMA;

------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ User, Role 생성 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
--                            실 프로젝트에서는 생성해야 한다.
------------------------------------------------------------------------------------

-- CREATE USER MASK 
-- PASSWORD='mask'
-- MUST_CHANGE_PASSWORD = TRUE
-- DEFAULT_ROLE = PBI_ROLE

-- SHOW USERS;

-- DESC USER MASK;

CREATE ROLE PBI_ROLE;                                                -- PBI ROLE 생성
-- GRANT USAGE ON DATABASE HYUNDAI_DB TO ROLE PBI_ROLE;                 -- PBI ROLE에게 DB 활용 권한 부여
-- GRANT USAGE ON SCHEMA PENTA_SCHEMA TO ROLE PBI_ROLE;                 -- PBI ROLE에게 SCHEMA 활용 권한 부여
-- GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE TO ROLE PBI_ROLE;        -- PBI ROLE에게 특정 테이블 조회 권한 부여
-- GRANT SELECT ON ALL TABLES IN SCHEMA PENTA_SCHEMA TO ROLE PBI_ROLE;  -- PBI ROLE에게 특정 스키마 내의 모든 테이블 조회 권한 부여
-- GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE PBI_ROLE;              -- PBI ROLE에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 
-- GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE PBI_ROLE;                -- PBI ROLE에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여
-- GRANT ROLE PBI_ROLE TO USER MASK;                                    -- PBI USER에게 PBI ROLE 부여

-- GRANT ROLE PBI_ROLE TO USER PENTA_02;

-- REVOKE ROLE PBI_ROLE FROM USER PENTA_02;

-- GRANT ROLE PBI_ROLE TO ROLE ACCOUNTADMIN;
-- REVOKE ROLE PBI_ROLE FROM ROLE ACCOUNTADMIN;

-- SELECT CURRENT_ROLE();
-- SHOW GRANTS TO ROLE ACCOUNTADMIN;
-- SHOW GRANTS OF ROLE PBI_ROLE;

SHOW ROLES;

------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE 생성 : DPTS_PCH_CD를 마스킹할 예정 ■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------

CREATE OR REPLACE TABLE OG_TABLE AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;

SELECT * FROM OG_TABLE;

------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ TEST를 위한 DYNAMIC TABLEs 생성 : DPTS_PCH_CD를 마스킹할 예정 ■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------

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
-- (현 사용자는 해당 역할이 없으니까 정상 데이터 확인 의도)
CREATE OR REPLACE MASKING POLICY TEST2 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;


DESC MASKING POLICY TEST1;
SHOW MASKING POLICIES IN SCHEMA PENTA_SCHEMA;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD SET MASKING POLICY TEST1;
ALTER TABLE IF EXISTS MASKING_TEST2 MODIFY COLUMN DPTS_PCH_CD SET MASKING POLICY TEST2;


-- 현재 사용자의 역할에 PBI_ROLE이 없다면, 마스킹 적용 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;


-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
-- (현 사용자는 해당 역할이 없으니까 정상 데이터 확인 의도)
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST2;
