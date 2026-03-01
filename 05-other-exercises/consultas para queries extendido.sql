-- Aquí realizaremos las consultas del apartado "consultas varias" y de "consultas avanzadas"
SELECT * 
	FROM Grades g
	ORDER BY g.value
;

SELECT *
	FROM Grades g
	WHERE g.value >= 5
	ORDER BY (SELECT s.surname
				 FROM Students s
				 WHERE s.studentId = g.studentId)
	DESC
;

SELECT *
	FROM Grades g
	WHERE g.value >= 5
	ORDER BY (SELECT s.surname
				 FROM Students s
				 WHERE s.studentId = g.studentId)
				 DESC
	LIMIT 5
;

SELECT * 
	FROM Groups g
	JOIN GroupsStudents gs ON (g.groupId = gs.groupId)
	JOIN Students s ON (s.studentId = gs.studentId)
;

SELECT * 
	FROM Groups 
	NATURAL JOIN GroupsStudents 
	NATURAL JOIN Students
;


SELECT s.firstName, s.surname, AVG(g.value) AS mean_score
	FROM Students s
	JOIN Grades g ON (s.studentId = g.studentId)
	GROUP BY s.studentId
;

CREATE OR REPLACE VIEW vSubjectGrades AS
	SELECT st.studentId, st.firstName, st.surname,
			 sb.subjectId, sb.name, gd.value, gd.gradeCall,
			 gr.year
	FROM Students st
	JOIN Grades gd ON (st.studentId = gd.studentId)
	JOIN Groups gr ON (gd.groupId = gr.groupId)
	JOIN Subjects sb ON (sb.subjectId = gr.subjectId)
;

SELECT v.gradeCall, v.name, AVG(v.value)
	FROM vSubjectGrades v
	WHERE v.value >= 5 AND v.year = 2018
	GROUP BY v.gradeCall, v.subjectId
;
