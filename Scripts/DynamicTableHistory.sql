-----------------------------------------------
--                                           --
--        기본 Snowflake 설정 사항             --
--                                           --
-----------------------------------------------

USE WAREHOUSE PENTA_WH;
USE DATABASE HYUNDAI_DB;
USE SCHEMA HDHS_PD;


------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■ 1. DYNAMIC_TABLE_REFRESH_HISTORY ■■■■■■■■■■■■■■■■■■■■■■■■■■■

--              동적 테이블 의 각 새로 고침(완료 및 실행 중)에 대한 정보를 반환
------------------------------------------------------------------------------------

SELECT *
  FROM TABLE(information_schema.DYNAMIC_TABLE_REFRESH_HISTORY (
      RESULT_LIMIT => 100
    , ERROR_ONLY => FALSE
  )
)
;

------------------------------------------------------------------------------------
--■■■■■■■■■■■■■ 1.1. DYNAMIC_TABLE_REFRESH_HISTORY로 새로고침 걸린 시간 계산 ■■■■■■■■■■■■■■
------------------------------------------------------------------------------------


-- 현재 시간 기준 {}시간 전 부터 검색
SELECT 
    NAME 
  , STATE
  , STATE_MESSAGE
  , REFRESH_START_TIME 
  , REFRESH_END_TIME 
  , TO_TIME(TO_TIMESTAMP(TIMESTAMPDIFF(second , REFRESH_START_TIME , REFRESH_END_TIME))) AS REFRESH_DURATION
FROM 
  TABLE(information_schema.DYNAMIC_TABLE_REFRESH_HISTORY (
      DATA_TIMESTAMP_START => DATEADD(HOUR, -4, CURRENT_TIMESTAMP()) 
     , ERROR_ONLY => FALSE
  )
)
ORDER BY  NAME 
         ,REFRESH_DURATION DESC;

-- 특정 시간부터 검색
SELECT 
    NAME 
  , STATE 
  , STATE_MESSAGE
  , REFRESH_START_TIME 
  , REFRESH_END_TIME 
  , TO_TIME(TO_TIMESTAMP(TIMESTAMPDIFF(second , REFRESH_START_TIME , REFRESH_END_TIME))) AS REFRESH_DURATION
FROM 
  TABLE(information_schema.DYNAMIC_TABLE_REFRESH_HISTORY (
      DATA_TIMESTAMP_START => TO_TIMESTAMP_LTZ('2024-04-15 14:00:00')
     , RESULT_LIMIT => 100
     , ERROR_ONLY => FALSE
  )
)
ORDER BY  NAME 
         ,REFRESH_DURATION DESC;

------------------------------------------------------------------------------------
--■■■■■■■■■■■■■■■■■■■■■■■■■■■ 2. DYNAMIC_TABLE_GRAPH_HISTORY ■■■■■■■■■■■■■■■■■■■■■■■■■■■■

--                    현재 계정의 모든 동적 테이블 에 대한 정보를 반환
------------------------------------------------------------------------------------


SELECT *
  FROM TABLE(information_schema.DYNAMIC_TABLE_GRAPH_HISTORY (
    HISTORY_START => DATEADD(MINUTES, -10, CURRENT_TIMESTAMP())
  )
);

SELECT to_time(VALID_TO), to_time(VALID_FROM)
  FROM TABLE(information_schema.DYNAMIC_TABLE_GRAPH_HISTORY (
    HISTORY_START => DATEADD(MINUTES, -10, CURRENT_TIMESTAMP())
  )
);









