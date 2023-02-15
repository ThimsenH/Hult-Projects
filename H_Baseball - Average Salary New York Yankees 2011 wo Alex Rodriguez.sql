USE H_Baseball;

SELECT 
    team,
    FORMAT(AVG(salary), '#,##0') AS avg_player_wo_alex_rodrigez
FROM
    players
WHERE
    team = 'New York Yankees'
        AND year = 2011
        AND name <> 'Alex Rodriguez'
GROUP BY team;