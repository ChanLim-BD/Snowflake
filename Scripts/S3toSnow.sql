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
CREATE OR REPLACE FILE FORMAT my_csv_format
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  NULL_IF = ('NULL', 'null')
  EMPTY_FIELD_AS_NULL = true;

CREATE OR REPLACE FILE FORMAT my_json_format
  TYPE = JSON;

-- 외부 Stage 만들기
CREATE OR REPLACE STAGE csv_s3_stage
  STORAGE_INTEGRATION = test_s3_snow
  URL = 's3://snow-test-bucket/test/';
  FILE_FORMAT = my_csv_format;

DESC STAGE csv_s3_stage;

CREATE OR REPLACE STAGE json_s3_stage
  STORAGE_INTEGRATION = test_s3_snow
  URL = 's3://snow-test-bucket/test/';
  FILE_FORMAT = my_json_format;

-- 데이터 로드하기
ALTER WAREHOUSE COMPUTE_WH RESUME;

CREATE OR REPLACE TABLE s3table1 (
    id VARCHAR(100),
    first_name VARCHAR(100),
    last_name VARCHAR(100)
);

CREATE OR REPLACE TABLE RAW_SRC (
    SRC VARIANT
);

-- COPY INTO CSV
COPY INTO s3table1
FROM @csv_s3_stage
PATTERN='.*.csv'
FILE_FORMAT = my_csv_format;

-- COPY INTO JSON
COPY INTO RAW_SRC
FROM @json_s3_stage
PATTERN='.*.json'
FILE_FORMAT = (TYPE = JSON);
    
SELECT * FROM s3table1;

SELECT * FROM RAW_SRC;

DROP TABLE s3table1;
DROP TABLE RAW_SRC;

ALTER WAREHOUSE COMPUTE_WH SUSPEND;

  