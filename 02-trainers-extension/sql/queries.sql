
DELIMITER //
CREATE OR REPLACE FUNCTION fnumSetsWon(playerId INT, matchId INT) RETURNS INTEGER
BEGIN
	DECLARE numSetsWon INT;
	SELECT COUNT(*) INTO numSetsWon
	FROM sets s
	WHERE s.match_id = matchId
	AND s.winner_id = playerId;
	RETURN numSetsWon;
END //
DELIMITER ;

SELECT m.match_id, p1.`name`, fnumSetsWon(m.player1_id, m.match_id) sets_won_p1, p2.`name`, fnumSetsWon(m.player2_id, m.match_id)
 	FROM matches m
 	JOIN people p1 ON (m.player1_id = p1.person_id)
 	JOIN people p2 ON (m.player2_id = p2.person_id)
 	LIMIT 7
;

-- 5. CONSULTAS
-- Fecha y duración de los partidos decididos en 2 sets

DELIMITER //
CREATE OR REPLACE FUNCTION fnumSets(matchId INT) RETURNS INTEGER
BEGIN
	DECLARE numSets INT;
	SELECT COUNT(*) INTO numSets
	FROM sets s
	WHERE s.match_id = matchId;
	RETURN numSets;
END //
DELIMITER ;

SELECT m.match_date, m.duration
	FROM matches m
	WHERE fnumSets(m.match_id) = 2
;

-- Lista de árbitros ordenados por número de partidos arbitrados, incluyendo el número de partidos arbitrados por cada árbitro.
DELIMITER //
CREATE OR REPLACE FUNCTION fnumPartidosArbitrados(referee_id INT) RETURNS INTEGER
BEGIN
	DECLARE numPartidos INT;
	SELECT COUNT(*) INTO numPartidos
	FROM matches m
	WHERE m.referee_id = referee_id;
	RETURN numPartidos;
END //
DELIMITER ;

SELECT p.`name`, fnumPartidosArbitrados(r.referee_id) as num
	FROM referees r
	JOIN people p ON (p.person_id = r.referee_id)
	ORDER BY num
	DESC
;

-- 6. TRANSACCIONES
-- • Realice un procedimiento transaccional que crea dos entrenadores. Debe recibir como parámetros
-- todos los datos necesarios para crear ambos entrenadores.
-- • Realice una prueba para comprobar el correcto funcionamiento:
-- ‣ Primer con datos correctos, segundo entrenador es un tenista en activo

SET AUTOCOMMIT=0;

DELIMITER //
CREATE OR REPLACE PROCEDURE pInsertTwoTrainers(
   name1 VARCHAR(100),
   age1 INT,
   nationality1 VARCHAR(50),
	experience1 INT,
	specialty1 VARCHAR(64),   
	isPlayer1 BOOLEAN,
    ranking1 INT,
    active1 BOOLEAN,
    trainer_id1 INT,
	name2 VARCHAR(100),
   age2 INT,
   nationality2 VARCHAR(50),
	experience2 INT,
	specialty2 VARCHAR(64),
	isPlayer2 BOOLEAN,
    ranking2 INT,
    active2 BOOLEAN,
    trainer_id2 INT
)
BEGIN
	INSERT INTO people (name, age, nationality) VALUES (name1, age1, nationality1);
    SET @person1_id = LAST_INSERT_ID();
	INSERT INTO people (name, age, nationality) VALUES (name2, age2, nationality2);
    SET @person2_id = LAST_INSERT_ID();
    INSERT INTO trainers (trainer_id, experience, specialty)
        VALUES (@person1_id, experience1, specialty1);
    INSERT INTO trainers (trainer_id, experience, specialty)
        VALUES (@person2_id, experience2, specialty2);
	IF (isPlayer1) THEN
		INSERT INTO players VALUES
		(@person1_id, ranking1, active1, trainer_id1);
	END IF;        
	IF (isPlayer2) THEN
		INSERT INTO players VALUES
		(@person2_id, ranking2, active2, trainer_id2);
	END IF;   
   
END //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE pNewTwoTrainersTransactional(
   name1 VARCHAR(100),
   age1 INT,
   nationality1 VARCHAR(50),
	experience1 INT,
	specialty1 VARCHAR(64),   
	isPlayer1 BOOLEAN,
    ranking1 INT,
    active1 BOOLEAN,
    trainer_id1 INT,
	name2 VARCHAR(100),
   age2 INT,
   nationality2 VARCHAR(50),
	experience2 INT,
	specialty2 VARCHAR(64),
	isPlayer2 BOOLEAN,
    ranking2 INT,
    active2 BOOLEAN,
    trainer_id2 INT
)
BEGIN
    START TRANSACTION;
    tblock: BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            ROLLBACK;
            RESIGNAL;
        END;
        CALL pInsertTwoTrainers(name1, age1, nationality1, experience1, specialty1, isPlayer1, ranking1, active1, trainer_id1, name2, age2, nationality2, experience2, specialty2, isPlayer2, ranking2, active2, trainer_id2);
        COMMIT;
    END tblock;
END //
DELIMITER ;


CALL	p_populate_db();

DELIMITER //
CREATE OR REPLACE PROCEDURE pTestTwoTrainers()
BEGIN 
	CALL p_populate_db();
	CALL pNewTwoTrainersTransactional('testTrainer1', 40, 'Spain', 20, 'Dobles', FALSE, NULL, NULL, NULL, 'testTrainer2', 50, 'Spain', 30, 'Dobles', TRUE, 300, TRUE, NULL);
END //
DELIMITER ;



