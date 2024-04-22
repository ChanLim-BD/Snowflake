-----------------------------------------------
--                                           --
--         기본 Snowflake 설정 사항            --
--                                           --
-----------------------------------------------

USE WAREHOUSE COMPUTE_WH;
USE DATABASE HYUNDAI_DB;
USE SCHEMA PENTA_SCHEMA;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■ User, Role 생성 ■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

-- 1. 보안 또는 개인정보보호 담당자를 위한 사용자 지정 역할 즉, MASKING_ADMIN에 `마스킹 정책 관리 권한`을 부여합니다.
-- 2. 알맞은 사용자에게 사용자 지정 역할을 부여합니다.
-- 3. 보안 또는 개인정보보호 담당자는 마스킹 정책을 생성 및 정의하고 민감한 데이터가 있는 열에 마스킹 정책을 적용합니다.

-----------------------------------------------
--                                           --
--                  사용자 생성                --
--                                           --
-----------------------------------------------

-- CREATE USER EX_USER; 
-- PASSWORD='mask'
-- MUST_CHANGE_PASSWORD = TRUE
-- DEFAULT_ROLE = --;

-- SHOW USERS;
-- DESC USER MASK;
-- DROP USER MASK;

-----------------------------------------------
--                                           --
--              관리자 역할 생성               --
--                                           --
-----------------------------------------------

CREATE ROLE MASKING_ADMIN;                                                                    -- MASKING_ADMIN 생성.

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE MASKING_ADMIN;                                    -- MASKING_ADMIN에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여.
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE MASKING_ADMIN;                                  -- MASKING_ADMIN에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 (컴퓨팅 사이즈 변경 같은)

GRANT CREATE MASKING POLICY ON SCHEMA PENTA_SCHEMA TO ROLE MASKING_ADMIN;                     -- MASKING_ADMIN에게 특정 스키마에서 마스킹 정책 생성 권한 부여.
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE MASKING_ADMIN;                                  -- MASKING_ADMIN에게 마스킹 정책 적용 권한 부여.
GRANT CREATE TAG ON SCHEMA PENTA_SCHEMA TO ROLE MASKING_ADMIN;                                -- MASKING_ADMIN에게 TAG 생성 권한 부여.

-- 스키마의 모든 오브젝트에 대해 작업하려면 상위 데이터베이스 및 스키마에 대한 USAGE 권한도 필요.

GRANT USAGE ON DATABASE HYUNDAI_DB TO ROLE MASKING_ADMIN;                                     -- MASKING_ADMIN에게 특정 DB 활용 권한 부여.
GRANT USAGE ON SCHEMA PENTA_SCHEMA TO ROLE MASKING_ADMIN;                                     -- MASKING_ADMIN에게 특정 SCHEMA 활용 권한 부여.

-- 마스킹 관리자가 테이블의 데이터를 조회할 일이 있다면, 부여하는 권한.
-- 민감한 데이터 유출 위험으로 해당 권한은 부여하지 않을 것으로 판단.
-- GRANT SELECT ON ALL TABLES IN SCHEMA HYUNDAI_DB.PENTA_SCHEMA TO ROLE MASKING_ADMIN;           -- MASKING_ADMIN에게 특정 스키마 내의 모든 테이블 조회 권한 부여.
-- GRANT SELECT ON FUTURE TABLES IN DATABASE HYUNDAI_DB TO ROLE MASKING_ADMIN;                   -- MASKING_ADMIN에게 미래의 대한 테이블 조회 권한 부여.
-- GRANT SELECT ON FUTURE DYNAMIC TABLES IN DATABASE HYUNDAI_DB TO ROLE MASKING_ADMIN;           -- MASKING_ADMIN에게 미래의 대한 동적 테이블 조회 권한 부여.

GRANT ROLE MASKING_ADMIN TO USER PENTA_02;                                                    -- 특정 사용자에게 MASKING_ADMIN 역할 사용 권한 부여.
-- GRANT ROLE MASKING_ADMIN TO USER ex_user;

-----------------------------------------------
--                                           --
--            일반 사용자 역할 생성             --
--                                           --
--          즉, 마스킹된 데이터를 조회           --
--                                           --
-----------------------------------------------

CREATE ROLE GEN_ROLE;                                                           -- GEN_ROLE 생성

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE GEN_ROLE;                           -- GEN_ROLE에게 COMPUTE_WH명의 웨어하우스 사용 권한 부여
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE GEN_ROLE;                         -- GEN_ROLE에게 COMPUTE_WH명의 웨어하우스 동작 권한 부여 (컴퓨팅 사이즈 변경 같은) 

GRANT USAGE ON DATABASE HYUNDAI_DB TO ROLE GEN_ROLE;                            -- GEN_ROLE에게 DB 활용 권한 부여
GRANT USAGE ON SCHEMA PENTA_SCHEMA TO ROLE GEN_ROLE;                            -- GEN_ROLE에게 SCHEMA 활용 권한 부여

GRANT SELECT ON ALL TABLES IN SCHEMA HYUNDAI_DB.PENTA_SCHEMA TO ROLE GEN_ROLE;  -- GEN_ROLE에게 특정 스키마 내의 모든 테이블 조회 권한 부여
GRANT SELECT ON FUTURE TABLES IN DATABASE HYUNDAI_DB TO ROLE GEN_ROLE;          -- GEN_ROLE에게 미래의 대한 테이블 조회 권한 부여
GRANT SELECT ON FUTURE DYNAMIC TABLES IN DATABASE HYUNDAI_DB TO ROLE GEN_ROLE;  -- GEN_ROLE에게 미래의 대한 동적 테이블 조회 권한 부여


-- 사용자에게 생성한 Role 권한 부여
GRANT ROLE GEN_ROLE TO USER PENTA_02;                                           -- 특정 사용자에게 MASKING_ADMIN 역할 사용 권한 부여.
-- GRANT ROLE GEN_ROLE TO USER ex_user;

-- 사용자에게 생성한 Role 권한 회수
-- REVOKE ROLE GEN_ROLE FROM USER PENTA_02;
-- REVOKE ROLE GEN_ROLE FROM USER ex_user;

-- 생성한 역할의 권한을 갖는 사용자 조회 쿼리
SHOW GRANTS OF ROLE GEN_ROLE;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■--
---------------------------------------------------------

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■ 테스트 진행 전 ■■■■■■■■■■■■■■■■■■■■■--
--
-- ACCOUNTADMIN 역할은 테이블 생성, 삭제 및 데이터 삽입 역할 담당
-- MASKING_ADMIN 역할은 마스킹 정책 생성, 삭제 및 열 적용 담당
-- GEN_ROLE 역할은 마스킹된 테이블 조회 담당
--                                      
-- 다만, 빠른 테스트를 위해 ACCOUNTADMIN 역할로 마스킹 정책도
-- 생성, 삭제 및 열 적용을 담당.
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
--■■■■■■■■■■■■■■■■■■■■■ 마스킹 정책들 생성 ■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

CREATE MASKING POLICY IF NOT EXISTS TEST1 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '****')
    END;

CREATE MASKING POLICY IF NOT EXISTS TEST2 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 3), '@@@@')
    END;

CREATE MASKING POLICY IF NOT EXISTS TEST3 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 4), '●●●●')
    END;

CREATE MASKING POLICY IF NOT EXISTS TEST4 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 2), '★★', SUBSTR(VAL, len(VAL) - 1, len(VAL)))
    END;

CREATE MASKING POLICY IF NOT EXISTS TEST5 AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT('★★', SUBSTR(VAL, len(VAL) - 4, len(VAL)))
    END;

CREATE MASKING POLICY IF NOT EXISTS TEST6 AS (VAL NUMBER) RETURNS NUMBER ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE 0
    END;

-- 생성한 마스킹 정책들 확인
-- 마스킹 정책은 스키마에 종속되므로 
-- 마스킹 정책만 생성하는 스키마 생성 고려
SHOW MASKING POLICIES;
SHOW MASKING POLICIES IN SCHEMA PENTA_SCHEMA;

---------------------------------------------------------
--■■■■■■■■■■■■■ LOG_TABLE - 마스킹 정책 TESTs  ■■■■■■■■■■■■■■
---------------------------------------------------------

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

-----------------------------------------------
--     특정 마스킹 정책이 적용된 TABLE 조회      --
-----------------------------------------------

SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME AS REF_TABLE
      , REF_COLUMN_NAME AS REF_COLUMN      
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(policy_name => 'TEST1'));

-----------------------------------------------
--     특정 테이블에 적용된 마스킹 정책 조회      --
-----------------------------------------------

SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME AS REF_TABLE
      , REF_COLUMN_NAME AS REF_COLUMN
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(ref_entity_name => 'LOG_TABLE', ref_entity_domain => 'table'));


SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.POLICY_REFERENCES;
  
-----------------------------------------------------------------------
--  위의 조회 명령어는 특정 '정책' 또는 'Table(View)를 지정하고 조회할 수 있다.
--  따라서, 정책 이름을 모른다면 이를 이용할 수 없다. 즉, 관리하기 어렵다.
-----------------------------------------------------------------------

-- 테이블에 직접 한 열에 여러 마스킹 정책을 부여할 수 없다.
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST3;

-- FORCE 키워드를 포함하면 곧바로 마스킹 정책을 변경할 수 있다.
-- 다만, 이 명령도 다중 마스킹 정책을 적용할 수 없다.
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
SET MASKING POLICY TEST3 FORCE;

-- 테이블에 직접 부여된 마스킹 정책을 제거하려면 다음과 같다.
-- 특정 열에 대한 마스킹 정책을 UNSET.
ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_CD 
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS LOG_TABLE MODIFY COLUMN DPTS_PCH_NM 
UNSET MASKING POLICY;

-- 역할 변경
USE ROLE GEN_ROLE;

-- 마스킹이 해제되었는 지 확인한다.
SELECT DPTS_PCH_CD, DPTS_PCH_NM 
FROM LOG_TABLE
LIMIT 5;

-- 역할 변경
USE ROLE ACCOUNTADMIN;

---------------------------------------------------------------
--■■■■■■■■■■■■■■■■■ 다량의 마스킹 정책 관리 방안 ■■■■■■■■■■■■■■■■■■■■■■
--
-- 1. Information Schema는 빠른 대신 조회할 객체를 지정해야 한다.
-- 2. Account Usage는 모든 객체에 대해 조회할 수 있지만 반영이 느리다.

-- 결론, 마스킹 정책 생성 및 조회할 때는 I.S를 활용하는 것이 좋고,
-- 모든 정책을 설정한 후, 추후에 전반적인 상황을 볼 때 A.U를 사용하자.
---------------------------------------------------------------

------------------------------------
--■■ 마스킹 정책 조회 및 레퍼런스 체크 ■■
------------------------------------

-- 마스킹 정책 조회
SHOW MASKING POLICIES;


-- 특정 정책이 부여된 테이블 조회
SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME AS REF_TABLE
      , REF_COLUMN_NAME AS REF_COLUMN      
      , POLICY_STATUS
  FROM (TABLE(information_schema.policy_references(policy_name => 'TEST1')));

SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME AS REF_TABLE
      , REF_COLUMN_NAME AS REF_COLUMN      
      , POLICY_STATUS
  FROM (TABLE(information_schema.policy_references(policy_name => 'TEST2')));
  
-- 특정 테이블에 부여된 정책 확인 명령
SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME AS REF_TABLE
      , REF_COLUMN_NAME AS REF_COLUMN
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(ref_entity_name => 'LOG_TABLE', ref_entity_domain => 'table'));


------------------------------------
--■■ account usage를 통해서 전체 현황 조회 ■■
------------------------------------
-- Snowflake account_usage의 내부 메타데이터 저장소에서 데이터를 추출하는 프로세스로 인해
-- 전체 마스킹 정책의 현황을 조회할 때 활용하는 것을 추천.


-- account usage로 마스킹 정책 조회
SELECT POLICY_NAME, POLICY_OWNER, POLICY_CATALOG, POLICY_SCHEMA
FROM snowflake.account_usage.masking_policies
WHERE DELETED IS NULL
AND POLICY_SCHEMA = 'PENTA_SCHEMA'
ORDER BY POLICY_NAME;


-- 정책 부여 및 회수 상황 반영이 느림.
SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME AS REF_TABLE
      , REF_COLUMN_NAME AS REF_COLUMN
      , POLICY_STATUS
  FROM SNOWFLAKE.ACCOUNT_USAGE.POLICY_REFERENCES;

  
SELECT *
  FROM SNOWFLAKE.ACCOUNT_USAGE.POLICY_REFERENCES
  WHERE REF_SCHEMA_NAME = 'PENTA_SCHEMA';
  

-- 현재 생성한 정책들 중 지정한 테이블에 부여된 정책 확인
WITH MaskingPolicies AS (
    SELECT POLICY_NAME, POLICY_OWNER, POLICY_CATALOG, POLICY_SCHEMA
    FROM snowflake.account_usage.masking_policies
    WHERE DELETED IS NULL
    AND POLICY_SCHEMA = 'PENTA_SCHEMA'
    ORDER BY POLICY_NAME
),
PolicyReferences AS (
    SELECT POLICY_NAME
          , POLICY_KIND
          , REF_ENTITY_NAME AS REF_TABLE
          , REF_COLUMN_NAME AS REF_COLUMN
          , POLICY_STATUS
    FROM snowflake.account_usage.policy_references
    WHERE REF_SCHEMA_NAME = 'PENTA_SCHEMA'
)
SELECT mp.POLICY_NAME, 
       mp.POLICY_OWNER, 
       mp.POLICY_CATALOG, 
       mp.POLICY_SCHEMA,
       pr.POLICY_KIND,
       pr.REF_TABLE,
       pr.REF_COLUMN,
       pr.POLICY_STATUS
FROM MaskingPolicies mp
LEFT OUTER JOIN PolicyReferences pr
ON mp.POLICY_NAME = pr.POLICY_NAME
ORDER BY mp.POLICY_NAME;

-- DYNAMIC_POLICY View 생성 
CREATE VIEW IF NOT EXISTS dynamic_policy_view AS
WITH MaskingPolicies AS (
    SELECT POLICY_NAME, POLICY_OWNER, POLICY_CATALOG, POLICY_SCHEMA
    FROM snowflake.account_usage.masking_policies
    WHERE DELETED IS NULL
    AND POLICY_SCHEMA = 'PENTA_SCHEMA'
    ORDER BY POLICY_NAME
),
PolicyReferences AS (
    SELECT POLICY_NAME
          , POLICY_KIND
          , REF_ENTITY_NAME AS REF_TABLE
          , REF_COLUMN_NAME AS REF_COLUMN
          , POLICY_STATUS
    FROM snowflake.account_usage.policy_references
    WHERE REF_SCHEMA_NAME = 'PENTA_SCHEMA'
)
SELECT mp.POLICY_NAME, 
       mp.POLICY_OWNER, 
       mp.POLICY_CATALOG, 
       mp.POLICY_SCHEMA,
       pr.POLICY_KIND,
       pr.REF_TABLE,
       pr.REF_COLUMN,
       pr.POLICY_STATUS
FROM MaskingPolicies mp
LEFT OUTER JOIN PolicyReferences pr
ON mp.POLICY_NAME = pr.POLICY_NAME
ORDER BY mp.POLICY_NAME;

-- View 호출
SELECT * FROM dynamic_policy_view;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

--◆◆◆◆◆◆◆◆◆◆◆◆◆◆  문제점  ◆◆◆◆◆◆◆◆◆◆◆◆◆◆

--    마스킹할 데이터는 즉, 주민번호, 전화번호와 같은 개인정보이다.
--   예를 들어, 여러 테이블에 전화번호는 010-xxxx-xxxx 형식인 것 처럼,
--
--   즉, 데이터의 형식은 대체로 지정되어 있고 한정적이다.
--   하나의 정책을 이름표처럼 붙여놓고 이름 따라 정책을 부여한다면?
--   이후 정책을 수정할 때 수십개의 테이블에 일일이 해제하고 다시 부여하는 과정 생략 가능 
--

-- -> TAG를 도입해보자.
-- -> 또한, 이것이 권장사항이다.

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■ TAG Test를 위한 준비 ■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

CREATE TABLE IF NOT EXISTS HYUNDAI_DB.PENTA_SCHEMA.CUSTOMERS(CUSTID INT, NAME STRING, PII VARCHAR, EMAIL VARCHAR, PHONE VARCHAR);
CREATE TABLE IF NOT EXISTS HYUNDAI_DB.PENTA_SCHEMA.EMPLOYEES(EMPID INT, NAME STRING, PII VARCHAR, EMAIL VARCHAR, PHONE VARCHAR);

INSERT INTO HYUNDAI_DB.PENTA_SCHEMA.CUSTOMERS VALUES
(1, 'JACK', '900101-1100223', 'abc@naver.com', '010-1111-1111'), 
(2, 'JACKEY', '900102-1100223', 'cds@naver.com', '010-1111-1112');

INSERT INTO HYUNDAI_DB.PENTA_SCHEMA.EMPLOYEES VALUES
(1, 'SAM', '900101-1100224', 'abc@naver.com', '010-1111-1113'), 
(2, 'SAMEY', '911102-1100223', 'cds@naver.com', '010-1111-1114');


CREATE MASKING POLICY IF NOT EXISTS PII_MASK AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 8), '●●●●●●')
    END;

CREATE MASKING POLICY IF NOT EXISTS PHONE_MASK AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 4), '****', SUBSTR(VAL, len(VAL) - 4, len(VAL)))
    END;

-----------------------------------------------------------
--■■■■■■■■■■■■■■■■ TAG 생성 및 마스킹 정책 부여■■■■■■■■■■■■■■■■■■■
-----------------------------------------------------------

CREATE TAG IF NOT EXISTS PENTA_SCHEMA.PII_TAG;
CREATE TAG IF NOT EXISTS PENTA_SCHEMA.PHONE_TAG;

ALTER TAG PII_TAG SET MASKING POLICY PII_MASK;
ALTER TAG PHONE_TAG SET MASKING POLICY PHONE_MASK;

ALTER TABLE HYUNDAI_DB.PENTA_SCHEMA.CUSTOMERS 
MODIFY COLUMN PII SET TAG PII_TAG = 'PII';
ALTER TABLE HYUNDAI_DB.PENTA_SCHEMA.CUSTOMERS 
MODIFY COLUMN PHONE SET TAG PHONE_TAG = 'PHONE';

ALTER TABLE HYUNDAI_DB.PENTA_SCHEMA.EMPLOYEES 
MODIFY COLUMN PII SET TAG PII_TAG = 'PII';
ALTER TABLE HYUNDAI_DB.PENTA_SCHEMA.EMPLOYEES 
MODIFY COLUMN PHONE SET TAG PHONE_TAG = 'PHONE';

USE ROLE GEN_ROLE;
SELECT * FROM CUSTOMERS;
SELECT * FROM EMPLOYEES;
USE ROLE ACCOUNTADMIN;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■ 정책 수정 시, ■■■■■■■■■■■■■■■■■■■■■■■
-- TAG에 걸린 정책만 잠시 해제하고 수정한 다음 다시 설정하면
--   이전처럼 모든 테이블에 부여한 정책을 회수할 필요 없이
--          한번에 수정된 정책을 적용할 수 있다.
---------------------------------------------------------

-- PII의 새로운 마스킹 정책
CREATE MASKING POLICY IF NOT EXISTS PII_MASK_NEW AS (VAL STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() NOT IN ('GEN_ROLE') 
            THEN VAL
        ELSE CONCAT(SUBSTR(VAL, 0, 8), '******')
    END;

-- TAG에 부여된 정책을 새로운 정책으로 수정
ALTER TAG PII_TAG SET MASKING POLICY PII_MASK_NEW FORCE;

USE ROLE GEN_ROLE;
SELECT * FROM CUSTOMERS;
SELECT * FROM EMPLOYEES;
USE ROLE ACCOUNTADMIN;

-----------------------------------------------------------------
--     여러 정책을 한번에 설정할 수 있는 기능이 있다면?
--    -> 한정적인 조건 하에서 가능(정책마다 데이터 유형이 달라야 한다.)
-----------------------------------------------------------------

----------------------------------------
--■■ TAG 마스킹 정책 조회 및 레퍼런스 체크 ■■
----------------------------------------
SHOW TAGS;

SELECT *
  from table(HYUNDAI_DB.information_schema.tag_references_all_columns('CUSTOMERS', 'table'));
  
SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME AS REF_TABLE
      , REF_COLUMN_NAME AS REF_COLUMN
      , POLICY_STATUS
  FROM TABLE(information_schema.policy_references(ref_entity_name => 'CUSTOMERS', ref_entity_domain => 'table'));

SELECT POLICY_NAME
      , POLICY_KIND
      , REF_ENTITY_NAME AS REF_TABLE
      , REF_COLUMN_NAME AS REF_COLUMN      
      , POLICY_STATUS
  FROM (TABLE(information_schema.policy_references(policy_name => 'PII_MASK_NEW')));
  
------------------------------------
--■■ account usage를 통해서 전체 현황 조회 ■■
------------------------------------
-- Tag가 어디 테이블의 컬럼에 부여되어 있는 지 전체적으로 확인할 수 있다.
-- 또한 해당 Tag는 어떤 마스킹 정책을 부여하는 지 알 수 있다.
-- 다만, 업데이트가 느리다.

WITH tags AS (
    SELECT 
        TAG_NAME
        , TAG_DATABASE
        , TAG_SCHEMA 
    FROM snowflake.account_usage.tags WHERE DELETED IS NULL
),
tag_ref AS (
    SELECT 
        TAG_NAME
        , OBJECT_NAME
        , OBJECT_DATABASE
        , OBJECT_SCHEMA
        , COLUMN_NAME
    FROM snowflake.account_usage.tag_references
),
policies AS (
    SELECT 
        POLICY_NAME,
        POLICY_KIND,
        REF_ENTITY_NAME AS REF_TABLE,
    FROM snowflake.account_usage.policy_references
)
SELECT 
      tg.TAG_NAME
    , p.POLICY_NAME
    , tg.TAG_DATABASE
    , tg.TAG_SCHEMA
    , tgr.OBJECT_NAME AS REF_TABLE
FROM tags tg
LEFT OUTER JOIN tag_ref tgr
    ON tg.TAG_NAME = tgr.TAG_NAME
LEFT OUTER JOIN policies p
    ON tgr.TAG_NAME = p.REF_TABLE
ORDER BY tg.TAG_NAME;


-- VIEW로 만들어보기
CREATE VIEW IF NOT EXISTS dynamic_tag_policy_view AS
WITH tags AS (
    SELECT 
        TAG_NAME
        , TAG_DATABASE
        , TAG_SCHEMA 
    FROM snowflake.account_usage.tags WHERE DELETED IS NULL
),
tag_ref AS (
    SELECT 
        TAG_NAME
        , OBJECT_NAME
        , OBJECT_DATABASE
        , OBJECT_SCHEMA
        , COLUMN_NAME
    FROM snowflake.account_usage.tag_references
),
policies AS (
    SELECT 
        POLICY_NAME,
        POLICY_KIND,
        REF_ENTITY_NAME AS REF_TABLE,
    FROM snowflake.account_usage.policy_references
)
SELECT 
      tg.TAG_NAME
    , p.POLICY_NAME
    , tg.TAG_DATABASE
    , tg.TAG_SCHEMA
    , tgr.OBJECT_NAME AS REF_TABLE
FROM tags tg
LEFT OUTER JOIN tag_ref tgr
    ON tg.TAG_NAME = tgr.TAG_NAME
LEFT OUTER JOIN policies p
    ON tgr.TAG_NAME = p.REF_TABLE
ORDER BY tg.TAG_NAME;

-- dynamic_tag_policy_view 호출 
SELECT * FROM dynamic_tag_policy_view;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

-----------------------------------------------------------
--■■■■■■■■■■■■■■■■ DYNAMIC TABLE과 마스킹 정책 ■■■■■■■■■■■■■■■■■■
--
--         TAG로 ORIGIN TABLE과 DYNAMIC TABLE 적용 시,
--          문제 없이 마스킹 정책이 잘 동작하는 모습을 보인다.
--              ORIGIN에 데이터 삽입 후, DT REFRESH도
--              원활하게 삽입되며, 마스킹도 잘 적용된다.
-----------------------------------------------------------
-- ORIGIN TABLE 생성 
CREATE TABLE IF NOT EXISTS HYUNDAI_DB.PENTA_SCHEMA.ORIGIN_TABLE(ID INT, NAME STRING, PII VARCHAR, EMAIL VARCHAR, PHONE VARCHAR);

INSERT INTO HYUNDAI_DB.PENTA_SCHEMA.ORIGIN_TABLE VALUES
(1, 'PACK', '920101-1100223', 'adsadbc@naver.com', '010-2222-1111'), 
(2, 'PACKEY', '920102-1100223', 'cdsfsdf@naver.com', '010-3333-1112');

-- DYNAMIC TABLE 생성
CREATE DYNAMIC TABLE IF NOT EXISTS HYUNDAI_DB.PENTA_SCHEMA.DT_MASKING
TARGET_LAG = '1 hours'
WAREHOUSE = COMPUTE_WH
AS
SELECT * FROM HYUNDAI_DB.PENTA_SCHEMA.ORIGIN_TABLE;

-- 자동 새로고침 중지
ALTER DYNAMIC TABLE HYUNDAI_DB.PENTA_SCHEMA.DT_MASKING SUSPEND;

-- 다이나믹 테이블 확인 
SELECT * FROM HYUNDAI_DB.PENTA_SCHEMA.DT_MASKING;

-- ORIGIN TABLE에 데이터 마스킹 정책 태그 적용 
ALTER TABLE HYUNDAI_DB.PENTA_SCHEMA.ORIGIN_TABLE 
MODIFY COLUMN PII SET TAG PII_TAG = 'PII';
ALTER TABLE HYUNDAI_DB.PENTA_SCHEMA.ORIGIN_TABLE 
MODIFY COLUMN PHONE SET TAG PHONE_TAG = 'PHONE';

-- DYNAMIC TABLE에 데이터 마스킹 정책 태그 적용 
ALTER TABLE HYUNDAI_DB.PENTA_SCHEMA.DT_MASKING 
MODIFY COLUMN PII SET TAG PII_TAG = 'PII';
ALTER TABLE HYUNDAI_DB.PENTA_SCHEMA.DT_MASKING 
MODIFY COLUMN PHONE SET TAG PHONE_TAG = 'PHONE';

-- 데이터 삽입 시
INSERT INTO HYUNDAI_DB.PENTA_SCHEMA.ORIGIN_TABLE VALUES
(3, 'PACKPA', '920121-1100253', 'adsadd@naver.com', '010-2222-3333'); 

-- 데이터 삭제 시
DELETE FROM HYUNDAI_DB.PENTA_SCHEMA.ORIGIN_TABLE
WHERE ID = 3;

-- DYNAMIC TABLE 새로고침 
ALTER DYNAMIC TABLE DT_MASKING REFRESH;

-- 마스킹 적용 확인 용 명령어
USE ROLE GEN_ROLE;
SELECT * FROM ORIGIN_TABLE;
SELECT * FROM DT_MASKING;
USE ROLE ACCOUNTADMIN;
