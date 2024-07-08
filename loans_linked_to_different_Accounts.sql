select B.CIF_ID "Loan CIF",A.DIS_AMT "DISBURSED_AMOUNT",
            b.ACCT_NAME "LOAN_ACCOUNT_NAME",
            CAST(b.FORACID AS VARCHAR2(50)) AS loan_account_no, trunc(B.ACCT_OPN_DATE,'dd') "LOAN_ACCOUNT_OPEN_DATE",
            b.SOL_ID,INITCAP(CONCAT(CONCAT(B.SCHM_CODE,'-'),SCHM.SCHM_DESC)) "SCHEME_DESC",b.ACCT_MGR_USER_ID,
            b.CLR_BAL_AMT "UNCONVERTED_BALANCE",
            c.ACCT_NAME "OPERATIVE_ACCT_NAME",
            C.CIF_ID "OPERATIVE ACCOUNT_CIF",
            CAST(c.FORACID AS VARCHAR2(50)) "OPERATIVE_ACCOUNT"
from UGEDW.STG_LAM   a
            left join (select * from ugedw.stg_gam   where SCHM_TYPE = 'LAA' AND bank_id = '54') b on b.ACID = A.ACID
            left join (select * from ugedw.stg_gam   where SCHM_TYPE in ('CAA','SBA') AND bank_id = '54') c on c.ACID = A.OP_ACID
            left join  UGEDW.SCHM_DESC schm on SCHM.SCHM_CODE = B.SCHM_CODE 
where A.BANK_ID = '54'
            --and B.SOL_ID in ('001','002')
            and B.CIF_ID <> C.CIF_ID
            and B.ACCT_CLS_FLG = 'N'
            and B.CLR_BAL_AMT <0
            and B.ACCT_NAME not in C.ACCT_NAME
            and C.ACCT_NAME not in B.ACCT_NAME
            and B.ACCT_NAME <> C.ACCT_NAME
            and concat(concat(regexp_substr(B.ACCT_NAME,'[^ ]+',1,1),' '),(regexp_substr(B.ACCT_NAME,'[^ ]+',1,2))) 
                <>
                concat(concat(regexp_substr(C.ACCT_NAME,'[^ ]+',1,1),' '),(regexp_substr(C.ACCT_NAME,'[^ ]+',1,2))) 
           and concat(concat(regexp_substr(B.ACCT_NAME,'[^ ]+',1,1),' '),(regexp_substr(B.ACCT_NAME,'[^ ]+',1,3))) 
            <>
           concat(concat(regexp_substr(C.ACCT_NAME,'[^ ]+',1,1),' '),(regexp_substr(C.ACCT_NAME,'[^ ]+',1,3))) 
           and B.ACCT_OPN_DATE between '01-Apr-24' and '24-Jun-24'