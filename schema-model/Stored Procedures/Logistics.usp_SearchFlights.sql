SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- BOOK-101: the booking site needs to search flights by route. Customers
-- always know where they're flying from and to at this point, so it's
-- departure + arrival city, upcoming flights only, soonest first, first
-- page of 50.

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
