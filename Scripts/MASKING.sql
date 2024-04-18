-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항             --
--                                           --
-----------------------------------------------


USE WAREHOUSE COMPUTE_WH;
USE DATABASE HYUNDAI_DB;
USE SCHEMA PENTA_SCHEMA;


-----------------------------------------
--■■■■■■■■■■■■■ User, Role 생성 ■■■■■■■■■■■■■
-----------------------------------------


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
--             마스킹된 데이터를 조회           --
--                                           --
-----------------------------------------------


CREATE ROLE GEN_ROLE;                                                           -- GEN_ROLE 생성
GRANT USAGE ON DATABASE HYUNDAI_DB TO ROLE GEN_ROLE;                            -- GEN_ROLE에게 DB 활용 권한 부여
GRANT USAGE ON SCHEMA PENTA_SCHEMA TO ROLE GEN_ROLE;                            -- GEN_ROLE에게 SCHEMA 활용 권한 부여

GRANT SELECT ON ALL TABLES IN SCHEMA HYUNDAI_DB.PENTA_SCHEMA TO ROLE GEN_ROLE;  -- GEN_ROLE에게 특정 스키마 내의 모든 테이블 조회 권한 부여
GRANT SELECT ON FUTURE TABLES IN DATABASE HYUNDAI_DB TO ROLE GEN_ROLE;          -- GEN_ROLE에게 미래의 대한 테이블 조회 권한 부여
GRANT SELECT ON FUTURE DYNAMIC TABLES IN DATABASE HYUNDAI_DB TO ROLE GEN_ROLE;  -- GEN_ROLE에게 미래의 대한 동적 테이블 조회 권한 부여

GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE GEN_ROLE;                         -- GEN_ROLE에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE GEN_ROLE;                           -- GEN_ROLE에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여


-----------------------------------------------
--                                           --
--           사용자에게 새로운 역할 부여         --
--                                           --
-----------------------------------------------


GRANT ROLE GEN_ROLE TO USER PENTA_02;
-- GRANT ROLE GEN_ROLE TO USER MASK;

-- 사용자에게 생성한 Role 회수
-- REVOKE ROLE GEN_ROLE FROM USER PENTA_02;
-- REVOKE ROLE GEN_ROLE FROM USER MASK;


-- 현재 사용중인 역할 조회
SELECT CURRENT_ROLE();


-- 생성한 역할의 권한을 갖는 사용자 조회 쿼리
SHOW GRANTS OF ROLE GEN_ROLE;


---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------


---------------------------------------------------------
--■■■■■■■■■■■■■■■ TEST를 위한 LOG_TABLE 생성  ■■■■■■■■■■■■■■■■
---------------------------------------------------------


CREATE OR REPLACE TABLE LOG_TABLE AS 
    SELECT * 
    FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD_LOG t1
    WHERE LENGTH(t1.dpts_pch_cd) = 6;


-- 생성 확인
SELECT * FROM LOG_TABLE LIMIT 5;


---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■ 마스킹 정책 생성 ■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------


-- 현재 사용자의 역할이 GEN_ROLE이라면 마스킹된 데이터를 조회하는 정책
CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;


-- 마스킹 정책 확인
DESC MASKING POLICY TEST1;
SHOW MASKING POLICIES IN SCHEMA PENTA_SCHEMA;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

---------------------------------------------------------
--■■■■■■■■■■■ LOG_TABLE에 마스킹 정책 적용 및 확인 ■■■■■■■■■■■■
---------------------------------------------------------


ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;


-- 현재 사용자의 역할이 GEN_ROLE이 아니므로 원본을 볼 수 있다. 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------


---------------------------------------------------------
--■■■■■■■■■■■■■■■■ 마스킹 정책 회수 및 삭제 건 ■■■■■■■■■■■■■■■■■
---------------------------------------------------------

---------------------------------------------------------
--                                                    --
--     마스킹 정책은 어느 테이블(뷰)에 부여된 상태라면,      --
--                                                    --
--                  DROP이 불가능하다.                  --
--                                                    --
--------------------------------------------------------

DROP MASKING POLICY TEST1;

-- Policy TEST1 cannot be dropped/replaced as it is associated with one or more entities.
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
  FROM TABLE(information_schema.policy_references(policy_name => 'TEST1'));


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
  FROM TABLE(information_schema.policy_references(ref_entity_name => 'LOG_TABLE', ref_entity_domain => 'table'));


-----------------------------------------------
--                                           --
--     해당 테이블에 적용된 마스킹 정책 회수      --
--                                           --
-----------------------------------------------


ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


-----------------------------------------------
--                                           --
--         해당 마스킹 정책에 대해 재조회        --
--                                           --
-----------------------------------------------


SELECT POLICY_NAME
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_KIND
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(policy_name => 'TEST1'));

  
SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(ref_entity_name => 'LOG_TABLE', ref_entity_domain => 'table'));


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


DROP MASKING POLICY TEST1;
-- 마스킹 정책 Drop 확인

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------


---------------------------------------------------------
--■■■■■ 기존 테이블의 부여된 마스킹 정책 새로운 정책으로 변경 ■■■■
---------------------------------------------------------


-- 현재 사용자의 역할이 GEN_ROLE이라면 마스킹된 데이터를 조회하는 정책
CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;


-- 문자열 중간 마스킹 정책 생성
CREATE OR REPLACE MASKING POLICY TEST_MD AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '**', SUBSTR(VAL, len(VAL) - 1, len(VAL)))
    END;


-- 마스킹 정책 TEST1 적용
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;


-- 현재 사용자의 역할이 GEN_ROLE이 아니므로 원본을 볼 수 있다. 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- 테이블의 기존 마스킹 정책인 TEST1 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


-- 마스킹 정책 TEST_MD 적용
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST_MD;


-- 현재 사용자의 역할이 GEN_ROLE이 아니므로 원본을 볼 수 있다. 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


--------------------------------------------------------
-- 마스킹 정책을 부여한 열에 새로운 마스킹 정책으로 변경할 때, 
--
--     위와 같이 기존 정책을 해제하고 새로운 정책을 부여
--        잠깐이지만 모든 마스킹이 해제된 순간이 존재
--             이를 방지하기 위한 방법이 FORCE
--------------------------------------------------------


-- FORCE 사용
ALTER TABLE LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1 FORCE;


-- 현재 사용자의 역할이 GEN_ROLE이 아니므로 원본을 볼 수 있다. 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- FORCE 사용
ALTER TABLE LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST_MD FORCE;


-- 현재 사용자의 역할이 GEN_ROLE이 아니므로 원본을 볼 수 있다. 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- 테이블의 기존 마스킹 정책인 TEST_MD 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

DROP MASKING POLICY TEST1;
DROP MASKING POLICY TEST_MD;
-- 마스킹 정책 Drop 확인

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------


---------------------------------------------------------
--■■■■■■■■■■■■■■■■ 한 테이블에 여러 마스킹 정책 ■■■■■■■■■■■■■■■■■
---------------------------------------------------------

---------------------------------------------------------
--         동일한 열에 두 개 이상의 마스킹 정책 적용 건.
---------------------------------------------------------

-- 현재 사용자의 역할이 GEN_ROLE이라면 마스킹된 데이터를 조회하는 정책
CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;


-- 문자열 중간 마스킹 정책 생성
CREATE OR REPLACE MASKING POLICY TEST2 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '**', SUBSTR(VAL, len(VAL) - 1, len(VAL)))
    END;

    
-- 마스킹 정책 적용
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;

ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST2;


-- 한 열에 서로 다른 두 마스킹 정책을 부여할 수 없다.

-- Specified column already attached to another masking policy. 
-- A column cannot be attached to multiple masking policies. 
-- Please drop the current association in order to attach a new masking policy.


-- 마스킹 정책 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


---------------------------------------------------------
--         동일한 열에 두 개 이상의 마스킹 정책 적용 건.
--                      불 가 능
---------------------------------------------------------


---------------------------------------------------------
--        서로 다른 두 열에 동일한 마스킹 정책 적용 건.
---------------------------------------------------------

-- 현재 사용자의 역할이 GEN_ROLE이라면 마스킹된 데이터를 조회하는 정책
-- CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
--     CASE
--         WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
--             THEN VAL
--         ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
--     END;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;

ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_NM 
SET MASKING POLICY TEST1;


-- 현재 사용자의 역할이 GEN_ROLE이 아니므로 원본을 볼 수 있다. 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;

-- 마스킹 정책 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_NM 
UNSET MASKING POLICY;

---------------------------------------------------------
--        서로 다른 두 열에 동일한 마스킹 정책 적용 건.
--                      적용 확인 
---------------------------------------------------------

---------------------------------------------------------
--        서로 다른 두 열에 서로 다른 마스킹 정책 적용 건.
---------------------------------------------------------

-- 현재 사용자의 역할이 GEN_ROLE이라면 마스킹된 데이터를 조회하는 정책
-- CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
--     CASE
--         WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
--             THEN VAL
--         ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
--     END;


-- 문자열 중간 마스킹 정책 생성
-- CREATE OR REPLACE MASKING POLICY TEST2 AS (VAL STRING) RETURNS STRING ->
--     CASE
--         WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
--             THEN VAL
--         ELSE CONCAT(SUBSTR(VAL, 0, 2), '**', SUBSTR(VAL, len(VAL) - 1, len(VAL)))
--     END;


-- 마스킹 정책 적용
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;

ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_NM 
SET MASKING POLICY TEST2;


-- 현재 사용자의 역할이 GEN_ROLE이 아니므로 원본을 볼 수 있다. 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- 마스킹 정책 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_NM 
UNSET MASKING POLICY;


---------------------------------------------------------
--        서로 다른 두 열에 서로 다른 마스킹 정책 적용 건.
--                      적용 확인 
---------------------------------------------------------

-----------------------------------------------
--                                           --
--       다중 마스킹 정책에 대해 관리할 때        --
--                                           --
--       다음 쿼리를 실행하여 파악할 수 있다.     --
--                                           --
-----------------------------------------------


SELECT POLICY_NAME
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_KIND
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(policy_name => 'TEST1'));

  
SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME
      , REF_COLUMN_NAME
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(ref_entity_name => 'LOG_TABLE', ref_entity_domain => 'table'));

  
---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

---------------------------------------------------------
--■■■■■■■■■■■■■ 데이터 삽입 시 마스킹 정책 적용 건 ■■■■■■■■■■■■■
---------------------------------------------------------

-- 이전에 생성한 마스킹 정책 그대로 사용 예정

-- CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
--     CASE
--         WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
--             THEN VAL
--         ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
--     END;


-- LOG_TABLE에 마스킹 정책 부여 
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;


-- 데이터 삽입
INSERT INTO LOG_TABLE (DPTS_PCH_CD, DPTS_PCH_NM, BCD_LEN) VALUES ('999998', '안녕인', NULL);


-- 삽입된 데이터 확인
SELECT * FROM LOG_TABLE WHERE DPTS_PCH_CD = '999998';


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인 X
-- 마스킹된 데이터를 조회하므로 '999998'이 조회가 안된다.
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
WHERE DPTS_PCH_CD = '999998';


-- 다른 열을 검색하여 조회
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
WHERE DPTS_PCH_NM = '안녕인';


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- 마스킹 정책 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

--
--

---------------------------------------------------------
--■■■■■■■■■■■■■■■■ 마스킹 정책과 Dynamic Table ■■■■■■■■■■■■■■■
---------------------------------------------------------

---------------------------------------------------------
--                   Dynamic Table 생성                 --
---------------------------------------------------------

CREATE OR REPLACE DYNAMIC TABLE DT_MASKING
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM LOG_TABLE;

ALTER DYNAMIC TABLE DT_MASKING SUSPEND;

SELECT * FROM DT_MASKING LIMIT 5;

---------------------------------------------------------
--                Dynamic Table 생성 [完]               --
---------------------------------------------------------


---------------------------------------------------------
--         Dynamic Table에도 마스킹 정책 적용 확인         --
---------------------------------------------------------

-- 이전에 생성한 마스킹 정책 그대로 사용 예정

-- CREATE OR REPLACE MASKING POLICY TEST1 AS (VAL STRING) RETURNS STRING ->
--     CASE
--         WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
--             THEN VAL
--         ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
--     END;


-- 마스킹 정책 TEST1 적용
ALTER TABLE IF EXISTS DT_MASKING MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;


---------------------------------------------------------
--            ALTER DYNAMIC TABLE ~ 명령문은            --
--      새로고침 중지 및 실행, LAG 설정에만 사용한다.        --
--                                                     --
--       따라서 마스킹 정책 적용하려면 DYNAMIC은 생략한다.   --
---------------------------------------------------------
-- ALTER DYNAMIC TABLE IF EXISTS DT_MASKING MODIFY COLUMN DPTS_PCH_CD 
-- SET MASKING POLICY TEST1;



-- 현재 사용자의 역할이 GEN_ROLE이 아니므로 원본을 볼 수 있다. 
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM DT_MASKING
LIMIT 5;


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM DT_MASKING
LIMIT 5;


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- 테이블의 기존 마스킹 정책인 TEST1 회수이지만, 
-- 다음 테스트를 위해 생략
-- ALTER TABLE IF EXISTS DT_MASKING MODIFY COLUMN DPTS_PCH_CD 
-- UNSET MASKING POLICY;


---------------------------------------------------------
--      Dynamic Table에도 마스킹 정책 적용 확인 [完]       --
---------------------------------------------------------

---------------------------------------------------------
--       Dynamic Table Refresh에도 마스킹 정책 확인       --
---------------------------------------------------------

-- LOG_TABLE에 데이터 삽입
INSERT INTO LOG_TABLE (DPTS_PCH_CD, DPTS_PCH_NM, BCD_LEN) VALUES ('999997', '다이나믹테이블', NULL);

-- Dynamic Table Refresh
ALTER DYNAMIC TABLE DT_MASKING REFRESH;


-- 삽입된 데이터 확인
SELECT * FROM LOG_TABLE WHERE DPTS_PCH_CD = '999997';
SELECT * FROM DT_MASKING WHERE DPTS_PCH_CD = '999997';


-- 역할 변경
USE ROLE GEN_ROLE;


-- 현재 사용자의 역할이 GEN_ROLE이므로 마스킹된 데이터 확인 X
-- 마스킹된 데이터를 조회하므로 '999997'이 조회가 안된다.
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM DT_MASKING
WHERE DPTS_PCH_CD = '999997';


-- 다른 열을 검색하여 조회
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM DT_MASKING
WHERE DPTS_PCH_NM = '다이나믹테이블';


-- 역할 변경
USE ROLE ACCOUNTADMIN;


-- 마스킹 정책 회수
ALTER TABLE IF EXISTS DT_MASKING MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

---------------------------------------------------------
--     Dynamic Table Refresh에도 마스킹 정책 확인  [完]    --
---------------------------------------------------------


---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------


---------------------------------------------------------
--■■ 마스킹 정책이 적용된 LOG_TABLE 바라보는 DYNAMIC TABLE ■■
---------------------------------------------------------

-------------------------------------------------------
--                                                   --
--  마스킹 정책 적용된 LOG_TABLE -> Dynamic Table 생성  --
--                                                   --
-------------------------------------------------------

-- CREATE OR REPLACE TABLE LOG_TABLE AS 
--     SELECT * 
--     FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD_LOG t1
--     WHERE LENGTH(t1.dpts_pch_cd) = 6;

-- LOG_TABLE에 마스킹 정책 부여
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;


-- DYNAMIC TABLE 생성 시도
CREATE OR REPLACE DYNAMIC TABLE DT_MASKING_2
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM LOG_TABLE;

-------------------------------------------------------
--              Dynamic Table 생성 안됨               --
-------------------------------------------------------

-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger INITIAL at data_timestamp 1713250826808 because of the error: 
-- SQL compilation error: Target table failed to refresh: 
-- SQL compilation error: Dynamic Table 'DT_MASKING_2' needs to be recreated because a base table changed.


-- DYNAMIC TABLE FULL REFRESH MODE 생성 시도
CREATE OR REPLACE DYNAMIC TABLE DT_MASKING_2
TARGET_LAG = '1 hours'
REFRESH_MODE = FULL
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM LOG_TABLE;


-------------------------------------------------------
--              Dynamic Table 생성 안됨               --
-------------------------------------------------------

-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger INITIAL at data_timestamp 1713250826808 because of the error: 
-- SQL compilation error: Target table failed to refresh: 
-- SQL compilation error: Dynamic Table 'DT_MASKING_2' needs to be recreated because a base table changed.



-- LOG_TABLE의 마스킹 정책 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


-------------------------------------------------------
--                                                   --
--  마스킹 정책 적용된 LOG_TABLE -> Dynamic Table 생성  --
--                                                   --
--                     생성 불가                      --
--                                                   --
-------------------------------------------------------


---------------------------------------------------------
--■■ LOG, DT 먼저 생성 후, LOG에 정책 적용 후 DT Refresh  ■■
---------------------------------------------------------


-- CREATE OR REPLACE TABLE LOG_TABLE AS 
--     SELECT * 
--     FROM HYUNDAI_DB.HDHS_PD.IM_DPTS_PCH_CD_LOG t1
--     WHERE LENGTH(t1.dpts_pch_cd) = 6;


-- DYNAMIC TABLE 생성
CREATE OR REPLACE DYNAMIC TABLE DT_MASKING_3
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM LOG_TABLE;


-- LOG_TABLE에 마스킹 정책 부여
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;


-- 자동 새로고침 중지
ALTER DYNAMIC TABLE DT_MASKING_3 SUSPEND;


-- 새로고침 시도
ALTER DYNAMIC TABLE DT_MASKING_3 REFRESH;

-------------------------------------------------------
--       Dynamic Table 새로고침이 적용되지 않음.        --
-------------------------------------------------------

-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger MANUAL at data_timestamp 1713250979771 because of the error: SQL compilation error: 
-- Target table failed to refresh: SQL execution error: 
-- Dynamic table 'HYUNDAI_DB.PENTA_SCHEMA.DT_MASKING_3' is no longer incrementalizable because of reason 
-- 'Dynamic Tables only support 'FULL' refresh mode for sources with 'MASKING POLICY'. 
-- Either remove the policy from 'HYUNDAI_DB.PENTA_SCHEMA.OG_TABLE_PC' or recreate the Dynamic Table.'. 
-- Please recreate the dynamic table.


-- LOG_TABLE의 마스킹 정책 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


-- DROP 후 FULL REFRESH MODE DYNAMIC TABLE 생성 
DROP DYNAMIC TABLE DT_MASKING_3;


CREATE OR REPLACE DYNAMIC TABLE DT_MASKING_3
TARGET_LAG = '1 hours'
REFRESH_MODE = FULL
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM LOG_TABLE;


-- LOG_TABLE에 마스킹 정책 부여
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST1;


-- 자동 새로고침 중지
ALTER DYNAMIC TABLE DT_MASKING_3 SUSPEND;

-- 새로고침 시도
ALTER DYNAMIC TABLE DT_MASKING_3 REFRESH;


-------------------------------------------------------
--            Dynamic Table Refresh 안됨              --
-------------------------------------------------------


-- ERROR LOG
-- Failed to refresh dynamic table with refresh_trigger INITIAL at data_timestamp 1713250826808 because of the error: 
-- SQL compilation error: Target table failed to refresh: 
-- SQL compilation error: Dynamic Table 'DT_MASKING_3' needs to be recreated because a base table changed.


-- LOG_TABLE의 마스킹 정책 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


DROP TABLE DT_MASKING_3;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■--
---------------------------------------------------------


----------------------------------------------------------
--■■■■■■■ 마스킹 정책은 최소 권한 원칙을 지켜야 할 것이다. ■■■■■■■
--
--     따라서, 마스킹 정책만 관리하는 관리자의 필요성을 느낌
----------------------------------------------------------

-----------------------------------------------
--                                           --
--              관리자 역할 생성               --
--                                           --
-----------------------------------------------

CREATE ROLE MSK_ADMIN;                                                                              -- MSK_ADMIN 생성

GRANT ROLE MSK_ADMIN TO USER PENTA_02;                                                              -- 사용자에게 MSK_ADMIN 역할 사용 권한 부여

GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE MSK_ADMIN;                                            -- MSK_ADMIN에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE MSK_ADMIN;                                              -- MSK_ADMIN에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여

-- GRANT CREATE MASKING POLICY ON ALL SCHEMAS IN DATABASE HYUNDAI_DB TO ROLE MSK_ADMIN;                -- MSK_ADMIN에게 특정 DB의 모든 스키마에 마스킹 정책 생성 권한 부여
GRANT CREATE MASKING POLICY ON SCHEMA PENTA_SCHEMA TO ROLE MSK_ADMIN;                               -- MSK_ADMIN에게 특정 스키마에 마스킹 정책 생성 권한 부여
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE MSK_ADMIN;                                            -- MSK_ADMIN에게 마스킹 정책 적용 권한 부여

GRANT USAGE ON DATABASE HYUNDAI_DB TO ROLE MSK_ADMIN;                                               -- MSK_ADMIN에게 DB 활용 권한 부여
GRANT USAGE ON SCHEMA PENTA_SCHEMA TO ROLE MSK_ADMIN;                                               -- MSK_ADMIN에게 SCHEMA 활용 권한 부여

-- GRANT SELECT ON TABLE PENTA_SCHEMA.OG_TABLE TO ROLE MSK_ADMIN;                                      -- MSK_ADMIN에게 특정 테이블 조회 권한 부여
-- GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST1 TO ROLE MSK_ADMIN;                                 -- MSK_ADMIN에게 특정 테이블 조회 권한 부여
-- GRANT SELECT ON TABLE PENTA_SCHEMA.MASKING_TEST2 TO ROLE MSK_ADMIN;                                 -- MSK_ADMIN에게 특정 테이블 조회 권한 부여
GRANT SELECT ON ALL TABLES IN SCHEMA HYUNDAI_DB.PENTA_SCHEMA TO ROLE MSK_ADMIN;                     -- MSK_ADMIN에게 특정 스키마 내의 모든 테이블 조회 권한 부여

GRANT SELECT ON FUTURE TABLES IN DATABASE HYUNDAI_DB TO ROLE MSK_ADMIN;                             -- MSK_ADMIN에게 미래의 대한 테이블 조회 권한 부여
GRANT SELECT ON FUTURE DYNAMIC TABLES IN DATABASE HYUNDAI_DB TO ROLE MSK_ADMIN;                     -- MSK_ADMIN에게 미래의 대한 동적 테이블 조회 권한 부여

-----------------------------------------------
--                                           --
--          생성한 관리자 역할 TEST.            --
--                                           --
-----------------------------------------------

USE ROLE MSK_ADMIN;


-- MSK_ADMIN이 정확히 권한이 부여됬는지 확인용 정책 생성 쿼리 
CREATE OR REPLACE MASKING POLICY TEST_BY_MSK_ADMIN AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '********')
    END;
-- 정상 생성 확인


-- 마스킹 정책 테이블에 적용
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST_BY_MSK_ADMIN;


SELECT * FROM LOG_TABLE LIMIT 5;

-- 마스킹 정책 정상 적용 확인 
USE ROLE GEN_ROLE;

SELECT * FROM LOG_TABLE LIMIT 5;

-- 관리자로 되돌아가기
USE ROLE MSK_ADMIN;


-- 마스킹 정책 회수
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;


-- 마스킹 정책 제거
DROP MASKING POLICY TEST_BY_MSK_ADMIN;

USE ROLE ACCOUNTADMIN;


-----------------------------------------------
--                                           --
--         생성한 관리자 역할 TEST  완료       --
--                                           --
-----------------------------------------------


