WITH accounts AS (
  SELECT 
    gam.acid,
    gam.RCRE_TIME                     AS created_at,
    gam.sol_id,
    branch.branch_name,
    CAST(gam.foracid AS VARCHAR2(50)) AS account_no, -- Adjust VARCHAR2(50) based on your actual column width
    acct_name                         AS account_name,
    sanct_lim,
    clr_bal_amt,
    gam.schm_code,
    product.schm_desc                 AS product_name,
    gam.schm_type,
    cif_id,
    acct_mgr_user_id
  FROM ugedw.stg_gam gam 
  LEFT JOIN ugedw.branch_details branch ON
    gam.sol_id = branch.sol_id
  LEFT JOIN ugedw.stg_gsp product ON
    gam.schm_code = product.schm_code AND
    product.bank_id = '54'
  WHERE
    gam.bank_id = '54' AND
    gam.acct_cls_flg = 'N' AND
    gam.clr_bal_amt < 0 AND
    gam.schm_type = 'LAA' AND
    gam.schm_code NOT IN (
      'LA590',
      'LA591',
      'LA592',
      'LA593',
      'LA594',
      'LA595',
      'LA596',
      'LA597',
      'LA598',
      'LA512') AND
    gam.acct_mgr_user_id IS NULL 
),

classify AS (
  SELECT 
    B2K_ID AS acid,
    sub_classification_system
  FROM ugedw.stg_acd
  WHERE
    bank_id = '54'
),

merged AS (
  SELECT 
    accounts.acid,
    accounts.created_at,
    accounts.sol_id,
    accounts.branch_name,
    accounts.account_no,
    accounts.account_name,
    accounts.sanct_lim                 AS disbursed_amount,
    accounts.clr_bal_amt * -1          AS outstanding_balance,
    accounts.schm_code                 AS scheme_code,
    accounts.schm_type                 AS scheme_type,
    accounts.cif_id                    AS cif_id,
    accounts.acct_mgr_user_id          AS account_manager,
    classify.sub_classification_system AS classification
  FROM accounts 
  LEFT JOIN classify ON
    accounts.acid = classify.acid
)

SELECT 
  sol_id,
  created_at,
  branch_name,
  account_no,
  account_name,
  disbursed_amount,
  outstanding_balance,
  CASE
    WHEN 
      outstanding_balance >= 0 AND outstanding_balance < 500000 
    THEN '0 - 500K'
    WHEN 
      outstanding_balance >= 500000 AND outstanding_balance < 1000000 
    THEN '500K - 1M'
    WHEN 
      outstanding_balance >= 1000000 AND outstanding_balance < 2000000 
    THEN '1M - 2M'
    WHEN 
      outstanding_balance >= 2000000 AND outstanding_balance < 5000000 
    THEN '2M - 5M'
    WHEN 
      outstanding_balance >= 5000000 AND outstanding_balance < 10000000 
    THEN '5M - 10M'
    ELSE 'Above 10M'
  END AS balance_band,
  scheme_code,
  scheme_type,
  cif_id,
  account_manager,
  CASE 
    WHEN 
      classification = 'NORM' 
    THEN 'Normal'
    WHEN 
      classification = 'WATC' 
    THEN 'Watch'
    WHEN 
      classification = 'SUBS' 
    THEN 'Substandard'
    WHEN 
      classification = 'DBTL' 
    THEN 'Doubtful'
    WHEN 
      classification = 'LOSS' 
    THEN 'Loss'
  END AS classification,
  CASE 
    WHEN 
      classification = 'NORM' 
    THEN 1
    WHEN 
      classification = 'WATC' 
    THEN 2
    WHEN 
      classification = 'SUBS' 
    THEN 3
    WHEN 
      classification = 'DBTL' 
    THEN 4
    WHEN 
      classification = 'LOSS' 
    THEN 5
  END AS band_order
FROM merged;