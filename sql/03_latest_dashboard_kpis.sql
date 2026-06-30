-- 03_latest_dashboard_kpis.sql
-- Latest KPI Summary for USDC Supply and Reserve Coverage Dashboard
--
-- Replace reserve report figures before publishing.

WITH reserve_reports AS (
    SELECT *
    FROM (
        VALUES
            -- Replace these sample figures before publishing.
            (DATE '2025-01-31', 42000000000.00, 'Sample placeholder - replace with actual issuer reserve figure'),
            (DATE '2025-02-28', 43000000000.00, 'Sample placeholder - replace with actual issuer reserve figure'),
            (DATE '2025-03-31', 44000000000.00, 'Sample placeholder - replace with actual issuer reserve figure'),
            (DATE '2025-04-30', 45000000000.00, 'Sample placeholder - replace with actual issuer reserve figure')
    ) AS t(report_as_of_date, reported_reserves_usd, source_note)
),

mint_burn_events AS (
    SELECT
        block_date AS day,
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
        COALESCE(s.daily_net_change, 0) AS daily_net_change
    FROM date_spine d
    LEFT JOIN daily_supply_change s
        ON d.day = s.day
),

supply_trend AS (
    SELECT
        day,
        SUM(daily_net_change) OVER (
            ORDER BY day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS circulating_supply
    FROM daily_filled
),

latest_supply AS (
    SELECT
        day,
        circulating_supply
    FROM supply_trend
    WHERE day = (
        SELECT MAX(day)
        FROM supply_trend
    )
),

latest_reserve AS (
    SELECT
        report_as_of_date,
        reported_reserves_usd,
        source_note
    FROM reserve_reports
    WHERE report_as_of_date = (
        SELECT MAX(report_as_of_date)
        FROM reserve_reports
    )
)

SELECT
    s.day AS latest_supply_date,
    r.report_as_of_date AS latest_reserve_report_date,
    s.circulating_supply,
    r.reported_reserves_usd,
    r.reported_reserves_usd - s.circulating_supply AS reserve_surplus_usd,
    r.reported_reserves_usd / NULLIF(s.circulating_supply, 0) * 100 AS coverage_ratio_pct,
    CASE
        WHEN r.reported_reserves_usd / NULLIF(s.circulating_supply, 0) >= 1 THEN 'PASS'
        ELSE 'FLAG'
    END AS coverage_status,
    r.source_note
FROM latest_supply s
CROSS JOIN latest_reserve r;
