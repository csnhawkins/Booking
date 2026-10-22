SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- BOOK-214: customers keep typing "Lon" or "new york" instead of the exact city name and getting no
-- results, so make the search forgiving (partial, case-insensitive match). Product also asked for a
-- "number of flights earlier on this route" column so the site can show "3rd flight today", the
-- engineering flag for flights with maintenance history, and to show every match instead of just
-- the first page, cheapest first.
-- BOOK-215: performance fix. Matching relies on the database collation being case-insensitive
-- (SQL_Latin1_General_CP1_CI_AS) so LOWER() is not needed. The per-row subquery and the whole-table
-- view aggregation are replaced by a window function over the matched routes and an aggregate of
-- MaintenanceLog only.

CREATE OR ALTER PROCEDURE [Logistics].[usp_SearchFlights]
    @DepartureCity NVARCHAR(50),
    @ArrivalCity   NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME = GETDATE();

    -- RANK() - 1 counts flights on the route with a strictly earlier departure, including past ones.
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
        WHERE f.DepartureCity LIKE '%' + @DepartureCity + '%'
          AND f.ArrivalCity   LIKE '%' + @ArrivalCity   + '%'
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
        ISNULL(ml.MaintenanceCount, 0) AS MaintenanceCount,
        rf.FlightsEarlierOnRoute
    FROM RouteFlights AS rf
    LEFT JOIN
    (
        SELECT m.FlightID, COUNT(m.LogID) AS MaintenanceCount
        FROM [Logistics].[MaintenanceLog] AS m
        GROUP BY m.FlightID
    ) AS ml ON ml.FlightID = rf.FlightID
    WHERE rf.DepartureTime >= @Now
    ORDER BY rf.Price ASC;
END
GO
