USE ROLE ACCOUNTADMIN;
USE DATABASE s3db;
USE SCHEMA s3db.public;

-- 원천(기본) 테이블 확인
-- 기존에는 id가 12까지 존재
SELECT S3TABLEEVOLVECSV."id" FROM S3TABLEEVOLVECSV;

-- Dynamic Table 생성
CREATE OR REPLACE DYNAMIC TABLE DTableTest
  TARGET_LAG = '1 minutes'
  WAREHOUSE = COMPUTE_WH
  AS
    SELECT "id", "first_name" FROM S3TABLEEVOLVECSV;

-- Dynamic Table의 데이터 확인
-- id가 12까지 존재
SELECT * FROM DTABLETEST;

-- 원천 테이블에 id = 13 인 데이터 삽입
INSERT INTO S3TABLEEVOLVECSV ("id", "first_name") VALUES (13, 'Jin');

-- 원천 테이블에 데이터 확인
SELECT * FROM S3TABLEEVOLVECSV;

-- Dynamic Table에 데이터 확인 1
  -- 바로 쿼리하면 아마 새로운 데이터 삽입 안되어있음
  -- 그 이유는 Lag에 1분이 경과되지 않아서 Update 안됨.
-- 1분 경과 후 쿼리 시, id = 13인 데이터 삽입된 것 확인
SELECT * FROM DTABLETEST;

-- 원천 테이블에 id = 13 데이터 삭제
DELETE FROM S3TABLEEVOLVECSV WHERE "id" = 13;

-- 원천 테이블에 데이터 확인
SELECT * FROM S3TABLEEVOLVECSV;

-- Dynamic Table에 데이터 확인 1
  -- 바로 쿼리하면 아마 새로운 데이터 삭제 안되어있음
  -- 그 이유는 Lag에 1분이 경과되지 않아서 Update 안됨.
-- 1분 경과 후 쿼리 시, id = 13인 데이터 삭제된 것 확인
SELECT * FROM DTABLETEST;


-- Dynamic Table 나열하고 세부 정보 보기
-- 여기서 REFRESH_MODE 열의 값 확인하면 `증분`인지 `전체` 새로고침인지 확인 가능
SHOW DYNAMIC TABLES LIKE 'DTABLETEST' IN SCHEMA S3DB.public;

-- Dynamic Table 일시 중지 및 재개
ALTER DYNAMIC TABLE DTABLETEST SUSPEND;
ALTER DYNAMIC TABLE DTABLETEST RESUME;

-- 수동 새로고침
ALTER DYNAMIC TABLE DTABLETEST REFRESH;

-- Lag 변경
ALTER DYNAMIC TABLE DTABLETEST SET TARGET_LAG = DOWNSTREAM;