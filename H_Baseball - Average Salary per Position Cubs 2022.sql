USE H_Baseball;

SELECT DISTINCT position,
    FORMAT(AVG(salary), '#,##0') AS avg_salary_per_position_2022_formated,
    AVG(salary) AS avg_salary
FROM
    players
WHERE
    year = 2022 AND team LIKE '%Cubs'
GROUP BY position
ORDER BY avg_salary DESC;
