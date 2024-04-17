-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항             --
--                                           --
-----------------------------------------------


USE WAREHOUSE COMPUTE_WH;
USE DATABASE HYUNDAI_DB;
USE SCHEMA PENTA_SCHEMA;


-----------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ User, Role 생성 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
--
--                                           실 프로젝트에서는 생성해야 한다.
--
-----------------------------------------------------------------------------------------------------------------


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

-- GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE TO ROLE PBI_ROLE;                   -- PBI ROLE에게 특정 테이블 조회 권한 부여
-- GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST1 TO ROLE PBI_ROLE;              -- PBI ROLE에게 특정 테이블 조회 권한 부여
-- GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST2 TO ROLE PBI_ROLE;              -- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON ALL TABLES IN SCHEMA HYUNDAI_DB.PENTA_SCHEMA TO ROLE PBI_ROLE;  -- PBI ROLE에게 특정 스키마 내의 모든 테이블 조회 권한 부여

GRANT SELECT ON FUTURE TABLES IN DATABASE HYUNDAI_DB TO ROLE PBI_ROLE;          -- PBI ROLE에게 미래의 대한 테이블 조회 권한 부여

GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE PBI_ROLE;                         -- PBI ROLE에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE PBI_ROLE;                           -- PBI ROLE에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여


-----------------------------------------------
--                                           --
--       새로운 사용자에게 새로운 역할 부여       --
--                                           --
-----------------------------------------------


GRANT ROLE PBI_ROLE TO USER PENTA_02;
-- GRANT ROLE PBI_ROLE TO USER MASK;

-- 사용자에게 생성한 Role 회수
-- REVOKE ROLE PBI_ROLE FROM USER PENTA_02;
-- REVOKE ROLE PBI_ROLE FROM USER MASK;


-- 현재 사용중인 역할 조회
SELECT CURRENT_ROLE();


-- 생성한 역할의 권한을 갖는 사용자 조회 쿼리
SHOW GRANTS OF ROLE PBI_ROLE;


---------------------------------------------------------
--■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE 생성  ■■■■■■■■■■■■■■■■■
---------------------------------------------------------


CREATE OR REPLACE TABLE OG_TABLE AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD_LOG t1
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


ALTER DYNAMIC TABLE MASKING_TEST1 SUSPEND;
ALTER DYNAMIC TABLE MASKING_TEST2 SUSPEND;


-----------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE 생성 : DPTS_PCH_CD를 마스킹 ■■■■■■■■■■■■■■■■■
-----------------------------------------------------------------------------


-- 현재 사용자의 역할에 PBI_ROLE이 없다면, 마스킹 적용하는 정책 생성
CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;

    
-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용하는 정책 생성
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
ALTER TABLE IF EXISTS MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;

ALTER TABLE IF EXISTS MASKING_TEST2 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST2;


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


-- MASKING_TEST1 테이블에 마스킹 정책 회수
ALTER TABLE IF EXISTS MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


-- 정책 회수 후 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;


-- 문자열 중간 마스킹 정책 생성
CREATE OR REPLACE MASKING POLICY TEST_MD AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '**', SUBSTR(VAL, 5, 6))
    END;

    
-- MASKING_TEST1에 MD 마스킹 정책 부여
ALTER TABLE IF EXISTS MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST_MD;


-- 현재 사용자의 역할에 PBI_ROLE이 없다면, 마스킹 적용 
-- (즉, PBI_ROLE이 아니므로 마스킹 적용)
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;


-- MD 정책 회수
ALTER TABLE IF EXISTS MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


-- Dynamic Table 새로고침 중단
ALTER DYNAMIC TABLE MASKING_TEST1 SUSPEND;
ALTER DYNAMIC TABLE MASKING_TEST2 SUSPEND;


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ 마스킹 정책을 부여한 열에 새로운 마스킹 정책으로 변경할 때, ■■■■■■■■■■■■■■■■■
--
--                  위와 같이 기존 정책을 해제하고 새로운 정책을 부여
--                     잠깐이지만 모든 마스킹이 해제된 순간이 존재
--                          이를 방지하기 위한 방법이 존재
------------------------------------------------------------------------------------


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;


-- 마스킹 적용 확인 (ACCOUNDADMIN 역할 시,)
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;


-- FORCE 사용
ALTER TABLE MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST_MD FORCE;


-- 마스킹 적용 확인 (ACCOUNDADMIN 역할 시,)
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;


-- FORCE 사용
ALTER TABLE MASKING_TEST1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1 FORCE;


-- FORCE 적용 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM MASKING_TEST1;



------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE_PC1 : 한 테이블에 여러 정책 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 동일한 열에 두 개 이상의 마스킹 정책 적용 건. ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------------


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC1 AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;


-- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE_PC1 TO ROLE PBI_ROLE;   

    
-- Table 확인
SELECT * FROM OG_TABLE_PC1 LIMIT 1;


-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
CREATE OR REPLACE MASKING POLICY TEST2 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;

    
-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
CREATE OR REPLACE MASKING POLICY TEST3 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 4), '★★★★★★★')
    END;
    

-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST2;

ALTER TABLE IF EXISTS OG_TABLE_PC1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST3;


-- 한 열에 서로 다른 두 마스킹 정책을 부여할 수 없다.

-- Specified column already attached to another masking policy. 
-- A column cannot be attached to multiple masking policies. 
-- Please drop the current association in order to attach a new masking policy.


------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 동일한 열에 두 개 이상의 마스킹 정책 적용 불가 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 서로 다른 열에 같은 마스킹 정책 적용 건. ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------------


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC1 AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;


-- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE_PC1 TO ROLE PBI_ROLE;   

    
-- Table 확인
SELECT * FROM OG_TABLE_PC2 LIMIT 1;

    
-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
CREATE OR REPLACE MASKING POLICY TEST3 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 4), '★★★★★★★')
    END;
    

-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST3;

ALTER TABLE IF EXISTS OG_TABLE_PC1 MODIFY COLUMN DPTS_PCH_NM 
SET MASKING POLICY TEST3;


-- 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM OG_TABLE_PC1
LIMIT 5;


-- 역할 변경
USE ROLE PBI_ROLE;


-- 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM OG_TABLE_PC1
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 서로 다른 열에 같은 마스킹 정책 적용 확인 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■--
--                                                                                            --
--                다만, 열마다 값의 특징이 다르므로 마스킹 정책을 재각각 생성하는 것을 추천             --
------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■ 서로 다른 열에 서로 다른 두 개 이상의 마스킹 정책 적용 건. ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------------------------------------------------------


-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
CREATE OR REPLACE MASKING POLICY TEST2 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;

    
-- 현재 사용자의 역할에 PBI_ROLE이 있다면, 마스킹 적용 
CREATE OR REPLACE MASKING POLICY TEST3 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('PBI_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 4), '★★★★★★★')
    END;

    
-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC1 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST2;

ALTER TABLE IF EXISTS OG_TABLE_PC1 MODIFY COLUMN DPTS_PCH_NM 
SET MASKING POLICY TEST3;


-- 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM OG_TABLE_PC1
LIMIT 5;


-- 역할 변경
USE ROLE PBI_ROLE;


-- 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM OG_TABLE_PC1
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


---------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■ 서로 다른 열에 서로 다른 두 개 이상의 마스킹 정책 적용 가능 확인 ■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■ 다중 마스킹 정책 관리 방안 검토 ■■■■■■■■■■■■■■■■■■■■■■■■■■
----------------------------------------------------------------------------

---------------------------------------------------------
--                                                    --
--     마스킹 정책은 어느 테이블(뷰)에 부여된 상태라면,      --
--                                                    --
--                  DROP이 불가능하다.                  --
--                                                    --
--------------------------------------------------------

DROP MASKING POLICY TEST2;

-- Policy TEST2 cannot be dropped/replaced as it is associated with one or more entities.
-- 따라서, 이러한 정책들이 적용된 테이블(뷰)를 파악할 수 있어야 한다.


-----------------------------------------------
--                                           --
--     해당 마스킹 정책이 적용된 TABLE 조회      --
--                                           --
-----------------------------------------------


SELECT POLICY_NAME
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_KIND
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(policy_name => 'TEST2'));


SELECT POLICY_NAME
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_KIND
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(policy_name => 'TEST3'));


-----------------------------------------------
--                                           --
--     해당 테이블에 적용된 마스킹 정책 조회      --
--                                           --
-----------------------------------------------

  
SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(ref_entity_name => 'OG_TABLE_PC2', ref_entity_domain => 'table'));


-----------------------------------------------
--                                           --
--     해당 테이블에 적용된 마스킹 정책 회수      --
--                                           --
-----------------------------------------------


ALTER TABLE IF EXISTS MASKING_TEST2 MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS OG_TABLE_PC MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS OG_TABLE_PC1 MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS OG_TABLE_PC1 MODIFY COLUMN DPTS_PCH_NM 
UNSET MASKING POLICY;


-----------------------------------------------
--                                           --
--     해당 마스킹 정책이 적용된 TABLE 조회      --
--                                           --
-----------------------------------------------


SELECT POLICY_NAME
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_KIND
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(policy_name => 'TEST2'));

  
SELECT POLICY_NAME
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_KIND
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(policy_name => 'TEST3'));


-----------------------------------------------
--                                           --
--     해당 테이블에 적용된 마스킹 `정책` 조회    --
--                                           --
-----------------------------------------------

  
SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(ref_entity_name => 'OG_TABLE_PC1', ref_entity_domain => 'table'));


-- POLICY_STATUS - 정책 상태 종류

-- ACTIVE                                           : 활성화 
-- MULTIPLE_MASKING_POLICY_ASSIGNED_TO_THE_COLUMN   : 한 열에 다중 마스킹 정책 
-- COLUMN_IS_MISSING_FOR_SECONDARY_ARG              : 열이 빠짐
-- COLUMN_DATATYPE_MISMATCH_FOR_SECONDARY_ARG       : 열의 데이터 타입이 일치하지 않음

-- 즉, ACTIVE가 아니면 모두 오류

---------------------------------------------------------
--                                                    --
--     마스킹 정책은 어느 테이블(뷰)에 부여된 상태라면,      --
--                                                    --
--   정책이 부여된 테이블에 접근하여 정책 회수 후 DROP 가능  --
--                                                    --
--------------------------------------------------------

DROP MASKING POLICY TEST2;

-- 마스킹 정책 Drop 확인

------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ ORIGIN에 데이터를 삽입 후, DYNAMIC TABLE 새로고침 이후,  ■■■■■■■■■■■■■■■■■
--■■■■■■■■■■■■■■■         마스킹 정책이 그대로 유지되는지 확인하기          ■■■■■■■■■■■■■■■■■
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



------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■ ORIGIN에 데이터를 삽입 후, DYNAMIC TABLE 새로고침 이후,  ■■■■■■■■■■■■■■■■■
--■■■■■■■■■■■■■■■         마스킹 정책이 그대로 유지되는지 확인             ■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------



---
---



------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE_PC : 오리진에서 정책 적용하면 DT에도 적용될까? ■■■■■■■■■■■■■■■■■■
------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------
--                                                                     --
--              오리진 생성 후 정책 적용 -> Dynamic Table 확인             --
--                                                                     --
-------------------------------------------------------------------------


-- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE_PC2 TO ROLE PBI_ROLE;   


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC2 AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;

    
-- Table 확인
SELECT * FROM OG_TABLE_PC2 LIMIT 5;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC2 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST2;


-- 역할 변경
USE ROLE PBI_ROLE;


-- 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM OG_TABLE_PC2;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- Dynamic Table 생성 
CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST3
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE_PC2;

-- Dynamic Table 생성 안됨

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
--                                                                     --
-------------------------------------------------------------------------


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC2 AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;

    
-- Table 확인
SELECT * FROM OG_TABLE_PC2;


-- PBI ROLE에게 특정 테이블 조회 권한 부여
GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE_PC2 TO ROLE PBI_ROLE;   


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC2 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST2;


-- 역할 변경
USE ROLE PBI_ROLE;


-- 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM OG_TABLE_PC2;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- Dynamic Table 생성 
CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST3
TARGET_LAG = '1 hours'
REFRESH_MODE = FULL
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE_PC2;

-- Dynamic Table 생성 안됨.

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
DROP TABLE OG_TABLE_PC2;


-- Table 생성
CREATE OR REPLACE TABLE OG_TABLE_PC2 AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;

    
-- Dynamic Table 생성 
CREATE OR REPLACE DYNAMIC TABLE MASKING_TEST3
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM OG_TABLE_PC2;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS OG_TABLE_PC2 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST2;


-- 새로고침 시도
ALTER DYNAMIC TABLE MASKING_TEST3 REFRESH;


-- Dynamic Table 새로고침이 적용되지 않음.

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
--                                                                     --
-------------------------------------------------------------------------

-- Table Drop
DROP TABLE OG_TABLE_PC2;
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
ALTER TABLE IF EXISTS OG_TABLE_PC2 MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST2;


-- 새로고침 시도
ALTER DYNAMIC TABLE MASKING_TEST3 REFRESH;


-- Dynamic Table 새로고침이 적용되지 않음.

-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger MANUAL at data_timestamp 1713251825545 because of the error: 
-- SQL compilation error: 
-- Target table failed to refresh: 
-- SQL compilation error: 
-- Dynamic Table 'MASKING_TEST3' needs to be recreated because a base table changed.


-- ERROR MESSAGE 모음
SELECT
*
FROM
  TABLE (
    INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY (
      NAME_PREFIX => 'HYUNDAI_DB.PENTA_SCHEMA.', ERROR_ONLY => TRUE
    )
  )
ORDER BY
  name,
  data_timestamp;


-- Dynamic Table 새로고침 중단
ALTER DYNAMIC TABLE MASKING_TEST1 SUSPEND;
ALTER DYNAMIC TABLE MASKING_TEST2 SUSPEND;

  
------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■ TEST를 위한 OG_TABLE_PC : 오리진에서 정책 적용하면 DT에도 적용될까? ■■■■■■■■■■■■■■■■■■■
--
--■■■■■■■■■■■■■■■■                              X                                ■■■■■■■■■■■■■■■■■■
--
--                                      테이블 마다 정책을 주입
--                     정책이 주입된 ORIGIN Table을 바라보는 Dynamic Table은 에러
------------------------------------------------------------------------------------------------





-------------------------------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 마스킹 정책은 최소 권한 원칙을 지켜야 할 것이다. ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
--
--                          따라서, 마스킹 정책만 관리하는 관리자의 필요성을 느낌
-------------------------------------------------------------------------------------------------------------

-----------------------------------------------
--                                           --
--             관리자 역할  생성               --
--                                           --
-----------------------------------------------

CREATE ROLE MSK_ADMIN;                                                                              -- MSK_ADMIN 생성

GRANT ROLE MSK_ADMIN TO USER PENTA_02;                                                              -- 사용자에게 MSK_ADMIN 역할 사용 권한 부여

GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE MSK_ADMIN;                                            -- MSK_ADMIN에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE MSK_ADMIN;                                              -- MSK_ADMIN에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여

GRANT CREATE MASKING POLICY ON ALL SCHEMAS IN DATABASE HYUNDAI_DB TO ROLE MSK_ADMIN;                -- MSK_ADMIN에게 특정 DB의 모든 스키마에 마스킹 정책 생성 권한 부여
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE MSK_ADMIN;                                            -- MSK_ADMIN에게 마스킹 정책 적용 권한 부여

GRANT USAGE ON DATABASE HYUNDAI_DB TO ROLE MSK_ADMIN;                                               -- MSK_ADMIN에게 DB 활용 권한 부여
GRANT USAGE ON SCHEMA PENTA_SCHEMA TO ROLE MSK_ADMIN;                                               -- MSK_ADMIN에게 SCHEMA 활용 권한 부여

-- GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE TO ROLE MSK_ADMIN;                                      -- MSK_ADMIN에게 특정 테이블 조회 권한 부여
-- GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST1 TO ROLE MSK_ADMIN;                                 -- MSK_ADMIN에게 특정 테이블 조회 권한 부여
-- GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST2 TO ROLE MSK_ADMIN;                                 -- MSK_ADMIN에게 특정 테이블 조회 권한 부여
GRANT SELECT ON ALL TABLES IN SCHEMA HYUNDAI_DB.PENTA_SCHEMA TO ROLE MSK_ADMIN;                     -- MSK_ADMIN에게 특정 스키마 내의 모든 테이블 조회 권한 부여

GRANT SELECT ON FUTURE TABLES IN DATABASE HYUNDAI_DB TO ROLE MSK_ADMIN;                             -- MSK_ADMIN에게 미래의 대한 테이블 조회 권한 부여


USE ROLE MSK_ADMIN;

USE ROLE ACCOUNTADMIN;



















