SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- BOOK-214: customers keep typing "Lon" or "new york" instead of the exact city name and getting no
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
        -- Count maintenance rows only for the flights returned. The previous join to the
        -- FlightMaintenanceStatus view aggregated every flight in the table (about 1M rows) on every search.
        (SELECT COUNT(m.LogID)
         FROM [Logistics].[MaintenanceLog] AS m
         WHERE m.FlightID = f.FlightID) AS MaintenanceCount,
        -- Seeks on IX_Flight_Route (DepartureCity, ArrivalCity, DepartureTime) once per returned row.
        (SELECT COUNT(*)
         FROM [Logistics].[Flight] AS earlier
         WHERE earlier.DepartureCity = f.DepartureCity
           AND earlier.ArrivalCity   = f.ArrivalCity
           AND earlier.DepartureTime < f.DepartureTime) AS FlightsEarlierOnRoute
    FROM [Logistics].[Flight] AS f
    -- Prefix match ("Lon" finds "London") so IX_Flight_Route can be used for a seek. The database collation
    -- is case-insensitive, so LOWER() is not needed and would stop the index being used.
    WHERE f.DepartureCity LIKE @DepartureCity + N'%'
      AND f.ArrivalCity   LIKE @ArrivalCity   + N'%'
      AND f.DepartureTime >= GETDATE()
    ORDER BY f.Price ASC;
END
GO
