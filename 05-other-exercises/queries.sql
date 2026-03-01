INSERT INTO Degrees(name, years) VALUES
	('Ingeniería del Software', 4),
	('Ingeniería del Computadores', 4),
	('Tecnologías Informáticas', 4);
	
INSERT INTO Subjects(name, acronym, credits, year, type, degreeId) VALUES
	('Fundamentos de Programación', 'FP', 12, 1, 'Formación Básica', 3),
	('Lógica Informática', 'LI', 6, 2, 'Optativa', 3);
	
INSERT INTO Groups(name, activity, year, subjectId) VALUES
	('T1', 'Teoría', 2019, 1),
	('L1', 'Laboratorio', 2019, 1),
	('L2', 'Laboratorio', 2019, 1);
	
INSERT INTO Students(accessMethod, dni, firstName, surname, birthDate, email, password) VALUES
	('Selectividad', '12345678A', 'Daniel', 'Pérez', '1991-01-01', 'daniel@alum.us.es', 'password1'),
	('Selectividad', '22345678A', 'Rafael', 'Ramírez', '1992-01-01', 'rafael@alum.us.es', 'password2'),
	('Selectividad', '32345678A', 'Gabriel', 'Hernández', '1993-01-01', 'gabriel@alum.us.es', 'password3');

INSERT INTO GroupsStudents (groupId, studentId) VALUES
	(1, 1),
	(3, 1);
	
INSERT INTO Grades (value, gradeCall, withHonours, studentId, groupId) VALUES
	(4.50, 1, 0, 1, 1),
	(5.00, 1, 0, 2, 1),
	(6.00, 1, 0, 3, 1),
	(7.00, 2, 0, 1, 1),
	(9.00, 2, 1, 2, 1),
	(9.00, 2, 0, 3, 1),
	(10.00, 3, 0, 1, 3),
	(5.50, 3, 0, 2, 3),
	(6.00, 2, 1, 3, 3);
	
-- ahora pondremos los UPDATE, DELETE y SELECT:

UPDATE Students
	SET Birthdate = '1998-01-01', surname= 'Fernández'
	WHERE studentId = 3;
	
Update Subjects
	SET credits = credits/2;
	
DELETE FROM Grades
	WHERE gradeId = 1;
	
SELECT (AVG(credits))
	FROM Subjects;
	
SELECT AVG(credits), SUM(credits), name
	FROM Subjects;
	
SELECT firstName, surname
	FROM Students
	WHERE accessMethod = 'Selectividad';
	
SELECT COUNT(*) AS numAsignaturas
	FROM Subjects
	WHERE credits > 4;
	
-- VISTAS 
CREATE OR REPLACE VIEW vGradesGroup1 AS
	SELECT * 
	FROM Grades g
	WHERE g.groupId=1;
	
SELECT * FROM vGradesGroup1

SELECT MAX(value) FROM vGradesGroup1
SELECT COUNT(*) FROM vGradesGroup1

CREATE OR REPLACE VIEW vGradesGroup1Call1 AS
	SELECT * FROM vGradesGroup1 WHERE gradeCall=1;

SELECT * FROM vGradesGroup1Call1
	