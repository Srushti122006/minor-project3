USE redflag;

SELECT COUNT(*) AS total_transactions
FROM transactions;

SELECT COUNT(DISTINCT user_id) AS total_users
FROM transactions;

SELECT MIN(txn_time) AS first_transaction,
       MAX(txn_time) AS last_transaction
FROM transactions;


-- =====================================================================
-- PATTERN 1 · VELOCITY FRAUD
-- Detect users making 30 or more transactions on a single day.
-- Expected result: approximately 45-55 user-days.
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS transaction_date,
    COUNT(*) AS daily_transaction_count
FROM transactions
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY daily_transaction_count DESC;

-- Findings:
-- The query identified 50 suspicious user-days where a user made
-- 30 or more transactions in a single day. These high transaction
-- frequencies may indicate automated or fraudulent activity.

-- =====================================================================
-- PATTERN 2 · ROUND-AMOUNT CLUSTERING
-- Detect users making 15 or more transactions using exact round amounts.
-- Expected result: exactly 25 suspects.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS round_amount_transactions
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_amount_transactions DESC;

-- Findings:
-- The query identified 25 users who made 15 or more transactions
-- using predefined round amounts such as ₹100, ₹500, ₹1,000 and ₹10,000.
-- Repeated use of round amounts can be a potential indicator of
-- structured or suspicious transactions.

-- =====================================================================
-- PATTERN 3 · CARD TESTING
-- Detect users making 30 or more transactions below ₹10 in one day.
-- Expected result: exactly 20 suspects.
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS transaction_date,
    COUNT(*) AS tiny_transaction_count
FROM transactions
WHERE amount < 10
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY tiny_transaction_count DESC;

-- Findings:
-- The query identified 20 users who performed 30 or more transactions
-- below ₹10 on a single day. A high number of very small transactions
-- may indicate card testing or verification activity.

-- =====================================================================
-- PATTERN 4 · FAILED-THEN-SUCCEEDED
-- Detect users with 20+ failed transactions followed within 2 minutes
-- by a successful transaction of the same amount.
-- Expected result: exactly 25 suspects.
-- =====================================================================

SELECT
    f.user_id,
    COUNT(*) AS failed_success_pairs
FROM transactions AS f
JOIN transactions AS s
    ON s.user_id = f.user_id
    AND s.amount = f.amount
    AND s.status = 'SUCCESS'
    AND s.txn_time >= f.txn_time
    AND s.txn_time <= DATE_ADD(f.txn_time, INTERVAL 2 MINUTE)
WHERE f.status = 'FAILED'
GROUP BY f.user_id
HAVING COUNT(*) >= 20
ORDER BY failed_success_pairs DESC;

-- Findings:
-- The query identified 25 users with at least 20 instances where a
-- failed transaction was followed by a successful transaction of the
-- same amount within two minutes. This repeated pattern may indicate
-- suspicious transaction retries.

-- =====================================================================
-- PATTERN 5 · ODD-HOUR CONCENTRATION
-- Detect users with at least 30 transactions where 80% or more
-- occur between 2 AM and 5 AM.
-- Expected result: exactly 20 suspects.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) AS odd_hour_transactions,
    ROUND(
        SUM(
            CASE
                WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS odd_hour_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND
   SUM(
       CASE
           WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
           ELSE 0
       END
   ) / COUNT(*) >= 0.80
ORDER BY odd_hour_percentage DESC;

-- Findings:
-- The query identified 20 users with at least 30 transactions where
-- 80% or more occurred between 2 AM and 5 AM. Such concentration of
-- activity during unusual hours may indicate automated or suspicious
-- transaction behavior.


-- =====================================================================
-- PATTERN 6 · MULE ACCOUNTS
-- Detect users where 5+ CREDIT transactions are followed within
-- 30 minutes by a DEBIT worth at least 70% of the CREDIT.
-- Expected result: exactly 30 suspects.
-- =====================================================================

SELECT
    c.user_id,
    COUNT(*) AS mule_instances
FROM transactions AS c
WHERE c.txn_type = 'CREDIT'
  AND EXISTS (
      SELECT 1
      FROM transactions AS d
      WHERE d.user_id = c.user_id
        AND d.txn_type = 'DEBIT'
        AND d.txn_time >= c.txn_time
        AND d.txn_time <= DATE_ADD(c.txn_time, INTERVAL 30 MINUTE)
        AND d.amount >= c.amount * 0.70
  )
GROUP BY c.user_id
HAVING COUNT(*) >= 5
ORDER BY mule_instances DESC;

-- Findings:
-- The query identified 30 users with at least 5 instances where a
-- credit transaction was followed within 30 minutes by a debit
-- worth at least 70% of the credited amount. This rapid movement
-- of funds may indicate potential mule-account behavior.

-- =====================================================================
-- PATTERN 7 · REFUND ABUSE
-- Detect users with 20+ transactions and a refund ratio above 40%.
-- Expected result: approximately 24-25 suspects.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) AS refund_transactions,
    ROUND(
        SUM(
            CASE
                WHEN txn_type = 'REFUND' THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS refund_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND
   SUM(
       CASE
           WHEN txn_type = 'REFUND' THEN 1
           ELSE 0
       END
   ) / COUNT(*) > 0.40
ORDER BY refund_percentage DESC;

-- Findings:
-- The query identified 24 users who had at least 20 transactions
-- and a refund ratio above 40%. A high proportion of refunds may
-- indicate potential refund abuse or unusual transaction behavior.

-- =====================================================================
-- PATTERN 8 · MERCHANT COLLUSION
-- Detect merchants where the top 5 users generate more than 60%
-- of the merchant's total transaction value.
-- Expected result: exactly 15 merchants.
-- =====================================================================

WITH user_merchant_volume AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_volume
    FROM transactions
    GROUP BY
        merchant_id,
        user_id
),

ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_volume,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_volume DESC
        ) AS user_rank
    FROM user_merchant_volume
),

top_five_volume AS (
    SELECT
        merchant_id,
        SUM(user_volume) AS top_five_volume
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY merchant_id
),

merchant_total AS (
    SELECT
        merchant_id,
        SUM(amount) AS total_volume
    FROM transactions
    GROUP BY merchant_id
)

SELECT
    m.merchant_id,
    t.top_five_volume,
    m.total_volume,
    ROUND(
        t.top_five_volume / m.total_volume * 100,
        2
    ) AS top_five_percentage
FROM merchant_total AS m
JOIN top_five_volume AS t
    ON m.merchant_id = t.merchant_id
WHERE t.top_five_volume / m.total_volume > 0.60
ORDER BY top_five_percentage DESC;

-- Findings:
-- The query identified 15 merchants where the top five users
-- contributed more than 60% of the merchant's total transaction
-- volume. Such concentration may indicate potential collusion or
-- coordinated transaction activity.

-- =====================================================================
-- PATTERN 9 · JUST-UNDER-THRESHOLD / STRUCTURING
-- Detect users making 10 or more transactions exactly at ₹9,999.
-- Expected result: exactly 20 suspects.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS threshold_transactions
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_transactions DESC;

-- Findings:
-- The query identified 20 users who made 10 or more transactions
-- exactly at ₹9,999. Repeated transactions just below a common
-- threshold may indicate possible structuring to avoid transaction
-- limits or monitoring thresholds.

-- =====================================================================
-- PATTERN 10 · DORMANT-THEN-ACTIVE
-- Detect users with a 90+ day transaction gap followed by
-- at least 15 later transactions.
-- Expected result: approximately 25-27 suspects.
-- =====================================================================

WITH transaction_history AS (
    SELECT
        user_id,
        txn_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
),

dormant_gaps AS (
    SELECT
        user_id,
        txn_time AS activation_time,
        previous_txn_time,
        TIMESTAMPDIFF(
            DAY,
            previous_txn_time,
            txn_time
        ) AS inactive_days
    FROM transaction_history
    WHERE previous_txn_time IS NOT NULL
      AND TIMESTAMPDIFF(
          DAY,
          previous_txn_time,
          txn_time
      ) >= 90
),

post_gap_activity AS (
    SELECT
        d.user_id,
        d.activation_time,
        d.inactive_days,
        COUNT(t.txn_id) AS transactions_after_gap
    FROM dormant_gaps AS d
    JOIN transactions AS t
        ON t.user_id = d.user_id
       AND t.txn_time > d.activation_time
    GROUP BY
        d.user_id,
        d.activation_time,
        d.inactive_days
)

SELECT
    user_id,
    activation_time,
    inactive_days,
    transactions_after_gap
FROM post_gap_activity
WHERE transactions_after_gap >= 15
ORDER BY transactions_after_gap DESC;

-- Findings:
-- The query identified approximately 26 suspicious user activity
-- periods where a user remained inactive for at least 90 days and
-- then performed 15 or more subsequent transactions. Sudden
-- reactivation after a long dormant period may indicate unusual
-- account activity.

-- =====================================================================
-- PATTERN 11 · VELOCITY SPIKE
-- Detect users whose peak monthly transaction count is at least
-- 5 times their average monthly transaction count, with a peak
-- of at least 20 transactions.
-- Expected result: approximately 35-45 suspects according to the brief.
-- =====================================================================

WITH monthly_transactions AS (
    SELECT
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS transaction_month,
        COUNT(*) AS monthly_transaction_count
    FROM transactions
    GROUP BY
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m')
),

user_statistics AS (
    SELECT
        user_id,
        AVG(monthly_transaction_count) AS average_monthly_transactions,
        MAX(monthly_transaction_count) AS peak_monthly_transactions
    FROM monthly_transactions
    GROUP BY user_id
)

SELECT
    user_id,
    ROUND(average_monthly_transactions, 2)
        AS average_monthly_transactions,
    peak_monthly_transactions,
    ROUND(
        peak_monthly_transactions /
        average_monthly_transactions,
        2
    ) AS velocity_ratio
FROM user_statistics
WHERE peak_monthly_transactions >= 20
  AND peak_monthly_transactions /
      average_monthly_transactions >= 5
ORDER BY velocity_ratio DESC;

-- Findings:
-- The query identifies users whose peak monthly transaction count
-- is at least 20 transactions and is at least five times their
-- average monthly transaction count. These sudden increases in
-- transaction activity may indicate abnormal or potentially
-- fraudulent behavior.
-- Total suspects identified: 3
-- =====================================================================
-- PATTERN 12 · GEOGRAPHIC IMPOSSIBILITY
-- Detect users who transact in different cities within 60 minutes.
-- Expected result: exactly 15 suspects.
-- =====================================================================

WITH transaction_history AS (
    SELECT
        user_id,
        txn_id,
        city,
        txn_time,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
)

SELECT
    user_id,
    txn_id,
    previous_city,
    city AS current_city,
    previous_txn_time,
    txn_time AS current_txn_time,
    TIMESTAMPDIFF(
        MINUTE,
        previous_txn_time,
        txn_time
    ) AS minutes_between_transactions
FROM transaction_history
WHERE previous_city IS NOT NULL
  AND previous_city <> city
  AND TIMESTAMPDIFF(
      MINUTE,
      previous_txn_time,
      txn_time
  ) <= 60
ORDER BY minutes_between_transactions ASC;

-- Findings:
-- The query identified 15 users who performed transactions in
-- different cities within a 60-minute interval. Such rapid changes
-- in transaction location may indicate geographically impossible
-- activity or potential account compromise.