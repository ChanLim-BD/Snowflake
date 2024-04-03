USE ROLE ACCOUNTADMIN;
USE DATABASE s3db;
USE SCHEMA s3db.public;

-- 원천(기본) 테이블 확인
-- 기존에는 id가 12까지 존재
SELECT S3TABLEEVOLVECSV."id" FROM S3TABLEEVOLVECSV;

-- Materialized View 생성
CREATE MATERIALIZED VIEW S3MV
  AS
    SELECT "id", "first_name" FROM S3TABLEEVOLVECSV;

-- Materialized View의 데이터 확인
-- id가 12까지 존재
SELECT * FROM S3MV;

-- 원천 테이블에 id = 13 인 데이터 삽입
INSERT INTO S3TABLEEVOLVECSV ("id", "first_name") VALUES (13, 'Jin');

-- 원천 테이블에 데이터 확인
SELECT * FROM S3TABLEEVOLVECSV;

-- Dynamic Table에 데이터 확인 1
-- id = 13인 데이터 삽입된 것 확인
SELECT * FROM S3MV;

-- 원천 테이블에 id = 13 데이터 삭제
DELETE FROM S3TABLEEVOLVECSV WHERE "id" = 13;

-- 원천 테이블에 데이터 확인
SELECT * FROM S3TABLEEVOLVECSV;

-- Dynamic Table에 데이터 확인 2
-- id = 13인 데이터 삭제된 것 확인
SELECT * FROM S3MV;