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
CREATE OR REPLACE FILE FORMAT my_csv_format_evolve
  TYPE = CSV
  FIELD_DELIMITER = ','
  NULL_IF = ('NULL', 'null')
  EMPTY_FIELD_AS_NULL = true
  -- 헤더 파싱
  PARSE_HEADER = TRUE
  -- 해당 파라미터 설정 시, Column의 수가 맞지 않더라도 실행
  ERROR_ON_COLUMN_COUNT_MISMATCH = false;

-- 외부 Stage 만들기
CREATE OR REPLACE STAGE csv_s3_stage
  STORAGE_INTEGRATION = test_s3_snow
  URL = 's3://snow-test-bucket/csv_test/';
  FILE_FORMAT = my_csv_format;

-- Stage 상세 정보
DESC STAGE csv_s3_stage;

-- IINFER_SCHEMA test
SELECT *
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@csv_s3_stage/'
      , FILE_FORMAT=>'my_csv_format_evolve'
      )
    );

-- ENABLE_SCHEMA_EVOLUTION이 설정된 Table 생성
CREATE OR REPLACE TABLE s3tableEvolveCsv ENABLE_SCHEMA_EVOLUTION = TRUE 
USING TEMPLATE (
    SELECT ARRAY_AGG(object_construct(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION=>'@csv_s3_stage/',
          FILE_FORMAT=>'my_csv_format_evolve'
        )
      ));

-- ENABLE_SCHEMA_EVOLUTION이 설정되지 않은 Table 생성
CREATE OR REPLACE TABLE s3tableEvolve(
    hello NUMBER
);

-- 기존 Table 생성 후, 설정 바꾸는 Ver.
ALTER TABLE s3tableEvolve SET ENABLE_SCHEMA_EVOLUTION = TRUE;

-- 기존 Table 생성 후 값 하나 넣고 Test 하기 위한 준비.
DESC TABLE s3tableevolve;
INSERT INTO s3tableevolve (hello) values(5);
SELECT * FROM s3tableevolve;

-- COPY INTO CSV
COPY INTO s3tableEvolveCsv
FROM @csv_s3_stage
PATTERN='.*.csv'
FILE_FORMAT = my_csv_format_evolve
-- 대소문자 민감도 해제
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- COPY INTO (ALTER 파라미터 ver)
COPY INTO s3tableEvolve
FROM @csv_s3_stage
PATTERN='.*.csv'
FILE_FORMAT = my_csv_format_evolve
-- 대소문자 민감도 해제
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- 결과 확인 1.
SELECT * FROM s3tableEvolveCsv;
SELECT "id", "first_name", "last_name", "email", "gender", "ip_address" FROM s3tableEvolveCsv;

-- 결과 확인 2.
SELECT * FROM s3tableevolve;

DESC TABLE s3tableEvolveCsv;

TRUNCATE TABLE s3tableEvolve;
TRUNCATE TABLE s3tableEvolveCsv;

DROP TABLE s3tableEvolve;
DROP TABLE s3tableEvolveCsv;

ALTER WAREHOUSE COMPUTE_WH SUSPEND;