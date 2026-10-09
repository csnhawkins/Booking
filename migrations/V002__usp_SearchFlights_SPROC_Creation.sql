SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Creating [Logistics].[usp_SearchFlights]'
GO
IF OBJECT_ID(N'[Logistics].[usp_SearchFlights]', 'P') IS NULL
EXEC sp_executesql N'-- BOOK-101: the booking site needs to search flights by route. Customers
-- always know where they''re flying from and to at this point, so it''s
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
'
GO
PRINT N'Refreshing [Logistics].[FlightMaintenanceStatus]'
GO
IF OBJECT_ID(N'[Logistics].[FlightMaintenanceStatus]', 'V') IS NOT NULL
EXEC sp_refreshview N'[Logistics].[FlightMaintenanceStatus]'
GO
PRINT N'Creating index [IX_Flight_Route] on [Logistics].[Flight]'
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Flight_Route' AND object_id = OBJECT_ID(N'[Logistics].[Flight]'))
CREATE NONCLUSTERED INDEX [IX_Flight_Route] ON [Logistics].[Flight] ([DepartureCity], [ArrivalCity], [DepartureTime]) INCLUDE ([Airline], [ArrivalTime], [Price], [AvailableSeats])
GO

