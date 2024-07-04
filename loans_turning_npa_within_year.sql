SELECT
  gam.ACID,  
  gam.SOL_ID, 
  branch.BRANCH_NAME                                  AS branch,
  branch.REGION, 
  CAST(gam.CIF_ID AS VARCHAR2(50))                    AS cif_id, 
  CAST(gam.FORACID AS VARCHAR2(50))                   AS account_no, 
  gam.ACCT_NAME                                       AS account_name,
  code.SCHM_DESC                                      AS product_name,
  gam.rcre_time                                       AS disbursed_date,
  TO_CHAR(gam.rcre_time, 'MON-YYYY')                  AS disbursed_month,
  gam.CLR_BAL_AMT * -1                                AS outstanding_balance,
  CASE 
    WHEN 
      gam.CLR_BAL_AMT * -1 BETWEEN 1000 AND 100000 
    THEN '1K - 100K'
    WHEN 
      gam.CLR_BAL_AMT * -1 BETWEEN 100001 AND 500000 
    THEN '100K - 500K'
    WHEN 
      gam.CLR_BAL_AMT * -1 BETWEEN 500001 AND 1000000 
    THEN '500K - 1M'
    WHEN 
      gam.CLR_BAL_AMT * -1 BETWEEN 1000001 AND 2000000 
    THEN '1M - 2M'
    WHEN 
      gam.CLR_BAL_AMT * -1 BETWEEN 2000001 AND 5000000 
    THEN '2M - 5M'
    WHEN 
      gam.CLR_BAL_AMT * -1 > 5000000 THEN 'Above 5M'
  END                                                  AS band,
  lam.DIS_AMT                                          AS disbursed_amount,
  CASE 
    WHEN 
      class.sub_classification_system = 'NORM' 
    THEN 'Normal'
    WHEN 
      class.sub_classification_system = 'WATC' 
    THEN 'Watch'
    WHEN 
      class.sub_classification_system = 'SUBS' 
    THEN 'Substandard'
    WHEN 
      class.sub_classification_system = 'DBTL' 
    THEN 'Doubtful'
    WHEN 
      class.sub_classification_system = 'LOSS' 
    THEN 'Loss'
  END                                                  AS classification,
  CASE 
    WHEN 
      class.sub_classification_system IN (
        'SUBS', 
        'DBTL',
        'LOSS'
        ) 
    THEN 'Non Peforming'
    ELSE 'Performing'
  END                                                  AS loan_status
FROM ugedw.stg_gam gam
LEFT JOIN ugedw.branch_details branch ON 
  gam.sol_id = branch.sol_id
LEFT JOIN ugedw.schm_desc code ON
  gam.schm_code = code.schm_code 
LEFT JOIN ugedw.stg_lam lam ON
  gam.acid = lam.acid
LEFT JOIN ugedw.stg_acd class ON
  gam.acid = class.b2k_id
WHERE
  gam.bank_id = '54' AND
  gam.rcre_time BETWEEN SYSDATE - INTERVAL '1' YEAR AND SYSDATE AND
  gam.acct_cls_flg = 'N' AND
  gam.clr_bal_amt * -1 > 1000 AND -- This is to get balance more than 1000
  gam.schm_type = 'LAA'