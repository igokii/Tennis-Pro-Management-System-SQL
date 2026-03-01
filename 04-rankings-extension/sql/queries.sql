-- EJERCICIO 4: Funciones
-- sets ganados por tenista en partido
DELIMITER //
CREATE OR REPLACE FUNCTION numSets(match_id INT, player_id INT) RETURNS INTEGER
BEGIN
	DECLARE numSets INTEGER;
	
	SELECT COUNT(*) INTO numSets 
		FROM matches m
		JOIN sets s ON (s.match_id = m.match_id)
		WHERE s.winner_id = player_id
				AND m.match_id = match_id;
		
	RETURN numSets;
END //
DELIMITER ;

SELECT m.match_id, p1.`name`, numSets(m.match_id, m.player1_id) as sets_won_p1, p2.`name`, numSets(m.match_id, m.player2_id) as sets_won_p2
	FROM matches m
		JOIN people p1 ON (m.player1_id = p1.person_id)
		JOIN people p2 ON (m.player2_id = p2.person_id)
	LIMIT 7;

-- EJERCICIO 5:
-- para cada torneo duracion media, maxima y minima
-- ordenado por  duracion media DESC

SELECT m.tournament, AVG(m.duration) as avg_duration, MIN(m.duration) as min_duration, MAX(m.duration) as max_duration
	FROM matches m
	group by m.tournament
	ORDER BY avg_duration DESC;

-- partido mas largo de cada torneo ordenado por torneo
CREATE OR REPLACE VIEW vDuracionMaximaPorTorneo AS
	SELECT m.tournament, MAX(m.duration) as max_duration
	 FROM matches m
	 GROUP BY m.tournament
;

SELECT m.tournament, m.match_id, m.duration
	FROM matches m
	JOIN vDuracionMaximaPorTorneo v
      ON (v.tournament = m.tournament AND m.duration = v.max_duration)
	ORDER BY m.tournament
;



-- EJERCICIO 6:
-- transaccion  añade dos cambios de ranking a un tenista
SET AUTOCOMMIT=0;
DELIMITER //
CREATE OR REPLACE PROCEDURE pInsertTwoRankings(
	 person_id INT,
	 date1 DATE, 
	 position1 INT,
	 date2 DATE, 
	 position2 INT
)
BEGIN
    INSERT INTO rankings (person_id, date, position) VALUES (person_id, date1, position1);
    INSERT INTO rankings (person_id, date, position) VALUES (person_id, date2, position2);
END //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE pTwoRankingsTransactional(
	 person_id INT,
	 date1 DATE, 
	 position1 INT,
	 date2 DATE, 
	 position2 INT
)
BEGIN
    START TRANSACTION;
    tblock: BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            ROLLBACK;
            RESIGNAL;
        END;
        CALL pInsertTwoRankings(person_id, date1, position1, date2, position2);
        COMMIT;
    END tblock;
END //
DELIMITER ;


CALL p_populate_db();
SELECT *
	FROM players p
	JOIN rankings r ON (r.person_id = p.player_id)
	WHERE p.player_id = 3
;

CALL p_populate_db();
CALL pTwoRankingsTransactional(3, DATE('2020-02-02'), 20, DATE('2021-02-02'), 30);

SELECT *
	FROM players p
	JOIN rankings r ON (r.person_id = p.player_id)
	WHERE p.player_id = 3
;


CALL p_populate_db();
CALL pTwoRankingsTransactional(3, DATE('2020-02-02'), 20, DATE('2021-02-02'), 80);

-- comprobación de que el procedimiento se ha hecho correctamente. la tabla debe estar vacia
SELECT *
	FROM players p
	JOIN rankings r ON (r.person_id = p.player_id)
	WHERE p.player_id = 3
;



-- CALL p_populate_db();
-- CALL pTwoRankingsTransactional(3, DATE('2020-02-02'), 20, DATE('2021-02-02'), 100);



















