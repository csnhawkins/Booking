-- ---------------------------------------------------------------------
-- Annotate this release on Redgate Monitor 
-- ---------------------------------------------------------------------
IF HAS_PERMS_BY_NAME(N'sys.xp_logevent', N'OBJECT', N'EXECUTE') = 1
BEGIN
    DECLARE @databaseName AS nvarchar(2048), @eventMessage AS nvarchar(2048)
    SET @databaseName = REPLACE(REPLACE(DB_NAME(), N'\', N'\\'), N'"', N'\"')
    SET @eventMessage = N'Redgate Flyway: { "deployment": { "description": "Flyway deployed to ' + 'Booking App' + N'", "database": "' + 'Booking' + N'" }}'
    EXECUTE sys.xp_logevent 55000, @eventMessage
END
GO