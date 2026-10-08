SELECT
    role::text AS role,
    status::text AS status,
    count(*) AS users
FROM "User"
GROUP BY 1,2
ORDER BY 3 DESC;

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema='public'
ORDER BY 1;
