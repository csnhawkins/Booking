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
-- BOOK-215: made SARGable. City search is now a case-insensitive prefix match (database collation is
-- SQL_Latin1_General_CP1_CI_AS) so IX_Flight_Route can be used; the per-row correlated count is a
-- RANK() window (RANK() - 1 = rows with a strictly earlier DepartureTime, past flights included);
-- maintenance counts are aggregated only for the matching flights.

CREATE OR ALTER PROCEDURE [Logistics].[usp_SearchFlights]
    @DepartureCity NVARCHAR(50),
    @ArrivalCity   NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME = GETDATE();

    WITH RouteFlights AS
    (
        SELECT
            f.FlightID,
            f.Airline,
            f.DepartureCity,
            f.ArrivalCity,
            f.DepartureTime,
            f.ArrivalTime,
            f.Price,
            f.AvailableSeats,
            RANK() OVER (PARTITION BY f.DepartureCity, f.ArrivalCity ORDER BY f.DepartureTime) - 1 AS FlightsEarlierOnRoute
        FROM [Logistics].[Flight] AS f
        WHERE f.DepartureCity LIKE @DepartureCity + ''%''
          AND f.ArrivalCity   LIKE @ArrivalCity   + ''%''
    )
    SELECT
        rf.FlightID,
        rf.Airline,
        rf.DepartureCity,
        rf.ArrivalCity,
        rf.DepartureTime,
        rf.ArrivalTime,
        rf.Price,
        rf.AvailableSeats,
        (SELECT COUNT(m.LogID)
         FROM [Logistics].[MaintenanceLog] AS m
         WHERE m.FlightID = rf.FlightID) AS MaintenanceCount,
        rf.FlightsEarlierOnRoute
    FROM RouteFlights AS rf
    WHERE rf.DepartureTime >= @Now
    ORDER BY rf.Price ASC;
END
'
GO

