SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Dropping index [IX_Flight_Route] from [Logistics].[Flight]'
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Flight_Route' AND object_id = OBJECT_ID(N'[Logistics].[Flight]'))
DROP INDEX [IX_Flight_Route] ON [Logistics].[Flight]
GO
PRINT N'Dropping [Logistics].[usp_SearchFlights]'
GO
IF OBJECT_ID(N'[Logistics].[usp_SearchFlights]', 'P') IS NOT NULL
DROP PROCEDURE [Logistics].[usp_SearchFlights]
GO
PRINT N'Refreshing [Logistics].[FlightMaintenanceStatus]'
GO
IF OBJECT_ID(N'[Logistics].[FlightMaintenanceStatus]', 'V') IS NOT NULL
EXEC sp_refreshview N'[Logistics].[FlightMaintenanceStatus]'
GO

