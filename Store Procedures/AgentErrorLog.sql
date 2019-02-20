CREATE PROCEDURE [dbo].[AgentErrorLog]
AS
DECLARE @AgentErrorlog TABLE (LogDate datetime, ErrorLevel VARCHAR (10),ErrorMSG VARCHAR(4000))
INSERT INTO @AgentErrorlog 
EXEC sp_executesql N'xp_readerrorlog 0,2'

SELECT  LogDate,ErrorLevel,ErrorMSG
--case when errorlevel = 1 then 'Error'
--when errorlevel = 2 then 'Warning'
--when errorlevel = 3 then 'Informational' end ErrorLevel,ErrorMSG
FROM  @AgentErrorlog ORDER BY LogDate DESC
RETURN 0
