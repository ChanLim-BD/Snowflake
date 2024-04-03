USE ROLE ACCOUNTADMIN;
CREATE DATABASE CDC_TEST;
CREATE SCHEMA CDC_SCHEMA;

CREATE OR REPLACE PROCEDURE CDC_TEST.SP_MERGE_INTO_SCSSHOP()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS 
$$
	-- -----------------------------------------------------------------------------------
	-- VERSION    : 0.1
	-- CREATED AT : 2024.01.05
	-- LAST UPDATE: 2024.01.05	
	-- PURPOSE    : CDC_TEST.---
	-- 		        - MERGE INTO
	-- -----------------------------------------------------------------------------------
	-- ARGUMENTS  : 없음.
	-- -----------------------------------------------------------------------------------
	-- RETURNS    : 없음.
	-- -----------------------------------------------------------------------------------
	-- EXCEPTIONS : 없음.
	-- -----------------------------------------------------------------------------------
	-- TLOGIC : FUNCTION 변환 로직
	-- DLOGIC : 데이터 변환 로직 
	-- JOB COMMENT 
	-- 		>> 1. SOURCE : 
	-- 		>> 2. TARGET :
	--      >> 3. TLOGIC : 
	--      >> 4. DLOGIC : 
	-- -----------------------------------------------------------------------------------

BEGIN
	
    ALTER EXTERNAL TABLE CDC_TEST.CDC_SCHEMA.CDC_PRAC_DB_EXT REFRESH;
	
    MERGE
     INTO CDC_TEST.CDC_SCHEMA.RESULT_CDC_EXT T
    USING (
            SELECT T2.*
    	     FROM (
                    SELECT T1.*
                    		, ROW_NUMBER() OVER(PARTITION BY T1.CD_KEY
                    										ORDER BY T1.TRANSACTION_ID DESC) AS RNUM
                    FROM EXT_STREAM T1
    			   ) T2
    		WHERE T2.RNUM = 1 
    	   ) S
       ON T.CD_KEY    = S.CD_KEY     
    WHEN MATCHED AND (S.TRANSACTIONS = 'INSERT' OR S.TRANSACTIONS = 'UPDATE') THEN
        UPDATE SET   T.CD_KEY         = S.CD_KEY 
                   , T.PARENT_CD      = S.PARENT_CD   
                   , T.CD             = S.CD   
                   , T.LVL            = S.LVL   
                   , T.SORT           = S.SORT   
                   , T.USE_YN         = S.USE_YN   
                   , T.CD_NM          = S.CD_NM    
                   , T.CD_NM_ENG      = S.CD_NM_ENG   
                   , T.CD_NM_CHN      = S.CD_NM_CHN   
                   , T.CD_NM_JPN      = S.CD_NM_JPN   
                   , T.CD_NM_ETC      = S.CD_NM_ETC  
                   , T.RMK            = S.RMK   
                   , T.ERP_PARENT_CD  = S.ERP_PARENT_CD   
                   , T.ERP_TABLE      = S.ERP_TABLE   
                   , T.VAL1           = S.VAL1   
                   , T.VAL2           = S.VAL2   
                   , T.VAL3           = S.VAL3  
                   , T.VAL4           = S.VAL4  
                   , T.VAL5           = S.VAL5   
                   , T.VAL6           = S.VAL6  
                   , T.VAL7           = S.VAL7   
                   , T.VAL8           = S.VAL8   
                   , T.VAL9           = S.VAL9  
                   , T.VAL10          = S.VAL10
    WHEN MATCHED AND S.TRANSACTIONS = 'DELETE' THEN
    	DELETE
    WHEN NOT MATCHED AND (S.TRANSACTIONS = 'INSERT' OR S.TRANSACTIONS = 'UPDATE') THEN
        INSERT (
                  CD_KEY 
                , PARENT_CD   
                , CD   
                , LVL   
                , SORT   
                , USE_YN   
                , CD_NM    
                , CD_NM_ENG   
                , CD_NM_CHN   
                , CD_NM_JPN   
                , CD_NM_ETC  
                , RMK   
                , ERP_PARENT_CD   
                , ERP_TABLE   
                , VAL1   
                , VAL2   
                , VAL3  
                , VAL4  
                , VAL5   
                , VAL6  
                , VAL7   
                , VAL8   
                , VAL9  
                , VAL10
        )
        VALUES (
                  S.CD_KEY 
                , S.PARENT_CD   
                , S.CD   
                , S.LVL   
                , S.SORT   
                , S.USE_YN   
                , S.CD_NM    
                , S.CD_NM_ENG   
                , S.CD_NM_CHN   
                , S.CD_NM_JPN   
                , S.CD_NM_ETC  
                , S.RMK   
                , S.ERP_PARENT_CD   
                , S.ERP_TABLE   
                , S.VAL1   
                , S.VAL2   
                , S.VAL3  
                , S.VAL4  
                , S.VAL5   
                , S.VAL6  
                , S.VAL7   
                , S.VAL8   
                , S.VAL9  
                , S.VAL10
        )
    ;
	
	RETURN '정상종료';

EXCEPTION

  WHEN STATEMENT_ERROR THEN
    RETURN OBJECT_CONSTRUCT('ERROR TYPE', 'STATEMENT_ERROR',
                            'SQLCODE', SQLCODE,
                            'SQLERRM', SQLERRM,
                            'SQLSTATE', SQLSTATE);
  WHEN EXPRESSION_ERROR THEN
    RETURN OBJECT_CONSTRUCT('ERROR TYPE', 'EXPRESSION_ERROR',
                            'SQLCODE', SQLCODE,
                            'SQLERRM', SQLERRM,
                            'SQLSTATE', SQLSTATE);
  WHEN OTHER THEN
    RETURN OBJECT_CONSTRUCT('ERROR TYPE', 'OTHER ERROR',
                            'SQLCODE', SQLCODE,
                            'SQLERRM', SQLERRM,
                            'SQLSTATE', SQLSTATE);	

END;
$$
;