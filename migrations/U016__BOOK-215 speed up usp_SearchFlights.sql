SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Altering [Logistics].[usp_SearchFlights]'
GO
IF OBJECT_ID(N'[Logistics].[usp_SearchFlights]', 'P') IS NOT NULL
EXEC sp_executesql N'-- BOOK-214: customers keep typing "Lon" or "new york" instead of the exact city name and getting no
-- results, so make the search forgiving (partial, case-insensitive match). Product also asked for a
-- "number of flights earlier on this route" column so the site can show "3rd flight today", the
-- engineering flag for flights with maintenance history, and to show every match instead of just
-- the first page, cheapest first.
CREATE OR ALTER PROCEDURE [Logistics].[usp_SearchFlights]
    @DepartureCity NVARCHAR(50),
    @ArrivalCity   NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        f.FlightID,
        f.Airline,
        f.DepartureCity,
        f.ArrivalCity,
        f.DepartureTime,
        f.ArrivalTime,
        f.Price,
        f.AvailableSeats,
        ms.MaintenanceCount,
        (SELECT COUNT(*)
         FROM [Logistics].[Flight] AS earlier
         WHERE earlier.DepartureCity = f.DepartureCity
           AND earlier.ArrivalCity   = f.ArrivalCity
           AND earlier.DepartureTime < f.DepartureTime) AS FlightsEarlierOnRoute
    FROM [Logistics].[Flight] AS f
    LEFT JOIN [Logistics].[FlightMaintenanceStatus] AS ms ON ms.FlightID = f.FlightID
    WHERE LOWER(f.DepartureCity) LIKE ''%'' + LOWER(@DepartureCity) + ''%''
      AND LOWER(f.ArrivalCity)   LIKE ''%'' + LOWER(@ArrivalCity)   + ''%''
      AND f.DepartureTime >= GETDATE()
    ORDER BY f.Price ASC;
END'
GO

