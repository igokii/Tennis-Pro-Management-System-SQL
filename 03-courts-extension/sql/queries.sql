-- EJERCICIO 4: Funciones
CREATE OR REPLACE VIEW vMatchesCourts AS
	SELECT m.*, c.name, c.surface, c.capacity
	FROM matches m
	JOIN courts c ON (m.court_id = c.court_id)
;


DELIMITER //
CREATE OR REPLACE FUNCTION  f_player_win_rate_on_surface(p_player_id INT, p_surface VARCHAR(64)) RETURNS DEC(5,2)
BEGIN
	DECLARE wins INT;
	DECLARE games INT;
	DECLARE win_rate DEC(5,2);
	
	SELECT COUNT(*) INTO wins
		FROM vMatchesCourts v
			WHERE v.surface = p_surface
			AND p_player_id = v.winner_id
;

	SELECT COUNT(*) INTO games
		FROM vMatchesCourts v
			WHERE v.surface = p_surface
			AND (p_player_id = v.player1_id OR p_player_id = v.player2_id)
;

	IF (games = 0) THEN
		SET games = 1;
	END IF;
	
	SET win_rate = wins / games * 100;
		
	RETURN win_rate;
	
END //
DELIMITER ;

SELECT c.surface, f_player_win_rate_on_surface(1, c.surface) -- este es nadal, devuelve 25,0
	FROM courts c
	GROUP BY c.surface;

-- EJERCICIO 5: Consultas
SELECT v.court_id, v.`name`, v.capacity, COUNT(v.match_id) as numMatches
	FROM vMatchesCourts v
	GROUP BY v.court_id
	ORDER BY numMatches
	DESC
;

SELECT v.surface, AVG(v.duration) as duracionMedia
	FROM vMatchesCourts v
	GROUP BY v.surface
;

-- EJERCICIO 6: Transacciones
-- p_create_match_with_court(...).
SET AUTOCOMMIT=0;

DELIMITER //
CREATE OR REPLACE PROCEDURE pInsertMatchWithCourt(
    referee_id INT,
    player1_id INT,
    player2_id INT,
    winner_id INT,
    tournament VARCHAR(100),
    match_date DATE,
    round VARCHAR(30),
    duration INT,
    court_name VARCHAR(100)
)
BEGIN
    DECLARE court_id INT;
    SET court_id = (SELECT c.court_id FROM courts c WHERE c.name=court_name);
    
    INSERT INTO matches (referee_id, player1_id, player2_id, winner_id, tournament, match_date, round, duration, court_id) 
	 		VALUES (referee_id, player1_id, player2_id, winner_id, tournament, match_date, round, duration, court_id);
	 		
END //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE p_create_match_with_court(
    referee_id INT,
    player1_id INT,
    player2_id INT,
    winner_id INT,
    tournament VARCHAR(100),
    match_date DATE,
    round VARCHAR(30),
    duration INT,
    court_name VARCHAR(100) 
)
BEGIN
    START TRANSACTION;
    tblock: BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            ROLLBACK;
            RESIGNAL;
        END;
        CALL pInsertMatchWithCourt(referee_id, player1_id, player2_id, winner_id, tournament, match_date, round, duration, court_name);
        COMMIT;
    END tblock;
END //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE pTestCreateMatchWithCourt()
BEGIN
	CALL p_populate_db();
	CALL p_create_match_with_court(8, 1, 2, 1, 'Test Tournament', '2020-01-20', 'Final', 200,'No. 1 Court');
END //
DELIMITER ;

CALL pTestCreateMatchWithCourt();
-- CALL p_create_match_with_court(8, 1, 2, 1, 'Test Tournament', '2020-01-20', 'Final', 200,'Pista_no_existente');

-- p_inaugurate_court
DELIMITER //
CREATE OR REPLACE PROCEDURE pNewCourtNewMatch(
 	name VARCHAR(100),
 	surface ENUM('Hierba', 'Arcilla', 'Dura'), 
 	capacity INT,
     referee_id INT,
     player1_id INT,
     player2_id INT,
     winner_id INT,
     tournament VARCHAR(100),
     match_date DATE,
     round VARCHAR(30),
     duration INT
     -- LAST_INSERT_ID() court_id
)
BEGIN
    DECLARE court_id INT;
    INSERT INTO courts (name, surface, capacity) VALUES
        (name, surface, capacity);
    SET court_id = LAST_INSERT_ID();
    INSERT INTO  matches (referee_id, player1_id, player2_id, winner_id, tournament, match_date, round, duration, court_id)
        VALUES (referee_id, player1_id, player2_id, winner_id, tournament, match_date, round, duration, court_id);
END //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE p_inaugurate_court(
 	name VARCHAR(100),
 	surface ENUM('Hierba', 'Arcilla', 'Dura'), 
 	capacity INT,
     referee_id INT,
     player1_id INT,
     player2_id INT,
     winner_id INT,
     tournament VARCHAR(100),
     match_date DATE,
     round VARCHAR(30),
     duration INT
     -- LAST_INSERT_ID() court_id
)
BEGIN
    START TRANSACTION;
    tblock: BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            ROLLBACK;
            RESIGNAL;
        END;
        CALL pNewCourtNewMatch(name, surface, capacity, referee_id, player1_id,
		  player2_id, winner_id, tournament, match_date, round, duration);
        COMMIT;
    END tblock;
END //
DELIMITER ;

CALL p_inaugurate_court('PISTA NUEVA', 'Hierba', 12000, 8, 1, 2, 1, 'torneo de prueba', '2025-01-30', 'Amistoso', 50);

SELECT *
FROM vMatchesCourts v
WHERE v.`name` = 'PISTA NUEVA';


CALL p_inaugurate_court('PISTA ERRÓNEA', 'Hierba', 12000, 8, 1, 2, 1, 'torneo de prueba', 'fecha errónea', 'Amistoso', 50);


SELECT *
FROM vMatchesCourts v;
-- Hago el select y veo que 'pista errónea' no se ha creado. transacción correcta


