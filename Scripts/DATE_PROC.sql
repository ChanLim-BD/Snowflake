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