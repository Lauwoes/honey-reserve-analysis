-- Queries against the SQLite database the notebook writes (honey.db).
--
-- The notebook produces one flat table, `honey`, with one row per state-year:
--   state_alpha, year, production_lb, yield_lb_colony, price_usd_lb,
--   value_usd, colonies, share
--
-- Run one from Python by pasting it into a triple-quoted string:
--   q = """ ... """
--   pd.read_sql(q, con)
-- Splitting this file on semicolons does not work, because comments and
-- strings contain them too. Paste queries individually, or open honey.db in
-- DB Browser for SQLite and run them one at a time.


-- 1. Concentration of production, by year.
--    OVER (PARTITION BY year) computes a yearly total without collapsing the
--    rows, which is what makes the share and the rank available on every row
--    at once. Note the 1.0 multiplier: SQLite does integer division otherwise.
WITH ranked AS (
    SELECT
        year,
        state_alpha,
        production_lb,
        production_lb * 1.0 / SUM(production_lb) OVER (PARTITION BY year) AS share,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY production_lb DESC)   AS rk
    FROM honey
    WHERE production_lb IS NOT NULL
)
SELECT
    year,
    ROUND(SUM(CASE WHEN rk <= 5  THEN share END) * 100, 1) AS top5_pct,
    ROUND(SUM(CASE WHEN rk <= 10 THEN share END) * 100, 1) AS top10_pct,
    COUNT(*)                                               AS reporting_states
FROM ranked
GROUP BY year
ORDER BY year;


-- 2. Which states make the top five, and how often.
WITH ranked AS (
    SELECT
        year,
        state_alpha,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY production_lb DESC) AS rk
    FROM honey
    WHERE production_lb IS NOT NULL
)
SELECT state_alpha, COUNT(*) AS years_in_top5
FROM ranked
WHERE rk <= 5
GROUP BY state_alpha
ORDER BY years_in_top5 DESC;


-- 3. State summary: scale, yield, price and volatility together.
--    This is the table the price finding comes out of.
SELECT
    state_alpha,
    COUNT(*)                                         AS years,
    ROUND(AVG(production_lb) / 1e6, 1)               AS mean_prod_mlb,
    ROUND(AVG(yield_lb_colony), 1)                   AS mean_yield,
    ROUND(AVG(price_usd_lb), 2)                      AS mean_price,
    ROUND(AVG(yield_lb_colony * yield_lb_colony)
          - AVG(yield_lb_colony) * AVG(yield_lb_colony), 1) AS var_yield
FROM honey
WHERE yield_lb_colony IS NOT NULL
GROUP BY state_alpha
HAVING years >= 7
ORDER BY mean_prod_mlb DESC;


-- 4. Yield per colony over time with a three-year rolling mean, so a single
--    bad season is distinguishable from a trend.
SELECT
    state_alpha,
    year,
    yield_lb_colony,
    ROUND(AVG(yield_lb_colony) OVER (
        PARTITION BY state_alpha
        ORDER BY year
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1) AS yield_3yr_mean
FROM honey
WHERE yield_lb_colony IS NOT NULL
ORDER BY state_alpha, year;


-- 5. National totals by year. Yield and price are recomputed from the
--    aggregates rather than averaged across states, because averaging state
--    yields would weight North Dakota the same as Rhode Island.
SELECT
    year,
    ROUND(SUM(production_lb) / 1e6, 1)                       AS production_mlb,
    ROUND(SUM(production_lb) / NULLIF(SUM(colonies), 0), 1)   AS national_yield,
    ROUND(SUM(value_usd) / NULLIF(SUM(production_lb), 0), 3)  AS implied_price_lb
FROM honey
GROUP BY year
ORDER BY year;
