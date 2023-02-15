USE H_Baseball;

SELECT 
    name,
    team,
    position,
    FORMAT(salary, '#,##0') AS player_salary
FROM
    players
WHERE
    team = 'New York Yankees'
        AND year = 2011
ORDER BY salary DESC;