CREATE FUNCTION [dbo].[TraceData]
(	
	@traceFile nvarchar(max) = NULL,
	@errors int = 0
)
RETURNS TABLE 
AS
RETURN 
(
SELECT TextData AS Query, ObjectName, DatabaseName, HostName, ApplicationName, RowCounts, LoginName, Duration, StartTime, EndTime, ServerName, Error
FROM fn_trace_gettable(CASE WHEN @traceFile IS NULL 
THEN (SELECT TrcFileName FROM  dbo.CurrentTraceFile)
ELSE 'D:\SQLProfiler\' + @traceFile +'.trc' END, DEFAULT) 
WHERE 
(SPID IS NOT NULL AND Error = @errors)
OR
(SPID IS NOT NULL AND @errors = 0)
OR
(@errors IS NULL)
)
GO
