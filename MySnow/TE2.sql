-- USE ROLE 을 실행하여 ACCOUNTADMIN을 사용자 세션의 활성 역할로 설정합니다.
USE ROLE ACCOUNTADMIN;

-- Snowflake 계정이 위치한 AWS Virtual Network(VNet)의 IDs을 검색합니다.
SELECT SYSTEM$GET_SNOWFLAKE_PLATFORM_INFO();

-- Snowflake에서 클라우드 저장소 Integration 만들기
CREATE OR REPLACE STORAGE INTEGRATION test_s3_snow
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{---}:role/test-snow-role'
  STORAGE_ALLOWED_LOCATIONS = ('*');
  --[ STORAGE_BLOCKED_LOCATIONS = ('s3://<bucket>/<path>/', 's3://<bucket>/<path>/') ]

-- Snowflake 계정에 대한 AWS IAM 사용자 검색
DESC INTEGRATION test_s3_snow;

-- 외부 Stage 만들기 준비
-- CREATE OR REPLACE ROLE s3role;
GRANT CREATE STAGE ON SCHEMA public TO ROLE ACCOUNTADMIN;
GRANT USAGE ON INTEGRATION test_s3_snow TO ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE s3db;
USE DATABASE s3db;
USE SCHEMA s3db.public;

-- File_Format 생성
CREATE OR REPLACE FILE FORMAT my_json_format_arr_evolve
  TYPE = JSON
  STRIP_OUTER_ARRAY =TRUE;

-- Non-arr  
CREATE OR REPLACE FILE FORMAT my_json_format_evolve
  TYPE = JSON;

DESC FILE FORMAT my_json_format_evolve;

-- 외부 Stage 만들기 1
CREATE OR REPLACE STAGE json_s3_stage1
  STORAGE_INTEGRATION = test_s3_snow
  URL = 's3://snow-test-bucket/json_test/';
  FILE_FORMAT = my_json_format_evolve;

-- 외부 Stage 만들기 2
CREATE OR REPLACE STAGE json_s3_stage2
  STORAGE_INTEGRATION = test_s3_snow
  URL = 's3://snow-test-bucket/json_test/';
  FILE_FORMAT = my_json_format_arr_evolve;

  
-- Stage 상세 정보
DESC STAGE json_s3_stage1;
DESC STAGE json_s3_stage2;

-- IINFER_SCHEMA test
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@json_s3_stage1/'
      , FILE_FORMAT=>'my_json_format_evolve'
      )
    );

-- Table 생성 (CREATE EVOLVE)
CREATE OR REPLACE TABLE s3tableEvolve1 ENABLE_SCHEMA_EVOLUTION = TRUE 
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@json_s3_stage1/',
          FILE_FORMAT=>'my_json_format_evolve'
        )
      ));

CREATE OR REPLACE TABLE s3tableEvolve2 ENABLE_SCHEMA_EVOLUTION = TRUE 
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@json_s3_stage2/',
          FILE_FORMAT=>'my_json_format_arr_evolve'
        )
      ));

-- COPY INTO
COPY INTO s3tableEvolve1
FROM @json_s3_stage1
PATTERN='.*.json'
FILE_FORMAT = my_json_format_evolve
-- 대소문자 민감도 해제
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

COPY INTO s3tableEvolve2
FROM @json_s3_stage2
PATTERN='.*.json'
FILE_FORMAT = my_json_format_arr_evolve
-- 대소문자 민감도 해제
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

SELECT * FROM s3tableEvolve1;
SELECT * FROM s3tableEvolve2;
SELECT "id", "first_name", "LAST_NAME" FROM s3tableEvolve;

DESC TABLE s3tableEvolve1;
DESC TABLE s3tableEvolve2;

TRUNCATE TABLE s3tableevolve1;
TRUNCATE TABLE s3tableevolve2;

DROP TABLE s3tableEvolve1;
DROP TABLE s3tableEvolve2;

ALTER WAREHOUSE COMPUTE_WH SUSPEND;

---
--- JSON 데이터 추출해서 정형 테이블로 변환 시도 중
---

-- 테스트 테이블 생성
CREATE OR REPLACE TABLE new_test (
    -- id INT,
    A004_KND_CDE VARCHAR,
    AW_SN_LENX_CDE VARCHAR
);

SELECT GET(s3tableEvolve1."trafficSafetyA004AInfo", 'row') as Data, Data[0]:A004_KND_CDE
FROM s3tableEvolve1;

INSERT INTO new_test (A004_KND_CDE, AW_SN_LENX_CDE)
SELECT 
    -- id, 
    GET(s3tableEvolve1."trafficSafetyA004AInfo", 'row')[0]:A004_KND_CDE::VARCHAR AS A004_KND_CDE,
    GET(s3tableEvolve1."trafficSafetyA004AInfo", 'row')[0]:AW_SN_LENX_CDE::VARCHAR AS AW_SN_LENX_CDE,
FROM s3tableEvolve1;

-- 결과 확인
SELECT * FROM new_test;

TRUNCATE TABLE new_test;