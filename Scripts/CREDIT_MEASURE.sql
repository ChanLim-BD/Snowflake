-----------------------------------------------
--                                           --
--         기본 Snowflake 설정 사항            --
--                                           --
-----------------------------------------------

USE WAREHOUSE COMPUTE_WH;
USE DATABASE HYUNDAI_DB;
USE SCHEMA PENTA_SCHEMA;

-- 컴퓨팅 테스트를 위한 웨어하우스 생성

-- CREATE WAREHOUSE TEST_XS WAREHOUSE_SIZE = 'X-SMALL';
-- CREATE WAREHOUSE TEST_S WAREHOUSE_SIZE = 'SMALL';
-- CREATE WAREHOUSE TEST_M WAREHOUSE_SIZE = 'MEDIUM';
-- CREATE WAREHOUSE TEST_L WAREHOUSE_SIZE = 'LARGE';

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■ 프로시저 테스트 1 ■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

CREATE OR REPLACE PROCEDURE HYUNDAI_DB.PENTA_SCHEMA.STOREDPROC1(ARGUMENT1 VARCHAR)
RETURNS string not null
language javascript 
AS
$$
var INPUT_ARGUMENT1 = ARGUMENT1;
var result = `${INPUT_ARGUMENT1}`
return result;
$$;

CREATE OR REPLACE PROCEDURE HYUNDAI_DB.PENTA_SCHEMA.STOREDPROC2(message VARCHAR)
RETURNS VARCHAR NOT NULL
LANGUAGE SQL
AS
BEGIN
  RETURN message;
END;
;

CALL HYUNDAI_DB.PENTA_SCHEMA.STOREDPROC1('Snowflake Snowflake Test');
CALL HYUNDAI_DB.PENTA_SCHEMA.STOREDPROC2('Snowflake Snowflake Test');

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■ 프로시저 테스트 2 ■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

CREATE OR REPLACE PROCEDURE HYUNDAI_DB.PENTA_SCHEMA.STOREDPROC3()
RETURNS VARCHAR
LANGUAGE SQL
AS 	
DECLARE
    -- 변수 선언
    today  DATE;
    v_dt   DATE;
    v_dt_w DATE;
    v_dt_1w_m DATE;
    v_dt_1w_s DATE;
    v_dt_2w_m DATE;
    v_dt_2w_s DATE;
    v_dt_m DATE;
    v_dt_1m_s DATE;
    v_dt_1m_e DATE;
    v_dt_y DATE;
    v_dt_m_1w DATE;
    v_dt_y_1w DATE;
    v_dt_d_py DATE;
    v_dt_d_py2 DATE;
    v_dt_w_py DATE;
    v_dt_1w_m_py DATE;
    v_dt_1w_s_py DATE;
    v_dt_1w_s_py2 DATE;
    v_dt_2w_m_py DATE;
    v_dt_2w_s_py DATE;
    v_dt_m_py DATE;
    v_dt_1m_s_py DATE;
    v_dt_1m_e_py DATE;
    v_dt_py DATE;
    v_dt_m_py_1w DATE;
    v_dt_py_1w DATE;
    v_cy_fr DATE;
    v_cy_to DATE;
    v_py_fr DATE;
    v_py_to DATE;

BEGIN
    -- 변수 값 설정
    today  := CONVERT_TIMEZONE('Asia/Seoul', GETDATE());               -- 당일
    v_dt   := DATEADD('DAY', -1, :today);                              -- 전일자
    v_dt_w := DATE_TRUNC('WEEK', :today);                              -- 금주 월요일
    v_dt_1w_m := (DATE_TRUNC('WEEK', today) - 7);                     -- 전주 월요일
    v_dt_1w_s := (DATE_TRUNC('WEEK', today) - 1);                     -- 전주 일요일
    v_dt_2w_m := (DATE_TRUNC('WEEK', today) - 14);                    -- 2주전 월요일
    v_dt_2w_s := (DATE_TRUNC('WEEK', today) - 8);                     -- 2주전 일요일
    v_dt_m := DATE_TRUNC('MONTH', today);                             -- 이번달 1일
    v_dt_1m_s := ADD_MONTHS(DATE_TRUNC('MONTH', today), -1);          -- 전월 1일          
    v_dt_1m_e := (DATE_TRUNC('MONTH', today) - 1);                    -- 전월 마지막일
    v_dt_y := DATE_TRUNC('YEAR', today);                              -- 올해 1월 1일
    v_dt_m_1w := DATE_TRUNC('MONTH', v_dt_1w_s);                      -- 1주전 기준 월 1일
    v_dt_y_1w := DATE_TRUNC('YEAR', v_dt_1w_s);                       -- 1주전 기준 년 1일
    v_dt_d_py := (today - (1 + 364));                                 -- 전년도 전일자(동요일)
    v_dt_d_py2 := ADD_MONTHS(today - 1, -12);                         -- 전년도 전일자(동일)
    v_dt_w_py := (DATE_TRUNC('WEEK', today) - 364);                   -- 전년도 이번주 월요일
    v_dt_1w_m_py := (DATE_TRUNC('WEEK', today) - (7 + 364));          -- 전년도 전주 월요일     
    v_dt_1w_s_py := (DATE_TRUNC('WEEK', today) - (1 + 364));          -- 전년도 전주 일요일(동요일)
    v_dt_1w_s_py2 := ADD_MONTHS(v_dt_1w_s, -12);                     -- 전년도 전주 일요일(동일)
    v_dt_2w_m_py := (DATE_TRUNC('WEEK', today) - (14 + 364));         -- 전년도 2주전 월요일
    v_dt_2w_s_py := (DATE_TRUNC('WEEK', today) - (8 + 364));          -- 전년도 2주전 일요일
    v_dt_m_py := ADD_MONTHS(DATE_TRUNC('MONTH', today), -12);         -- 전년도 이번달 1일
    v_dt_1m_s_py := ADD_MONTHS(DATE_TRUNC('MONTH', today), -13);      -- 전년도 전월 1일
    v_dt_1m_e_py := ADD_MONTHS(DATE_TRUNC('MONTH', today) - 1, -12);  -- 전년도 전월 마지막일
    v_dt_py := ADD_MONTHS(DATE_TRUNC('YEAR', today), -12);           -- 전년도 1월 1일
    v_dt_m_py_1w := DATE_TRUNC('MONTH', v_dt_d_py2);                  -- 전년도 1주전 기준 월 1일
    v_dt_py_1w := DATE_TRUNC('YEAR', v_dt_d_py2);                    -- 전년도 1주전 기준 년 1일
    v_cy_fr := LEAST(v_dt_y, v_dt_2w_m, v_dt_y_1w);
    v_cy_to := v_dt;            
    v_py_fr := LEAST(v_dt_py, v_dt_2w_m_py, v_dt_py_1w);
    v_py_to := GREATEST(v_dt_d_py, v_dt_d_py2);

    -- 테이블에 변수 값 저장을 위한 기존 테이블 삭제
    DROP TABLE IF EXISTS HYUNDAI_DB.PENTA_SCHEMA.param_test;
    
    -- 변수 값을 저장할 테이블 생성
    CREATE TABLE HYUNDAI_DB.PENTA_SCHEMA.param_test
    (
       PARAM  TEXT COMMENT '변수명',
       VAL    TEXT COMMENT '치환값'
    );
    
    -- 변수 값 INSERT
    INSERT INTO HYUNDAI_DB.PENTA_SCHEMA.param_test (PARAM, VAL)
    VALUES
        ('today', '당일      :' || :today::STRING),
        ('v_dt', '전일      :' || :v_dt::STRING),
        ('v_dt_w', '금주월요일 :' || :v_dt_w::STRING),
        ('v_dt_1w_m', '전주월요일 :' || :v_dt_1w_m::STRING),
        ('v_dt_1w_s', '전주일요일 :' || :v_dt_1w_s::STRING),
        ('v_dt_2w_m', '2주전월요일 :' || :v_dt_2w_m::STRING),
        ('v_dt_2w_s', '2주전일요일 :' || :v_dt_2w_s::STRING),
        ('v_dt_m', '이번달1일 :' || :v_dt_m::STRING),
        ('v_dt_1m_s', '전월1일 :' || :v_dt_1m_s::STRING),
        ('v_dt_1m_e', '전월마지막일 :' || :v_dt_1m_e::STRING),
        ('v_dt_y', '올해1월1일 :' || :v_dt_y::STRING),
        ('v_dt_m_1w', '1주전기준월1일 :' || :v_dt_m_1w::STRING),
        ('v_dt_y_1w', '1주전기준년1일 :' || :v_dt_y_1w::STRING),
        ('v_dt_d_py', '전년도전일자동요일 :' || :v_dt_d_py::STRING),
        ('v_dt_d_py2', '전년도전일자동일 :' || :v_dt_d_py2::STRING),
        ('v_dt_w_py', '전년도금주월요일 :' || :v_dt_w_py::STRING),
        ('v_dt_1w_m_py', '전년도전주월요일 :' || :v_dt_1w_m_py::STRING),
        ('v_dt_1w_s_py', '전년도전주일요일동요일 :' || :v_dt_1w_s_py::STRING),
        ('v_dt_1w_s_py2', '전년도전주일요일동일 :' || :v_dt_1w_s_py2::STRING),
        ('v_dt_2w_m_py', '전년도2주전월요일 :' || :v_dt_2w_m_py::STRING),
        ('v_dt_2w_s_py', '전년도2주전일요일 :' || :v_dt_2w_s_py::STRING),
        ('v_dt_m_py', '전년도이번달1일 :' || :v_dt_m_py::STRING),
        ('v_dt_1m_s_py', '전년도전월1일 :' || :v_dt_1m_s_py::STRING),
        ('v_dt_1m_e_py', '전년도전월마지막일 :' || :v_dt_1m_e_py::STRING),
        ('v_dt_py', '전년도1월1일 :' || :v_dt_py::STRING),
        ('v_dt_m_py_1w', '전년도1주전기준월1일 :' || :v_dt_m_py_1w::STRING),
        ('v_dt_py_1w', '전년도1주전기준년1일 :' || :v_dt_py_1w::STRING),
        ('v_cy_fr', '올해기준FROM :' || :v_cy_fr::STRING),
        ('v_cy_to', '올해기준TO :' || :v_cy_to::STRING),
        ('v_py_fr', '전년도기준FROM :' || :v_py_fr::STRING),
        ('v_py_to', '전년도기준TO :' || :v_py_to::STRING);
    ;

    RETURN '변수 출력 테스트를 완료했습니다.';
END;
;

CALL HYUNDAI_DB.PENTA_SCHEMA.STOREDPROC3();

SELECT * FROM HYUNDAI_DB.PENTA_SCHEMA.PARAM_TEST;
TRUNCATE TABLE HYUNDAI_DB.PENTA_SCHEMA.PARAM_TEST;

---------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■ 프로시저 테스트 3 ■■■■■■■■■■■■■■■■■■■■■■
---------------------------------------------------------

-- 고객사 (현대홈쇼핑) 프로시저 변환 중...

---------------------------------------------------------
--■■■■■■■■■■■■■■ 쿼리 시간 및 크레딧 소모 조회문 ■■■■■■■■■■■■■■■
---------------------------------------------------------

-- Credits_Used = Credits_Used_Cloud_Services + Credits_Used_Compute.

-- There is now an additional column in this view called Credits_Used_Cloud_Services. 
-- This will show you how many cloud services credits were used by each individual query.

-- https://community.snowflake.com/s/article/Cloud-Services-Billing-Update-Understanding-and-Adjusting-Usage
-- 2024/03/12 ver.

SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY ORDER BY USAGE_DATE DESC LIMIT 1;

---------------------------
--■■■■■■■■ 처음 버전 ■■■■■■■■■
---------------------------

SELECT 
    QUERY_TEXT                                                                                   -- 명령문 조회
    , QUERY_TYPE                                                                                 -- QUERY 종류
    , WAREHOUSE_NAME                                                                             -- WAREHOUSE 이름
    , WAREHOUSE_SIZE                                                                             -- WAREHOUSE 크기
    , EXECUTION_STATUS                                                                           -- 실행 상태 (성공, 실패, 실행중...)
    , TO_TIME(TO_TIMESTAMP(TIMESTAMPDIFF('second', START_TIME, END_TIME))) AS DURATION_TIME                                          
    , CREDITS_USED_CLOUD_SERVICES                                                                -- 클라우드 서비스에 사용된 크레딧 수
FROM TABLE(information_schema.query_history())
WHERE 
    QUERY_TYPE != 'UNKNOWN' -- 최근 실행 쿼리 조회 시, 당장 실행하는 해당 쿼리부터 조회를 제외하기 위함.
ORDER BY start_time DESC -- 최근 실행 쿼리 순 조회
LIMIT 5
;      

------------------------------------------------
--■■■■■■ METERING_DAILY_HISTORY 따라서 작성 ■■■■■■■
------------------------------------------------
SELECT 
    QUERY_TEXT                                                                                   -- 명령문 조회
    , QUERY_TYPE                                                                                 -- QUERY 종류
    , WAREHOUSE_NAME                                                                             -- WAREHOUSE 이름
    , WAREHOUSE_SIZE                                                                             -- WAREHOUSE 크기
    , EXECUTION_STATUS                                                                           -- 실행 상태 (성공, 실패, 실행중...)
    , TO_TIME(TO_TIMESTAMP(TIMESTAMPDIFF(second , START_TIME , END_TIME)))  AS DURATION_TIME
    , CASE WHEN (LIKE(WAREHOUSE_SIZE, 'X-Small')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0003 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Small')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0003
           WHEN (LIKE(WAREHOUSE_SIZE, 'Small')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0006 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Small')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0006
           WHEN (LIKE(WAREHOUSE_SIZE, 'Medium')   AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0011 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Medium')   AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0011
           WHEN (LIKE(WAREHOUSE_SIZE, 'Large')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0022 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Large')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0022
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Large')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0044 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Large')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0044
           ELSE NULL
        END                                                                 AS CREDITS_USED_COMPUTE
    , CREDITS_USED_CLOUD_SERVICES
    , CREDITS_USED_COMPUTE + CREDITS_USED_CLOUD_SERVICES                    AS CREDITS_USED
    , -(CREDITS_USED_CLOUD_SERVICES)                                        AS CREDITS_ADJUSTMENT_CLOUD_SERVICES
    , CREDITS_USED - CREDITS_ADJUSTMENT_CLOUD_SERVICES                      AS CREDITS_BILLED
FROM TABLE(information_schema.query_history())
WHERE 
    QUERY_TYPE != 'UNKNOWN' -- 최근 실행 쿼리 조회 시, 당장 실행하는 해당 쿼리부터 조회를 제외하기 위함.
ORDER BY start_time DESC    -- 최근 실행 쿼리 순 조회
LIMIT 5
;   


------------------------------------------------
--■■■■■■ 결론은 CREDIT_USED는 COMPUTE와 동일 ■■■■■■■
------------------------------------------------
SELECT 
    QUERY_TEXT                                                                                   -- 명령문 조회
    , QUERY_TYPE                                                                                 -- QUERY 종류
    , WAREHOUSE_NAME                                                                             -- WAREHOUSE 이름
    , WAREHOUSE_SIZE                                                                             -- WAREHOUSE 크기
    , EXECUTION_STATUS                                                                           -- 실행 상태 (성공, 실패, 실행중...)
    , TO_TIME(TO_TIMESTAMP(TIMESTAMPDIFF(second , START_TIME , END_TIME)))  AS DURATION_TIME
    , CASE WHEN (LIKE(WAREHOUSE_SIZE, 'X-Small')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0003 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Small')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0003
           WHEN (LIKE(WAREHOUSE_SIZE, 'Small')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0006 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Small')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0006
           WHEN (LIKE(WAREHOUSE_SIZE, 'Medium')   AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0011 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Medium')   AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0011
           WHEN (LIKE(WAREHOUSE_SIZE, 'Large')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0022 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Large')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0022
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Large')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0044 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Large')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0044
           ELSE NULL
        END                                                                 AS CREDITS_USED
FROM TABLE(information_schema.query_history())
WHERE 
    QUERY_TYPE != 'UNKNOWN' -- 최근 실행 쿼리 조회 시, 당장 실행하는 해당 쿼리부터 조회를 제외하기 위함.
ORDER BY start_time DESC    -- 최근 실행 쿼리 순 조회
LIMIT 5
;  

---------------------------
--■■■■■■ 시간대 고려 ■■■■■■■
---------------------------
SELECT 
    QUERY_TEXT                                                                                   -- 명령문 조회
    , QUERY_TYPE                                                                                 -- QUERY 종류
    , WAREHOUSE_NAME                                                                             -- WAREHOUSE 이름
    , WAREHOUSE_SIZE                                                                             -- WAREHOUSE 크기
    , EXECUTION_STATUS                                                                           -- 실행 상태 (성공, 실패, 실행중...)
    , TIMESTAMPDIFF('second', START_TIME, END_TIME)     AS DURATION                              -- 문 시작 시간 - 문 종료 시간
    , TO_TIME(TO_TIMESTAMP(DURATION))                   AS DURATION_TIME                                          
    , CASE WHEN (RLIKE(WAREHOUSE_NAME, '.*_Small')  AND DURATION  < 60) THEN 0.0006 * 60
            WHEN (RLIKE(WAREHOUSE_NAME, '.*_Small')  AND DURATION >= 60) THEN DURATION * 0.0006
            WHEN (RLIKE(WAREHOUSE_NAME, '.*_Medium') AND DURATION  < 60) THEN 0.0011 * 60
            WHEN (RLIKE(WAREHOUSE_NAME, '.*_Medium') AND DURATION >= 60) THEN DURATION * 0.0011
            WHEN (RLIKE(WAREHOUSE_NAME, '.*_Large')  AND DURATION  < 60) THEN 0.0022 * 60
            WHEN (RLIKE(WAREHOUSE_NAME, '.*_Large')  AND DURATION >= 60) THEN DURATION * 0.0022
            ELSE CASE WHEN DURATION  < 60 THEN 0.0003 * 60 
                      WHEN DURATION >= 60 THEN DURATION * 0.0003
                 ELSE NULL
                  END
        END                                              AS CREDIT                               -- 클라우드 서비스에 사용된 크레딧 수
    , CREDITS_USED_CLOUD_SERVICES
  FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
      END_TIME_RANGE_START => '2024-04-24 08:00:00'::TIMESTAMP_LTZ
    , END_TIME_RANGE_END   => '2024-04-24 17:00:00'::TIMESTAMP_LTZ
    , RESULT_LIMIT => 1000
  ))
    WHERE 
    QUERY_TYPE != 'UNKNOWN' -- 최근 실행 쿼리 조회 시, 당장 실행하는 해당 쿼리부터 조회를 제외하기 위함.
ORDER BY start_time DESC    -- 최근 실행 쿼리 순 조회
LIMIT 5
;  



---------------------------------------------------------
--■■■■■■■■■■■■■■ 쿼리 시간 및 크레딧 소모 TEST ■■■■■■■■■■■■■■■
---------------------------------------------------------

-- USE WAREHOUSE TEST_XS;
-- CALL STOREDPROC3();

-- USE WAREHOUSE TEST_S;
-- CALL STOREDPROC3();

-- USE WAREHOUSE TEST_M;
-- CALL STOREDPROC3();

-- USE WAREHOUSE TEST_L;
-- CALL STOREDPROC3();


ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'X-SMALL';
CALL STOREDPROC3();
SELECT LAST_QUERY_ID();

ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'SMALL';
CALL STOREDPROC3();
SELECT LAST_QUERY_ID();

ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'MEDIUM';
CALL STOREDPROC3();
SELECT LAST_QUERY_ID();

ALTER WAREHOUSE COMPUTE_WH SET WAREHOUSE_SIZE = 'LARGE';
CALL STOREDPROC3();
SELECT LAST_QUERY_ID();


SELECT 
    QUERY_TEXT                                                                                   -- 명령문 조회
    , QUERY_TYPE                                                                                 -- QUERY 종류
    , WAREHOUSE_NAME                                                                             -- WAREHOUSE 이름
    , WAREHOUSE_SIZE                                                                             -- WAREHOUSE 크기
    , EXECUTION_STATUS                                                                           -- 실행 상태 (성공, 실패, 실행중...)
    , TO_TIME(TO_TIMESTAMP(TIMESTAMPDIFF(second , START_TIME , END_TIME)))  AS DURATION_TIME
    , CASE WHEN (LIKE(WAREHOUSE_SIZE, 'X-Small')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0003 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Small')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0003
           WHEN (LIKE(WAREHOUSE_SIZE, 'Small')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0006 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Small')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0006
           WHEN (LIKE(WAREHOUSE_SIZE, 'Medium')   AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0011 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Medium')   AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0011
           WHEN (LIKE(WAREHOUSE_SIZE, 'Large')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0022 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'Large')    AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0022
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Large')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME)  < 60) THEN 0.0044 * 60
           WHEN (LIKE(WAREHOUSE_SIZE, 'X-Large')  AND TIMESTAMPDIFF(second , START_TIME , END_TIME) >= 60) THEN TIMESTAMPDIFF(second , START_TIME , END_TIME) * 0.0044
           ELSE NULL
        END                                                                 AS CREDITS_USED
FROM TABLE(information_schema.query_history())
WHERE 
    QUERY_TYPE != 'UNKNOWN' -- 최근 실행 쿼리 조회 시, 당장 실행하는 해당 쿼리부터 조회를 제외하기 위함.
    AND QUERY_ID IN (
                     '01b3e0c7-0000-6bc4-0000-856d0037cbd2'
                    ,'01b3e0c8-0000-6bb5-0000-856d0037ecf2'
                    ,'01b3e0c8-0000-6bb6-0000-856d0037f7f6'
                    ,'01b3e0c8-0000-6bb5-0000-856d0037ed1e' 
                    )
ORDER BY start_time DESC;      -- 최근 실행 쿼리 순 조회

