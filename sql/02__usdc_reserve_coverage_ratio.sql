-- 02_usdc_reserve_coverage_ratio.sql
-- USDC Circulating Supply and Estimated Reserve Coverage Ratio
--
-- Method:
-- 1. Calculate daily USDC circulating supply from mint / burn events.
-- 2. Manually input issuer-published reserve figures.
-- 3. Use the latest available reserve figure as of each day.
-- 4. Estimate daily reserve surplus and coverage ratio.
--
-- Important:
-- This is an as-of reserve coverage estimate, not a real-time reserve attestation.
-- Replace the sample reserve figures below with actual figures from issuer disclosures.

WITH reserve_reports AS (
    SELECT *
    FROM (
        VALUES
            (
                DATE '2025-01-31',
                53283800358.00,
                'Circle USDC Reserve Report as of 2025-01-31'
            ),
            (
                DATE '2025-02-28',
                56349194760.00,
                'Circle USDC Reserve Report as of 2025-02-28'
            ),
            (
                DATE '2025-03-31',
                60040707040.00,
                'Circle USDC Reserve Report as of 2025-03-31'
            ),
            (
                DATE '2025-04-30',
                61477725087.00,
                'Circle USDC Reserve Report as of 2025-04-30'
            )
    ) AS t(
        report_as_of_date,
        reported_reserves_usd,
        source_note
    )
),

mint_burn_events AS (
    SELECT
        block_date AS day,
        CASE
            WHEN "from" = 0x0000000000000000000000000000000000000000
                THEN amount
            ELSE 0
        END AS minted_amount,
        CASE
            WHEN "to" = 0x0000000000000000000000000000000000000000
                THEN amount
            ELSE 0
        END AS burned_amount,
        CASE
            WHEN "from" = 0x0000000000000000000000000000000000000000
                THEN amount
            WHEN "to" = 0x0000000000000000000000000000000000000000
                THEN -amount
            ELSE 0
        END AS supply_delta
    FROM tokens.transfers
    WHERE blockchain = 'ethereum'
      AND contract_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
      AND block_date >= DATE '2018-09-26'
      AND (
          "from" = 0x0000000000000000000000000000000000000000
          OR "to" = 0x0000000000000000000000000000000000000000
      )
),

daily_supply_change AS (
    SELECT
        day,
        SUM(minted_amount) AS daily_minted,
        SUM(burned_amount) AS daily_burned,
        SUM(supply_delta) AS daily_net_change
    FROM mint_burn_events
    GROUP BY 1
),

date_spine AS (
    SELECT day
    FROM UNNEST(
        SEQUENCE(
            DATE '2018-09-26',
            CURRENT_DATE,
            INTERVAL '1' DAY
        )
    ) AS t(day)
),

daily_filled AS (
    SELECT
        d.day,
        COALESCE(s.daily_minted, 0) AS daily_minted,
        COALESCE(s.daily_burned, 0) AS daily_burned,
        COALESCE(s.daily_net_change, 0) AS daily_net_change
    FROM date_spine d
    LEFT JOIN daily_supply_change s
        ON d.day = s.day
),

supply_trend AS (
    SELECT
        day,
        daily_minted,
        daily_burned,
        daily_net_change,
        SUM(daily_net_change) OVER (
            ORDER BY day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS circulating_supply
    FROM daily_filled
),

coverage AS (
    SELECT
        s.day,
        s.daily_minted,
        s.daily_burned,
        s.daily_net_change,
        s.circulating_supply,
        MAX_BY(r.reported_reserves_usd, r.report_as_of_date) AS latest_reported_reserves_usd,
        MAX_BY(r.source_note, r.report_as_of_date) AS reserve_source_note,
        MAX(r.report_as_of_date) AS reserve_report_as_of
    FROM supply_trend s
    LEFT JOIN reserve_reports r
        ON r.report_as_of_date <= s.day
    GROUP BY
        s.day,
        s.daily_minted,
        s.daily_burned,
        s.daily_net_change,
        s.circulating_supply
)

SELECT
    day,
    reserve_report_as_of,
    daily_minted,
    daily_burned,
    daily_net_change,
    circulating_supply,
    latest_reported_reserves_usd,
    latest_reported_reserves_usd - circulating_supply AS reserve_surplus_usd,
    latest_reported_reserves_usd / NULLIF(circulating_supply, 0) * 100 AS coverage_ratio_pct,
    CASE
        WHEN latest_reported_reserves_usd IS NULL THEN 'NO RESERVE DATA'
        WHEN latest_reported_reserves_usd / NULLIF(circulating_supply, 0) >= 1 THEN 'PASS'
        ELSE 'FLAG'
    END AS coverage_status,
    reserve_source_note
FROM coverage
WHERE day >= DATE '2025-01-01'
ORDER BY day DESC;
