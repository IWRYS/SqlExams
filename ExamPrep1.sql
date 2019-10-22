CREATE DATABASE Airport

CREATE TABLE Planes(
Id INT NOT NULL PRIMARY KEY IDENTITY (1,1),
[Name] VARCHAR(30) NOT NULL,
Seats INT NOT NULL,
Range INT NOT NULL
)

CREATE TABLE Flights (
Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
DepartureTime DATETIME,
ArrivalTime DATETIME,
Origin VARCHAR(50) NOT NULL,
Destination VARCHAR(50) NOT NULL,
PlaneId INT NOT NULL,
FOREIGN KEY (PlaneId) REFERENCES Planes(Id)
)

CREATE TABLE Passengers(
Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
FirstName VARCHAR(30) NOT NULL,
LastName VARCHAR(30) NOT NULL,
Age INT NOT NULL,
Address VARCHAR(30) NOT NULL,
PassportId CHAR(11) NOT NULL
)

CREATE TABLE LuggageTypes (
Id INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
[Type] VARCHAR(30) NOT NULL
)

CREATE TABLE Luggages(
Id INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
LuggageTypeId INT NOT NULL,
PassengerId INT NOT NULL
FOREIGN KEY (LuggageTypeId) REFERENCES LuggageTypes(Id),
FOREIGN KEY (PassengerId) REFERENCES Passengers(Id)
)

CREATE TABLE Tickets (
Id INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
PassengerId INT NOT NULL,
FlightId INT NOT NULL,
LuggageId INT NOT NULL,
Price DECIMAL(15,2)
FOREIGN KEY (PassengerId) REFERENCES Passengers(Id),
FOREIGN KEY (FlightId) REFERENCES Flights(Id),
FOREIGN KEY (LuggageId) REFERENCES Luggages(Id)
)


INSERT INTO Planes([Name],Seats,[Range])
VALUES
('Airbus 336',112,5132),
('Airbus 330',432,5325),
('Boeing 369',231,2355),
('Stelt 297',254,2143),
('Boeing 338',165,5111),
('Airbus 558',387,1342),
('Boeing 128',345,5541)


INSERT INTO LuggageTypes([Type])
VALUES
('Crossbody Bag'),
('School Backpack'),
('Shoulder Bag')

UPDATE Tickets
SET Price+= Price * 0.13 
WHERE FlightId IN (SELECT Flights.Id
						FROM Flights
						WHERE Flights.Destination ='Carlsbad')
						 
DELETE FROM Tickets
WHERE FlightId IN ( SELECT FlightId
					FROM Flights
					WHERE Flights.Destination ='Ayn Halagim')

DELETE FROM Flights
WHERE Flights.Destination = 'Ayn Halagim'


SELECT *
FROM Planes
WHERE Planes.Name Like ('%tr%')
ORDER BY Id,Name,Seats,Range


SELECT t.FlightId,SUM(t.Price) as Price
FROM Tickets t
GROUP BY t.FlightId
ORDER BY Price DESC, t.FlightId

SELECT p.FirstName+' '+p.LastName as [Full Name], f.Origin,f.Destination FROM Passengers p
JOIN Tickets t ON p.Id = t.PassengerId
JOIN Flights f ON t.FlightId = f.Id
ORDER BY [Full Name],Origin,Destination


SELECT p.FirstName,p.LastName,p.Age FROM Passengers p
LEFT JOIN Tickets t ON p.Id = t.PassengerId
WHERE t.PassengerId IS NULL
ORDER BY p.Age DESC, p.FirstName,p.LastName


SELECT  pas.FirstName+' '+pas.LastName as [Full Name],
p.Name as [Plane Name],
f.Origin+' - '+f.Destination as Trip,
lt.[Type] as [Luggage Type]
FROM Passengers pas
JOIN Tickets t ON t.PassengerId =pas.Id
JOIN Flights f ON f.Id = t.FlightId
JOIN Planes p ON f.PlaneId = p.Id
JOIN Luggages l ON t.LuggageId = l.Id
JOIN LuggageTypes lt ON l.LuggageTypeId = lt.Id
ORDER BY [Full Name],[Plane Name],Origin,Destination,[Luggage Type]

SELECT * FROM Tickets
SELECT * FROM Luggages
SELECT * FROM LuggageTypes
SELECT * FROM Planes
SELECT * FROM Flights
SELECT * FROM Passengers


SELECT p.Name,p.Seats,COUNT(pas.Id) as [Passengers Count]
FROM Planes p
LEFT JOIN Flights f ON f.PlaneId = p.Id
LEFT JOIN Tickets t ON t.FlightId = f.Id
LEFT JOIN Passengers pas ON pas.Id =t.PassengerId
GROUP BY p.Name, p.Seats
ORDER BY [Passengers Count] DESC,p.Name,p.Seats


CREATE FUNCTION udf_CalculateTickets(@origin VARCHAR(50), @destination VARCHAR(50), @peopleCount INT)
RETURNS VARCHAR(50)
AS
BEGIN
IF @peopleCount <=0 RETURN 'Invalid people count!';
DECLARE @flightId INT =(SELECT TOP(1) Id FROM Flights
						WHERE Origin=@origin AND Destination = @destination)

IF @flightId IS NULL RETURN 'Invalid flight!';

DECLARE @pricePerPerson DECIMAL(18,2) = (SELECT t.Price FROM Tickets t 
										WHERE t.FlightId =@flightId )
DECLARE @result VARCHAR(50) = CONCAT('Total price ',@pricePerPerson * @peopleCount)

RETURN @result
END



CREATE PROC usp_CancelFlights
AS
BEGIN
UPDATE	Flights
SET DepartureTime = NULL, ArrivalTime = NULL
WHERE DATEDIFF(SECOND,DepartureTime,ArrivalTime)> 0
END
