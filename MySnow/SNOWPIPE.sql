-- WH, DB 사용 설정
USE WAREHOUSE COMPUTE_WH;
USE DATABASE S3DB;

-- Snowpipe용 Stage 생성 및 설정
CREATE STAGE pipestage
  URL = 's3://snow-test-bucket/test/*'
  STORAGE_INTEGRATION = test_s3_snow;


-- Snowpipe용 Table 설정
CREATE OR REPLACE TABLE PIPETABLE(SRC VARIANT);

-- Snowpipe 생성
CREATE OR REPLACE PIPE S3DB.public.MYPIPE auto_ingest=true as
  COPY INTO S3DB.public.PIPETABLE
  FROM @json_s3_stage
  PATTERN='.*.json'
  FILE_FORMAT = (TYPE = JSON);

-- S3 SQS 설정을 위한 정보 보기
SHOW PIPES;

-- COPY INTO 확인
SELECT * FROM PIPETABLE;

-- Table 삭제
DROP TABLE PIPETABLE;

-- WH 중지
ALTER WAREHOUSE COMPUTE_WH SUSPEND;