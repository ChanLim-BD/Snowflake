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

CREATE USER TEST1 
PASSWORD='TEST'
MUST_CHANGE_PASSWORD = TRUE
DEFAULT_ROLE = PBI_ROLE;

SHOW USERS;

DESC USER TEST1;

DROP USER TEST1;

CREATE ROLE TEST_ROLE;                                                -- PBI ROLE 생성
GRANT USAGE ON DATABASE HYUNDAI_DB TO ROLE TEST_ROLE;                 -- PBI ROLE에게 DB 활용 권한 부여
GRANT USAGE ON SCHEMA PENTA_SCHEMA TO ROLE TEST_ROLE;                 -- PBI ROLE에게 SCHEMA 활용 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE TO ROLE TEST_ROLE;        -- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST1 TO ROLE TEST_ROLE;   -- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST2 TO ROLE TEST_ROLE;   -- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON ALL TABLES IN SCHEMA PENTA_SCHEMA TO ROLE TEST_ROLE;  -- PBI ROLE에게 특정 스키마 내의 모든 테이블 조회 권한 부여
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TEST_ROLE;              -- PBI ROLE에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE TEST_ROLE;                -- PBI ROLE에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여

-- 사용자에게 생성한 Role 부여
GRANT ROLE PBI_ROLE TO USER MASK;

-- 사용자에게 생성한 Role 회수
REVOKE ROLE PBI_ROLE FROM USER MASK;

-- 현재 Role 확인
SELECT CURRENT_ROLE();

-- 역할 부여 확인하는 두 Queries
SHOW GRANTS TO ROLE ACCOUNTADMIN;
SHOW GRANTS OF ROLE TEST_ROLE;

SHOW ROLES;