CREATE DATABASE School

CREATE TABLE Students(
Id  INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
FirstName NVARCHAR(30) NOT NULL,
MiddleName NVARCHAR(25),
LastName NVARCHAR(30) NOT NULL,
Age INT NOT NULL,
CHECK(Age >= 5 and Age <= 100) ,
[Address] NVARCHAR(50),
Phone NCHAR(10)
)

CREATE TABLE Subjects(
Id  INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
[Name] NVARCHAR(20) NOT NULL,
Lessons INT NOT NULL,
CHECK(Lessons > 0) 
)

CREATE TABLE Teachers(
Id  INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
FirstName NVARCHAR(20) NOT NULL,
LastName NVARCHAR(20) NOT NULL,
[Address] NVARCHAR(20) NOT NULL,
Phone NCHAR(10),
SubjectId INT NOT NULL
FOREIGN KEY (SubjectId) REFERENCES Subjects(Id)
)

CREATE TABLE StudentsSubjects(
Id  INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
StudentId INT NOT NULL,
SubjectId INT NOT NULL,
Grade DECIMAL(15,2) NOT NULL,
CHECK(Grade >= 2 and Grade <= 6) ,
FOREIGN KEY (SubjectId) REFERENCES Subjects(Id),
FOREIGN KEY (StudentId) REFERENCES Students(Id)
)


CREATE TABLE Exams(
Id  INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
Date DATETIME,
SubjectId INT NOT NULL
FOREIGN KEY (SubjectId) REFERENCES Subjects(Id),
)

CREATE TABLE StudentsExams(
StudentId INT NOT NULL,
ExamId INT NOT NULL,
Grade DECIMAL(15,2) NOT NULL,
CHECK(Grade >= 2 and Grade <= 6),
FOREIGN KEY (StudentId) REFERENCES Students(Id),
FOREIGN KEY (ExamId) REFERENCES Exams(Id),
PRIMARY KEY (StudentId,ExamId)
)

CREATE TABLE StudentsTeachers (
StudentId INT NOT NULL,
TeacherId INT NOT NULL
FOREIGN KEY (StudentId) REFERENCES Students(Id),
FOREIGN KEY (TeacherId) REFERENCES Teachers(Id),
PRIMARY KEY(StudentId,TeacherId)
)


 INSERT INTO Teachers(FirstName,LastName,Address,Phone,SubjectId)
 VALUES
 ('Ruthanne','Bamb','84948 Mesta Junction','3105500146',6),
 ('Gerrard','Lowin','370 Talisman Plaza','3324874824',2),
 ('Merrile','Lambdin','81 Dahle Plaza','4373065154',5),
 ('Bert','Ivie','2 Gateway Circle','4409584510',4)

 INSERT INTO Subjects (Name,Lessons)
 VALUES
 ('Geometry',12),
 ('Health',10),
 ('Drama',7),
 ('Sports',9)


 UPDATE StudentsSubjects
 SET Grade = 6.00
 WHERE Grade>=5.50 AND SubjectId IN(1,2)

 DELETE FROM StudentsTeachers WHERE TeacherId IN (SELECT Teachers.Id FROM Teachers WHERE Teachers.Phone LIKE '%72%')
 DELETE FROM Teachers WHERE Teachers.Phone LIKE ('%72%')


 SELECT FirstName,LastName,Age
  FROM  Students
  WHERE Students.Age >= 12 
  ORDER BY FirstName,LastName


 SELECT s.FirstName,s.LastName , COUNT(t.Id) as TeachersCount
 FROM Students s
 JOIN StudentsTeachers st ON st.StudentId = s.Id
 JOIN Teachers t ON t.Id = st.TeacherId 
 GROUP BY s.FirstName,s.LastName


 SELECT s.FirstName+' '+s.LastName as [Full Name] FROM Students s
 FULL JOIN StudentsExams se ON s.Id = se.StudentId
 FULL JOIN Exams e ON s.Id = se.ExamId
 WHERE ExamId IS NULL
 ORDER BY [Full Name]


SELECT TOP(10) s.FirstName,s.LastName, FORMAT(AVG(se.Grade),'N2') as Grade FROM Students s
JOIN StudentsExams se ON s.Id = se.StudentId
GROUP BY s.FirstName,s.LastName
ORDER BY Grade DESC,s.FirstName,s.LastName


SELECT s.FirstName+' '+ISNULL(s.MiddleName+' ','')+s.LastName as [Full Name]
FROM Students s
FULL JOIN StudentsSubjects sb ON sb.StudentId = s.Id
FULL JOIN Subjects sub ON sub.Id = sb.SubjectId 
WHERE sub.Id IS NULL
ORDER BY [Full Name]


SELECT s.Name, AVG(ss.Grade) as AverageGrade FROM Subjects s
JOIN StudentsSubjects ss ON ss.SubjectId = s.Id
GROUP BY s.Name, s.Id
ORDER BY s.Id


CREATE OR ALTER FUNCTION udf_ExamGradesToUpdate(@studentId INT , @grade DECIMAL(15,2))
RETURNS VARCHAR(100)
AS 
BEGIN

IF @grade > 6.00
RETURN 'Grade cannot be above 6.00!'

IF @studentId < 0 OR @studentId IS NULL OR @studentId > (SELECT MAX(Id) FROM Students)
RETURN 'The student with provided id does not exist in the school!'

DECLARE @gradesCount INT =  (SELECT COUNT(Grade) FROM StudentsExams 
								WHERE Grade BETWEEN @grade AND Grade+@grade
								GROUP BY StudentId
								HAVING StudentId = @studentId)

DECLARE @student NVARCHAR(50) = (SELECT Students.FirstName From Students WHERE Students.Id =@studentId)

RETURN CONCAT('You have to update ',@gradesCount,' grades for the student ',@student)

END

SELECT dbo.udf_ExamGradesToUpdate(12, 6.20)


SELECT dbo.udf_ExamGradesToUpdate(12, 5.50)

SELECT dbo.udf_ExamGradesToUpdate(121, 5.50)



CREATE PROCEDURE usp_ExcludeFromSchool(@StudentId INT)
AS
BEGIN

DECLARE @msgText VARCHAR(50) = 'This school has no student with the provided id!';

IF @StudentId < 0 OR @StudentId IS NULL OR @StudentId > (SELECT MAX(Id) FROM Students)
THROW 51000,@msgText,1;

DELETE FROM StudentsTeachers WHERE StudentsTeachers.StudentId = @StudentId
DELETE FROM StudentsExams WHERE StudentsExams.StudentId = @StudentId
DELETE FROM StudentsSubjects WHERE StudentsSubjects.StudentId = @StudentId
DELETE FROM Students WHERE Students.Id = @StudentId

END