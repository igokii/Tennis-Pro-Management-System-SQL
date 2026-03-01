-- 
-- Autor: David Ruiz
-- Fecha: Noviembre 2025
-- Descripción: Script para crear la BD de Tenis
-- 
USE TenisPistasDB;

-- Eliminar tablas si existen (orden seguro por claves foráneas)
-- Primero eliminar vistas que dependan de las tablas
DROP VIEW IF EXISTS v_players;
DROP VIEW IF EXISTS v_referees;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS sets;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS referees;
DROP TABLE IF EXISTS people;
DROP TABLE IF EXISTS courts;
-- NO borrar test_results para preservar resultados de tests
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE courts (
 	court_id INT AUTO_INCREMENT,
 	name VARCHAR(100) NOT NULL,
 	surface ENUM('Hierba', 'Arcilla', 'Dura') NOT NULL, -- RA-01
 	capacity INT NOT NULL,
 	PRIMARY KEY (court_id),
  	CONSTRAINT ra_02_court_minimum_capacity CHECK (capacity >= 500)
  	-- RA-03 COMO TRIGGER
  	-- RA-04 COMO TRIGGER
);

CREATE TABLE people (
    person_id INT AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    nationality VARCHAR(50) NOT NULL,
    PRIMARY KEY (person_id),
    CONSTRAINT rn_03_unique_name UNIQUE(name),
    CONSTRAINT rn_02_adult_age CHECK (age >= 18)
);

CREATE TABLE players (
    player_id INT,
    ranking INT NOT NULL,
    PRIMARY KEY (player_id),
    FOREIGN KEY (player_id) REFERENCES people(person_id),
    CONSTRAINT rn_04_ranking CHECK (ranking > 0 AND ranking <= 1000)
);

CREATE TABLE referees (
    referee_id INT,
    license VARCHAR(30) NOT NULL,
    PRIMARY KEY (referee_id),
    FOREIGN KEY (referee_id) REFERENCES people(person_id),
    CONSTRAINT rn_07_license CHECK (license IN ('Nacional', 'Internacional'))
);

CREATE TABLE matches (
    match_id INT AUTO_INCREMENT,
    referee_id INT NOT NULL,
    player1_id INT NOT NULL,
    player2_id INT NOT NULL,
    winner_id INT NOT NULL,
    tournament VARCHAR(100) NOT NULL,
    match_date DATE NOT NULL,
    round VARCHAR(30) NOT NULL,
    duration INT NOT NULL,
    court_id INT NOT NULL,
    PRIMARY KEY (match_id),
    FOREIGN KEY (referee_id) REFERENCES referees(referee_id),
    FOREIGN KEY (player1_id) REFERENCES players(player_id),
    FOREIGN KEY (player2_id) REFERENCES players(player_id),
    FOREIGN KEY (winner_id) REFERENCES players(player_id),  
    FOREIGN KEY (court_id) REFERENCES courts(court_id),
    CONSTRAINT rn_05_different_players CHECK (player1_id <> player2_id),
    CONSTRAINT rn_xx_valid_winner CHECK (winner_id IN (player1_id, player2_id)),
    CONSTRAINT rn_xx_duration CHECK (duration > 0) -- Extra: positive duration
);

CREATE TABLE sets (
    set_id INT AUTO_INCREMENT,
    match_id INT NOT NULL,
    winner_id INT NOT NULL,
    set_order INT NOT NULL,
    score VARCHAR(20) NOT NULL,
    PRIMARY KEY (set_id),
    FOREIGN KEY (match_id) REFERENCES matches(match_id),
    FOREIGN KEY (winner_id) REFERENCES players(player_id),
    CONSTRAINT rn_03_set_order CHECK (set_order >= 1 AND set_order <= 5)
);

-- Vistas para simplificar consultas uniendo people con referees/players
CREATE OR REPLACE VIEW v_referees AS
SELECT 
    r.referee_id AS person_id,
    p.name,
    p.age,
    p.nationality,
    r.license
FROM referees r
JOIN people p ON p.person_id = r.referee_id;

CREATE OR REPLACE VIEW v_players AS
SELECT 
    pl.player_id AS person_id,
    p.name,
    p.age,
    p.nationality,
    pl.ranking
FROM players pl
JOIN people p ON p.person_id = pl.player_id;

-- ============================================================================
-- TRIGGERS DE VALIDACIÓN
-- ============================================================================

DELIMITER //

-- ============================================================================
-- RN-06: Un árbitro no puede arbitrar más de 3 partidos en el mismo día
-- ============================================================================

CREATE OR REPLACE TRIGGER t_biu_matches_rn06
BEFORE INSERT OR UPDATE ON matches
FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*) INTO v_count
    FROM matches
    WHERE referee_id = NEW.referee_id
      AND match_date = NEW.match_date
      AND match_id <> IFNULL(NEW.match_id, 0);
    
    IF v_count >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN-06: Un árbitro no puede arbitrar más de 3 partidos en el mismo día';
    END IF;
END //

-- ============================================================================
-- RN-07: La nacionalidad del árbitro no puede coincidir con la de ninguno de los jugadores
-- ============================================================================

CREATE OR REPLACE TRIGGER t_biu_matches_rn07
BEFORE INSERT OR UPDATE ON matches
FOR EACH ROW
BEGIN
    DECLARE v_ref_nationality VARCHAR(50);
    DECLARE v_player1_nationality VARCHAR(50);
    DECLARE v_player2_nationality VARCHAR(50);
    
    -- Uso de vistas para obtener las nacionalidades
    SELECT nationality INTO v_ref_nationality
    FROM v_referees
    WHERE person_id = NEW.referee_id;
    
    SELECT nationality INTO v_player1_nationality
    FROM v_players
    WHERE person_id = NEW.player1_id;
    
    SELECT nationality INTO v_player2_nationality
    FROM v_players
    WHERE person_id = NEW.player2_id;
    
    IF v_ref_nationality = v_player1_nationality OR v_ref_nationality = v_player2_nationality THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN-07: La nacionalidad del árbitro no puede coincidir con la de ninguno de los jugadores';
    END IF;
END //

-- ============================================================================
-- Sets: Validación de ganador y máximo 5 sets
-- ============================================================================

-- Validar que el ganador del set sea uno de los jugadores del partido
-- y que no se excedan los 5 sets por partido
CREATE OR REPLACE TRIGGER t_biu_sets_validations
BEFORE INSERT OR UPDATE ON sets
FOR EACH ROW
BEGIN
    DECLARE v_player1 INT;
    DECLARE v_player2 INT;
    DECLARE v_count INT;

    -- Validar ganador del set
    SELECT player1_id, player2_id INTO v_player1, v_player2
    FROM matches
    WHERE match_id = NEW.match_id;

    IF NEW.winner_id NOT IN (v_player1, v_player2) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sets: El ganador del set debe ser uno de los jugadores del partido';
    END IF;

    -- Validar máximo 5 sets
    SELECT COUNT(*) INTO v_count
    FROM sets
    WHERE match_id = NEW.match_id
      AND set_id <> IFNULL(NEW.set_id, 0);
    
    IF v_count >= 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sets: Un partido no puede tener más de 5 sets';
    END IF;
END //


-- ============================================================================
-- RA-03: Si el torneo es "Wimbledon", la pista debe ser 'Hierba'. Si es "Roland Garros",
--        debe ser 'Arcilla'. Si es "US Open" o "Australian Open", debe ser 'Dura'.
-- ============================================================================

-- Wimbledon: GRASS
-- Roland Garros: CLAY
-- US Open, Australian Open: HARD

CREATE OR REPLACE TRIGGER t_biu_matches_rA03
BEFORE INSERT OR UPDATE ON matches
FOR EACH ROW
BEGIN

    DECLARE tipoPista VARCHAR(64);
    
    SELECT c.surface INTO tipoPista
    FROM courts c
		WHERE c.court_id = new.court_id;
    
	 IF (new.tournament LIKE '%Wimbledon%' AND tipoPista <> 'Hierba')
	 	  OR (new.tournament LIKE '%Roland Garros%' AND tipoPista <> 'Arcilla')
		  OR ((new.tournament LIKE '%US Open%' OR new.tournament LIKE '%Australian Open%') AND tipoPista <> 'Dura') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RA-03: Un partido debe tener la superficie de pista correcta en función del torneo.';
    END IF;
END //
DELIMITER ;








