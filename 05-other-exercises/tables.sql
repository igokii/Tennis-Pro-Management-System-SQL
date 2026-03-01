DROP TABLE IF EXISTS Grades;
DROP TABLE IF EXISTS GroupsStudents;
DROP TABLE IF EXISTS Students;
DROP TABLE IF EXISTS Groups;
DROP TABLE IF EXISTS Subjects;
DROP TABLE IF EXISTS Degrees;

CREATE TABLE Degrees(
	degreeId INT NOT NULL AUTO_INCREMENT,
	name VARCHAR(64) NOT NULL,
	years INT DEFAULT(4) NOT NULL,
	PRIMARY KEY (degreeId),
	CONSTRAINT invalidDegreeYear CHECK (years >= 3 AND years <= 5),
	CONSTRAINT uniqueDegreeName UNIQUE (name)
);

CREATE TABLE Subjects(
	subjectId INT NOT NULL AUTO_INCREMENT,
	name VARCHAR(100) NOT NULL,
	acronym VARCHAR(8) NOT NULL,
	credits INT NOT NULL,
	year INT NOT NULL,
	type VARCHAR(20) NOT NULL,
	degreeId INT NOT NULL,
	PRIMARY KEY (subjectId),
	FOREIGN KEY (degreeId) REFERENCES Degrees (degreeId),
	CONSTRAINT uniqueSubjectName UNIQUE (name),
	CONSTRAINT uniqueSubjectAcronym UNIQUE (acronym),
	CONSTRAINT negativeSubjectCredits CHECK (credits > 0),
	CONSTRAINT invalidSubjectYear CHECK (year >= 1 AND year <= 5),
	CONSTRAINT invalidSubjectType CHECK (type IN ('Formación Básica', 'Optativa', 'Obligatoria'))
);

CREATE TABLE Groups(
	groupId INT NOT NULL AUTO_INCREMENT,
	name VARCHAR(30) NOT NULL,
	activity VARCHAR(20) NOT NULL,
	year INT NOT NULL,
	subjectId INT NOT NULL,
	PRIMARY KEY (groupId),
	FOREIGN KEY (subjectId) REFERENCES Subjects (subjectId) ON DELETE CASCADE,
	CONSTRAINT repeatedGroup UNIQUE (name, year, subjectId),
	CONSTRAINT invalidGroupActivity CHECK (activity IN ('Teoría', 'Laboratorio')),
	CONSTRAINT negativeGroupYear CHECK (year > 0)
);

CREATE TABLE Students(
	studentId INT NOT NULL AUTO_INCREMENT,
	accessMethod VARCHAR(30) NOT NULL,
	dni CHAR(9) NOT NULL,
	firstName VARCHAR(100) NOT NULL,
	surname VARCHAR(100) NOT NULL,
	birthDate DATE NOT NULL,
	email VARCHAR(250) NOT NULL,
	password VARCHAR(250) NOT NULL,
	PRIMARY KEY (studentId),
	CONSTRAINT invalidStudentAccessMethod CHECK (accessMethod IN ('Selectividad', 'Ciclo', 'Mayor', 'Titulado Extranjero')),
	CONSTRAINT uniqueStudentDni UNIQUE (dni),
	CONSTRAINT uniqueStudentEmail UNIQUE (email)
);

CREATE TABLE GroupsStudents(
	GroupStudentId INT NOT NULL AUTO_INCREMENT,
	groupId INT NOT NULL,
	studentId INT NOT NULL,
	PRIMARY KEY (groupStudentId),
	FOREIGN KEY (groupId) REFERENCES Groups (groupId),
	FOREIGN KEY (studentId) REFERENCES Students (studentId),
	CONSTRAINT repeatedGroupStudent UNIQUE (groupId, studentId)
);

CREATE TABLE Grades(
	gradeId INT NOT NULL AUTO_INCREMENT,
	value INT NOT NULL,
	gradeCall DEC(4,2) NOT NULL,
	withHonours BOOLEAN NOT NULL,
	groupId INT NOT NULL,
	studentId INT NOT NULL,
	PRIMARY KEY (gradeId),
	FOREIGN KEY (groupId) REFERENCES Groups (groupId),
	FOREIGN KEY (studentId) REFERENCES Students (studentId),
	CONSTRAINT repreatedGrade UNIQUE (groupId, studentId, gradeCall),
	CONSTRAINT invalidGradeValue CHECK (value >= 0 AND value <= 10),
	CONSTRAINT invalidGradeCall CHECK (gradeCall >= 1 AND gradeCall <= 3)
);


