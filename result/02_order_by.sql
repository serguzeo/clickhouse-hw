-- Подготовка таблиц с разными ключами сортировки
DROP TABLE IF EXISTS takt.hw_events_country;
DROP TABLE IF EXISTS takt.hw_events_time;

CREATE TABLE takt.hw_events_time
AS takt.listening_events
ENGINE = MergeTree
ORDER BY (ended_at)
SETTINGS index_granularity = 8192, index_granularity_bytes = 0;

CREATE TABLE takt.hw_events_country
AS takt.hw_events_time
ENGINE = MergeTree
ORDER BY (country, ended_at)
SETTINGS index_granularity = 8192, index_granularity_bytes = 0;

INSERT INTO takt.hw_events_time
SELECT * FROM takt.listening_events
WHERE ended_at >= toDateTime('2026-10-13 00:00:00', 'UTC')
  AND ended_at < toDateTime('2026-10-27 00:00:00', 'UTC');

INSERT INTO takt.hw_events_country
SELECT * FROM takt.hw_events_time;

OPTIMIZE TABLE takt.hw_events_time FINAL;
OPTIMIZE TABLE takt.hw_events_country FINAL;

SELECT
    table,
    count() AS active_parts,
    sum(rows) AS events
FROM system.parts
WHERE database = 'takt'
  AND active
  AND table IN ('hw_events_time', 'hw_events_country')
GROUP BY table
ORDER BY table;

SHOW CREATE TABLE takt.hw_events_time;
SHOW CREATE TABLE takt.hw_events_country;



-- Подготовка отчетов

-- Германия, ключ по времени
SELECT
    country,
    count() AS events_total,
    countIf(played_seconds < 20) AS events_under_20,
    round(100.0 * events_under_20 / events_total, 2) AS under_20_percent
FROM takt.hw_events_time
WHERE ended_at >= toDateTime('2026-10-24 00:00:00', 'UTC')
  AND ended_at <  toDateTime('2026-10-25 00:00:00', 'UTC')
  AND country = 'DE'
GROUP BY country
ORDER BY country
SETTINGS
    max_threads = 4,
    use_query_cache = 0,
    use_query_condition_cache = 0,
    optimize_move_to_prewhere = 0;

-- Германия, ключ по стране и времени
SELECT
    country,
    count() AS events_total,
    countIf(played_seconds < 20) AS events_under_20,
    round(100.0 * events_under_20 / events_total, 2) AS under_20_percent
FROM takt.hw_events_country
WHERE ended_at >= toDateTime('2026-10-24 00:00:00', 'UTC')
  AND ended_at <  toDateTime('2026-10-25 00:00:00', 'UTC')
  AND country = 'DE'
GROUP BY country
ORDER BY country
SETTINGS
    max_threads = 4,
    use_query_cache = 0,
    use_query_condition_cache = 0,
    optimize_move_to_prewhere = 0;

-- Все страны, ключ по времени
SELECT
    country,
    count() AS events_total,
    countIf(played_seconds < 20) AS events_under_20,
    round(100.0 * events_under_20 / events_total, 2) AS under_20_percent
FROM takt.hw_events_time
WHERE ended_at >= toDateTime('2026-10-24 00:00:00', 'UTC')
  AND ended_at <  toDateTime('2026-10-25 00:00:00', 'UTC')
GROUP BY country
ORDER BY country
SETTINGS
    max_threads = 4,
    use_query_cache = 0,
    use_query_condition_cache = 0,
    optimize_move_to_prewhere = 0;

-- Все страны, ключ по стране и времени
SELECT
    country,
    count() AS events_total,
    countIf(played_seconds < 20) AS events_under_20,
    round(100.0 * events_under_20 / events_total, 2) AS under_20_percent
FROM takt.hw_events_country
WHERE ended_at >= toDateTime('2026-10-24 00:00:00', 'UTC')
  AND ended_at <  toDateTime('2026-10-25 00:00:00', 'UTC')
GROUP BY country
ORDER BY country
SETTINGS
    max_threads = 4,
    use_query_cache = 0,
    use_query_condition_cache = 0,
    optimize_move_to_prewhere = 0;



-- Построение планов

-- План: германия, ключ по времени
EXPLAIN indexes = 1
SELECT
    country,
    count() AS events_total,
    countIf(played_seconds < 20) AS events_under_20,
    round(100.0 * events_under_20 / events_total, 2) AS under_20_percent
FROM takt.hw_events_time
WHERE ended_at >= toDateTime('2026-10-24 00:00:00', 'UTC')
  AND ended_at <  toDateTime('2026-10-25 00:00:00', 'UTC')
  AND country = 'DE'
GROUP BY country
ORDER BY country
SETTINGS
    max_threads = 4,
    use_query_cache = 0,
    use_query_condition_cache = 0,
    optimize_move_to_prewhere = 0;

-- План: германия, ключ по стране и времени
EXPLAIN indexes = 1
SELECT
    country,
    count() AS events_total,
    countIf(played_seconds < 20) AS events_under_20,
    round(100.0 * events_under_20 / events_total, 2) AS under_20_percent
FROM takt.hw_events_country
WHERE ended_at >= toDateTime('2026-10-24 00:00:00', 'UTC')
  AND ended_at <  toDateTime('2026-10-25 00:00:00', 'UTC')
  AND country = 'DE'
GROUP BY country
ORDER BY country
SETTINGS
    max_threads = 4,
    use_query_cache = 0,
    use_query_condition_cache = 0,
    optimize_move_to_prewhere = 0;

-- План: все страны, ключ по времени
EXPLAIN indexes = 1
SELECT
    country,
    count() AS events_total,
    countIf(played_seconds < 20) AS events_under_20,
    round(100.0 * events_under_20 / events_total, 2) AS under_20_percent
FROM takt.hw_events_time
WHERE ended_at >= toDateTime('2026-10-24 00:00:00', 'UTC')
  AND ended_at <  toDateTime('2026-10-25 00:00:00', 'UTC')
GROUP BY country
ORDER BY country
SETTINGS
    max_threads = 4,
    use_query_cache = 0,
    use_query_condition_cache = 0,
    optimize_move_to_prewhere = 0;

-- План: все страны, ключ по стране и времени
EXPLAIN indexes = 1
SELECT
    country,
    count() AS events_total,
    countIf(played_seconds < 20) AS events_under_20,
    round(100.0 * events_under_20 / events_total, 2) AS under_20_percent
FROM takt.hw_events_country
WHERE ended_at >= toDateTime('2026-10-24 00:00:00', 'UTC')
  AND ended_at <  toDateTime('2026-10-25 00:00:00', 'UTC')
GROUP BY country
ORDER BY country
SETTINGS
    max_threads = 4,
    use_query_cache = 0,
    use_query_condition_cache = 0,
    optimize_move_to_prewhere = 0;
