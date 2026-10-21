SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Restoring [Logistics].[usp_SearchFlights] to its BOOK-101 definition'
GO
-- BOOK-101: departure + arrival city, upcoming flights only, soonest first, first page of 50.
CREATE OR ALTER PROCEDURE [Logistics].[usp_SearchFlights]
    @DepartureCity NVARCHAR(50),
    @ArrivalCity   NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
        f.FlightID,
        f.Airline,
        f.DepartureCity,
        f.ArrivalCity,
        f.DepartureTime,
        f.ArrivalTime,
        f.Price,
        f.AvailableSeats
    FROM [Logistics].[Flight] AS f
    WHERE f.DepartureCity = @DepartureCity
      AND f.ArrivalCity   = @ArrivalCity
      AND f.DepartureTime >= GETDATE()
    ORDER BY f.DepartureTime ASC;
END
GO
