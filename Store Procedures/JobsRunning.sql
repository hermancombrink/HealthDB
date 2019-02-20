CREATE PROCEDURE [dbo].[JobsRunning]
AS
BEGIN
exec msdb.dbo.sp_help_job @execution_status=1 
END 
GO
