SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- BOOK-214: customers keep typing "Lon" or "new york" instead of the exact city name and getting no
-- results, so make the search forgiving (partial, case-insensitive match). Product also asked for a
-- "number of flights earlier on this route" column so the site can show "3rd flight today", the
-- engineering flag for flights with maintenance history, and to show every match instead of just
-- the first page, cheapest first.
-- BOOK-215: fix slow search. City match is now a case-insensitive prefix match (SARGable on
-- IX_Flight_Route), earlier-flight count uses a window function, and maintenance rows are counted
-- per matching flight instead of aggregating the whole MaintenanceLog through the view.

CREATE OR ALTER PROCEDURE [Logistics].[usp_SearchFlights]
    @DepartureCity NVARCHAR(50),
    @ArrivalCity   NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME = GETDATE();

    -- Rank over every flight on the matched routes (past ones included) so the count matches the old subquery
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
            CAST(RANK() OVER (PARTITION BY f.DepartureCity, f.ArrivalCity ORDER BY f.DepartureTime) - 1 AS INT) AS FlightsEarlierOnRoute
        FROM [Logistics].[Flight] AS f
        WHERE f.DepartureCity LIKE @DepartureCity + '%'
          AND f.ArrivalCity   LIKE @ArrivalCity   + '%'
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
        mc.MaintenanceCount,
        rf.FlightsEarlierOnRoute
    FROM RouteFlights AS rf
    OUTER APPLY
    (
        SELECT COUNT(m.LogID) AS MaintenanceCount
        FROM [Logistics].[MaintenanceLog] AS m
        WHERE m.FlightID = rf.FlightID
    ) AS mc
    WHERE rf.DepartureTime >= @Now
    ORDER BY rf.Price ASC;
END
GO
