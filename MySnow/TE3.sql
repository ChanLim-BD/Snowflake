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
CREATE OR REPLACE FILE FORMAT my_parquet_format
  TYPE = PARQUET
  COMPRESSION = SNAPPY;

DESC FILE FORMAT my_parquet_format;

-- 외부 Stage 만들기 
CREATE OR REPLACE STAGE par_s3_stage
  STORAGE_INTEGRATION = test_s3_snow
  URL = 's3://snow-test-bucket/par_test/';
  FILE_FORMAT = my_parquet_format;

  
-- Stage 상세 정보
DESC STAGE par_s3_stage;

-- IINFER_SCHEMA test
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@par_s3_stage/'
      , FILE_FORMAT=>'my_parquet_format'
      )
    );

-- Table 생성 (CREATE EVOLVE)
CREATE OR REPLACE TABLE s3tableEvolvePar ENABLE_SCHEMA_EVOLUTION = TRUE 
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@par_s3_stage/',
          FILE_FORMAT=>'my_parquet_format'
        )
      ));

-- COPY INTO
COPY INTO s3tableEvolvePar
FROM @par_s3_stage
PATTERN='.*.parquet'
FILE_FORMAT = my_parquet_format
-- 대소문자 민감도 해제
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

SELECT * FROM s3tableEvolvePar;
SELECT "id", "first_name", "last_name" FROM s3tableEvolve;

DESC TABLE s3tableEvolvePar;

TRUNCATE TABLE s3tableEvolvePar;

DROP TABLE s3tableEvolvePar;

ALTER WAREHOUSE COMPUTE_WH SUSPEND;

---
---
---

SELECT *, GET(s3tableEvolve1."trafficSafetyA004AInfo", 'row') 
FROM s3tableEvolve1;