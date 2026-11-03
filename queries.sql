-- 1. Валидация данных ---------------------------------------------------------
-- 1.1 Размер таблицы и пропуски
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN userid IS NULL OR userid = '' THEN 1 ELSE 0 END) AS null_userid,
       SUM(CASE WHEN version IS NULL OR version = '' THEN 1 ELSE 0 END) AS null_version
FROM cookie_cats;

-- 1.2 Дубли userid
SELECT userid, COUNT(*) AS cnt
FROM cookie_cats
GROUP BY userid
HAVING COUNT(*) > 1;

-- 1.3 Допустимые значения version
SELECT version, COUNT(*) AS players
FROM cookie_cats
GROUP BY version;

-- 2. Размер групп и SRM (глазами) ---------------------------------------------
SELECT version,
       COUNT(*) AS players,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM cookie_cats
GROUP BY version;

-- 3. Удержание по группам -----------------------------------------------------
SELECT version,
       COUNT(*) AS players,
       ROUND(100.0 * AVG(CASE WHEN retention_1 = '1' THEN 1.0 ELSE 0 END), 2) AS ret_1d_pct,
       ROUND(100.0 * AVG(CASE WHEN retention_7 = '1' THEN 1.0 ELSE 0 END), 2) AS ret_7d_pct
FROM cookie_cats
GROUP BY version;

-- 4. Раунды: описательная статистика по группам -------------------------------
SELECT version,
       COUNT(*) AS players,
       ROUND(AVG(sum_gamerounds), 1) AS avg_rounds,
       MIN(sum_gamerounds) AS min_rounds,
       MAX(sum_gamerounds) AS max_rounds
FROM cookie_cats
GROUP BY version;

-- 5. Игроки, не сыгравшие ни одного раунда ------------------------------------
SELECT version,
       SUM(CASE WHEN sum_gamerounds = 0 THEN 1 ELSE 0 END) AS zero_rounds,
       ROUND(100.0 * SUM(CASE WHEN sum_gamerounds = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS zero_pct
FROM cookie_cats
GROUP BY version;

-- 6. Распределение игроков по корзинам раундов --------------------------------
SELECT CASE
         WHEN sum_gamerounds = 0 THEN '0'
         WHEN sum_gamerounds BETWEEN 1 AND 5 THEN '1-5'
         WHEN sum_gamerounds BETWEEN 6 AND 20 THEN '6-20'
         WHEN sum_gamerounds BETWEEN 21 AND 50 THEN '21-50'
         WHEN sum_gamerounds BETWEEN 51 AND 100 THEN '51-100'
         ELSE '100+'
       END AS rounds_bucket,
       version,
       COUNT(*) AS players
FROM cookie_cats
GROUP BY rounds_bucket, version
ORDER BY MIN(sum_gamerounds), version;

-- 7. Воронка по порогам раундов (сколько дошло до порога) ---------------------
-- Пороги выбраны вокруг уровней 30 и 40, где стоят ворота.
SELECT version,
       COUNT(*) AS all_players,
       SUM(CASE WHEN sum_gamerounds >= 1  THEN 1 ELSE 0 END)  AS reached_1,
       SUM(CASE WHEN sum_gamerounds >= 10 THEN 1 ELSE 0 END)  AS reached_10,
       SUM(CASE WHEN sum_gamerounds >= 30 THEN 1 ELSE 0 END)  AS reached_30,
       SUM(CASE WHEN sum_gamerounds >= 40 THEN 1 ELSE 0 END)  AS reached_40,
       SUM(CASE WHEN sum_gamerounds >= 100 THEN 1 ELSE 0 END) AS reached_100
FROM cookie_cats
GROUP BY version;

-- 8. Воронка в процентах от всех игроков группы -------------------------------
SELECT version,
       ROUND(100.0 * SUM(CASE WHEN sum_gamerounds >= 1  THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_1,
       ROUND(100.0 * SUM(CASE WHEN sum_gamerounds >= 10 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_10,
       ROUND(100.0 * SUM(CASE WHEN sum_gamerounds >= 30 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_30,
       ROUND(100.0 * SUM(CASE WHEN sum_gamerounds >= 40 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_40,
       ROUND(100.0 * SUM(CASE WHEN sum_gamerounds >= 100 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_100
FROM cookie_cats
GROUP BY version;

-- 9. Удержание в зависимости от активности ------------------------------------
-- Вернулись ли игроки на 7 день в зависимости от числа сыгранных раундов
SELECT CASE
         WHEN sum_gamerounds < 10 THEN 'a) <10'
         WHEN sum_gamerounds < 30 THEN 'b) 10-29'
         WHEN sum_gamerounds < 100 THEN 'c) 30-99'
         ELSE 'd) 100+'
       END AS activity,
       version,
       COUNT(*) AS players,
       ROUND(100.0 * AVG(CASE WHEN retention_7 = '1' THEN 1.0 ELSE 0 END), 2) AS ret_7d_pct
FROM cookie_cats
GROUP BY activity, version
ORDER BY activity, version;

-- 10. Витрина под дашборд: одна строка на группу ------------------------------
CREATE VIEW ab_test_summary AS
SELECT version,
       COUNT(*) AS players,
       AVG(CASE WHEN retention_1 = '1' THEN 1.0 ELSE 0 END) AS ret_1d,
       AVG(CASE WHEN retention_7 = '1' THEN 1.0 ELSE 0 END) AS ret_7d,
       AVG(sum_gamerounds) AS avg_rounds,
       SUM(CASE WHEN sum_gamerounds = 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS zero_rounds_share
FROM cookie_cats
GROUP BY version;

SELECT * FROM ab_test_summary;
