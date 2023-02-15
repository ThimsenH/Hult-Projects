USE H_Baseball;

SELECT year, COUNT(name) AS number_of_player
FROM players
GROUP BY year;