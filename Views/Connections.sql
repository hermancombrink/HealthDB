CREATE VIEW [dbo].[Connections]
AS
SELECT        TOP (100) PERCENT @@SERVERNAME AS Server, DB_NAME(database_id) AS DatabaseName, COUNT(database_id) AS Connections, login_name AS LoginName, MIN(login_time) AS Login_Time, 
                         MIN(COALESCE (last_request_end_time, last_request_start_time)) AS Last_Batch
FROM            sys.dm_exec_sessions
WHERE        (database_id > 0) AND (DB_NAME(database_id) NOT IN ('master', 'msdb'))
GROUP BY database_id, login_name
ORDER BY DatabaseName
GO
