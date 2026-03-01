-- ENTENDIDO. EXPLICACIÓN:
-- He seguido dándole vueltas al hacer los ejercicios de nuevo y toparme con el mismo problema.
-- Esta vez (tras preguntarle a la IA en varias ocasiones y que me diera soluciones que no sirven) 
-- creo que he encontrado el problema.
-- He hecho varias pruebas haciendo uso de vistas diferentes y veo que el error está en el "HAVING". 
-- El having compara el v.year del SELECT inicial, y no el v.year del group by. Entonces toma una media
-- diferente (arbitraria) y no la del año que se está agrupando.



-- Nombre y apellidos de alumnos por año que tuvieron una nota media mayor que la nota media del año.
CREATE OR REPLACE VIEW vStudentGrades AS
	SELECT st.*, gd.value, gp.year
 	FROM Students st
 	JOIN Grades gd ON (st.studentId = gd.studentId)
 	JOIN Groups gp ON (gp.groupId = gd.groupId)
;

CREATE OR REPLACE VIEW vYearAverage AS
	SELECT v.year, AVG(v.value) AS avgYear
	FROM vStudentGrades v
	GROUP BY v.year
;


-- OPCIÓN MÍA, FUNCIONA:
CREATE OR REPLACE VIEW vStudentAverage AS 
	SELECT v.studentId, v.firstname, v.surname, AVG(v.value) AS avgStudent, v.year
	FROM vStudentGrades v
	GROUP BY v.studentId, v.year
;
SELECT v.studentId, v.firstName, v.surname, v.avgStudent
	FROM vStudentAverage v
	WHERE v.avgStudent > (SELECT vAvg.avgYear
								 FROM vYearAverage vAvg
								 WHERE vAvg.year = v.year)
;

--  OPCIÓN QUE NO FUNCIONA, DA FILA EXTRA:
SELECT v.studentId, v.firstName, v.surname, AVG(v.value) as avgStudent
	FROM vStudentGrades v
	GROUP BY v.studentId, v.year
	HAVING avgStudent > (SELECT vAvg.avgYear
								 FROM vYearAverage vAvg
								 WHERE vAvg.year = v.year)
;

-- MISMA OPCIÓN QUE NO FUNCIONA, AÑADO avgYear PARA HACER LA COMPARACIÓN CON avgStudent
SELECT v.studentId, v.firstName, v.surname, AVG(v.value) as avgStudent, v.year, vj.year, vj.avgYear
	FROM vStudentGrades v
	JOIN vYearAverage vj ON (v.year = vj.year)
	GROUP BY v.studentId, v.year
	HAVING avgStudent > vj.year
;

CREATE OR REPLACE VIEW Borrar AS
	SELECT v.studentId, v.firstName, v.surname, AVG(v.value) as avgStudent, v.year, vj.avgYear
	FROM vStudentGrades v
	JOIN vYearAverage vj ON (v.year = vj.year)
	GROUP BY v.studentId, v.year
;

SELECT v.*
 	FROM Borrar v
 	WHERE avgStudent > (SELECT vAvg.avgYear
								 FROM vYearAverage vAvg
								 WHERE vAvg.year = v.year)
;

-- OPCIÓN DEL ENUNCIADO
CREATE OR REPLACE VIEW ViewSubjectGrades AS
	SELECT st.studentId, st.firstName, st.surname,
	  sb.subjectId, sb.name, gd.value, gd.gradeCall, 
	  gp.year
	FROM Students st
	JOIN Grades gd ON (st.studentId = gd.studentId)
	JOIN Groups gp ON (gd.groupId = gp.groupId)
	JOIN Subjects sb ON (gp.subjectId = sb.subjectId)
;
CREATE OR REPLACE VIEW ViewAvgGradesYear AS
	SELECT v.year, AVG(v.value) AS average
	FROM ViewSubjectGrades v
	GROUP BY v.year
;
SELECT v.firstName, v.surname, v.year AS yearAvg, AVG(v.value) AS studentAverage
	FROM ViewSubjectGrades v
	GROUP BY v.studentId, v.year
	HAVING (studentAverage > (SELECT vAvg.average 
		FROM ViewAvgGradesYear vAvg
		WHERE vAvg.year = yearAvg)
);





