CREATE FUNCTION [Timeouts]
(	
	@traceFile nvarchar(max) = NULL
)
RETURNS TABLE 
AS
RETURN 
(
SELECT TextData AS Query, ObjectName, DatabaseName, HostName, ApplicationName, RowCounts, LoginName, Duration, StartTime, EndTime, ServerName
FROM fn_trace_gettable((SELECT TrcFileName FROM  dbo.CurrentTraceFile), DEFAULT) 
WHERE SPID IS NOT NULL AND Error = 2
)
GO
