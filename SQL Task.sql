SELECT *
FROM player_details;
SELECT *
FROM level_details2; -- Checking the imported tables

-- Question 1
SELECT p.P_ID, Dev_ID, PName, Difficulty
FROM player_details AS p
LEFT JOIN level_details2 AS l
ON p.P_ID = l.P_ID
WHERE level = 0; 

-- Question 2
SELECT DISTINCT p.L1_Code, AVG(l.kill_count) AS avg_kill_count
FROM player_details AS p
LEFT JOIN level_details2 AS l
ON p.P_ID = l.P_ID
WHERE L1_Code IS NOT NULL AND l.Lives_Earned = '2' AND l.Stages_crossed >= '3'
GROUP BY p.L1_Code;

-- Question 3
SELECT SUM(stages_crossed) AS total_num_of_stages_crossed, difficulty 
FROM level_details2
WHERE Level = 2 AND Dev_ID LIKE 'zm%'  
GROUP BY difficulty
ORDER BY total_num_of_stages_crossed DESC;

-- Question 4
SELECT P_ID, COUNT(DISTINCT TimeStamp) AS total_num_of_unique_dates
FROM level_details2
GROUP BY P_ID 
HAVING COUNT(DISTINCT TimeStamp) > 1;

-- Question 5
SELECT COUNT(P_ID) AS id_count, level, SUM(Kill_Count) AS sum_of_kill_counts
FROM level_details2
WHERE Kill_Count > (SELECT AVG(Kill_Count) FROM level_details2 WHERE difficulty ='Medium' GROUP BY Difficulty) 
GROUP BY level 

-- Question 6 
SELECT l.Level AS Level, p.L1_Code AS Level_code, SUM(l.Lives_earned) AS Total_Lives
FROM level_details2 AS l
LEFT JOIN player_details AS p
ON l.P_ID = p.P_ID 
WHERE l.Level = 1
GROUP BY l.Level, p.L1_Code

UNION

SELECT l.Level AS Level, p.L2_Code AS Level_code, SUM(l.Lives_earned) AS Total_Lives
FROM level_details2 AS l
LEFT JOIN player_details AS p
ON l.P_ID = p.P_ID
WHERE l.Level = 2
GROUP BY l.Level, p.L2_Code

ORDER BY Level ASC;

-- Question 7
WITH RankedScores AS (
    SELECT
        Dev_ID,
        Score,
        Difficulty,
        ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score DESC) AS score_rank
    FROM
        level_details2
)
SELECT
    Dev_ID,
    Score,
    Difficulty,
    score_rank
FROM
    RankedScores
WHERE
    score_rank <= 3;

-- Question 8
SELECT Dev_ID, MIN(TimeStamp)
FROM level_details2
GROUP BY Dev_ID;

-- Question 9
WITH RankedScores AS (
     SELECT 
	 Dev_ID,
	 Score,
	 Difficulty,
	 ROW_NUMBER() OVER (PARTITION BY Difficulty ORDER BY Score DESC) AS score_rank
   FROM 
     level_details2
	 ) 
SELECT Dev_ID, Score, Difficulty, score_rank
FROM RankedScores
WHERE score_rank <= 5;

-- Question 10
SELECT l.P_ID, l.Dev_ID, l.TimeStamp
FROM level_details2 AS l
INNER JOIN (
           SELECT P_ID, MIN(Timestamp) AS first_login_timestamp
		   FROM level_details2
		   GROUP BY P_ID 
		   ) AS first_login 
ON l.P_ID = first_login.P_ID AND l.TimeStamp = first_login.first_login_timestamp;

-- Queston 11
SELECT P_ID,
       TimeStamp,
	   SUM(kill_Count) OVER(PARTITION BY P_ID ORDER BY TimeStamp ASC) AS sum_of_kill_count
FROM level_details2;

-- Alternative solution
SELECT
    P_ID,
    TimeStamp,
    (SELECT SUM(kill_count)
     FROM level_details2 AS l2
     WHERE l2.P_ID = l1.P_ID AND l2.TimeStamp <= l1.Timestamp) AS total_kill_counts
FROM level_details2 AS l1;

-- Question 12 
WITH CumulativeStages AS (
    SELECT
        P_ID,
        TimeStamp,
        SUM(stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS cumulative_stages
    FROM level_details2
)
SELECT
    P_ID,
    TimeStamp,
    cumulative_stages
FROM
    CumulativeStages;

-- Question 13
SELECT Dev_ID, P_ID, total_score
FROM (
    SELECT 
        Dev_ID, 
        P_ID, 
        SUM(Score) AS total_score,
        ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS score_rank
    FROM level_details2
    GROUP BY Dev_ID, P_ID
) AS ranked_scores
WHERE score_rank <= 3;

-- Question 14 
SELECT DISTINCT
    P_ID
FROM level_details2 AS l
WHERE Score > (
        SELECT 0.5 * AVG(Score)
        FROM level_details2
        WHERE P_ID = l.P_ID);

-- Question 15
 CREATE PROCEDURE GetTopHeadshotsByDevID
    @n INT
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = '
    WITH RankedHeadshots AS (
        SELECT
            Dev_ID,
            headshots_count,
            Difficulty,
            ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY headshots_count ASC) AS headshot_rank
        FROM level_details2
    )
    SELECT
        Dev_ID,
        headshots_count,
        Difficulty,
        headshot_rank
    FROM
        RankedHeadshots
    WHERE
        headshot_rank <= ' + CAST(@n AS NVARCHAR(10)) + ';';

    EXEC sp_executesql @sql;
END

EXEC GetTopHeadshotsByDevID @n = 3;
