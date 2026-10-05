# RedFlag – Fraud Detection Using SQL

## About the Project

RedFlag is a SQL-based fraud detection project created to identify unusual and suspicious transaction patterns from a large transaction dataset.

The main aim of this project is to use SQL queries to find different types of fraudulent or abnormal transaction activities. I worked on different SQL concepts like filtering, grouping, joins, subqueries, CTEs and window functions to analyze the transactions.

## Objective

The main objectives of this project are:

* Identify suspicious transaction patterns.
* Detect unusual user and merchant activities.
* Use SQL to analyze a large number of transactions.
* Find users or merchants that match different fraud patterns.
* Understand how SQL can be used for fraud detection and data analysis.

## Fraud Patterns Detected

I used SQL queries to detect the following 12 patterns:

1. **Velocity Fraud** – Finding users making a very high number of transactions in one day.
2. **Round-Amount Clustering** – Finding users repeatedly using common round transaction amounts.
3. **Card Testing** – Detecting users making many very small transactions.
4. **Failed-Then-Succeeded** – Finding repeated failed transactions followed by successful transactions.
5. **Odd-Hour Concentration** – Detecting users whose transactions are highly concentrated during unusual hours.
6. **Mule Accounts** – Finding accounts where money is quickly transferred after receiving it.
7. **Refund Abuse** – Identifying users with an unusually high percentage of refunds.
8. **Merchant Collusion** – Finding merchants where a small number of users account for a large part of the transaction volume.
9. **Just-Under-Threshold** – Detecting repeated transactions of ₹9,999.
10. **Dormant-Then-Active** – Finding accounts that become highly active after a long inactive period.
11. **Velocity Spike** – Detecting sudden increases in monthly transaction activity.
12. **Geographic Impossibility** – Finding transactions made in different cities within a very short time.

## Technologies Used

* MySQL
* SQL
* MySQL Workbench
* GitHub

## SQL Concepts Used

During this project, I used different SQL concepts such as:

* SELECT and WHERE
* GROUP BY
* HAVING
* ORDER BY
* Aggregate functions
* CASE statements
* JOIN
* EXISTS
* Common Table Expressions (CTEs)
* Window Functions
* `LAG()`
* `ROW_NUMBER()`
* Date and time functions
* Subqueries

## Project Structure

```text
minor-project-3
│
├── README.md
├── RedFlag_Srushti.sql
│
└── screenshots/
    ├── P1_velocity.png
    ├── P2_round_amount.png
    ├── P3_card_testing.png
    ├── P4_failed_success.png
    ├── P5_odd_hour.png
    ├── P6_mule_accounts.png
    ├── P7_refund_abuse.png
    ├── P8_merchant_collusion.png
    ├── P9_threshold.png
    ├── P10_dormant_active.png
    ├── P11_velocity_spike.png
    └── P12_geographic.png
```

## How I Worked on the Project

First, I imported the transaction dataset into MySQL and checked whether the data was loaded correctly.

After that, I created separate SQL queries for each fraud pattern. Each query uses different conditions based on the pattern that needs to be detected.

I then executed the queries and checked the results to make sure that the queries were working correctly.

For some of the more advanced patterns, I used CTEs and window functions such as `LAG()` and `ROW_NUMBER()` to compare transactions and identify unusual behaviour.

## Key Findings

The analysis helped identify different types of suspicious transaction behaviour, such as:

* High-frequency transactions by the same user.
* Repeated small-value transactions.
* Unusual transaction timings.
* Large numbers of refunds.
* Suspicious movement of money after credits.
* High concentration of transactions among a few users.
* Sudden changes in user activity.
* Transactions occurring in geographically impossible time intervals.

These patterns can be useful as indicators for further fraud investigation.

## Learning Outcome

Through this project, I got practical experience in using SQL for data analysis instead of only using it for basic database operations.

I also learned how different SQL techniques such as **CTEs, joins, aggregation and window functions** can be combined to detect patterns in transaction data.

## Note

The original transaction dataset is not included in this repository because of its size and project submission restrictions.

The repository contains the SQL detection queries and project documentation.

## Author

**Srushti Pujari**

Student | Learning SQL & Data Analytics
