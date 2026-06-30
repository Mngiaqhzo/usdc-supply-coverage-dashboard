-- 01_usdc_supply_trend.sql
-- USDC Circulating Supply Trend on Ethereum
--
-- Method:
-- Mint  = Transfer from zero address
-- Burn  = Transfer to zero address
-- Daily net change = minted - burned
-- Circulating supply = cumulative sum of daily net change

WITH mint_burn_events AS (
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
)

SELECT
    day,
    daily_minted,
    daily_burned,
    daily_net_change,
    circulating_supply
FROM supply_trend
ORDER BY day DESC;
